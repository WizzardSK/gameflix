#!/bin/bash
declare -a roms=()
source <(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.txt)

wget -O ~/.emulationstation/custom_systems/es_systems.xml https://raw.githubusercontent.com/WizzardSK/gameflix/main/.emulationstation/custom_systems/es_systems.xml
wget -O ~/.emulationstation/es_controller_mappings.cfg https://raw.githubusercontent.com/WizzardSK/gameflix/main/.emulationstation/es_controller_mappings.cfg
wget -O ~/.emulationstation/es_input.xml https://raw.githubusercontent.com/WizzardSK/gameflix/main/.emulationstation/es_input.xml

mkdir -p ~/media
mkdir -p ~/myrient
rm -rf ~/.emulationstation/downloaded_media
rm -rf ~/roms
mkdir -p ~/roms

rclone mount thumbnails: ~/media --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --vfs-cache-mode full --allow-non-empty --daemon
rclone mount myrient: ~/myrient --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --vfs-cache-mode full --allow-non-empty --daemon

IFS=","
for each in "${roms[@]}"; do
  read -ra rom < <(printf '%s' "$each")
  mkdir -p ~/.emulationstation/downloaded_media/${rom[0]}
  if grep -q "archive:" <<< "${rom[1]}"; then
    mkdir -p ~/roms/${rom[0]}
    rclone mount ${rom[1]} ~/roms/${rom[0]} --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --vfs-cache-mode full --allow-non-empty --daemon
  else
    mkdir -p ~/roms/${rom[0]}
    mount -o bind ~/myrient/${rom[1]} ~/roms/${rom[0]}
    #ln -s ~/myrient/${rom[1]} ~/roms/${rom[0]}
  fi
  mkdir -p ~/.emulationstation/downloaded_media/${rom[0]}/screenshots
  mount -o bind ~/media/${rom[2]} ~/.emulationstation/downloaded_media/${rom[0]}/screenshots
  #ln -s ~/media/${rom[2]} ~/.emulationstation/downloaded_media/${rom[0]}/screenshots
done

mkdir -p ~/roms/atari800
mkdir -p ~/roms/amstradcpc
mkdir -p ~/roms/zxspectrum

fuse-zip ~/myrient/TOSEC/Atari/8bit/Games/[ATR]/Atari\ 8bit\ -\ Games\ -\ \[ATR].zip ~/roms/atari800 -o nonempty -omodules=iconv,from_code=$charset1,to_code=$charset2
fuse-zip ~/myrient/TOSEC/Amstrad/CPC/Games/[DSK]/Amstrad\ CPC\ -\ Games\ -\ \[DSK].zip ~/roms/amstradcpc -o nonempty -omodules=iconv,from_code=$charset1,to_code=$charset2
fuse-zip ~/myrient/TOSEC/Sinclair/ZX\ Spectrum/Games/[Z80]/Sinclair\ ZX\ Spectrum\ -\ Games\ -\ \[Z80].zip ~/roms/zxspectrum -o nonempty -omodules=iconv,from_code=$charset1,to_code=$charset2

mv ~/.emulationstation/downloaded_media/atari8bit ~/.emulationstation/downloaded_media/atari800
mv ~/.emulationstation/downloaded_media/amstrad ~/.emulationstation/downloaded_media/amstradcpc
mv ~/.emulationstation/downloaded_media/spectrum ~/.emulationstation/downloaded_media/zxspectrum

emulationstation &
rclone sync "archive:retroarchbios" ~/.config/retroarch/system
