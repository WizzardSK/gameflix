#!/bin/bash

export LD_LIBRARY_PATH=/usr/local/lib
mkdir -p ~/myrient ~/roms ~/roms/dos-other ~/iso ~/gameflix ~/share/system/.cache/ratarmount ~/share/system/.cache/rclone ~/share/zip/atari2600roms ~/roms/Atari\ 2600\ ROMS ~/roms/TIC-80 ~/roms/Uzebox ~/roms/WASM-4

wget -nv -O ~/.config/rclone/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/rclone.conf
rclone mount myrient: ~/myrient --http-no-head --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h --allow-non-empty --daemon --no-check-certificate --allow-other

IFS=$'\n' read -d '' -ra roms <<< "$(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.txt)"
IFS=";"; for each in "${roms[@]}"; do
  echo "${rom3}"; read -ra rom < <(printf '%s' "$each")
  if grep -q ":" <<< "${rom[1]}"; then
    mkdir -p ~/roms/${rom[0]}-other
    rclone mount ${rom[1]} ~/roms/${rom[0]}-other --http-no-head --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h --allow-non-empty --daemon --no-check-certificate --allow-other
  fi
done

wait
