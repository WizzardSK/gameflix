#!/bin/bash
declare -a roms=()
params="--config=/userdata/system/.config/rclone/rclone.conf --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --vfs-cache-mode full --allow-non-empty --daemon"
if [ ! -f /userdata/system/.config/rclone/rclone.conf ]; then wget -O /userdata/system/.config/rclone/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/.config/rclone/rclone.conf; fi
curl -s -L https://rclone.org/install.sh | bash

roms+=("vectrex,myrient:No-Intro/GCE - Vectrex")
roms+=("intellivision,myrient:No-Intro/Mattel - Intellivision")
roms+=("colecovision,myrient:No-Intro/Coleco - ColecoVision")
roms+=("c64,myrient:No-Intro/Commodore - Commodore 64")

roms+=("atari2600,myrient:No-Intro/Atari - 2600")
roms+=("atari5200,myrient:No-Intro/Atari - 5200")
roms+=("atari7800,myrient:No-Intro/Atari - 7800")
roms+=("jaguar,myrient:No-Intro/Atari - Jaguar (J64)")
roms+=("lynx,myrient:No-Intro/Atari - Lynx")
roms+=("atarist,myrient:No-Intro/Atari - ST")

roms+=("nes,myrient:No-Intro/Nintendo - Nintendo Entertainment System (Headerless)")
roms+=("snes,myrient:No-Intro/Nintendo - Super Nintendo Entertainment System")
roms+=("n64,myrient:No-Intro/Nintendo - Nintendo 64 (ByteSwapped)")
roms+=("gamecube,archive:rvz-gc-usa-redump")

roms+=("psx,archive:chd_psx")
roms+=("psp,archive:psp_20220507")
roms+=("ps2,archive:ps2chd")

IFS=","
for each in "${roms[@]}"
do
  read -ra rom < <(printf '%s' "$each")
  mkdir -p /userdata/roms/${rom[0]}/online
  rclone mount ${rom[1]} /userdata/roms/${rom[0]}/online --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --vfs-cache-mode full --allow-non-empty --daemon
done

curl http://127.0.0.1:1234/reloadgames
