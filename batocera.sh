#!/bin/bash
mount -o remount,size=6000M /tmp
ln -s /usr/bin/fusermount /usr/bin/fusermount3
curl https://rclone.org/install.sh | bash
wget -O /userdata/system/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/rclone.conf
if [ ! -f /userdata/system/httpdirfs ]; then wget -O /userdata/system/httpdirfs https://github.com/WizzardSK/gameflix/raw/main/batocera/share/system/httpdirfs; chmod +x /userdata/system/httpdirfs; fi
if [ ! -f /userdata/system/mount-zip ]; then wget -O /userdata/system/mount-zip https://github.com/WizzardSK/gameflix/raw/main/batocera/share/system/mount-zip; chmod +x /userdata/system/mount-zip; fi
if [ ! -f /userdata/system/ratarmount ]; then wget -O /userdata/system/ratarmount https://github.com/mxmlnkn/ratarmount/releases/download/v0.15.1/ratarmount-0.15.1-x86_64.AppImage; chmod +x /userdata/system/ratarmount; fi
IFS=$'\n' read -d '' -ra roms <<< "$(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.txt)"

emulationstation stop; chvt 3; clear

mkdir -p /userdata/rom
mkdir -p /userdata/roms
mkdir -p /userdata/thumb
mkdir -p /userdata/thumbs
mkdir -p /userdata/system/.cache/httpdirfs
mkdir -p /userdata/system/.cache/ratarmount
mkdir -p /userdata/system/.cache/rclone

rclone mount myrient: /userdata/rom --http-no-head --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h --allow-non-empty --daemon --no-check-certificate --config=/userdata/system/rclone.conf
/userdata/system/cli/run

IFS=";"
for each in "${roms[@]}"; do
  read -ra rom < <(printf '%s' "$each")
  if [ ! -f /userdata/thumb/${rom[0]}.png ]; then wget -O /userdata/thumb/${rom[0]}.png https://raw.githubusercontent.com/fabricecaruso/es-theme-carbon/master/art/consoles/${rom[0]}.png; fi                                                                                        
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
        echo "<game><path>./${rom3}/${line}</path><name>${line2}</name><image>./images/${line2}.png</image><marquee>./titles/${line2}.png</marquee><thumbnail>./boxes/${line2}.png</thumbnail></game>" >> /userdata/roms/${rom[0]}/gamelist.xml
      fi
    done
    echo "<folder><path>./${rom3}</path><name>${rom3}</name><image>~/../thumb/${rom[0]}.png</image></folder>" >> /userdata/roms/${rom[0]}/gamelist.xml
  fi
  rom2="${rom[2]// /_}"
  if [ ! -d "/userdata/thumbs/${rom[2]}" ]; then git clone "https://github.com/WizzardSK/${rom2}.git" /userdata/thumbs/${rom[2]}; fi
  git -C /userdata/thumbs/${rom[2]} config pull.rebase false
  git -C /userdata/thumbs/${rom[2]} pull &>> /userdata/system/logs/git.log
  ) &
  sleep 1
done
for each in "${roms[@]}"; do
  read -ra rom < <(printf '%s' "$each")
  mkdir -p /userdata/roms/${rom[0]}/images  
  mkdir -p /userdata/roms/${rom[0]}/titles  
  mkdir -p /userdata/roms/${rom[0]}/boxes  
  if ! findmnt -rn /userdata/roms/${rom[0]}/images > /dev/null; then
    mount -o bind /userdata/thumbs/${rom[2]}/Named_Snaps /userdata/roms/${rom[0]}/images
    mount -o bind /userdata/thumbs/${rom[2]}/Named_Titles /userdata/roms/${rom[0]}/titles
    mount -o bind /userdata/thumbs/${rom[2]}/Named_Boxarts /userdata/roms/${rom[0]}/boxes
  fi
done
for each in "${roms[@]}"; do
  read -ra rom < <(printf '%s' "$each")
  if ! grep -Fxq "<gameList>" /userdata/roms/${rom[0]}/gamelist.xml; then sed -i "1i <gameList>" /userdata/roms/${rom[0]}/gamelist.xml; fi
  if ! grep -Fxq "</gameList>" /userdata/roms/${rom[0]}/gamelist.xml; then sed -i "\$a </gameList>" /userdata/roms/${rom[0]}/gamelist.xml; fi
done
wait
cp /usr/share/emulationstation/es_systems.cfg /usr/share/emulationstation/es_systems.bak
wget -O /usr/share/emulationstation/es_systems.cfg https://github.com/WizzardSK/gameflix/raw/main/batocera/share/system/es_systems.cfg > /dev/null
chvt 2
wget http://127.0.0.1:1234/reloadgames
