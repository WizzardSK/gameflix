#!/bin/bash
emulationstation stop; chvt 3; clear; mount -o remount,size=6000M /tmp
wget -O /userdata/system/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/rclone.conf > /dev/null 2>&1
for file in httpdirfs fuse-zip mount-zip; do [ ! -f /userdata/system/$file ] && wget -nv -O /userdata/system/$file https://github.com/WizzardSK/gameflix/raw/main/batocera/$file && chmod +x /userdata/system/$file; done
if [ ! -f /userdata/system/ratarmount ]; then wget -nv -O /userdata/system/ratarmount https://github.com/mxmlnkn/ratarmount/releases/download/v1.1.0/ratarmount-1.1.0-full-x86_64.AppImage; chmod +x /userdata/system/ratarmount; fi
if [ ! -f /userdata/system/configs/emulationstation/es_systems_voxatron.cfg ]; then wget -nv -O /userdata/system/configs/emulationstation/es_systems_voxatron.cfg https://github.com/WizzardSK/gameflix/raw/main/batocera/es_systems_voxatron.cfg; fi
for name in voxatron pico8; do [ ! -f /userdata/roms/$name/splore.png ] && wget -nv -O /userdata/roms/$name/splore.png https://github.com/WizzardSK/gameflix/raw/main/fantasy/$name.png; done
ln -sf /userdata/system/.lexaloffle/Voxatron/bbs/carts /userdata/roms/voxatron/Voxatron; ln -sf /userdata/system/.lexaloffle/pico-8/bbs/carts /userdata/roms/pico8/PICO-8

mkdir -p /userdata/{rom,roms,thumb,thumbs,zip,zips} /userdata/system/.cache/{httpdirfs,ratarmount,rclone} /userdata/roms/{tic80/TIC-80,lowresnx/LowresNX,wasm4/WASM-4,uzebox/Uzebox,vircon32/Vircon32,"atari2600/Atari 2600 ROMS"}
IFS=$'\n' read -d '' -ra roms <<< "$(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.txt)"
rclone mount myrient: /userdata/rom --http-no-head --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h --allow-non-empty --daemon --no-check-certificate --config=/userdata/system/rclone.conf
rclone mount thumbs:Data/share/thumbs /userdata/thumbs --vfs-cache-mode full --daemon --config=/userdata/system/rclone.conf --cache-dir=/userdata/system/.cache/rclone --allow-non-empty --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h
rclone mount archive:all_vircon32_roms_and_media/all_vircon32_roms_and_media /userdata/roms/vircon32/Vircon32 --daemon --config=/userdata/system/rclone.conf
ratarmount /userdata/rom/Internet\ Archive/sketch_the_cow/Total_DOS_Collection_Release_16_March_2019/Games/Files/*/ /userdata/roms/dos/TDC

if [ ! -f /userdata/system/offline ]; then
  archives=( "https://www.atarimania.com/roms/Atari-2600-VCS-ROM-Collection.zip" )
  archives+=( https://github.com/WizzardSK/gameflix/raw/refs/heads/main/fantasy/{tic80,wasm4,uzebox,lowresnx}.zip )
else
  if [ ! -f /userdata/zip/Atari-2600-VCS-ROM-Collection.zip ]; then wget -nv -O /userdata/zip/Atari-2600-VCS-ROM-Collection.zip https://www.atarimania.com/roms/Atari-2600-VCS-ROM-Collection.zip; fi
  for name in tic80 wasm4 uzebox lowresnx; do [ ! -f /userdata/zip/$name.zip ] && wget -nv -O /userdata/zip/$name.zip https://github.com/WizzardSK/gameflix/raw/refs/heads/main/fantasy/$name.zip; done 
  archives=( "/userdata/zip/Atari-2600-VCS-ROM-Collection.zip" )
  archives+=( /userdata/zip/{tic80,wasm4,uzebox,lowresnx}.zip )
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
