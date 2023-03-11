#!/bin/bash
mkdir -p /recalbox/share/system/.config/rclone
if [ ! -f /recalbox/share/system/.config/rclone/rclone.conf ]; then wget -O /recalbox/share/system/.config/rclone/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/.config/rclone/rclone.conf; fi
declare -a roms=()

roms+=("atari2600,myrient:No-Intro/Atari - 2600")
roms+=("atari5200,myrient:No-Intro/Atari - 5200")
roms+=("atari7800,myrient:No-Intro/Atari - 7800")
roms+=("jaguar,myrient:No-Intro/Atari - Jaguar (J64)")
roms+=("lynx,myrient:No-Intro/Atari - Lynx")
roms+=("atarist,myrient:No-Intro/Atari - ST")

roms+=("vectrex,myrient:No-Intro/GCE - Vectrex")
roms+=("intellivision,myrient:No-Intro/Mattel - Intellivision")
roms+=("colecovision,myrient:No-Intro/Coleco - ColecoVision")
roms+=("c64,myrient:No-Intro/Commodore - Commodore 64")

roms+=("nes,myrient:No-Intro/Nintendo - Nintendo Entertainment System (Headerless)")
roms+=("snes,myrient:No-Intro/Nintendo - Super Nintendo Entertainment System")
roms+=("n64,myrient:No-Intro/Nintendo - Nintendo 64 (ByteSwapped)")

roms+=("sg1000,myrient:No-Intro/Sega - SG-1000")
roms+=("mastersystem,myrient:No-Intro/Sega - Master System - Mark III")
roms+=("gamegear,myrient:No-Intro/Sega - Game Gear")
roms+=("megadrive,myrient:No-Intro/Sega - Mega Drive - Genesis")
roms+=("sega32x,myrient:No-Intro/Sega - 32X")
roms+=("segacd,myrient:Redump/Sega - Mega CD & Sega CD")
roms+=("dreamcast,archive:dreamcastfrenchchd")

roms+=("psx,archive:andrettiracingusa")
roms+=("psp,archive:psp_20220507")

#echo "Mounting BIOS"
#rclone mount "archive:recalbox-bios" /recalbox/share/bios --config=/recalbox/share/system/.config/rclone/rclone.conf --vfs-cache-mode full --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --allow-non-empty --daemon --allow-other
IFS=","
for each in "${roms[@]}"
do
  read -ra rom < <(printf '%s' "$each")
  echo "Mounting ${rom[0]}"
  mkdir -p /recalbox/share/roms/${rom[0]}/online
  rclone mount ${rom[1]} /recalbox/share/roms/${rom[0]}/online --config=/recalbox/share/system/.config/rclone/rclone.conf --file-perms 777 --daemon --vfs-cache-mode full --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --allow-non-empty --allow-other
  > /recalbox/share/roms/${rom[0]}/gamelist.xml
  echo "<gameList>" >> /recalbox/share/roms/${rom[0]}/gamelist.xml
  ls /recalbox/share/roms/${rom[0]}/online | while read line; do
    echo "<game><path>online/${line}</path></game>" >> /recalbox/share/roms/${rom[0]}/gamelist.xml
  done
  echo "</gameList>" >> /recalbox/share/roms/${rom[0]}/gamelist.xml
done

es restart
