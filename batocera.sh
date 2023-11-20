#!/bin/bash
wget -O /userdata/system/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/.config/rclone/rclone.conf
if [ ! -f /userdata/system/mount-zip ]; then wget -O /userdata/system/mount-zip https://github.com/WizzardSK/gameflix/raw/main/batocera/share/system/mount-zip; chmod +x /userdata/system/mount-zip; fi
source <(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.txt)

emulationstation stop; chvt 3; clear

rm -rf /userdata/roms
mkdir -p /userdata/roms
mkdir -p /userdata/thumbs
mkdir -p /userdata/rom
mkdir -p /userdata/zip
mkdir -p /userdata/rom/No-Intro
mkdir -p /userdata/rom/Redump

rclone mount thumbnails: /userdata/thumbs --no-checksum --no-modtime --dir-cache-time 100h --allow-non-empty --attr-timeout 100h --poll-interval 100h --daemon --config=/userdata/system/rclone.conf
rclone mount myrient:No-Intro /userdata/rom/No-Intro --no-checksum --no-modtime --dir-cache-time 100h --allow-non-empty --attr-timeout 100h --poll-interval 100h --daemon --config=/userdata/system/rclone.conf
rclone mount myrient:Redump /userdata/rom/Redump --no-checksum --no-modtime --dir-cache-time 100h --allow-non-empty --attr-timeout 100h --poll-interval 100h --daemon --config=/userdata/system/rclone.conf

IFS=";"
for each in "${roms[@]}"; do
  read -ra rom < <(printf '%s' "$each")
  echo "Mounting ${rom[0]}"
  mkdir -p /userdata/roms/${rom[0]}/online
  mkdir -p /userdata/roms/${rom[0]}/images  
  if grep -q ":" <<< "${rom[1]}"; then
    rclone mount ${rom[1]} /userdata/roms/${rom[0]}/online --no-checksum --no-modtime --dir-cache-time 100h --allow-non-empty --attr-timeout 100h --poll-interval 100h --daemon --config=/userdata/system/rclone.conf
  else mount -o bind /userdata/rom/${rom[1]} /userdata/roms/${rom[0]}/online; fi
  mount -o bind /userdata/thumbs/${rom[2]}/Named_Snaps /userdata/roms/${rom[0]}/images
done
for each in "${zips[@]}"; do
  read -ra zip < <(printf '%s' "$each")
  echo "Mounting ${zip[0]}"
  mkdir -p /userdata/roms/${zip[0]}/online
  mkdir -p /userdata/roms/${zip[0]}/images
  if [ ! -f /userdata/zip/${zip[0]}.zip ]; then wget -O /userdata/zip/${zip[0]}.zip https://myrient.erista.me/files/${zip[1]}; fi  
  /userdata/system/mount-zip /userdata/zip/${zip[0]}.zip /userdata/roms/${zip[O]}/online -o nonempty -omodules=iconv,from_code=$charset1,to_code=$charset2
  mount -o bind /userdata/thumbs/${zip[2]}/Named_Snaps /userdata/roms/${zip[0]}/images
done

wget -O /usr/share/emulationstation/es_systems.cfg https://github.com/WizzardSK/gameflix/raw/main/batocera/share/system/es_systems.cfg
chvt 2
curl http://127.0.0.1:1234/reloadgames
curl http://127.0.0.1:1234/reloadgames
curl http://127.0.0.1:1234/reloadgames
