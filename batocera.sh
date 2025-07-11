#!/bin/bash
emulationstation stop; chvt 3; clear; mount -o remount,size=6000M /tmp
wget -O /userdata/system/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/rclone.conf > /dev/null 2>&1
if [ ! -f /userdata/system/httpdirfs ];  then wget -nv -O /userdata/system/httpdirfs  https://github.com/WizzardSK/gameflix/raw/main/batocera/httpdirfs; chmod +x /userdata/system/httpdirfs; fi
if [ ! -f /userdata/system/fuse-zip ];   then wget -nv -O /userdata/system/fuse-zip   https://github.com/WizzardSK/gameflix/raw/main/batocera/fuse-zip;  chmod +x /userdata/system/fuse-zip; fi
if [ ! -f /userdata/system/mount-zip ];  then wget -nv -O /userdata/system/mount-zip  https://github.com/WizzardSK/gameflix/raw/main/batocera/mount-zip; chmod +x /userdata/system/mount-zip; fi
if [ ! -f /userdata/system/ratarmount ]; then wget -nv -O /userdata/system/ratarmount https://github.com/mxmlnkn/ratarmount/releases/download/v1.1.0/ratarmount-1.1.0-full-x86_64.AppImage; chmod +x /userdata/system/ratarmount; fi
if [ ! -f /userdata/system/configs/emulationstation/es_systems_voxatron.cfg ]; then wget -nv -O /userdata/system/configs/emulationstation/es_systems_voxatron.cfg https://github.com/WizzardSK/gameflix/raw/main/batocera/es_systems_voxatron.cfg; fi
if [ ! -f /userdata/roms/voxatron/splore.png ]; then wget -nv -O /userdata/roms/voxatron/splore.png https://github.com/WizzardSK/gameflix/raw/main/fantasy/voxatron.png; fi
if [ ! -f /userdata/roms/pico8/splore.png ];    then wget -nv -O /userdata/roms/pico8/splore.png    https://github.com/WizzardSK/gameflix/raw/main/fantasy/pico8.png; fi

mkdir -p /userdata/{rom,roms,thumb,thumbs,zip,zips} /userdata/system/.cache/{httpdirfs,ratarmount,rclone}
mkdir -p /userdata/roms/tic80/TIC-80 /userdata/roms/lowresnx/LowresNX /userdata/roms/wasm4/WASM-4 /userdata/roms/uzebox/Uzebox /userdata/roms/vircon32/Vircon32 "/userdata/roms/atari2600/Atari 2600 ROMS"
IFS=$'\n' read -d '' -ra roms <<< "$(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.txt)"
rclone mount myrient: /userdata/rom --http-no-head --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h --allow-non-empty --daemon --no-check-certificate --config=/userdata/system/rclone.conf
rclone mount thumbs:Data/share/thumbs /userdata/thumbs --vfs-cache-mode full --daemon --config=/userdata/system/rclone.conf --cache-dir=/userdata/system/.cache/rclone --allow-non-empty --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h
rclone mount archive:all_vircon32_roms_and_media/all_vircon32_roms_and_media /userdata/roms/vircon32/Vircon32 --daemon --config=/userdata/system/rclone.conf

if [ ! -f /userdata/system/offline ]; then
  archives=( "https://www.atarimania.com/roms/Atari-2600-VCS-ROM-Collection.zip" )
  archives+=( "https://github.com/WizzardSK/gameflix/raw/refs/heads/main/fantasy/tic80.zip" )
  archives+=( "https://github.com/WizzardSK/gameflix/raw/refs/heads/main/fantasy/wasm4.zip" )
  archives+=( "https://github.com/WizzardSK/gameflix/raw/refs/heads/main/fantasy/uzebox.zip" )
  archives+=( "https://github.com/WizzardSK/gameflix/raw/refs/heads/main/fantasy/lowresnx.zip" )
else
  if [ ! -f /userdata/zip/Atari-2600-VCS-ROM-Collection.zip ]; then wget -nv -O /userdata/zip/Atari-2600-VCS-ROM-Collection.zip https://www.atarimania.com/roms/Atari-2600-VCS-ROM-Collection.zip; fi
  if [ ! -f /userdata/zip/tic80.zip ]; then wget -nv -O /userdata/zip/tic80.zip https://github.com/WizzardSK/gameflix/raw/refs/heads/main/fantasy/tic80.zip; fi
  if [ ! -f /userdata/zip/wasm4.zip ]; then wget -nv -O /userdata/zip/wasm4.zip https://github.com/WizzardSK/gameflix/raw/refs/heads/main/fantasy/wasm4.zip; fi
  if [ ! -f /userdata/zip/uzebox.zip ]; then wget -nv -O /userdata/zip/uzebox.zip https://github.com/WizzardSK/gameflix/raw/refs/heads/main/fantasy/uzebox.zip; fi
  if [ ! -f /userdata/zip/lowresnx.zip ]; then wget -nv -O /userdata/zip/lowresnx.zip https://github.com/WizzardSK/gameflix/raw/refs/heads/main/fantasy/lowresnx.zip; fi    
  archives=( "/userdata/zip/Atari-2600-VCS-ROM-Collection.zip" )
  archives+=( "/userdata/zip/tic80.zip" )
  archives+=( "/userdata/zip/wasm4.zip" )
  archives+=( "/userdata/zip/uzebox.zip" )
  archives+=( "/userdata/zip/lowresnx.zip" )
