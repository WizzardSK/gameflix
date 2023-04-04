#!/bin/bash
declare -a roms=()

roms+=("arcade,archive:MAME_2003-Plus_Reference_Set_2018,MAME/Named_Snaps,/roms")
roms+=("dos,archive:exov5_2,DOS/Named_Snaps,/eXo/eXoDOS")
roms+=("amiga1200,archive:AmigaSingleRomsA-ZReuploadByGhostware,Commodore - Amiga/Named_Snaps")

roms+=("vectrex,myrient:No-Intro/GCE - Vectrex,GCE - Vectrex/Named_Snaps")
roms+=("intellivision,myrient:No-Intro/Mattel - Intellivision,Mattel - Intellivision/Named_Snaps")
roms+=("colecovision,myrient:No-Intro/Coleco - ColecoVision,Coleco - ColecoVision/Named_Snaps")
roms+=("c64,myrient:No-Intro/Commodore - Commodore 64,Commodore - 64/Named_Snaps")

roms+=("atari2600,myrient:No-Intro/Atari - 2600,Atari - 2600/Named_Snaps")
roms+=("atari5200,myrient:No-Intro/Atari - 5200,Atari - 5200/Named_Snaps")
roms+=("atari7800,myrient:No-Intro/Atari - 7800,Atari - 7800/Named_Snaps")
roms+=("atarijaguar,myrient:No-Intro/Atari - Jaguar (J64),Atari - Jaguar/Named_Snaps")
roms+=("atarilynx,myrient:No-Intro/Atari - Lynx,Atari - Lynx/Named_Snaps")
roms+=("atarist,myrient:No-Intro/Atari - ST,Atari - ST/Named_Snaps")

roms+=("nes,myrient:No-Intro/Nintendo - Nintendo Entertainment System (Headerless),Nintendo - Nintendo Entertainment System/Named_Snaps")
roms+=("snes,myrient:No-Intro/Nintendo - Super Nintendo Entertainment System,Nintendo - Super Nintendo Entertainment System/Named_Snaps")
roms+=("n64,myrient:No-Intro/Nintendo - Nintendo 64 (ByteSwapped),Nintendo - Nintendo 64/Named_Snaps")
roms+=("gc,archive:rvz-gc-usa-redump,Nintendo - GameCube/Named_Boxarts")

roms+=("sg-1000,myrient:No-Intro/Sega - SG-1000,Sega - SG-1000/Named_Snaps")
roms+=("mastersystem,myrient:No-Intro/Sega - Master System - Mark III,Sega - Master System - Mark III/Named_Snaps")
roms+=("gamegear,myrient:No-Intro/Sega - Game Gear,Sega - Game Gear/Named_Snaps")
roms+=("genesis,myrient:No-Intro/Sega - Mega Drive - Genesis,Sega - Mega Drive - Genesis/Named_Snaps")
roms+=("sega32x,myrient:No-Intro/Sega - 32X,Sega - 32X/Named_Boxarts")
roms+=("segacd,myrient:Redump/Sega - Mega CD & Sega CD,Sega - Mega-CD - Sega CD/Named_Snaps")
roms+=("saturn,archive:SaturnRedumpCHDs,Sega - Saturn/Named_Snaps")
roms+=("dreamcast,archive:chd_dc,Sega - Dreamcast/Named_Snaps")

roms+=("psx,archive:chd_psx,Sony - PlayStation/Named_Snaps")
roms+=("psp,archive:psp_20220507,Sony - PlayStation Portable/Named_Boxarts")
roms+=("ps2,archive:ps2chd,Sony - PlayStation 2/Named_Boxarts")

wget -O ~/.emulationstation/custom_systems/es_systems.xml https://raw.githubusercontent.com/WizzardSK/gameflix/main/.emulationstation/custom_systems/es_systems.xml
wget -O ~/.emulationstation/es_controller_mappings.cfg https://raw.githubusercontent.com/WizzardSK/gameflix/main/.emulationstation/es_controller_mappings.cfg
wget -O ~/.emulationstation/es_input.xml https://raw.githubusercontent.com/WizzardSK/gameflix/main/.emulationstation/es_input.xml

mkdir -p ~/.emulationstation/media
rm -rf ~/.emulationstation/downloaded_media

rclone mount "archive:retroarchbios" ~/.config/retroarch/system --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --vfs-cache-mode full --allow-non-empty --daemon
rclone mount thumbnails: ~/.emulationstation/media --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --vfs-cache-mode full --allow-non-empty --daemon

IFS=","
for each in "${roms[@]}"
do
  read -ra rom < <(printf '%s' "$each")
  mkdir -p ~/roms/${rom[0]}
  mkdir -p ~/.emulationstation/downloaded_media/${rom[0]}
  rclone mount ${rom[1]} ~/roms/${rom[0]} --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --vfs-cache-mode full --allow-non-empty --daemon
  ln -s ~/.emulationstation/media/${rom[2]} ~/.emulationstation/downloaded_media/${rom[0]}/screenshots
done

emulationstation &
