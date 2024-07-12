#!/bin/bash
mount -o remount,size=6000M /tmp
ln -s /usr/bin/fusermount /usr/bin/fusermount3
curl https://rclone.org/install.sh | bash
wget -O /userdata/system/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/rclone.conf
if [ ! -f /userdata/system/mount-zip ]; then wget -O /userdata/system/mount-zip https://github.com/WizzardSK/gameflix/raw/main/batocera/share/system/mount-zip; chmod +x /userdata/system/mount-zip; fi
if [ ! -f /userdata/system/ratarmount ]; then wget -O /userdata/system/ratarmount https://github.com/mxmlnkn/ratarmount/releases/download/v0.14.2/ratarmount-0.14.2-x86_64.AppImage; chmod +x /userdata/system/ratarmount; fi
IFS=$'\n' read -d '' -ra roms <<< "$(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.txt)"

emulationstation stop; chvt 3; clear

mkdir -p /userdata/rom
mkdir -p /userdata/roms
mkdir -p /userdata/thumb
mkdir -p /userdata/thumbs
mkdir -p /userdata/system/.cache/httpdirfs
mkdir -p /userdata/system/.cache/ratarmount
mkdir -p /userdata/system/.cache/rclone

/userdata/system/httpdirfs --cache --no-range-check --cache-location /userdata/system/.cache/httpdirfs http://thumbnails.libretro.com /userdata/thumbs > /dev/null
rclone mount myrient: /userdata/rom --http-no-head --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h --allow-non-empty --daemon --no-check-certificate --config=/userdata/system/rclone.conf

IFS=";"
for each in "${roms[@]}"; do
  read -ra rom < <(printf '%s' "$each")
  if [ ! -f /userdata/thumb/${rom[2]}.svg ]; then wget -O /userdata/thumb/${rom[2]}.svg https://raw.githubusercontent.com/fabricecaruso/es-theme-carbon/master/art/controllers/${rom[0]}.svg; fi                                                                                        
done
for each in "${roms[@]}"; do (
  read -ra rom < <(printf '%s' "$each")
  rom3=$(sed 's/<[^>]*>//g' <<< "${rom[3]}")
  echo "${rom3}"
  mkdir -p /userdata/roms/${rom[0]}/${rom3}
  if [[ ${rom[1]} =~ \.zip$ ]]; then
    head /userdata/rom/${rom[1]} > /dev/null
    /userdata/system/ratarmount /userdata/rom/${rom[1]} /userdata/roms/${rom[0]}/${rom3} --index-folders /userdata/system/.cache/ratarmount > /dev/null
  else
    if grep -q ":" <<< "${rom[1]}"; then
      rclone mount ${rom[1]} /userdata/roms/${rom[0]}/${rom3} --http-no-head --no-checksum --no-modtime --dir-cache-time 1000h --allow-non-empty --attr-timeout 1000h --poll-interval 1000h --daemon --config=/userdata/system/rclone.conf
    else
      mount -o bind /userdata/rom/${rom[1]} /userdata/roms/${rom[0]}/${rom3}
    fi
  fi
  if ! grep -Fxq "<gameList>" /userdata/roms/${rom[0]}/gamelist.xml > /dev/null; then
    ls /userdata/roms/${rom[0]}/${rom3} | while read line; do
      if [[ ! ${line} =~ .*\.(jpg|png|torrent|xml|sqlite|mp3|ogg) ]]; then 
        line2=${line%.*}
        echo "<game><path>./${rom3}/${line}</path><name>${line2}</name><image>./images/${line2}.png</image></game>" >> /userdata/roms/${rom[0]}/gamelist.xml
      fi
    done
    echo "<folder><path>./${rom3}</path><name>${rom3}</name><image>~/../thumb/${rom[2]}.svg</image></folder>" >> /userdata/roms/${rom[0]}/gamelist.xml
  fi ) &
  sleep 1
done
echo " "
for each in "${roms[@]}"; do
  read -ra rom < <(printf '%s' "$each")
  mkdir -p /userdata/roms/${rom[0]}/images  
  if ! findmnt -rn /userdata/roms/${rom[0]}/images > /dev/null; then
    echo "${rom[0]} thumbs"
    mount -o bind /userdata/thumbs/${rom[2]}/Named_Snaps /userdata/roms/${rom[0]}/images
    ls /userdata/roms/${rom[0]}/images > /dev/null
  fi
done
for each in "${roms[@]}"; do
  read -ra rom < <(printf '%s' "$each")
  if ! grep -Fxq "<gameList>" /userdata/roms/${rom[0]}/gamelist.xml; then sed -i "1i <gameList>" /userdata/roms/${rom[0]}/gamelist.xml; fi
  if ! grep -Fxq "</gameList>" /userdata/roms/${rom[0]}/gamelist.xml; then sed -i "\$a </gameList>" /userdata/roms/${rom[0]}/gamelist.xml; fi
done
wait
wget -O /usr/share/emulationstation/es_systems.cfg https://github.com/WizzardSK/gameflix/raw/main/batocera/share/system/es_systems.cfg > /dev/null
chvt 2
curl http://127.0.0.1:1234/reloadgames
