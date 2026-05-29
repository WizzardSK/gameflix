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
# Args (passed straight through to emulatorlauncher except -rom): typically
#   %CONTROLLERSCONFIG% -system %SYSTEM% -rom %ROM% -gameinfoxml %GAMEINFOXML% -systemname %SYSTEMNAME%
LOG=/userdata/system/logs/gameflix-fetch.log

# --- on-screen download status on a scratch text VT ------------------------
# ES is frozen waiting for this <command>, so the screen is otherwise black
# during the fetch. Switch to a spare VT, print a progress bar, switch back
# before handing off to emulatorlauncher. Entirely best-effort: any missing
# tool (chvt/fgconsole) just disables the UI, never the download.
GF_VT=""; GF_TTY=""; GF_SCRATCH="${GAMEFLIX_VT:-6}"
gf_ui_init() {
  command -v chvt >/dev/null 2>&1 || return 0
  GF_VT=$(fgconsole 2>/dev/null || echo 1)
  if chvt "$GF_SCRATCH" 2>/dev/null && [[ -w "/dev/tty$GF_SCRATCH" ]]; then
    GF_TTY="/dev/tty$GF_SCRATCH"
    printf '\033[2J\033[H\033[?25l' > "$GF_TTY" 2>/dev/null   # clear + hide cursor
  fi
}
gf_say() { [[ -n "$GF_TTY" ]] && printf '%s\n' "$*" > "$GF_TTY" 2>/dev/null; }
gf_sum() { stat -c%s "$@" 2>/dev/null | awk '{s+=$1} END{print s+0}'; }
gf_bar() {  # $1=current bytes  $2=total bytes (0/empty = unknown)
  [[ -n "$GF_TTY" ]] || return 0
  local cur="${1:-0}" tot="${2:-0}" pct=0 i n=20 fill bar=""
  [[ "$tot" =~ ^[0-9]+$ ]] || tot=0
  if (( tot > 0 )); then (( pct = cur * 100 / tot )); (( pct > 100 )) && pct=100; (( fill = pct * n / 100 )); fi
  for ((i=0;i<n;i++)); do (( i < fill )) && bar+="#" || bar+="-"; done
  if (( tot > 0 )); then
    printf '\r  [%s] %3d%%  %d / %d MB ' "$bar" "$pct" $((cur/1048576)) $((tot/1048576)) > "$GF_TTY" 2>/dev/null
  else
    printf '\r  downloaded %d MB ' $((cur/1048576)) > "$GF_TTY" 2>/dev/null
  fi
}
gf_ui_done() {
  [[ -n "$GF_TTY" ]] && printf '\033[?25h\n' > "$GF_TTY" 2>/dev/null   # show cursor
  [[ -n "$GF_VT" ]] && chvt "$GF_VT" 2>/dev/null
  GF_TTY=""
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
    {
      echo "[$(date '+%F %T')] launch-wrapper fetch start: $inner"
      echo "  url: ${src}${enc}"
    } >>"$LOG"
    gf_ui_init
    gf_say "gameflix: downloading $(basename "$rom")"
    # 4-way parallel range-chunked download — archive.org throttles single
    # connections, splitting bypasses that (measured 4.4× speedup on a 20 MB
    # CDTV sample). Falls back to single-stream if HEAD fails, server doesn't
    # advertise byte ranges, or file is small (<4 MB).
    dl_url="${src}${enc}"
    hdr=$(curl -sIL --location-trusted ${ia_auth:+-H "Authorization: $ia_auth"} "$dl_url" 2>>"$LOG")
    size=$(echo "$hdr" | grep -i '^content-length:' | tail -1 | awk '{print $2}' | tr -d '\r\n')
    ranges=$(echo "$hdr" | grep -i '^accept-ranges:' | tail -1 | awk '{print $2}' | tr -d '\r\n')
    [[ "$size" =~ ^[0-9]+$ ]] || size=0
    fetch_ok=0
    if [[ -n "$size" && "$ranges" == "bytes" && "$size" -gt 4194304 ]]; then
      # Scale chunk count by file size — archive.org throttles past ~6-8
      # connections per IP, so cap there. Benchmark on 50 MB: n=2..4 ≈6 MB/s,
      # n=8 drops to 2 MB/s due to rate limit.
      if   (( size > 524288000 )); then n=8     # >500 MB (PS2/GC/Wii)
      elif (( size >  52428800 )); then n=6     # >50 MB (CHD, large CDTV/PSX)
      else                              n=4     # 4-50 MB
      fi
      chunk=$((size / n))
      tmpdir=$(mktemp -d)
      echo "[$(date '+%F %T')] launch-wrapper chunked fetch: $size bytes in $n parts" >>"$LOG"
      gf_say "  $((size/1048576)) MB in $n parts"
      pids=()
      for ((i=0; i<n; i++)); do
        start=$((i*chunk))
        end=$((i==n-1 ? size-1 : (i+1)*chunk-1))
        curl -sfL --location-trusted ${ia_auth:+-H "Authorization: $ia_auth"} \
             --range "${start}-${end}" -o "$tmpdir/p$i" "$dl_url" 2>>"$LOG" &
        pids+=($!)
      done
      ( while :; do gf_bar "$(gf_sum "$tmpdir"/p*)" "$size"; sleep 1; done ) & prog=$!
      chunk_ok=1
      for pid in "${pids[@]}"; do wait "$pid" || chunk_ok=0; done
      kill "$prog" 2>/dev/null; wait "$prog" 2>/dev/null
      gf_bar "$size" "$size"
      if (( chunk_ok == 1 )); then
        cat "$tmpdir"/p* > "$rom" && fetch_ok=1
      fi
      rm -rf "$tmpdir"
    fi
    if (( fetch_ok == 0 )); then
      # Single-stream fallback (small file, no range support, or chunked failed)
      curl -fL --location-trusted ${ia_auth:+-H "Authorization: $ia_auth"} -o "$rom" "$dl_url" 2>>"$LOG" & cpid=$!
      ( while :; do gf_bar "$(gf_sum "$rom")" "$size"; sleep 1; done ) & prog=$!
      cok=0; wait "$cpid" || cok=1
      kill "$prog" 2>/dev/null; wait "$prog" 2>/dev/null
      if (( cok != 0 )); then
        rm -f "$rom"
        echo "[$(date '+%F %T')] launch-wrapper download FAILED" >>"$LOG"
        gf_say ""; gf_say "  download FAILED — check $LOG"; sleep 3; gf_ui_done
        exit 1
      fi
      gf_bar "$size" "$size"
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
