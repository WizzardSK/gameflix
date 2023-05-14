#!/bin/bash
if [ ! -f /userdata/system/.config/rclone/rclone.conf ]; then wget -O /userdata/system/.config/rclone/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/.config/rclone/rclone.conf; fi
declare -a roms=()
source <(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.txt)

emulationstation stop
chvt 3
clear

mkdir -p /userdata/thumbs
mkdir -p /userdata/rom

rclone mount myrient: /userdata/rom --no-checksum --no-modtime --dir-cache-time 100h --allow-non-empty --attr-timeout 100h --poll-interval 100h --vfs-cache-mode full --daemon --config=/userdata/system/.config/rclone/rclone.conf
rclone mount thumbnails: /userdata/thumbs --no-checksum --no-modtime --dir-cache-time 100h --allow-non-empty --attr-timeout 100h --poll-interval 100h --vfs-cache-mode full --daemon --config=/userdata/system/.config/rclone/rclone.conf

IFS=","
for each in "${roms[@]}"; do
  read -ra rom < <(printf '%s' "$each")
  echo "Mounting ${rom[0]}"
  mkdir -p /userdata/roms/${rom[0]}/online
  mkdir -p /userdata/roms/${rom[0]}/images  
  if grep -q "archive:" <<< "${rom[1]}"; then
    rclone mount ${rom[1]} /userdata/roms/${rom[0]}/online --no-checksum --no-modtime --dir-cache-time 100h --allow-non-empty --attr-timeout 100h --poll-interval 100h --vfs-cache-mode full --daemon --config=/userdata/system/.config/rclone/rclone.conf
  else
    mount -o bind /userdata/rom/${rom[1]} /userdata/roms/${rom[0]}/online
  fi  
  mount -o bind /userdata/thumbs/${rom[2]}/Named_Snaps /userdata/roms/${rom[0]}/images
done

wget -O /userdata/system/fuse-zip https://raw.githubusercontent.com/WizzardSK/gameflix/main/fuse-zip
chmod +x /userdata/system/fuse-zip

echo "Mounting atari800"
/userdata/system/fuse-zip /userdata/rom/TOSEC/Atari/8bit/Games/[ATR]/Atari\ 8bit\ -\ Games\ -\ \[ATR].zip /userdata/roms/atari800/online -o nonempty -omodules=iconv,from_code=$charset1,to_code=$charset2
mount -o bind /userdata/thumbs/Atari\ -\ 8-\bit/Named_Snaps /userdata/roms/atari800/images

echo "Mounting amstradcpc"
/userdata/system/fuse-zip /userdata/rom/TOSEC/Amstrad/CPC/Games/[DSK]/Amstrad\ CPC\ -\ Games\ -\ \[DSK].zip /userdata/roms/amstradcpc/online -o nonempty -omodules=iconv,from_code=$charset1,to_code=$charset2
mount -o bind /userdata/thumbs/Amstrad\ -\ CPC/Named_Snaps /userdata/roms/amstradcpc/images

echo "Mounting zxspectrum"
/userdata/system/fuse-zip /userdata/rom/TOSEC/Sinclair/ZX\ Spectrum/Games/[Z80]/Sinclair\ ZX\ Spectrum\ -\ Games\ -\ \[Z80].zip /userdata/roms/zxspectrum/online -o nonempty -omodules=iconv,from_code=$charset1,to_code=$charset2
mount -o bind /userdata/thumbs/Sinclair\ -\ ZX\ Spectrum/Named_Snaps /userdata/roms/zxspectrum/images

chvt 2
curl http://127.0.0.1:1234/reloadgames
rclone sync archive:retroarchbios /userdata/bios --config=/userdata/system/.config/rclone/rclone.conf
