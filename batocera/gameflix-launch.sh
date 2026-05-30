#!/bin/bash
# es_systems.cfg <command> wrapper: download the chosen ROM (and, for zipped
# Redump-style images, extract it) BEFORE handing off to emulatorlauncher.
#
# Why this lives in <command> instead of a game-start hook: on Linux,
# Batocera ES sets `psi.waitForExit = (eventName == "quit")` in
# es-core/src/Scripting.cpp's executeScript — so game-start hooks (and the
# `-wait` suffix) do NOT block the emulator launch. A 338 MB CHD fetch
# would race the emulator, which loses. The <command> string IS the launch,
# so ES does wait for us to return.
#
# Two download shapes (see urls.sh sources):
#  * file INSIDE an archive.org .zip (URL like .../Collection.zip/Game.zip),
#    served via view_archive.php — a HEAD reports the *container* zip size
#    (e.g. 324 MB for the whole Mega Drive set), not the inner ROM, and ranges
#    don't map to the inner file. So: single-stream, and a pulsating bar
#    (real size unknown) showing MB downloaded.
#  * a direct file in an item (URL like .../item/ROMS/Game.zip) — HEAD reports
#    the real size and honours ranges. So: a real percentage bar, and a
#    parallel range-chunked download (≈4.4× on a 20 MB CDTV sample).
#
# On-screen progress is a `yad` window AS a Wayland client (ES runs under a
# labwc/wlroots compositor; a chvt to a text VT fought the session and dropped
# the Steam Deck panel rotation — never switch VTs here). Best-effort: missing
# yad/display just disables the window, never the download.
#
# Args (passed straight through to emulatorlauncher except -rom): typically
#   %CONTROLLERSCONFIG% -system %SYSTEM% -rom %ROM% -gameinfoxml %GAMEINFOXML% -systemname %SYSTEMNAME%
LOG=/userdata/system/logs/gameflix-fetch.log

