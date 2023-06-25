#!/bin/bash
source <(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.txt)

wget -O ~/.emulationstation/custom_systems/es_systems.xml https://raw.githubusercontent.com/WizzardSK/gameflix/main/.emulationstation/custom_systems/es_systems.xml
wget -O ~/.emulationstation/es_controller_mappings.cfg https://raw.githubusercontent.com/WizzardSK/gameflix/main/.emulationstation/es_controller_mappings.cfg
wget -O ~/.emulationstation/es_input.xml https://raw.githubusercontent.com/WizzardSK/gameflix/main/.emulationstation/es_input.xml
wget -O ~/.emulationstation/es_settings.xml https://raw.githubusercontent.com/WizzardSK/gameflix/main/.emulationstation/es_settings.xml

rm -rf ~/.emulationstation/downloaded_media
rm -rf ~/.emulationstation/gamelists
rm -rf ~/.cache/rclone
rm -rf ~/roms
mkdir -p ~/media
mkdir -p ~/myrient
mkdir -p ~/myrient/No-Intro
mkdir -p ~/myrient/Redump
mkdir -p ~/myrient/TOSEC
mkdir -p ~/roms
mkdir -p ~/iso

rclone mount thumbnails: ~/media --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --vfs-cache-mode full --allow-non-empty --daemon
rclone mount myrient:No-Intro ~/myrient/No-Intro --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --vfs-cache-mode writes --allow-non-empty --daemon
rclone mount myrient:Redump ~/myrient/Redump --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --allow-non-empty --daemon
rclone mount myrient:TOSEC ~/myrient/TOSEC --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h  --vfs-cache-mode writes --allow-non-empty --daemon

IFS=","
for each in "${roms[@]}"; do
  read -ra rom < <(printf '%s' "$each")
  mkdir -p ~/.emulationstation/downloaded_media/${rom[0]}
  if grep -q "archive:" <<< "${rom[1]}"; then
    mkdir -p ~/roms/${rom[0]}
    rclone mount ${rom[1]} ~/roms/${rom[0]} --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --vfs-cache-mode full --allow-non-empty --daemon
  else
    ln -s ~/myrient/${rom[1]} ~/roms/${rom[0]}
  fi
  ln -s ~/media/${rom[2]}/Named_Snaps ~/.emulationstation/downloaded_media/${rom[0]}/screenshots
#  mkdir -p ~/.emulationstation/gamelists/${rom[0]}
#  > ~/.emulationstation/gamelists/${rom[0]}/gamelist.xml
#  echo "<gameList>" >> ~/.emulationstation/gamelists/${rom[0]}/gamelist.xml
#  ls ~/roms/${rom[0]} | while read line; do
#    if [[ ! ${line} =~ .*\.(jpg|png|torrent|xml|sqlite|mp3|ogg) ]]; then echo "<game><path>./${line}</path></game>" >> ~/.emulationstation/gamelists/${rom[0]}/gamelist.xml; fi
#  done
#  echo "</gameList>" >> ~/.emulationstation/gamelists/${rom[0]}/gamelist.xml
done
for each in "${zips[@]}"; do
  read -ra zip < <(printf '%s' "$each")
  mkdir -p ~/roms/${zip[0]}
  mkdir -p ~/.emulationstation/downloaded_media/${zip[0]}
  ln -s ~/media/${zip[2]}/Named_Snaps ~/.emulationstation/downloaded_media/${zip[0]}/screenshots
  mount-zip ~/myrient/${zip[1]} ~/roms/${zip[O]} -o nonempty -omodules=iconv,from_code=$charset1,to_code=$charset2
#  mkdir -p ~/.emulationstation/gamelists/${zip[0]}
#  > ~/.emulationstation/gamelists/${zip[0]}/gamelist.xml
#  echo "<gameList>" >> ~/.emulationstation/gamelists/${zip[0]}/gamelist.xml
#  ls ~/roms/${zip[0]} | while read line; do
#    if [[ ! ${line} =~ .*\.(jpg|png|torrent|xml|sqlite|mp3|ogg) ]]; then echo "<game><path>./${line}</path></game>" >> ~/.emulationstation/gamelists/${zip[0]}/gamelist.xml; fi
#  done
#  echo "</gameList>" >> ~/.emulationstation/gamelists/${zip[0]}/gamelist.xml
done

emulationstation &
