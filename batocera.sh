#!/bin/bash
# gameflix Batocera setup — on-demand per-game fetch (no bulk romset downloads,
# no rclone/ratarmount mounts). EmulationStation runs with ParseGamelistOnly=true
# so it shows dlaždice straight from gamelist.xml without stat()ing each ROM;
# the game-start hook materializes each picked ROM via archive.org HTTPS just
# before launch.
#
# Logs to /userdata/system/logs/gameflix.log; status banners echoed to TTY3.
mkdir -p /userdata/system/logs
LOG=/userdata/system/logs/gameflix.log
exec >>"$LOG" 2>&1
status() { echo "$@"; echo "$@" >/dev/console 2>/dev/null; }
status "=== gameflix batocera.sh started at $(date) ==="
status "tail -f $LOG  # for live progress"
emulationstation stop; chvt 3; clear

# -- Cleanup any prior gameflix mounts and zip caches -----------------------
status "=== unmounting legacy FUSE mounts ==="
for mp in /userdata/zips-mount /userdata/share/roms-mount /userdata/iso; do
  [[ -d "$mp" ]] && mountpoint -q "$mp" 2>/dev/null && fusermount -u -z "$mp"
done
for d in /userdata/mount/*/; do
  [[ -d "$d" ]] || continue
  mountpoint -q "$d" 2>/dev/null && fusermount -u -z "$d"
done

status "=== deleting cached romset zips ==="
rm -rf /userdata/zip /userdata/zips /userdata/zips-mount /userdata/share/roms-mount
rmdir /userdata/mount/*/ 2>/dev/null
rmdir /userdata/mount 2>/dev/null

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

status "=== installing game-start hook (on-demand ROM fetch) ==="
mkdir -p /userdata/system/configs/emulationstation/scripts/game-start
wget -nv -O /userdata/system/configs/emulationstation/scripts/game-start/gameflix.sh \
  https://raw.githubusercontent.com/WizzardSK/gameflix/main/batocera/game-start.sh
chmod +x /userdata/system/configs/emulationstation/scripts/game-start/gameflix.sh

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

cp /usr/share/emulationstation/es_systems.cfg /userdata/system/es_systems.bak
wget -nv -O /usr/share/emulationstation/es_systems.cfg \
  https://github.com/WizzardSK/gameflix/raw/main/batocera/es_systems.cfg
cp /usr/share/emulationstation/es_systems.cfg /userdata/system/es_systems.cfg

# -- Enable ParseGamelistOnly so ES shows games even when files don't exist --
ES_SETTINGS=/userdata/system/.emulationstation/es_settings.cfg
mkdir -p "$(dirname "$ES_SETTINGS")"
touch "$ES_SETTINGS"
if grep -q 'name="ParseGamelistOnly"' "$ES_SETTINGS"; then
  sed -i 's|<bool name="ParseGamelistOnly" value="[^"]*"|<bool name="ParseGamelistOnly" value="true"|' "$ES_SETTINGS"
else
  # Insert before closing root tag or append
  if grep -q '</config>' "$ES_SETTINGS"; then
    sed -i 's|</config>|<bool name="ParseGamelistOnly" value="true" />\n</config>|' "$ES_SETTINGS"
  else
    echo '<bool name="ParseGamelistOnly" value="true" />' >> "$ES_SETTINGS"
  fi
fi

status "=== done — restarting EmulationStation ==="
chvt 1; batocera-es-swissknife --restart &
