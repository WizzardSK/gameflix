#!/bin/bash
params="--no-checksum --no-modtime --read-only --attr-timeout 10h --dir-cache-time 10h --poll-interval 10h --vfs-cache-mode full --allow-non-empty --daemon"
mkdir -p ~/roms

# DOS
#mkdir -p ~/roms/dos
#rclone mount "myrient:Redump/IBM - PC compatible" roms/dos $params
#mkdir -p ~/.emulationstation/downloaded_media/dos/screenshots
#rclone mount "thumbnails:DOS/Named_Boxarts" ~/.emulationstation/downloaded_media/dos/screenshots/ $params

# Arcade
mkdir -p ~/roms/fbneo
rclone mount archive:cylums-final-burn-neo-rom-collection roms/fbneo $params
mkdir -p ~/.emulationstation/downloaded_media/fbneo/screenshots
rclone mount "thumbnails:FBNeo - Arcade Games/Named_Snaps" ~/.emulationstation/downloaded_media/fbneo/screenshots/ $params

# Amstrad
mkdir -p ~/roms/amstradcpc
rclone mount archive:AmstradCPCGameCollectionByGhostware ~/roms/amstradcpc $params
mkdir -p ~/.emulationstation/downloaded_media/amstradcpc/screenshots
rclone mount "thumbnails:Amstrad - CPC/Named_Snaps" ~/.emulationstation/downloaded_media/amstradcpc/screenshots/ $params

# Atari - Amiga
mkdir -p ~/roms/atari2600
rclone mount "myrient:No-Intro/Atari - 2600" ~/roms/atari2600 $params
mkdir -p ~/.emulationstation/downloaded_media/atari2600/screenshots
rclone mount "thumbnails:Atari - 2600/Named_Snaps" ~/.emulationstation/downloaded_media/atari2600/screenshots/ $params

mkdir -p ~/roms/atari5200
rclone mount "myrient:No-Intro/Atari - 5200" ~/roms/atari5200 $params
mkdir -p ~/.emulationstation/downloaded_media/atari5200/screenshots
rclone mount "thumbnails:Atari - 5200/Named_Snaps" ~/.emulationstation/downloaded_media/atari5200/screenshots/ $params

mkdir -p ~/roms/atari7800
rclone mount "myrient:No-Intro/Atari - 7800" ~/roms/atari7800 $params
mkdir -p ~/.emulationstation/downloaded_media/atari7800/screenshots
rclone mount "thumbnails:Atari - 7800/Named_Snaps" ~/.emulationstation/downloaded_media/atari7800/screenshots/ $params

mkdir -p ~/roms/atarijaguar
rclone mount "myrient:No-Intro/Atari - Jaguar (J64)" ~/roms/atarijaguar $params
mkdir -p ~/.emulationstation/downloaded_media/atarijaguar/screenshots
rclone mount "thumbnails:Atari - Jaguar/Named_Snaps" ~/.emulationstation/downloaded_media/atarijaguar/screenshots/ $params

mkdir -p ~/roms/atarilynx
rclone mount "myrient:No-Intro/Atari - Lynx" ~/roms/atarilynx $params
mkdir -p ~/.emulationstation/downloaded_media/atarilynx/screenshots
rclone mount "thumbnails:Atari - Lynx/Named_Snaps" ~/.emulationstation/downloaded_media/atarilynx/screenshots/ $params

mkdir -p ~/roms/atarist
rclone mount "myrient:No-Intro/Atari - ST" ~/roms/atarist $params
mkdir -p ~/.emulationstation/downloaded_media/atarist/screenshots
rclone mount "thumbnails:Atari - ST/Named_Snaps" ~/.emulationstation/downloaded_media/atarist/screenshots/ $params

mkdir -p ~/roms/amiga
rclone mount archive:Amiga_WHD_Games ~/roms/amiga $params
mkdir -p ~/.emulationstation/downloaded_media/amiga/screenshots
rclone mount "thumbnails:Commodore - Amiga/Named_Snaps" ~/.emulationstation/downloaded_media/amiga/screenshots/ $params

mkdir -p ~/roms/c64
rclone mount "myrient:No-Intro/Commodore - Commodore 64" ~/roms/c64 $params
mkdir -p ~/.emulationstation/downloaded_media/c64/screenshots
rclone mount "thumbnails:Commodore - 64/Named_Snaps" ~/.emulationstation/downloaded_media/c64/screenshots/ $params

# PS
mkdir -p ~/roms/psx
rclone mount archive:chd_psx ~/roms/psx $params
mkdir -p ~/.emulationstation/downloaded_media/psx/screenshots
rclone mount "thumbnails:Sony - PlayStation/Named_Snaps" ~/.emulationstation/downloaded_media/psx/screenshots/ $params

mkdir -p ~/roms/psp
rclone mount archive:def-jam-vendetta-u ~/roms/psp $params
mkdir -p ~/.emulationstation/downloaded_media/psp/screenshots
rclone mount "thumbnails:Sony - PlayStation Portable/Named_Boxarts" ~/.emulationstation/downloaded_media/psp/screenshots/ $params

