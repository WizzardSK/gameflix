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
# Download is a single stream: every gameflix source is a file *inside* an
# archive.org .zip, served via view_archive.php. A HEAD on that redirects and
# reports the *container* zip's size (e.g. 324 MB for the whole Mega Drive
# set), not the inner ROM — so range/chunked downloads compute bogus offsets.
# Single-stream just works.
#
# On-screen progress: ES runs under a labwc/wlroots Wayland compositor, so we
# show a `yad` window AS a Wayland client (a chvt to a text VT fought the
# session and dropped the Steam Deck panel rotation — never switch VTs here).
# The inner-ROM size isn't known up front, so the bar pulsates and we show MB
# downloaded. Best-effort: missing yad/display just disables the window.
#
# Args (passed straight through to emulatorlauncher except -rom): typically
#   %CONTROLLERSCONFIG% -system %SYSTEM% -rom %ROM% -gameinfoxml %GAMEINFOXML% -systemname %SYSTEMNAME%
LOG=/userdata/system/logs/gameflix-fetch.log

# --- on-screen progress via a yad GTK dialog (Wayland-native) --------------
GF_FIFO=""; GF_YAD=""; GF_NAME=""
gf_ui_init() {  # $1 = ROM basename
  command -v yad >/dev/null 2>&1 || return 0
  : "${XDG_RUNTIME_DIR:=/var/run}"; : "${WAYLAND_DISPLAY:=wayland-0}"
  export XDG_RUNTIME_DIR WAYLAND_DISPLAY
  [[ -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" ]] || return 0
  GF_NAME="$1"
  GF_FIFO=$(mktemp -u)
  mkfifo "$GF_FIFO" 2>/dev/null || { GF_FIFO=""; return 0; }
  exec 9<>"$GF_FIFO"   # read-write so the open never blocks if yad dies
  GDK_BACKEND=wayland yad --progress --pulsate --title="gameflix" \
      --text="Downloading $1" --no-buttons --auto-close --center --width=520 \
      < "$GF_FIFO" >/dev/null 2>&1 &
  GF_YAD=$!
}
gf_sum() { stat -c%s "$@" 2>/dev/null | awk '{s+=$1} END{print s+0}'; }
gf_prog() {  # $1 = bytes downloaded so far (pulsates the bar + shows MB)
  [[ -n "$GF_FIFO" ]] || return 0
  printf '#%s  —  %d MB\n' "$GF_NAME" $(( ${1:-0} / 1048576 )) >&9 2>/dev/null
}
gf_ui_done() {
  [[ -n "$GF_FIFO" ]] || return 0
  exec 9>&- 2>/dev/null    # close write end
  kill "$GF_YAD" 2>/dev/null   # don't rely on EOF/auto-close — kill it
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
    {
      echo "[$(date '+%F %T')] launch-wrapper fetch start: $inner"
      echo "  url: ${dl_url}"
    } >>"$LOG"
    gf_ui_init "$(basename "$rom")"
    # Single stream (-s: no progress meter spamming the log). Run in the
    # background so we can pulse the yad bar + report MB while it downloads.
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
