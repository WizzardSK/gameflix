#!/bin/bash
#mount -o remount,rw /
mkdir -p /recalbox/share/system/.config/rclone
if [ ! -f /recalbox/share/system/.config/rclone/rclone.conf ]; then wget -O /recalbox/share/system/.config/rclone/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/.config/rclone/rclone.conf; fi
#curl -s -L https://rclone.org/install.sh | bash
declare -a roms=()

roms+=("atari2600,myrient:No-Intro/Atari - 2600")
roms+=("atari5200,myrient:No-Intro/Atari - 5200")
roms+=("atari7800,myrient:No-Intro/Atari - 7800")
roms+=("jaguar,myrient:No-Intro/Atari - Jaguar (J64)")
roms+=("lynx,myrient:No-Intro/Atari - Lynx")
roms+=("atarist,myrient:No-Intro/Atari - ST")

#roms+=("vectrex,myrient:No-Intro/GCE - Vectrex")
#roms+=("intellivision,myrient:No-Intro/Mattel - Intellivision")
#roms+=("colecovision,myrient:No-Intro/Coleco - ColecoVision")
#roms+=("c64,myrient:No-Intro/Commodore - Commodore 64")

#roms+=("nes,myrient:No-Intro/Nintendo - Nintendo Entertainment System (Headerless)")
#roms+=("snes,myrient:No-Intro/Nintendo - Super Nintendo Entertainment System")
#roms+=("n64,myrient:No-Intro/Nintendo - Nintendo 64 (ByteSwapped)")
#roms+=("gamecube,archive:rvz-gc-usa-redump")

#roms+=("sg1000,myrient:No-Intro/Sega - SG-1000")
#roms+=("mastersystem,myrient:No-Intro/Sega - Master System - Mark III")
#roms+=("gamegear,myrient:No-Intro/Sega - Game Gear")
#roms+=("megadrive,myrient:No-Intro/Sega - Mega Drive - Genesis")
#roms+=("sega32x,myrient:No-Intro/Sega - 32X")
#roms+=("segacd,myrient:Redump/Sega - Mega CD & Sega CD")
#roms+=("saturn,archive:SaturnRedumpCHDs")
#roms+=("dreamcast,archive:chd_dc")

#roms+=("psx,archive:chd_psx")
#roms+=("psp,archive:psp_20220507")
#roms+=("ps2,archive:ps2chd")

rclone mount "archive:retroarch-bios" /recalbox/share/bios --config=/recalbox/share/system/.config/rclone/rclone.conf --vfs-cache-mode full --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --allow-non-empty --daemon
IFS=","
for each in "${roms[@]}"
do
  read -ra rom < <(printf '%s' "$each")
  mkdir -p /recalbox/share/roms/${rom[0]}/online
  rclone mount ${rom[1]} /recalbox/share/roms/${rom[0]}/online --config=/recalbox/share/system/.config/rclone/rclone.conf --daemon --vfs-cache-mode full --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --allow-non-empty 
done