mkdir -p ~/roms/ps2
rclone mount archive:ps2chd ~/roms/ps2 $params
mkdir -p ~/.emulationstation/downloaded_media/ps2/screenshots
rclone mount "thumbnails:Sony - PlayStation 2/Named_Boxarts" ~/.emulationstation/downloaded_media/ps2/screenshots/ $params

# Sega
mkdir -p ~/roms/dreamcast
rclone mount archive:chd_dc ~/roms/dreamcast $params
mkdir -p ~/.emulationstation/downloaded_media/dreamcast/screenshots
rclone mount "thumbnails:Sega - Dreamcast/Named_Snaps" ~/.emulationstation/downloaded_media/dreamcast/screenshots/ $params

mkdir -p ~/roms/saturn
rclone mount archive:SaturnRedumpCHDs ~/roms/saturn $params
mkdir -p ~/.emulationstation/downloaded_media/saturn/screenshots
rclone mount "thumbnails:Sega - Saturn/Named_Snaps" ~/.emulationstation/downloaded_media/saturn/screenshots/ $params

mkdir -p ~/roms/genesis
rclone mount "myrient:No-Intro/Sega - Mega Drive - Genesis" ~/roms/genesis $params
mkdir -p ~/.emulationstation/downloaded_media/genesis/screenshots
rclone mount "thumbnails:Sega - Mega Drive - Genesis/Named_Snaps" ~/.emulationstation/downloaded_media/genesis/screenshots/ $params

mkdir -p ~/roms/segacd
rclone mount "myrient:Redump/Sega - Mega CD & Sega CD" ~/roms/segacd $params
mkdir -p ~/.emulationstation/downloaded_media/segacd/screenshots
rclone mount "thumbnails:Sega - Mega-CD - Sega CD/Named_Snaps" ~/.emulationstation/downloaded_media/segacd/screenshots/ $params

mkdir -p ~/roms/mastersystem
rclone mount "myrient:No-Intro/Sega - Master System - Mark III" ~/roms/mastersystem $params
mkdir -p ~/.emulationstation/downloaded_media/mastersystem/screenshots
rclone mount "thumbnails:Sega - Master System - Mark III/Named_Snaps" ~/.emulationstation/downloaded_media/mastersystem/screenshots/ $params

mkdir -p ~/roms/sg-1000
rclone mount "myrient:No-Intro/Sega - SG-1000" ~/roms/sg-1000 $params
mkdir -p ~/.emulationstation/downloaded_media/sg-1000/screenshots
rclone mount "thumbnails:Sega - SG-1000/Named_Snaps" ~/.emulationstation/downloaded_media/sg-1000/screenshots/ $params

mkdir -p ~/roms/sega32x
rclone mount "myrient:No-Intro/Sega - 32X" ~/roms/sega32x $params
mkdir -p ~/.emulationstation/downloaded_media/sega32x/screenshots
rclone mount "thumbnails:Sega - 32X/Named_Boxarts" ~/.emulationstation/downloaded_media/sega32x/screenshots/ $params

mkdir -p ~/roms/gamegear
rclone mount "myrient:No-Intro/Sega - Game Gear" ~/roms/gamegear $params
mkdir -p ~/.emulationstation/downloaded_media/gamegear/screenshots
rclone mount "thumbnails:Sega - Game Gear/Named_Snaps" ~/.emulationstation/downloaded_media/gamegear/screenshots/ $params

# Nintendo
mkdir -p ~/roms/gc
rclone mount archive:GamecubeCollectionByGhostware ~/roms/gc $params
mkdir -p ~/.emulationstation/downloaded_media/gc/screenshots
rclone mount "thumbnails:Nintendo - GameCube/Named_Boxarts" ~/.emulationstation/downloaded_media/gc/screenshots/ $params

mkdir -p ~/roms/n64
rclone mount "myrient:No-Intro/Nintendo - Nintendo 64 (ByteSwapped)" ~/roms/n64 $params
mkdir -p ~/.emulationstation/downloaded_media/n64/screenshots
rclone mount "thumbnails:Nintendo - Nintendo 64/Named_Snaps" ~/.emulationstation/downloaded_media/n64/screenshots/ $params

mkdir -p ~/roms/snes
rclone mount "myrient:No-Intro/Nintendo - Super Nintendo Entertainment System" ~/roms/snes $params
mkdir -p ~/.emulationstation/downloaded_media/snes/screenshots
rclone mount "thumbnails:Nintendo - Super Nintendo Entertainment System/Named_Snaps" ~/.emulationstation/downloaded_media/snes/screenshots/ $params

mkdir -p ~/roms/nes
rclone mount "myrient:No-Intro/Nintendo - Nintendo Entertainment System (Headerless)" ~/roms/nes $params
mkdir -p ~/.emulationstation/downloaded_media/nes/screenshots
rclone mount "thumbnails:Nintendo - Nintendo Entertainment System/Named_Snaps" ~/.emulationstation/downloaded_media/nes/screenshots/ $params

emulationstation &
