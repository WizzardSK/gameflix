#!/bin/bash
#curl -L https://rclone.org/install.sh | bash
params="--config=/userdata/system/.config/rclone/rclone.conf --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --vfs-cache-mode full --allow-non-empty --daemon"
#if [ ! -f /userdata/system/.config/rclone/rclone.conf ]; then wget -O /userdata/system/.config/rclone/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/.config/rclone/rclone.conf; fi
for dir in /userdata/roms/*/; do mkdir -p "$dir/online"; done

rclone mount "myrient:No-Intro/GCE - Vectrex"             /userdata/roms/vectrex/online $params
rclone mount "myrient:No-Intro/Mattel - Intellivision"    /userdata/roms/intellivision/online $params
rclone mount "myrient:No-Intro/Mattel - Intellivision"    /userdata/roms/intellivision/online $params
rclone mount "myrient:No-Intro/Coleco - ColecoVision"     /userdata/roms/colecovision/online $params
rclone mount "myrient:No-Intro/Commodore - Commodore 64"  /userdata/roms/c64/online $params

rclone mount "myrient:No-Intro/Atari - 2600"          /userdata/roms/atari2600/online $params
rclone mount "myrient:No-Intro/Atari - 5200"          /userdata/roms/atari5200/online $params
rclone mount "myrient:No-Intro/Atari - 7800"          /userdata/roms/atari7800/online $params
rclone mount "myrient:No-Intro/Atari - Jaguar (J64)"  /userdata/roms/jaguar/online $params
rclone mount "myrient:No-Intro/Atart - Lynx"          /userdata/roms/lynx/online $params
rclone mount "myrient:No-Intro/Atari - ST"            /userdata/roms/atarist/online $params

rclone mount "myrient:No-Intro/Nintendo - Nintendo Entertainment System (Headerless)" /userdata/roms/nes/online $params
rclone mount "myrient:No-Intro/Nintendo - Super Nintendo Entertainment System"        /userdata/roms/snes/online $params
rclone mount "myrient:No-Intro/Nintendo - Nintendo 64 (ByteSwapped)"                  /userdata/roms/n64/online $params
rclone mount "archive:rvz-gc-usa-redump"                                              /userdata/roms/gamecube/online $params

rclone mount "myrient:No-Intro/Sega - SG-1000"                  /userdata/roms/sg1000/online $params
rclone mount "myrient:No-Intro/Sega - Master System - Mark III" /userdata/roms/mastersystem/online $params
rclone mount "myrient:No-Intro/Sega - Game Gear"                /userdata/roms/gamegear/online $params
rclone mount "myrient:No-Intro/Sega - Mega Drive - Genesis"     /userdata/roms/megadrive/online $params
rclone mount "myrient:No-Intro/Sega - 32X"                      /userdata/roms/sega32x/online $params
rclone mount "myrient:Redump/Sega - Mega CD & Sega CD"          /userdata/roms/segacd/online $params
rclone mount "archive:SaturnRedumpCHDs"                         /userdata/roms/saturn/online $params
rclone mount "archive:chd_dc"                                   /userdata/roms/dreamcast/online $params

rclone mount "archive:chd_psx"      /userdata/roms/psx/online $params
rclone mount "archive:psp_20220507" /userdata/roms/psp/online $params
rclone mount "archive:ps2chd"       /userdata/roms/ps2/online $params

curl http://127.0.0.1:1234/reloadgames
