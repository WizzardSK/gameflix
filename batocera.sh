#!/bin/bash
mkdir -p /userdata/system/logs
LOG=/userdata/system/logs/gameflix.log
exec >>"$LOG" 2>&1
status() { echo "$@"; echo "$@" >/dev/console 2>/dev/null; }
status "=== gameflix batocera.sh started at $(date) ==="
status "tail -f $LOG  # for live progress"
emulationstation stop; chvt 3; clear

# -- Install runtime config and helpers -------------------------------------
status "=== installing rclone.conf (IA auth) ==="
wget -nv -O /userdata/system/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/rclone.conf

status "=== installing urls.sh (per-platform IA source lookup) ==="
# urls.sh is a build artifact — lives inside gameflix.zip alongside the web
# interface, not at repo root. Pull it out without exploding the whole archive.
wget -nv -O /tmp/gameflix.zip https://github.com/WizzardSK/gameflix/raw/refs/heads/main/gameflix.zip
unzip -p /tmp/gameflix.zip urls.sh > /userdata/system/urls.sh
rm -f /tmp/gameflix.zip
[[ ! -s /userdata/system/urls.sh ]] && status "WARNING: urls.sh empty — on-demand fetch will not work"

status "=== installing emulator launch wrapper (on-demand fetch + mount-zip) ==="
wget -nv -O /userdata/system/gameflix-launch.sh \
  https://raw.githubusercontent.com/WizzardSK/gameflix/main/batocera/gameflix-launch.sh
chmod +x /userdata/system/gameflix-launch.sh
# Disable legacy game-start hook (does nothing useful on Linux, still in
# repo for the standalone web flow which doesn't share this script)
rm -f /userdata/system/configs/emulationstation/scripts/game-start/gameflix-wait.sh \
      /userdata/system/configs/emulationstation/scripts/game-start/gameflix.sh

status "=== installing game-selected hook (thumbnail prefetch) ==="
mkdir -p /userdata/system/configs/emulationstation/scripts/game-selected
wget -nv -O /userdata/system/configs/emulationstation/scripts/game-selected/game.sh \
  https://raw.githubusercontent.com/WizzardSK/gameflix/main/batocera/game.sh
chmod +x /userdata/system/configs/emulationstation/scripts/game-selected/game.sh

status "=== installing systems.csv ==="
wget -nv -O /userdata/system/systems.csv https://raw.githubusercontent.com/WizzardSK/gameflix/main/systems.csv

# -- Pre-populate fantasy console placeholders + thumbnails -----------------
mkdir -p /userdata/{rom,roms,thumb,thumbs} /userdata/roms/{lowresnx/LowresNX,wasm4/WASM-4,voxatron,pico8,tic80}
for name in voxatron pico8; do
  [[ ! -f /userdata/roms/$name/splore.png ]] && wget -nv -O /userdata/roms/$name/splore.png \
    https://github.com/WizzardSK/gameflix/raw/main/fantasy/$name.png
done
touch /userdata/roms/tic80/surf.tic
[[ ! -f /userdata/roms/tic80/tic80.png ]] && wget -nv -O /userdata/roms/tic80/tic80.png \
  https://raw.githubusercontent.com/WizzardSK/gameflix/master/art/consoles/tic80.png

