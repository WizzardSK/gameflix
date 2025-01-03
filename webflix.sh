#!/bin/bash
export LD_LIBRARY_PATH=/usr/local/lib
IFS=$'\n' read -d '' -ra roms <<< "$(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.txt)"
mkdir -p ~/myrient
mkdir -p ~/roms
mkdir -p ~/iso
mkdir -p ~/gameflix
mkdir -p ~/share/system/.cache/ratarmount
mkdir -p ~/share/system/.cache/rclone

if [ ! -f ~/ratarmount ]; then wget -O ~/ratarmount https://github.com/mxmlnkn/ratarmount/releases/download/v0.15.0/ratarmount-0.15.0-x86_64.AppImage; chmod +x ~/ratarmount; fi
wget -O ~/.config/rclone/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/rclone.conf
rclone mount myrient: ~/myrient --http-no-head --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h --allow-non-empty --daemon --no-check-certificate

IFS=";"
for each in "${roms[@]}"; do
  echo "${rom3}"
  read -ra rom < <(printf '%s' "$each")
  if grep -q ":" <<< "${rom[1]}"; then
    mkdir -p ~/roms/${rom[0]}-other
    rclone mount ${rom[1]} ~/roms/${rom[0]}-other --http-no-head --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h --allow-non-empty --daemon --no-check-certificate 
  fi
  rom3=$(sed 's/<[^>]*>//g' <<< "${rom[3]}")
  if [[ ${rom[1]} =~ \.zip$ ]]; then
    mkdir -p ~/roms/${rom3}
    if [ -z "$(ls -A ~/roms/${rom3})" ]; then
      head ~/myrient/${rom[1]} > /dev/null
      ~/ratarmount ~/myrient/${rom[1]} ~/roms/${rom3} --index-folders ~/share/system/.cache/ratarmount > /dev/null &
    fi
  fi
done
wait
