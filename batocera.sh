#!/bin/bash
emulationstation stop; chvt 3; clear; mount -o remount,size=6000M /tmp
wget -O /userdata/system/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/rclone.conf > /dev/null 2>&1
for file in httpdirfs fuse-zip mount-zip; do [ ! -f /userdata/system/$file ] && wget -nv -O /userdata/system/$file https://github.com/WizzardSK/gameflix/raw/main/batocera/$file && chmod +x /userdata/system/$file; done
if [ ! -f /userdata/system/ratarmount-full ]; then wget -nv -O /userdata/system/ratarmount-full https://github.com/mxmlnkn/ratarmount/releases/download/v1.2.0/ratarmount-1.2.0-x86_64.AppImage; chmod +x /userdata/system/ratarmount-full; fi
if [ ! -f /userdata/system/ratarmount ]; then wget -nv -O /userdata/system/ratarmount https://github.com/mxmlnkn/ratarmount/releases/download/v1.2.0/ratarmount-1.2.0-slim-x86_64.AppImage; chmod +x /userdata/system/ratarmount; fi
mkdir -p /userdata/system/configs/emulationstation/scripts/game-selected
wget -nv -O /userdata/system/configs/emulationstation/scripts/game-selected/game.sh https://github.com/WizzardSK/gameflix/raw/main/batocera/game.sh > /dev/null 2>&1; chmod +x /userdata/system/configs/emulationstation/scripts/game-selected/game.sh
#wget -nv -O /usr/share/batocera/configgen/data/mame/messSystems.csv https://github.com/WizzardSK/gameflix/raw/main/batocera/messSystems.csv > /dev/null 2>&1
for name in voxatron pico8; do [ ! -f /userdata/roms/$name/splore.png ] && wget -nv -O /userdata/roms/$name/splore.png https://github.com/WizzardSK/gameflix/raw/main/fantasy/$name.png; done
touch /userdata/roms/tic80/surf.tic
if [ ! -f /userdata/roms/tic80/tic80.png ]; then wget -nv -O /userdata/roms/tic80/tic80.png https://raw.githubusercontent.com/WizzardSK/gameflix/master/art/consoles/tic80.png; fi

mkdir -p /userdata/{rom,roms,thumb,thumbs,zip,zips} /userdata/system/.cache/{httpdirfs,ratarmount,rclone} /userdata/roms/{lowresnx/LowresNX,wasm4/WASM-4}
wget -nv -O /userdata/system/systems.csv https://raw.githubusercontent.com/WizzardSK/gameflix/main/systems.csv > /dev/null 2>&1
IFS=$'\n' read -d '' -ra roms <<< "$(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.csv | tail -n +2 | awk '{o="";i=1;n=length($0);while(i<=n){c=substr($0,i,1);if(c==","){o=o";";i++}else if(c=="\""){i++;while(i<=n){c=substr($0,i,1);if(c=="\""){if(substr($0,i+1,1)=="\""){o=o"\"";i+=2}else{i++;break}}else{o=o c;i++}}}else{o=o c;i++}};print o}')"

IFS=";"; for each in "${roms[@]}"; do 
  read -ra rom < <(printf '%s' "$each")
  if [ ! -f /userdata/thumb/${rom[0]}.png ]; then wget -nv -O /userdata/thumb/${rom[0]}.png https://raw.githubusercontent.com/WizzardSK/gameflix/master/art/consoles/${rom[0]}.png; fi
  rom3=$(sed 's/<[^>]*>//g' <<< "${rom[2]}"); mkdir -p /userdata/roms/${rom[0]}/${rom3}; mount -o bind /userdata/rom/${rom[1]} /userdata/roms/${rom[0]}/${rom3}
done

archives=(wasm4 lowresnx)
for name in "${archives[@]}"; do
  wget -q "https://wizzardsk.github.io/$name.zip" -O "/userdata/system/$name.zip"; rm -rf "/userdata/roms/$name/*"; unzip -oq "/userdata/system/$name.zip" -d "/userdata/roms/$name"
done

wget -nv -O /userdata/system/gamelist.zip https://github.com/WizzardSK/gameflix/raw/main/batocera/gamelist.zip; unzip -q -o /userdata/system/gamelist.zip -d /userdata/roms
cp /usr/share/emulationstation/es_systems.cfg /userdata/system/es_systems.bak
wget -nv -O /usr/share/emulationstation/es_systems.cfg https://github.com/WizzardSK/gameflix/raw/main/batocera/es_systems.cfg > /dev/null 2>&1
cp /usr/share/emulationstation/es_systems.cfg /userdata/system/es_systems.cfg
chvt 1; wget http://127.0.0.1:1234/reloadgames > /dev/null 2>&1
