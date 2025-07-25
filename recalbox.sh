#!/bin/bash
mount -o remount,rw /
ln -s /usr/bin/fusermount /usr/bin/fusermount3
mkdir -p /recalbox/share/{rom,roms,thumbs,zip,romz}

case $( uname -m ) in
  armv7l) ziparch="arm"; rclarch="arm-v7" ;;
  aarch64) ziparch="arm64"; rclarch="arm64" ;;
  x86_64) ziparch="x64"; rclarch="amd64" ;;
  i386) ziparch="ia32"; rclarch="386" ;;
esac

if [ ! -f /usr/bin/7za ]; then wget -nv -O /usr/bin/7za https://github.com/develar/7zip-bin/raw/master/linux/${ziparch}/7za; chmod +x /usr/bin/7za; fi
if [ ! -f /usr/bin/mount-zip ]; then wget -nv -O /usr/bin/mount-zip https://github.com/WizzardSK/gameflix/raw/main/recalbox/mount-zip; chmod +x /usr/bin/mount-zip; fi
if [ ! -f /usr/bin/rclone ]; then
  wget -nv -O /usr/bin/rclone.zip https://downloads.rclone.org/v1.65.0/rclone-v1.65.0-linux-${rclarch}.zip
  7za e -y /usr/bin/rclone.zip
  mv rclone /usr/bin
  chmod +x /usr/bin/rclone
  rm /usr/bin/rclone.zip
fi

wget -nv -O /recalbox/share_init/system/.emulationstation/systemlist.xml https://github.com/WizzardSK/gameflix/raw/main/recalbox/systemlist.xml
wget -nv -O /recalbox/share/system/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/rclone.conf
IFS=$'\n' read -d '' -ra roms <<< "$(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.txt)"

es stop; chvt 3; clear

rclone mount thumbnails: /recalbox/share/thumbs --config=/recalbox/share/system/rclone.conf --daemon --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h --allow-non-empty
rclone mount myrient: /recalbox/share/rom --config=/recalbox/share/system/rclone.conf --daemon --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h --allow-non-empty

IFS=";"
for each in "${roms[@]}"; do
  read -ra rom < <(printf '%s' "$each")
  echo "Mounting ${rom[0]}"
  mkdir -p /recalbox/share/roms/${rom[0]}/Online
  if grep -q ":" <<< "${rom[1]}"; then
    rclone mount ${rom[1]} /recalbox/share/roms/${rom[0]}/Online --config=/recalbox/share/system/rclone.conf --http-no-head --daemon --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h --allow-non-empty
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

chvt 1; es start
