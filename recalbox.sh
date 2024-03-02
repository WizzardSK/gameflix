#!/bin/bash
mount -o remount,rw /
mount -o remount,size=4000M /tmp
ln -s /usr/bin/fusermount /usr/bin/fusermount3

case $( uname -m ) in
  armv7l) ziparch="arm"; rclarch="arm-v7" ;;
  aarch64) ziparch="arm64"; rclarch="arm64" ;;
  x86_64) ziparch="x64"; rclarch="amd64" ;;
  i386) ziparch="ia32"; rclarch="386" ;;
esac

if [ ! -f /usr/bin/7za ]; then wget -O /usr/bin/7za https://github.com/develar/7zip-bin/raw/master/linux/${ziparch}/7za; chmod +x /usr/bin/7za; fi
if [ ! -f /usr/bin/mount-zip ]; then wget -O /usr/bin/mount-zip https://github.com/WizzardSK/gameflix/raw/main/recalbox/share/system/mount-zip; chmod +x /usr/bin/mount-zip; fi
if [ ! -f /usr/bin/rclone ]; then
  wget -O /usr/bin/rclone.zip https://downloads.rclone.org/v1.65.0/rclone-v1.65.0-linux-${rclarch}.zip
  7za e -y /usr/bin/rclone.zip
  mv rclone /usr/bin
  chmod +x /usr/bin/rclone
  rm /usr/bin/rclone.zip
fi

wget -O /recalbox/share_init/system/.emulationstation/systemlist.xml https://github.com/WizzardSK/gameflix/raw/main/recalbox/share/system/systemlist.xml
wget -O /recalbox/share/system/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/rclone.conf
source <(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.txt)

es stop; chvt 3; clear

mkdir -p /recalbox/share/rom
mkdir -p /recalbox/share/roms
mkdir -p /recalbox/share/thumbs
mkdir -p /recalbox/share/zip
mkdir -p /recalbox/share/romz

rclone mount thumbnails: /recalbox/share/thumbs --config=/recalbox/share/system/rclone.conf --daemon --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --allow-non-empty
rclone mount myrient: /recalbox/share/rom --config=/recalbox/share/system/rclone.conf --daemon --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --allow-non-empty

IFS=";"
for each in "${roms[@]}"; do
  read -ra rom < <(printf '%s' "$each")
  echo "Mounting ${rom[0]}"
  mkdir -p /recalbox/share/roms/${rom[0]}/Online
  if grep -q ":" <<< "${rom[1]}"; then
    rclone mount ${rom[1]} /recalbox/share/roms/${rom[0]}/Online --config=/recalbox/share/system/rclone.conf --http-no-head --daemon --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --allow-non-empty
  else mount -o bind /recalbox/share/rom/${rom[1]} /recalbox/share/roms/${rom[0]}/Online; fi
  > /recalbox/share/roms/${rom[0]}/gamelist.xml
  echo "<gameList>" >> /recalbox/share/roms/${rom[0]}/gamelist.xml
  ls /recalbox/share/roms/${rom[0]}/Online | while read line; do
    if [[ ! ${line} =~ .*\.(jpg|png|torrent|xml|sqlite|mp3|ogg) ]]; then 
      line2=${line%.*}
      echo "<game><path>Online/${line}</path><name>${line2}</name><image>../../thumbs/${rom[2]}/Named_Snaps/${line2}.png</image></game>" >> /recalbox/share/roms/${rom[0]}/gamelist.xml
    fi
  done
  echo "</gameList>" >> /recalbox/share/roms/${rom[0]}/gamelist.xml
done
for each in "${isos[@]}"; do
  read -ra rom < <(printf '%s' "$each")
  echo "Mounting ${rom[0]}"
  mkdir -p /recalbox/share/roms/${rom[0]}/TOSEC-ISO
  mount -o bind /recalbox/share/rom/${rom[1]} /recalbox/share/roms/${rom[0]}/TOSEC-ISO
  > /recalbox/share/roms/${rom[0]}/gamelist.xml
  echo "<gameList>" >> /recalbox/share/roms/${rom[0]}/gamelist.xml
  ls /recalbox/share/roms/${rom[0]}/TOSEC-ISO | while read line; do
    if [[ ! ${line} =~ .*\.(jpg|png|torrent|xml|sqlite|mp3|ogg) ]]; then 
      line2=${line%.*}
      echo "<game><path>TOSEC-ISO/${line}</path><name>${line2}</name><image>../../thumbs/${rom[2]}/Named_Snaps/${line2}.png</image></game>" >> /recalbox/share/roms/${rom[0]}/gamelist.xml
    fi
  done
  echo "</gameList>" >> /recalbox/share/roms/${rom[0]}/gamelist.xml
done
for each in "${romz[@]}"; do
  read -ra zip < <(printf '%s' "$each")
  echo "Mounting ${zip[0]}"
  mkdir -p /recalbox/share/roms/${zip[0]}/No-Intro
  if [ ! -f /recalbox/share/romz/${zip[0]}.zip ]; then wget -O /recalbox/share/romz/${zip[0]}.zip https://archive.org/download/ni-roms/roms/${zip[1]}; fi  
  mount-zip /recalbox/share/romz/${zip[0]}.zip /recalbox/share/roms/${zip[O]}/No-Intro -o nonempty -omodules=iconv,from_code=$charset1,to_code=$charset2
  > /recalbox/share/roms/${zip[0]}/gamelist.xml
  echo "<gameList>" >> /recalbox/share/roms/${zip[0]}/gamelist.xml
  ls /recalbox/share/roms/${zip[0]}/No-Intro | while read line; do
    if [[ ! ${line} =~ .*\.(jpg|png|torrent|xml|sqlite|mp3|ogg) ]]; then
      line2=${line%.*}
      echo "<game><path>No-Intro/${line}</path><name>${line2}</name><image>../../thumbs/${zip[2]}/Named_Snaps/${line2}.png</image></game>" >> /recalbox/share/roms/${zip[0]}/gamelist.xml;
    fi
  done
  echo "</gameList>" >> /recalbox/share/roms/${zip[0]}/gamelist.xml
done
for each in "${zips[@]}"; do
  read -ra zip < <(printf '%s' "$each")
  echo "Mounting ${zip[0]}"
  mkdir -p /recalbox/share/roms/${zip[0]}/TOSEC
  if [ ! -f /recalbox/share/zip/${zip[0]}.zip ]; then wget -O /recalbox/share/zip/${zip[0]}.zip https://myrient.erista.me/files/${zip[1]}; fi  
  mount-zip /recalbox/share/zip/${zip[0]}.zip /recalbox/share/roms/${zip[O]}/TOSEC -o nonempty -omodules=iconv,from_code=$charset1,to_code=$charset2
  > /recalbox/share/roms/${zip[0]}/gamelist.xml
  echo "<gameList>" >> /recalbox/share/roms/${zip[0]}/gamelist.xml
  ls /recalbox/share/roms/${zip[0]}/TOSEC | while read line; do
    if [[ ! ${line} =~ .*\.(jpg|png|torrent|xml|sqlite|mp3|ogg) ]]; then
      line2=${line%.*}
      echo "<game><path>TOSEC/${line}</path><name>${line2}</name><image>../../thumbs/${zip[2]}/Named_Snaps/${line2}.png</image></game>" >> /recalbox/share/roms/${zip[0]}/gamelist.xml;
    fi
  done
  echo "</gameList>" >> /recalbox/share/roms/${zip[0]}/gamelist.xml
done

chvt 1; es start
