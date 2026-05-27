#!/bin/bash
# Batocera/Recalbox game-start hook: download the chosen ROM from archive.org
# just before the emulator launches. EmulationStation is configured with
# ParseGamelistOnly=true so dlaždice show even when the ROM file is missing;
# this hook materializes the file on-demand when the user actually presses
# Start, then returns and lets configgen launch the emulator normally.
#
# Args: $1 = system name (e.g. "snes"), $2 = full path to the game file.
SYSTEM="$1"
GAMEPATH="$2"
[[ -z "$GAMEPATH" ]] && exit 0
[[ -e "$GAMEPATH" ]] && exit 0  # already downloaded — fast path

# Resolve the archive.org URL prefix via urls.sh's lookup function. urls.sh is
# generated alongside the web build (see generate.sh) and installed by
# batocera.sh into /userdata/system/urls.sh.
src=""
if [[ -f /userdata/system/urls.sh ]]; then
  . /userdata/system/urls.sh
  gameflix_lookup_src "$(dirname "$GAMEPATH")/"
fi
[[ -z "$src" ]] && exit 0  # no on-demand source (fantasy consoles etc.)

# Read IA S3-key auth from rclone.conf (restricted IA items need it)
ia_auth=""
if [[ -f /userdata/system/rclone.conf ]]; then
  ia_key=$(awk '/^\[archive\]/{f=1;next} /^\[/{f=0} f && /access_key_id/{print $3;exit}' /userdata/system/rclone.conf)
  ia_sec=$(awk '/^\[archive\]/{f=1;next} /^\[/{f=0} f && /secret_access_key/{print $3;exit}' /userdata/system/rclone.conf)
  [[ -n "$ia_key" && -n "$ia_sec" ]] && ia_auth="LOW ${ia_key}:${ia_sec}"
fi

# Inner path relative to /userdata/roms/<system>/<foldername>/ (preserves any
# nested TOSEC-style subdirectories inside the IA zip)
relpath="${GAMEPATH#/userdata/roms/}"
inner="${relpath#*/}"; inner="${inner#*/}"
enc=""; for ((i=0;i<${#inner};i++)); do c="${inner:i:1}"; case "$c" in [/a-zA-Z0-9._~-]) enc+="$c";; *) printf -v c '%%%02X' "'$c"; enc+="$c";; esac; done

mkdir -p "$(dirname "$GAMEPATH")"
echo "gameflix: fetching $inner ..." >/dev/console 2>/dev/null
if ! curl -sfL --location-trusted ${ia_auth:+-H "Authorization: $ia_auth"} -o "$GAMEPATH" "${src}${enc}"; then
  rm -f "$GAMEPATH"
  echo "gameflix: download failed for ${src}${enc}" >/dev/console 2>/dev/null
  exit 1
fi
exit 0
