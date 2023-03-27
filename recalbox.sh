#!/bin/bash
mount -o remount,rw /

case $( uname -m ) in
  armv7l)
    ziparch="arm"
    rclarch="arm-v7"
  ;;
  aarch64)
    ziparch="arm64"
    rclarch="arm64"
  ;;
  x86_64)
    ziparch="x64"
    rclarch="amd64"
  ;;
  i386)
    ziparch="ia32"
    rclarch="386"
  ;;
esac

if [ ! -f /usr/bin/7za ]; then
  wget -O /usr/bin/7za https://github.com/develar/7zip-bin/raw/master/linux/${ziparch}/7za
  chmod +x /usr/bin/7za
fi

if [ ! -f /usr/bin/rclone ]; then
  wget https://downloads.rclone.org/rclone-current-linux-${rclarch}.zip
  7za e -y rclone-current-linux-${rclarch}.zip
  mv rclone /usr/bin/
  chmod +x /usr/bin/rclone
  rm rclone-current-linux-${rclarch}.zip
fi

mkdir -p /recalbox/share/system/.config/rclone
if [ ! -f /recalbox/share/system/.config/rclone/rclone.conf ]; then wget -O /recalbox/share/system/.config/rclone/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/.config/rclone/rclone.conf; fi
declare -a roms=()

roms+=("mame,archive:MAME_2003-Plus_Reference_Set_2018,MAME/Named_Snaps,/roms")
roms+=("dos,archive:exov5_2,DOS/Named_Boxarts,/eXo/eXoDOS")
roms+=("amiga1200,archive:AmigaSingleRomsA-ZReuploadByGhostware,Commodore - Amiga/Named_Snaps")

roms+=("atari2600,myrient:No-Intro/Atari - 2600,Atari - 2600/Named_Snaps")
roms+=("atari5200,myrient:No-Intro/Atari - 5200,Atari - 5200/Named_Snaps")
roms+=("atari7800,myrient:No-Intro/Atari - 7800,Atari - 7800/Named_Snaps")
roms+=("lynx,myrient:No-Intro/Atari - Lynx,Atari - Lynx/Named_Snaps")
roms+=("atarist,myrient:No-Intro/Atari - ST,Atari - ST/Named_Snaps")

roms+=("vectrex,myrient:No-Intro/GCE - Vectrex,GCE - Vectrex/Named_Snaps")
roms+=("intellivision,myrient:No-Intro/Mattel - Intellivision,Mattel - Intellivision/Named_Snaps")
roms+=("colecovision,myrient:No-Intro/Coleco - ColecoVision,Coleco - ColecoVision/Named_Snaps")
roms+=("c64,myrient:No-Intro/Commodore - Commodore 64,Commodore - 64/Named_Snaps")

roms+=("nes,myrient:No-Intro/Nintendo - Nintendo Entertainment System (Headered),Nintendo - Nintendo Entertainment System/Named_Snaps")
roms+=("snes,myrient:No-Intro/Nintendo - Super Nintendo Entertainment System,Nintendo - Super Nintendo Entertainment System/Named_Snaps")
roms+=("n64,archive:n64-raspberry-pi-buenos-aires,Nintendo - Nintendo 64/Named_Snaps")

roms+=("sg-1000,myrient:No-Intro/Sega - SG-1000,Sega - SG-1000/Named_Snaps")
roms+=("mastersystem,myrient:No-Intro/Sega - Master System - Mark III,Sega - Master System - Mark III/Named_Snaps")
roms+=("gamegear,myrient:No-Intro/Sega - Game Gear,Sega - Game Gear/Named_Snaps")
roms+=("megadrive,myrient:No-Intro/Sega - Mega Drive - Genesis,Sega - Mega Drive - Genesis/Named_Snaps")
roms+=("sega32x,myrient:No-Intro/Sega - 32X,Sega - 32X/Named_Boxarts")
roms+=("segacd,myrient:Redump/Sega - Mega CD & Sega CD,Sega - Mega-CD - Sega CD/Named_Snaps")
roms+=("dreamcast,archive:chd_dc,Sega - Dreamcast/Named_Snaps,/CHD-Dreamcast")

roms+=("psx,archive:chd_psx,Sony - PlayStation/Named_Snaps,/CHD-PSX-USA")
roms+=("psp,archive:psp_20220507,Sony - PlayStation Portable/Named_Boxarts")

es stop
chvt 3
clear

mkdir -p /recalbox/share/thumbs
rclone mount thumbnails: /recalbox/share/thumbs --config=/recalbox/share/system/.config/rclone/rclone.conf --daemon --vfs-cache-mode full --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --allow-non-empty

IFS=","
for each in "${roms[@]}"; do
  read -ra rom < <(printf '%s' "$each")
  echo "Mounting ${rom[0]}"
  mkdir -p /recalbox/share/roms/${rom[0]}/online
  rclone mount ${rom[1]} /recalbox/share/roms/${rom[0]}/online --config=/recalbox/share/system/.config/rclone/rclone.conf --daemon --vfs-cache-mode full --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --allow-non-empty
  > /recalbox/share/roms/${rom[0]}/gamelist.xml
  echo "<gameList>" >> /recalbox/share/roms/${rom[0]}/gamelist.xml
  ls /recalbox/share/roms/${rom[0]}/online${rom[3]} | while read line; do
    if [[ ! ${line} =~ .*\.(jpg|png|torrent|xml|sqlite|mp3|ogg) ]]; then 
      line2=${line%.*}
      #if [[ ${rom[0]} == "mame" ]]; then
      #  line2=$(xmllint --xpath "//game[@name='${line%.*}']/description/text()" /recalbox/share/bios/mame2003-plus/mame2003-plus.xml)
      #fi
      echo "<game><path>online${rom[3]}/${line}</path><image>../../thumbs/${rom[2]}/${line2}.png</image></game>" >> /recalbox/share/roms/${rom[0]}/gamelist.xml
    fi
  done
  echo "</gameList>" >> /recalbox/share/roms/${rom[0]}/gamelist.xml
done

wget -O /recalbox/share/roms/mame/gamelist.xml https://raw.githubusercontent.com/WizzardSK/gameflix/main/recalbox/share/roms/mame/gamelist.xml
wget -O /recalbox/share/roms/dos/gamelist.xml https://raw.githubusercontent.com/WizzardSK/gameflix/main/recalbox/share/roms/dos/gamelist.xml

chvt 1
es start

rclone sync "archive:recalbox-bios" /recalbox/share/bios --config=/recalbox/share/system/.config/rclone/rclone.conf

