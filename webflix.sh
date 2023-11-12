#!/bin/bash
source <(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.txt)
wget -O ~/.config/rclone/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/.config/rclone/rclone.conf
wget -O ~/style.css https://raw.githubusercontent.com/WizzardSK/gameflix/main/style.css
wget -O ~/script.js https://raw.githubusercontent.com/WizzardSK/gameflix/main/script.js

#wget -O ~/.local/share/applications/retroarch.sh.desktop https://raw.githubusercontent.com/WizzardSK/gameflix/main/retroarch.sh.desktop
#chmod +x ~/retroarch.sh
#xdg-mime default ~/.local/share/applications/retroarch.sh.desktop application/zip

mkdir -p ~/myrient
mkdir -p ~/myrient/No-Intro
mkdir -p ~/myrient/Redump
mkdir -p ~/myrient/TOSEC
mkdir -p ~/roms
mkdir -p ~/iso

rclone mount myrient:No-Intro ~/myrient/No-Intro --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --allow-non-empty --daemon --vfs-cache-mode full 
rclone mount myrient:Redump ~/myrient/Redump --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --allow-non-empty --daemon
rclone mount myrient:TOSEC ~/myrient/TOSEC --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --allow-non-empty --daemon --vfs-cache-mode full 

IFS=";"
for each in "${roms[@]}"; do
  read -ra rom < <(printf '%s' "$each")
  if grep -q ":" <<< "${rom[1]}"; then
    mkdir -p ~/roms/${rom[0]}
    rclone mount ${rom[1]} ~/roms/${rom[0]} --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --vfs-cache-mode full --allow-non-empty --daemon 
  fi
done
for each in "${zips[@]}"; do
  read -ra zip < <(printf '%s' "$each")
  mkdir -p ~/roms/${zip[0]}
  mount-zip ~/myrient/${zip[1]} ~/roms/${zip[O]} -o nonempty -omodules=iconv,from_code=$charset1,to_code=$charset2
done
