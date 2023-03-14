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

if [ ! -f /usr/bin/7za ]
then
  wget -O /usr/bin/7za https://github.com/develar/7zip-bin/raw/master/linux/${ziparch}/7za
  chmod +x /usr/bin/7za
fi

if [ ! -f /usr/bin/rclone ]
then
  wget https://downloads.rclone.org/rclone-current-linux-${rclarch}.zip
  7za e -y rclone-current-linux-${rclarch}.zip
  mv rclone /usr/bin/
  chmod +x /usr/bin/rclone
  rm rclone-current-linux-${rclarch}.zip
fi

mkdir -p /recalbox/share/system/.config/rclone
if [ ! -f /recalbox/share/system/.config/rclone/rclone.conf ]; then wget -O /recalbox/share/system/.config/rclone/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/.config/rclone/rclone.conf; fi
declare -a roms=()

roms+=("mame,archive:MAME_2003-Plus_Reference_Set_2018,/roms")
roms+=("neogeo,archive:Neo-geoRomCollectionByGhostware")
roms+=("dos,archive:exov5_2,/eXo/eXoDOS")
roms+=("amiga1200,archive:AmigaSingleRomsA-ZReuploadByGhostware")

roms+=("atari2600,myrient:No-Intro/Atari - 2600")
roms+=("atari5200,myrient:No-Intro/Atari - 5200")
roms+=("atari7800,myrient:No-Intro/Atari - 7800")
roms+=("lynx,myrient:No-Intro/Atari - Lynx")
roms+=("atarist,myrient:No-Intro/Atari - ST")

roms+=("vectrex,myrient:No-Intro/GCE - Vectrex")
roms+=("intellivision,myrient:No-Intro/Mattel - Intellivision")
roms+=("colecovision,myrient:No-Intro/Coleco - ColecoVision")
roms+=("c64,myrient:No-Intro/Commodore - Commodore 64")

roms+=("nes,myrient:No-Intro/Nintendo - Nintendo Entertainment System (Headered)")
roms+=("snes,myrient:No-Intro/Nintendo - Super Nintendo Entertainment System")
roms+=("n64,myrient:No-Intro/Nintendo - Nintendo 64 (ByteSwapped)")

roms+=("sg1000,myrient:No-Intro/Sega - SG-1000")
roms+=("mastersystem,myrient:No-Intro/Sega - Master System - Mark III")
roms+=("gamegear,myrient:No-Intro/Sega - Game Gear")
roms+=("megadrive,myrient:No-Intro/Sega - Mega Drive - Genesis")
roms+=("sega32x,myrient:No-Intro/Sega - 32X")
roms+=("segacd,myrient:Redump/Sega - Mega CD & Sega CD")
roms+=("dreamcast,archive:chd_dc,/CHD-Dreamcast")

roms+=("psx,archive:chd_psx,/CHD-PSX-USA")
roms+=("psp,archive:psp_20220507")

IFS=","
for each in "${roms[@]}"
do
  read -ra rom < <(printf '%s' "$each")
  echo "Mounting ${rom[0]}"
  mkdir -p /recalbox/share/roms/${rom[0]}/online
  rclone mount ${rom[1]} /recalbox/share/roms/${rom[0]}/online --config=/recalbox/share/system/.config/rclone/rclone.conf --daemon --vfs-cache-mode full --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --allow-non-empty
  > /recalbox/share/roms/${rom[0]}/gamelist.xml
  echo "<gameList>" >> /recalbox/share/roms/${rom[0]}/gamelist.xml
  ls /recalbox/share/roms/${rom[0]}/online${rom[2]} | while read line; do
    if [[ ! ${line} =~ .*\.(jpg|png|torrent|xml|sqlite) ]]; then 
      echo "<game><path>online${rom[2]}/${line}</path></game>" >> /recalbox/share/roms/${rom[0]}/gamelist.xml
    fi
  done
  echo "</gameList>" >> /recalbox/share/roms/${rom[0]}/gamelist.xml
done

test -e "/recalbox/share/system/samba.sh" && bash /recalbox/share/system/samba.sh

es restart

rclone sync "archive:recalbox-bios" /recalbox/share/bios --config=/recalbox/share/system/.config/rclone/rclone.conf