# --- on-screen progress via a yad GTK dialog (Wayland-native) --------------
GF_FIFO=""; GF_YAD=""; GF_NAME=""; GF_TOT=0
gf_ui_init() {  # $1=label  $2=total bytes (0/unknown => pulsating bar)
  command -v yad >/dev/null 2>&1 || return 0
  : "${XDG_RUNTIME_DIR:=/var/run}"; : "${WAYLAND_DISPLAY:=wayland-0}"
  export XDG_RUNTIME_DIR WAYLAND_DISPLAY
  [[ -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" ]] || return 0
  GF_NAME="$1"; GF_TOT="${2:-0}"; [[ "$GF_TOT" =~ ^[0-9]+$ ]] || GF_TOT=0
  local mode=""; (( GF_TOT > 0 )) || mode="--pulsate"
  GF_FIFO=$(mktemp -u)
  mkfifo "$GF_FIFO" 2>/dev/null || { GF_FIFO=""; return 0; }
  exec 9<>"$GF_FIFO"   # read-write so the open never blocks if yad dies
  GDK_BACKEND=wayland yad --progress $mode --title="gameflix" \
      --text="Downloading $1" --no-buttons --auto-close --center --width=520 \
      < "$GF_FIFO" >/dev/null 2>&1 &
  GF_YAD=$!
}
gf_sum() { stat -c%s "$@" 2>/dev/null | awk '{s+=$1} END{print s+0}'; }
gf_prog() {  # $1 = bytes downloaded so far
  [[ -n "$GF_FIFO" ]] || return 0
  local cur="${1:-0}"
  if (( GF_TOT > 0 )); then
    local pct=$(( cur*100/GF_TOT )); (( pct > 100 )) && pct=100
    printf '#%s  %d / %d MB\n%d\n' "$GF_NAME" $((cur/1048576)) $((GF_TOT/1048576)) "$pct" >&9 2>/dev/null
  else
    printf '#%s  —  %d MB\n' "$GF_NAME" $((cur/1048576)) >&9 2>/dev/null
  fi
}
gf_ui_done() {
  [[ -n "$GF_FIFO" ]] || return 0
  exec 9>&- 2>/dev/null         # close write end
  kill "$GF_YAD" 2>/dev/null    # don't rely on EOF/auto-close — kill it
  wait "$GF_YAD" 2>/dev/null
  rm -f "$GF_FIFO"
  GF_FIFO=""
}

args=("$@")
rom=""; rom_idx=-1
for ((i=0;i<${#args[@]};i++)); do
  if [[ "${args[$i]}" == "-rom" ]]; then
    rom="${args[$((i+1))]}"
    rom_idx=$((i+1))
    break
  fi
done

# Strip the double-escape backslashes Batocera's getEscapedPath adds
[[ -n "$rom" ]] && rom="${rom//\\/}"

# 1. ON-DEMAND DOWNLOAD ----------------------------------------------------
if [[ -n "$rom" && ! -e "$rom" ]]; then
  src=""
  if [[ -f /userdata/system/urls.sh ]]; then
    . /userdata/system/urls.sh
    gameflix_lookup_src "$(dirname "$rom")/"
  fi
  if [[ -n "$src" ]]; then
    ia_auth=""
    if [[ -f /userdata/system/rclone.conf ]]; then
      ia_key=$(awk '/^\[archive\]/{f=1;next} /^\[/{f=0} f && /access_key_id/{print $3;exit}' /userdata/system/rclone.conf)
      ia_sec=$(awk '/^\[archive\]/{f=1;next} /^\[/{f=0} f && /secret_access_key/{print $3;exit}' /userdata/system/rclone.conf)
      [[ -n "$ia_key" && -n "$ia_sec" ]] && ia_auth="LOW ${ia_key}:${ia_sec}"
    fi
    relpath="${rom#/userdata/roms/}"; inner="${relpath#*/}"; inner="${inner#*/}"
    urlenc() { local LC_ALL=C s="$1" i c e=""; for ((i=0;i<${#s};i++)); do c="${s:i:1}"; case "$c" in [/a-zA-Z0-9._~-]) e+="$c";; *) printf -v c '%%%02X' "'$c"; e+="$c";; esac; done; printf '%s' "$e"; }
    enc=$(urlenc "$inner")
    mkdir -p "$(dirname "$rom")"
    dl_url="${src}${enc}"
    name=$(basename "$rom")
    {
      echo "[$(date '+%F %T')] launch-wrapper fetch start: $inner"
      echo "  url: ${dl_url}"
    } >>"$LOG"

    # A ".zip/" path component means archive.org view_archive.php extraction —
    # HEAD reports the container size and ranges don't map to the inner file.
    size=0; ranges=""
    if [[ "$dl_url" != *.zip/* ]]; then
      hdr=$(curl -sIL --location-trusted ${ia_auth:+-H "Authorization: $ia_auth"} "$dl_url" 2>>"$LOG")
      size=$(echo "$hdr" | grep -i '^content-length:' | tail -1 | awk '{print $2}' | tr -d '\r\n')
      ranges=$(echo "$hdr" | grep -i '^accept-ranges:' | tail -1 | awk '{print $2}' | tr -d '\r\n')
      [[ "$size" =~ ^[0-9]+$ ]] || size=0
    fi
    gf_ui_init "$name" "$size"

    fetch_ok=0
    if [[ "$ranges" == "bytes" && "$size" -gt 4194304 ]]; then
      # Parallel range-chunked download (direct files only). archive.org
      # throttles past ~6-8 connections per IP, so cap there.
      if   (( size > 524288000 )); then n=8     # >500 MB (PS2/GC/Wii)
      elif (( size >  52428800 )); then n=6     # >50 MB (CHD, large CD/PSX)
      else                              n=4     # 4-50 MB
      fi
      chunk=$((size / n))
      tmpdir=$(mktemp -d)
      echo "[$(date '+%F %T')] chunked fetch: $size bytes in $n parts" >>"$LOG"
      pids=()
      for ((i=0; i<n; i++)); do
        start=$((i*chunk))
        end=$((i==n-1 ? size-1 : (i+1)*chunk-1))
        curl -sfL --location-trusted ${ia_auth:+-H "Authorization: $ia_auth"} \
             --range "${start}-${end}" -o "$tmpdir/p$i" "$dl_url" 2>>"$LOG" &
        pids+=($!)
      done
      # high-water mark: a part may truncate+restart on a redirect/reset, so
      # the raw byte-sum can dip — never let the bar go backwards.
      ( hi=0; while :; do c=$(gf_sum "$tmpdir"/p*); (( c > hi )) && hi=$c; gf_prog "$hi"; sleep 1; done ) & prog=$!
      chunk_ok=1
      for pid in "${pids[@]}"; do wait "$pid" || chunk_ok=0; done
      kill "$prog" 2>/dev/null; wait "$prog" 2>/dev/null
      if (( chunk_ok == 1 )); then
        cat "$tmpdir"/p* > "$rom" && fetch_ok=1
      fi
      rm -rf "$tmpdir"
    fi
    if (( fetch_ok == 0 )); then
      # Single stream (-s: no progress meter spamming the log). For inner-zip
      # the bar pulsates; for a direct file with a known size it shows percent.
      curl -sfL --location-trusted ${ia_auth:+-H "Authorization: $ia_auth"} -o "$rom" "$dl_url" 2>>"$LOG" & cpid=$!
      ( while :; do gf_prog "$(gf_sum "$rom")"; sleep 1; done ) & prog=$!
      cok=0; wait "$cpid" || cok=1
      kill "$prog" 2>/dev/null; wait "$prog" 2>/dev/null
      if (( cok != 0 )); then
        rm -f "$rom"
        echo "[$(date '+%F %T')] launch-wrapper download FAILED" >>"$LOG"
        gf_ui_done
        exit 1
      fi
    fi
    echo "[$(date '+%F %T')] launch-wrapper fetch done ($(stat -c%s "$rom") bytes)" >>"$LOG"
    gf_ui_done
  fi
fi

# 2. ZIP-WRAPPED CD-IMAGE HANDLING -----------------------------------------
# If the ROM is a zip containing CUE+BIN/track files (Redump/NonRedump style),
# mount it into /userdata/iso and swap -rom to point at the first playable
# inner file. Stock Batocera handled this in the per-system command, but only
# globbed for *.cue — fails for .iso/.gdi/.chd inside zips.
if [[ "$rom" == *.zip ]]; then
  umount /userdata/iso 2>/dev/null
  rm -rf /userdata/iso
  mkdir -p /userdata/iso
  /userdata/system/mount-zip "$rom" /userdata/iso 2>>"$LOG"
  inner=""
  for ext in cue gdi iso chd rvz gcm 3ds cci pbp cso m3u nrg toc img mdf ccd dol elf; do
    cand=$(ls /userdata/iso/*."$ext" 2>/dev/null | head -1)
    if [[ -n "$cand" ]]; then inner="$cand"; break; fi
  done
  if [[ -n "$inner" ]]; then
    args[$rom_idx]="$inner"
  else
    echo "[$(date '+%F %T')] zip-mount: no playable file inside $rom" >>"$LOG"
    ls -la /userdata/iso >>"$LOG"
  fi
fi

# 3. Hand off to the real launcher -----------------------------------------
exec emulatorlauncher "${args[@]}"
