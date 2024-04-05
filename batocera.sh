#!/bin/bash
mount -o remount,size=6000M /tmp
ln -s /usr/bin/fusermount /usr/bin/fusermount3
curl https://rclone.org/install.sh | bash
wget -O /userdata/system/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/rclone.conf
if [ ! -f /userdata/system/mount-zip ]; then wget -O /userdata/system/mount-zip https://github.com/WizzardSK/gameflix/raw/main/batocera/share/system/mount-zip; chmod +x /userdata/system/mount-zip; fi
if [ ! -f /userdata/system/httpdirfs ]; then wget -O /userdata/system/httpdirfs https://github.com/WizzardSK/gameflix/raw/main/batocera/share/system/httpdirfs; chmod +x /userdata/system/httpdirfs; fi
source <(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.txt)

emulationstation stop; chvt 3; clear

mkdir -p /userdata/rom
mkdir -p /userdata/roms
mkdir -p /userdata/thumbs
mkdir -p /userdata/zip
mkdir -p /userdata/romz

echo "Mounting thumbs"
/userdata/system/httpdirfs --cache --no-range-check --cache-location /userdata/system/.cache/httpdirfs http://thumbnails.libretro.com /userdata/thumbs
echo "Mounting roms"
/userdata/system/httpdirfs --cache --no-range-check --cache-location /userdata/system/.cache/httpdirfs https://myrient.erista.me/files /userdata/rom
#rclone mount myrient: /userdata/rom --no-check-certificate --http-no-head --no-checksum --no-modtime --dir-cache-time 1000h --allow-non-empty --attr-timeout 1000h --poll-interval 1000h --daemon --config=/userdata/system/rclone.conf

IFS=";"
for each in "${roms[@]}"; do
  read -ra rom < <(printf '%s' "$each")
  echo "rom: ${rom[2]}"
  mkdir -p /userdata/roms/${rom[0]}/Online
  mkdir -p /userdata/roms/${rom[0]}/images  
  if grep -q "http" <<< "${rom[1]}"; then
    /userdata/system/httpdirfs --cache --no-range-check --cache-location /userdata/system/.cache/httpdirfs ${rom[1]} /userdata/roms/${rom[0]}/Online
    #rclone mount ${rom[1]} /userdata/roms/${rom[0]}/Online --http-no-head --no-checksum --no-modtime --dir-cache-time 1000h --allow-non-empty --attr-timeout 1000h --poll-interval 1000h --daemon --config=/userdata/system/rclone.conf
  else mount -o bind /userdata/rom/${rom[1]} /userdata/roms/${rom[0]}/Online; fi
  mount -o bind /userdata/thumbs/${rom[2]}/Named_Snaps /userdata/roms/${rom[0]}/images
done
for each in "${isos[@]}"; do
  read -ra iso < <(printf '%s' "$each")
  echo "iso: ${iso[2]}"
  mkdir -p /userdata/roms/${iso[0]}/TOSEC-ISO
  mkdir -p /userdata/roms/${iso[0]}/images  
  mount -o bind /userdata/rom/${iso[1]} /userdata/roms/${iso[0]}/TOSEC-ISO
  mount -o bind /userdata/thumbs/${iso[2]}/Named_Snaps /userdata/roms/${iso[0]}/images
done
for each in "${romz[@]}"; do
  read -ra zip < <(printf '%s' "$each")
  echo "n-i: ${zip[2]}"
  mkdir -p /userdata/roms/${zip[0]}/No-Intro
  mkdir -p /userdata/roms/${zip[0]}/images
  if [ ! -f /userdata/romz/${zip[0]}.zip ]; then wget -O /userdata/romz/${zip[0]}.zip https://archive.org/download/ni-roms/roms/${zip[1]}; fi
  /userdata/system/mount-zip /userdata/romz/${zip[0]}.zip /userdata/roms/${zip[O]}/No-Intro -o nonempty -omodules=iconv,from_code=$charset1,to_code=$charset2
  mount -o bind /userdata/thumbs/${zip[2]}/Named_Snaps /userdata/roms/${zip[0]}/images
done
for each in "${zips[@]}"; do
  read -ra zip < <(printf '%s' "$each")
  echo "zip: ${zip[2]}"
  mkdir -p /userdata/roms/${zip[0]}/TOSEC
  mkdir -p /userdata/roms/${zip[0]}/images
  if [ ! -f /userdata/zip/${zip[0]}.zip ]; then wget -O /userdata/zip/${zip[0]}.zip https://myrient.erista.me/files/${zip[1]}; fi  
  /userdata/system/mount-zip /userdata/zip/${zip[0]}.zip /userdata/roms/${zip[O]}/TOSEC -o nonempty -omodules=iconv,from_code=$charset1,to_code=$charset2
  mount -o bind /userdata/thumbs/${zip[2]}/Named_Snaps /userdata/roms/${zip[0]}/images
done

wget -O /usr/share/emulationstation/es_systems.cfg https://github.com/WizzardSK/gameflix/raw/main/batocera/share/system/es_systems.cfg
chvt 2
curl http://127.0.0.1:1234/reloadgames
