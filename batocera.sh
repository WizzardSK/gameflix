#!/bin/bash
ln -s /usr/bin/fusermount /usr/bin/fusermount3
curl https://rclone.org/install.sh | bash
wget -O /userdata/system/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/.config/rclone/rclone.conf
if [ ! -f /userdata/system/mount-zip ]; then wget -O /userdata/system/mount-zip https://github.com/WizzardSK/gameflix/raw/main/batocera/share/system/mount-zip; chmod +x /userdata/system/mount-zip; fi
source <(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.txt)

emulationstation stop; chvt 3; clear

rm -rf /userdata/roms
mkdir -p /userdata/roms
mkdir -p /userdata/thumbs
mkdir -p /userdata/rom
mkdir -p /userdata/zip

#echo "Mounting thumbs"
#rclone mount thumbnails: /userdata/thumbs --http-no-head --no-checksum --no-modtime --dir-cache-time 100h --allow-non-empty --attr-timeout 100h --poll-interval 100h --daemon --config=/userdata/system/rclone.conf
echo "Mounting roms"
rclone mount myrient: /userdata/rom --http-no-head --no-checksum --no-modtime --dir-cache-time 100h --allow-non-empty --attr-timeout 100h --poll-interval 100h --daemon --config=/userdata/system/rclone.conf

IFS=";"
for each in "${roms[@]}"; do
  read -ra rom < <(printf '%s' "$each")
  echo "Setting ${rom[0]}"
  mkdir -p /userdata/roms/${rom[0]}/online
  mkdir -p /userdata/roms/${rom[0]}/images  
  if grep -q ":" <<< "${rom[1]}"; then
    rclone mount ${rom[1]} /userdata/roms/${rom[0]}/online --http-no-head --no-checksum --no-modtime --dir-cache-time 100h --allow-non-empty --attr-timeout 100h --poll-interval 100h --daemon --config=/userdata/system/rclone.conf
  else mount -o bind /userdata/rom/${rom[1]} /userdata/roms/${rom[0]}/online; fi
  #mount -o bind /userdata/thumbs/${rom[2]}/Named_Snaps /userdata/roms/${rom[0]}/images
  rclone sync thumbnails:${rom[2]}/Named_Snaps /userdata/roms/${rom[0]}/images --config=/userdata/system/rclone.conf
done
for each in "${zips[@]}"; do
  read -ra zip < <(printf '%s' "$each")
  echo "Setting ${zip[0]}"
  mkdir -p /userdata/roms/${zip[0]}/online
  mkdir -p /userdata/roms/${zip[0]}/images
  if [ ! -f /userdata/zip/${zip[0]}.zip ]; then wget -O /userdata/zip/${zip[0]}.zip https://myrient.erista.me/files/${zip[1]}; fi  
  /userdata/system/mount-zip /userdata/zip/${zip[0]}.zip /userdata/roms/${zip[O]}/online -o nonempty -omodules=iconv,from_code=$charset1,to_code=$charset2
  #mount -o bind /userdata/thumbs/${zip[2]}/Named_Snaps /userdata/roms/${zip[0]}/images
  rclone sync thumbnails:${zip[2]}/Named_Snaps /userdata/roms/${zip[0]}/images --config=/userdata/system/rclone.conf
done

wget -O /usr/share/emulationstation/es_systems.cfg https://github.com/WizzardSK/gameflix/raw/main/batocera/share/system/es_systems.cfg
chvt 2
curl http://127.0.0.1:1234/reloadgames
