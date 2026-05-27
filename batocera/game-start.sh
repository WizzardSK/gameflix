#!/bin/bash
# Batocera/Recalbox game-start hook: download the chosen ROM from archive.org
# just before the emulator launches. EmulationStation is configured with
# ParseGamelistOnly=true so dlaždice show even when the ROM file is missing;
# this hook materializes the file on-demand when the user actually presses
# Start, then returns and lets configgen launch the emulator normally.
#
# Args (per es-app/src/FileData.cpp's Scripting::fireEvent("game-start", ...)):
#   $1 = full ROM path (escaped)
#   $2 = basename without extension
#   $3 = display name
GAMEPATH="$1"
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
# LC_ALL=C forces byte-mode iteration so UTF-8 multibyte chars (e.g. 'í' =
# 0xC3 0xAD) get encoded as %C3%AD, not %ED. archive.org returns 404 otherwise.
urlenc() { local LC_ALL=C s="$1" i c e=""; for ((i=0;i<${#s};i++)); do c="${s:i:1}"; case "$c" in [/a-zA-Z0-9._~-]) e+="$c";; *) printf -v c '%%%02X' "'$c"; e+="$c";; esac; done; printf '%s' "$e"; }
enc=$(urlenc "$inner")

LOG=/userdata/system/logs/gameflix-fetch.log
mkdir -p "$(dirname "$GAMEPATH")"
{
  echo "[$(date '+%F %T')] fetch start: $inner"
  echo "  src: $src"
  echo "  url: ${src}${enc}"
} >>"$LOG"
if ! curl -fL --location-trusted ${ia_auth:+-H "Authorization: $ia_auth"} -o "$GAMEPATH" "${src}${enc}" 2>>"$LOG"; then
  rm -f "$GAMEPATH"
  echo "[$(date '+%F %T')] download FAILED for ${src}${enc}" >>"$LOG"
  exit 1
fi
echo "[$(date '+%F %T')] fetch done ($(stat -c%s "$GAMEPATH") bytes) → $GAMEPATH" >>"$LOG"
exit 0
