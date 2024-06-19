#!/bin/bash
mount -o remount,size=6000M /tmp
ln -s /usr/bin/fusermount /usr/bin/fusermount3
curl https://rclone.org/install.sh | bash
wget -O /userdata/system/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/rclone.conf
if [ ! -f /userdata/system/mount-zip ]; then wget -O /userdata/system/mount-zip https://github.com/WizzardSK/gameflix/raw/main/batocera/share/system/mount-zip; chmod +x /userdata/system/mount-zip; fi
if [ ! -f /userdata/system/httpdirfs ]; then wget -O /userdata/system/httpdirfs https://github.com/WizzardSK/gameflix/raw/main/batocera/share/system/httpdirfs; chmod +x /userdata/system/httpdirfs; fi
if [ ! -f /userdata/system/ratarmount ]; then wget -O /userdata/system/ratarmount https://github.com/mxmlnkn/ratarmount/releases/download/v0.14.2/ratarmount-0.14.2-x86_64.AppImage; chmod +x /userdata/system/ratarmount; fi
IFS=$'\n' read -d '' -ra roms <<< "$(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.txt)"

emulationstation stop; chvt 3; clear

mkdir -p /userdata/rom
#mkdir -p /userdata/rom/No-Intro
#mkdir -p /userdata/rom/Redump
#mkdir -p /userdata/rom/TOSEC
#mkdir -p /userdata/rom/TOSEC-ISO
mkdir -p /userdata/roms
mkdir -p /userdata/thumb
mkdir -p /userdata/thumbs
mkdir -p /userdata/system/.cache/httpdirfs
mkdir -p /userdata/system/.cache/ratarmount
mkdir -p /userdata/system/.cache/rclone

echo "Mounting thumbs"
#/userdata/system/httpdirfs --cache --no-range-check --cache-location /userdata/system/.cache/httpdirfs http://thumbnails.libretro.com /userdata/thumbs
rclone mount thumbnails: /userdata/thumbs          --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h --allow-non-empty --daemon --no-check-certificate --config=/userdata/system/rclone.conf --vfs-cache-mode full --cache-dir=/userdata/system/.cache/rclone
echo "Mounting roms"
#/userdata/system/httpdirfs --cache --no-range-check --cache-location /userdata/system/.cache/httpdirfs https://myrient.erista.me/files /userdata/rom
rclone mount myrient:            /userdata/rom           --http-no-head --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h --allow-non-empty --daemon --no-check-certificate --config=/userdata/system/rclone.conf
#rclone mount myrient:No-Intro/  /userdata/rom/No-Intro  --http-no-head --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h --allow-non-empty --daemon --no-check-certificate --config=/userdata/system/rclone.conf
#rclone mount myrient:Redump/    /userdata/rom/Redump    --http-no-head --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h --allow-non-empty --daemon --no-check-certificate --config=/userdata/system/rclone.conf
#rclone mount myrient:TOSEC-ISO/ /userdata/rom/TOSEC-ISO --http-no-head --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h --allow-non-empty --daemon --no-check-certificate --config=/userdata/system/rclone.conf
#rclone mount myrient:TOSEC/     /userdata/rom/TOSEC                    --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h --allow-non-empty --daemon --no-check-certificate --config=/userdata/system/rclone.conf --vfs-cache-mode full --cache-dir=/userdata/system/.cache/rclone

IFS=";"
for each in "${roms[@]}"; do
  read -ra rom < <(printf '%s' "$each")
  #> /userdata/roms/${rom[0]}/gamelist.xml
  if [ ! -f /userdata/thumb/${rom[2]}.png ]; then wget -O /userdata/thumb/${rom[2]}.png https://raw.githubusercontent.com/libretro/retroarch-assets/master/xmb/monochrome/png/${rom[2]}.png; fi
done
for each in "${roms[@]}"; do
  read -ra rom < <(printf '%s' "$each")
  rom3=$(sed 's/<[^>]*>//g' <<< "${rom[3]}")
  echo "${rom3}"
  mkdir -p /userdata/roms/${rom[0]}/${rom3}
  mkdir -p /userdata/roms/${rom[0]}/images  
  if [[ ${rom[1]} =~ \.zip$ ]]; then
    head /userdata/rom/${rom[1]} > /dev/null
    /userdata/system/ratarmount /userdata/rom/${rom[1]} /userdata/roms/${rom[0]}/${rom3} --index-folders /userdata/system/.cache/ratarmount
  else
    if grep -q ":" <<< "${rom[1]}"; then
      rclone mount ${rom[1]} /userdata/roms/${rom[0]}/${rom3} --http-no-head --no-checksum --no-modtime --dir-cache-time 1000h --allow-non-empty --attr-timeout 1000h --poll-interval 1000h --daemon --config=/userdata/system/rclone.conf
    else
      mount -o bind /userdata/rom/${rom[1]} /userdata/roms/${rom[0]}/${rom3}
    fi
  fi  
  if ! findmnt -rn /userdata/roms/${rom[0]}/images > /dev/null; then
    echo "${rom[2]}" thumbs
    mount -o bind /userdata/thumbs/${rom[2]}/Named_Snaps /userdata/roms/${rom[0]}/images
    #rclone mount thumbnails:${rom[2]}/Named_Snaps/ /userdata/roms/${rom[0]}/images --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h --allow-non-empty --daemon --no-check-certificate --config=/userdata/system/rclone.conf --vfs-cache-mode full --cache-dir=/userdata/system/.cache/rclone
  fi
  if ! grep -Fxq "<gameList>" /userdata/roms/${rom[0]}/gamelist.xml > /dev/null; then
    ls /userdata/roms/${rom[0]}/${rom3} | while read line; do
      if [[ ! ${line} =~ .*\.(jpg|png|torrent|xml|sqlite|mp3|ogg) ]]; then 
        line2=${line%.*}
        echo "<game><path>./${rom3}/${line}</path><name>${line2}</name><image>./images/${line2}.png</image></game>" >> /userdata/roms/${rom[0]}/gamelist.xml
      fi
    done
    echo "<folder><path>./${rom3}</path><name>${rom3}</name><image>~/../thumb/${rom[2]}.png</image></folder>" >> /userdata/roms/${rom[0]}/gamelist.xml
  fi
done
for each in "${roms[@]}"; do
  read -ra rom < <(printf '%s' "$each")
  if ! grep -Fxq "<gameList>" /userdata/roms/${rom[0]}/gamelist.xml; then sed -i "1i <gameList>" /userdata/roms/${rom[0]}/gamelist.xml; fi
  if ! grep -Fxq "</gameList>" /userdata/roms/${rom[0]}/gamelist.xml; then sed -i "\$a </gameList>" /userdata/roms/${rom[0]}/gamelist.xml; fi
done

wget -O /usr/share/emulationstation/es_systems.cfg https://github.com/WizzardSK/gameflix/raw/main/batocera/share/system/es_systems.cfg
chvt 2
curl http://127.0.0.1:1234/reloadgames
