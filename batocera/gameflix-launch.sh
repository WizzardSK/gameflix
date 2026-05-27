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
    if ! curl -fL --location-trusted ${ia_auth:+-H "Authorization: $ia_auth"} -o "$rom" "${src}${enc}" 2>>"$LOG"; then
      rm -f "$rom"
      echo "[$(date '+%F %T')] launch-wrapper download FAILED" >>"$LOG"
      exit 1
    fi
    echo "[$(date '+%F %T')] launch-wrapper fetch done ($(stat -c%s "$rom") bytes)" >>"$LOG"
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
