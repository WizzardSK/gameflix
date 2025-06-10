#!/bin/bash

export LD_LIBRARY_PATH=/usr/local/lib
mkdir -p ~/myrient ~/roms ~/dos ~/iso ~/zips ~/gameflix ~/share/system/.cache/ratarmount ~/share/system/.cache/rclone ~/share/zip/atari2600roms ~/roms/Atari\ 2600\ ROMS ~/roms/TIC-80 ~/roms/Uzebox ~/roms/WASM-4

wget -nv -O ~/.config/rclone/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/rclone.conf
rclone mount myrient: ~/myrient --http-no-head --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h --allow-non-empty --daemon --no-check-certificate --allow-other

IFS=$'\n' read -d '' -ra roms <<< "$(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.txt)"
IFS=";"; for each in "${roms[@]}"; do
  echo "${rom3}"; read -ra rom < <(printf '%s' "$each")
  if grep -q ":" <<< "${rom[1]}"; then
    mkdir -p ~/${rom[0]}
    rclone mount ${rom[1]} ~/${rom[0]} --http-no-head --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h --allow-non-empty --daemon --no-check-certificate --allow-other
  fi
  rom3=$(sed 's/<[^>]*>//g' <<< "${rom[3]}")
  if [[ ${rom[1]} =~ \.zip$ ]]; then
    rom[1]="${rom[1]//&/%26}"    
    rom[1]="${rom[1]// /%20}"
    rom[1]="${rom[1]//[/%5B}"
    rom[1]="${rom[1]//]/%5D}"
    rom[1]="${rom[1]//\'/%27}"
    archives+=" https://myrient.erista.me/files/${rom[1]}"
#    mkdir -p ~/roms/${rom3}
#    if [ -z "$(ls -A ~/roms/${rom3})" ]; then
#      ratarmount https://myrient.erista.me/files/${rom[1]} ~/roms/${rom3} -f &
#    fi
  fi
done

ratarmount --disable-union-mount "$archives" ~/zips -f &

wait