fi

IFS=";"
for each in "${roms[@]}"; do 
  read -ra rom < <(printf '%s' "$each")
  if [ ! -f /userdata/thumb/${rom[0]}.png ]; then wget -nv -O /userdata/thumb/${rom[0]}.png https://raw.githubusercontent.com/fabricecaruso/es-theme-carbon/master/art/consoles/${rom[0]}.png; fi
  rom3=$(sed 's/<[^>]*>//g' <<< "${rom[3]}"); mkdir -p /userdata/roms/${rom[0]}/${rom3}
  if [[ ${rom[1]} =~ \.zip$ ]]; then
    rom1="${rom[1]//&/%26}"; rom1="${rom1// /%20}"; rom1="${rom1//[/%5B}"; rom1="${rom1//]/%5D}"; rom1="${rom1//\'/%27}"
    if [ ! -f /userdata/system/offline ]; then
      archives+=( "https://myrient.erista.me/files/${rom1}" )
    else
      romfile=$(basename "${rom1}")
      if [ ! -f /userdata/zip/${romfile} ]; then wget -O /userdata/zip/${romfile} https://myrient.erista.me/files/${rom1}; fi
      archives+=( "/userdata/zip/${romfile}" )
    fi
  else
    if grep -q ":" <<< "${rom[1]}"; then
      rclone mount ${rom[1]} /userdata/roms/${rom[0]}/${rom3} --http-no-head --no-checksum --no-modtime --dir-cache-time 1000h --allow-non-empty --attr-timeout 1000h --poll-interval 1000h --daemon --config=/userdata/system/rclone.conf
    else mount -o bind /userdata/rom/${rom[1]} /userdata/roms/${rom[0]}/${rom3}; fi
  fi
done

/userdata/system/ratarmount -o attr_timeout=3600 --disable-union-mount "${archives[@]}" /userdata/zips -f & 
while ! grep -q " /userdata/zips " /proc/mounts; do sleep 5; done
mount -o bind /userdata/zips/Atari-2600-VCS-ROM-Collection.zip/ROMS "/userdata/roms/atari2600/Atari 2600 ROMS"
mount -o bind /userdata/zips/tic80.zip "/userdata/roms/tic80/TIC-80"
mount -o bind /userdata/zips/lowresnx.zip "/userdata/roms/lowresnx/LowresNX"
mount -o bind /userdata/zips/wasm4.zip "/userdata/roms/wasm4/WASM-4"
mount -o bind /userdata/zips/uzebox.zip "/userdata/roms/uzebox/Uzebox"

for each in "${roms[@]}"; do
  read -ra rom < <(printf '%s' "$each")
  rom3=$(sed 's/<[^>]*>//g' <<< "${rom[3]}")
  if [[ ${rom[1]} =~ \.zip$ ]]; then
    rom1="${rom[1]//&/%26}"; rom1="${rom1// /%20}"; rom1="${rom1//[/%5B}"; rom1="${rom1//]/%5D}"; rom1="${rom1//\'/%27}"
    mkdir -p /userdata/roms/${rom[0]}/${rom3}; mount -o bind /userdata/zips/${rom1##*/} /userdata/roms/${rom[0]}/${rom3}
  fi
done

DAT_URL="https://github.com/WizzardSK/gameflix/raw/refs/heads/main/neogeo.dat"; DAT_FILE="/tmp/neogeo.dat"
SRC_DIR="/userdata/rom/Internet Archive/chadmaster/fbnarcade-fullnonmerged/arcade"; DEST_DIR="/userdata/roms/neogeo/Neo Geo"
curl -s -L "$DAT_URL" -o "$DAT_FILE"; mkdir -p "$DEST_DIR"
while IFS= read -r line; do
  neo_file="${line%%[[:space:]]*}"
  [[ -z "$neo_file" || "$neo_file" != *.neo ]] && continue
  base_name="${neo_file%.neo}"
  zip_name="$base_name.zip"
  src_file="$SRC_DIR/$zip_name"
  dest_link="$DEST_DIR/$zip_name"
  if [[ -f "$src_file" ]]; then ln -sf "$src_file" "$dest_link"; fi
done < "$DAT_FILE"

wget -nv -O /userdata/system/gamelist.zip https://github.com/WizzardSK/gameflix/raw/main/batocera/gamelist.zip; unzip -o /userdata/system/gamelist.zip -d /userdata/roms

cp /usr/share/emulationstation/es_systems.cfg /usr/share/emulationstation/es_systems.bak
wget -nv -O /usr/share/emulationstation/es_systems.cfg https://github.com/WizzardSK/gameflix/raw/main/batocera/es_systems.cfg > /dev/null 2>&1
chvt 2; wget http://127.0.0.1:1234/reloadgames > /dev/null 2>&1
