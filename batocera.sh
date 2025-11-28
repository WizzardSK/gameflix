#!/bin/bash
emulationstation stop; chvt 3; clear; mount -o remount,size=6000M /tmp
wget -O /userdata/system/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/rclone.conf > /dev/null 2>&1
for file in httpdirfs fuse-zip mount-zip; do [ ! -f /userdata/system/$file ] && wget -nv -O /userdata/system/$file https://github.com/WizzardSK/gameflix/raw/main/batocera/$file && chmod +x /userdata/system/$file; done
if [ ! -f /userdata/system/ratarmount-full ]; then wget -nv -O /userdata/system/ratarmount-full https://github.com/mxmlnkn/ratarmount/releases/download/v1.2.0/ratarmount-1.2.0-x86_64.AppImage; chmod +x /userdata/system/ratarmount-full; fi
if [ ! -f /userdata/system/ratarmount ]; then wget -nv -O /userdata/system/ratarmount https://github.com/mxmlnkn/ratarmount/releases/download/v1.2.0/ratarmount-1.2.0-slim-x86_64.AppImage; chmod +x /userdata/system/ratarmount; fi
if [ ! -f /userdata/system/configs/emulationstation/es_systems_voxatron.cfg ]; then wget -nv -O /userdata/system/configs/emulationstation/es_systems_voxatron.cfg https://github.com/WizzardSK/gameflix/raw/main/batocera/es_systems_voxatron.cfg; fi
mkdir -p /userdata/system/configs/emulationstation/scripts/game-selected
wget -nv -O /userdata/system/configs/emulationstation/scripts/game-selected/game.sh https://github.com/WizzardSK/gameflix/raw/main/batocera/game.sh > /dev/null 2>&1; chmod +x /userdata/system/configs/emulationstation/scripts/game-selected/game.sh
wget -nv -O /usr/share/batocera/configgen/data/mame/messSystems.csv https://github.com/WizzardSK/gameflix/raw/main/batocera/messSystems.csv > /dev/null 2>&1
for name in voxatron pico8; do [ ! -f /userdata/roms/$name/splore.png ] && wget -nv -O /userdata/roms/$name/splore.png https://github.com/WizzardSK/gameflix/raw/main/fantasy/$name.png; done
ln -sf /userdata/system/.lexaloffle/Voxatron/bbs/carts /userdata/roms/voxatron/Voxatron; ln -sf /userdata/system/.lexaloffle/pico-8/bbs/carts /userdata/roms/pico8/PICO-8

mkdir -p /userdata/{rom,roms,thumb,thumbs,zip,zips} /userdata/system/.cache/{httpdirfs,ratarmount,rclone} /userdata/roms/{tic80/TIC-80,lowresnx/LowresNX,wasm4/WASM-4}
IFS=$'\n' read -d '' -ra roms <<< "$(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.csv)"
rclone mount myrient: /userdata/rom --http-no-head --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h --allow-non-empty --daemon --no-check-certificate --config=/userdata/system/rclone.conf

archives=(https://wizzardsk.github.io/{tic80,wasm4,lowresnx}.zip)

IFS=";"; for each in "${roms[@]}"; do 
  read -ra rom < <(printf '%s' "$each")
  if [ ! -f /userdata/thumb/${rom[0]}.png ]; then wget -nv -O /userdata/thumb/${rom[0]}.png https://raw.githubusercontent.com/fabricecaruso/es-theme-carbon/master/art/consoles/${rom[0]}.png; fi
  rom3=$(sed 's/<[^>]*>//g' <<< "${rom[3]}"); mkdir -p /userdata/roms/${rom[0]}/${rom3}; mount -o bind /userdata/rom/${rom[1]} /userdata/roms/${rom[0]}/${rom3}
done

/userdata/system/ratarmount-full -o attr_timeout=3600 --disable-union-mount "${archives[@]}" /userdata/zips -f & 
while ! grep -q " /userdata/zips " /proc/mounts; do sleep 5; done
mount -o bind /userdata/zips/tic80.zip "/userdata/roms/tic80/TIC-80"
mount -o bind /userdata/zips/lowresnx.zip "/userdata/roms/lowresnx/LowresNX"
mount -o bind /userdata/zips/wasm4.zip "/userdata/roms/wasm4/WASM-4"

wget -nv -O /userdata/system/gamelist.zip https://github.com/WizzardSK/gameflix/raw/main/batocera/gamelist.zip; unzip -q -o /userdata/system/gamelist.zip -d /userdata/roms

cp /usr/share/emulationstation/es_systems.cfg /usr/share/emulationstation/es_systems.bak
wget -nv -O /usr/share/emulationstation/es_systems.cfg https://github.com/WizzardSK/gameflix/raw/main/batocera/es_systems.cfg > /dev/null 2>&1
chvt 2; wget http://127.0.0.1:1234/reloadgames > /dev/null 2>&1