# Bundled wasm4/lowresnx zips (fantasy consoles use local files, not on-demand fetch)
for name in wasm4 lowresnx; do
  wget -q -O "/userdata/system/$name.zip" "https://wizzardsk.github.io/$name.zip"
  rm -rf "/userdata/roms/$name"/*
  unzip -oq "/userdata/system/$name.zip" -d "/userdata/roms/$name"
done

# Per-platform console thumbnails (used by ES grid background)
status "=== fetching per-platform console icons ==="
while IFS=',' read -r platform _; do
  [[ -z "$platform" || "$platform" == "platform" ]] && continue
  if [[ ! -f /userdata/thumb/${platform}.png ]]; then
    wget -nv -O /userdata/thumb/${platform}.png \
      https://raw.githubusercontent.com/WizzardSK/gameflix/master/art/consoles/${platform}.png 2>/dev/null
  fi
done < <(awk -F',' 'NR>1{print $1}' /userdata/system/systems.csv | sort -u)

# -- Install gamelists + es_systems --------------------------------------------
status "=== installing gamelists ==="
wget -nv -O /userdata/system/gamelist.zip https://github.com/WizzardSK/gameflix/raw/main/batocera/gamelist.zip
unzip -q -o /userdata/system/gamelist.zip -d /userdata/roms

status "=== regenerating Switch gamelist from local files ==="
SWITCH_DIR=/userdata/roms/switch
if [[ -d "$SWITCH_DIR" ]]; then
  {
    echo '<gameList>'
    find "$SWITCH_DIR" -maxdepth 1 -type f \( -name '*.nsp' -o -name '*.xci' \) -printf '%f\n' | sort | \
    while IFS= read -r fname; do
      name="${fname%.*}"
      # Strip "(region) [tag]" suffix for thumbnail lookup
      short="${name%% (*}"; short="${short%% [*}"
      echo "<game><path>./${fname}</path><name>${name}</name><image>~/../thumbs/Nintendo - Nintendo Switch/Named_Snaps/${short}.png</image></game>"
    done
    echo '</gameList>'
  } > "$SWITCH_DIR/gamelist.xml"
  status "Switch gamelist: $(grep -c '<game>' "$SWITCH_DIR/gamelist.xml") entries"
fi

cp /usr/share/emulationstation/es_systems.cfg /userdata/system/es_systems.bak
wget -nv -O /usr/share/emulationstation/es_systems.cfg \
  https://github.com/WizzardSK/gameflix/raw/main/batocera/es_systems.cfg
cp /usr/share/emulationstation/es_systems.cfg /userdata/system/es_systems.cfg

ES_SETTINGS=/userdata/system/.emulationstation/es_settings.cfg
mkdir -p "$(dirname "$ES_SETTINGS")"
if [[ ! -s "$ES_SETTINGS" ]] || ! grep -q '<config>' "$ES_SETTINGS"; then
  # Initialise with a valid skeleton — ES doesn't fall back to defaults if it
  # fails to parse the file, it would just ignore our setting.
  printf '<?xml version="1.0"?>\n<config>\n</config>\n' > "$ES_SETTINGS"
fi
if grep -q 'name="ParseGamelistOnly"' "$ES_SETTINGS"; then
  sed -i 's|<bool name="ParseGamelistOnly" value="[^"]*"|<bool name="ParseGamelistOnly" value="true"|' "$ES_SETTINGS"
else
  sed -i 's|</config>|\t<bool name="ParseGamelistOnly" value="true" />\n</config>|' "$ES_SETTINGS"
fi

if grep -q 'name="SaveGamelistsOnExit"' "$ES_SETTINGS"; then
  sed -i 's|<bool name="SaveGamelistsOnExit" value="[^"]*"|<bool name="SaveGamelistsOnExit" value="false"|' "$ES_SETTINGS"
else
  sed -i 's|</config>|\t<bool name="SaveGamelistsOnExit" value="false" />\n</config>|' "$ES_SETTINGS"
fi

# Sync to the configs path too — Batocera reads from
# /userdata/system/configs/emulationstation/es_settings.cfg
ES_CFG=/userdata/system/configs/emulationstation/es_settings.cfg
if [[ -f "$ES_CFG" ]]; then
  for k in ParseGamelistOnly SaveGamelistsOnExit; do
    v=true
    [[ "$k" == SaveGamelistsOnExit ]] && v=false
    if grep -q "name=\"$k\"" "$ES_CFG"; then
      sed -i "s|<bool name=\"$k\" value=\"[^\"]*\"|<bool name=\"$k\" value=\"$v\"|" "$ES_CFG"
    else
      sed -i "s|</config>|\t<bool name=\"$k\" value=\"$v\" />\n</config>|" "$ES_CFG"
    fi
  done
fi

status "=== done — restarting EmulationStation ==="
chvt 1; batocera-es-swissknife --restart &
