#!/bin/bash
params="--no-checksum --no-modtime --read-only --attr-timeout 10h --dir-cache-time 10h --poll-interval 10h --vfs-cache-mode full --allow-non-empty"

# DOS
#rclone mount "myrient:Redump/IBM - PC compatible" roms/dos $params &
#rclone mount "thumbnails:DOS/Named_Boxarts" ~/.emulationstation/downloaded_media/dos/screenshots/ $params &

# Arcade
#rclone mount archive:fbnarcade-fullnonmerged roms/mame $params &
#rclone mount "thumbnails:MAME/Named_Snaps" ~/.emulationstation/downloaded_media/mame/screenshots/ $params &

# Amstrad
rclone mount archive:AmstradCPCGameCollectionByGhostware roms/amstradcpc $params &
rclone mount "thumbnails:Amstrad - CPC/Named_Snaps" ~/.emulationstation/downloaded_media/amstradcpc/screenshots/ $params &

# Atari - Amiga
rclone mount "myrient:No-Intro/Atari - 2600" roms/atari2600 $params &
rclone mount "thumbnails:Atari - 2600/Named_Snaps" ~/.emulationstation/downloaded_media/atari2600/screenshots/ $params &

rclone mount "myrient:No-Intro/Atari - 5200" roms/atari5200 $params &
rclone mount "thumbnails:Atari - 5200/Named_Snaps" ~/.emulationstation/downloaded_media/atari5200/screenshots/ $params &

rclone mount "myrient:No-Intro/Atari - 7800" roms/atari7800 $params &
rclone mount "thumbnails:Atari - 7800/Named_Snaps" ~/.emulationstation/downloaded_media/atari7800/screenshots/ $params &

rclone mount "myrient:No-Intro/Atari - Jaguar (J64)" roms/atarijaguar $params &
rclone mount "thumbnails:Atari - Jaguar/Named_Snaps" ~/.emulationstation/downloaded_media/atarijaguar/screenshots/ $params &

rclone mount "myrient:No-Intro/Atari - Lynx" roms/atarilynx $params &
rclone mount "thumbnails:Atari - Lynx/Named_Snaps" ~/.emulationstation/downloaded_media/atarilynx/screenshots/ $params &

rclone mount "myrient:No-Intro/Atari - ST" roms/atarist $params &
rclone mount "thumbnails:Atari - ST/Named_Snaps" ~/.emulationstation/downloaded_media/atarist/screenshots/ $params &

rclone mount archive:Amiga_WHD_Games roms/amiga $params &
rclone mount "thumbnails:Commodore - Amiga/Named_Snaps" ~/.emulationstation/downloaded_media/amiga/screenshots/ $params &

rclone mount "myrient:No-Intro/Commodore - Commodore 64" roms/c64 $params &
rclone mount "thumbnails:Commodore - 64/Named_Snaps" ~/.emulationstation/downloaded_media/c64/screenshots/ $params &

# PS
rclone mount archive:chd_psx roms/ps1 $params &
rclone mount "thumbnails:Sony - PlayStation/Named_Snaps" ~/.emulationstation/downloaded_media/psx/screenshots/ $params &

rclone mount archive:def-jam-vendetta-u roms/psp $params &
rclone mount "thumbnails:Sony - PlayStation Portable/Named_Boxarts" ~/.emulationstation/downloaded_media/psp/screenshots/ $params &

rclone mount archive:ps2chd roms/ps2 $params &
rclone mount "thumbnails:Sony - PlayStation 2/Named_Boxarts" ~/.emulationstation/downloaded_media/ps2/screenshots/ $params &

# Sega
rclone mount archive:chd_dc roms/segadc $params &
rclone mount "thumbnails:Sega - Dreamcast/Named_Snaps" ~/.emulationstation/downloaded_media/dreamcast/screenshots/ $params &

rclone mount "myrient:Redump/Sega - Saturn" roms/segasaturn $params &
rclone mount "thumbnails:Sega - Saturn/Named_Snaps" ~/.emulationstation/downloaded_media/saturn/screenshots/ $params &

rclone mount "myrient:No-Intro/Sega - Mega Drive - Genesis" roms/segamd $params &
rclone mount "thumbnails:Sega - Mega Drive - Genesis/Named_Snaps" ~/.emulationstation/downloaded_media/genesis/screenshots/ $params &

rclone mount "myrient:Redump/Sega - Mega CD & Sega CD" roms/segacd $params &
rclone mount "thumbnails:Sega - Mega-CD - Sega CD/Named_Snaps" ~/.emulationstation/downloaded_media/segacd/screenshots/ $params &

rclone mount "myrient:No-Intro/Sega - Master System - Mark III" roms/segams $params &
rclone mount "thumbnails:Sega - Master System - Mark III/Named_Snaps" ~/.emulationstation/downloaded_media/mastersystem/screenshots/ $params &

rclone mount "myrient:No-Intro/Sega - SG-1000" roms/sega1000 $params &
rclone mount "thumbnails:Sega - SG-1000/Named_Snaps" ~/.emulationstation/downloaded_media/sg-1000/screenshots/ $params &

rclone mount "myrient:No-Intro/Sega - 32X" roms/sega32x $params &
rclone mount "thumbnails:Sega - 32X/Named_Boxarts" ~/.emulationstation/downloaded_media/sega32x/screenshots/ $params &

rclone mount "myrient:No-Intro/Sega - Game Gear" roms/segagg $params &
rclone mount "thumbnails:Sega - Game Gear/Named_Snaps" ~/.emulationstation/downloaded_media/gamegear/screenshots/ $params &

# Nintendo
rclone mount archive:GamecubeCollectionByGhostware roms/gamecube $params &
rclone mount "thumbnails:Nintendo - GameCube/Named_Boxarts" ~/.emulationstation/downloaded_media/gc/screenshots/ $params &

rclone mount "myrient:No-Intro/Nintendo - Nintendo 64 (BigEndian)" roms/n64 $params &
rclone mount "thumbnails:Nintendo - Nintendo 64/Named_Snaps" ~/.emulationstation/downloaded_media/n64/screenshots/ $params &

rclone mount "myrient:No-Intro/Nintendo - Super Nintendo Entertainment System" roms/snes $params &
rclone mount "thumbnails:Nintendo - Super Nintendo Entertainment System/Named_Snaps" ~/.emulationstation/downloaded_media/snes/screenshots/ $params &

rclone mount "myrient:No-Intro/Nintendo - Nintendo Entertainment System (Headerless)" roms/nes $params &
rclone mount "thumbnails:Nintendo - Nintendo Entertainment System/Named_Snaps" ~/.emulationstation/downloaded_media/nes/screenshots/ $params &
