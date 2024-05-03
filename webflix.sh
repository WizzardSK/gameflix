#!/bin/bash
IFS=$'\n' read -d '' -ra roms <<< "$(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.txt)"
mkdir -p ~/myrient
mkdir -p ~/roms
mkdir -p ~/iso
mkdir -p ~/gameflix
mkdir -p ~/share/system/.cache/httpdirfs
mkdir -p ~/share/system/.cache/ratarmount

wget -O ~/.config/rclone/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/rclone.conf
httpdirfs --cache --no-range-check --cache-location ~/share/system/.cache/httpdirfs https://myrient.erista.me/files ~/myrient
IFS=";"
for each in "${roms[@]}"; do
  read -ra rom < <(printf '%s' "$each")
  if grep -q ":" <<< "${rom[1]}"; then
    mkdir -p ~/roms/${rom[0]}-other
    rclone mount ${rom[1]} ~/roms/${rom[0]}-other --http-no-head --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h --allow-non-empty --daemon --no-check-certificate 
  fi
  rom3=$(sed 's/<[^>]*>//g' <<< "${rom[3]}")
  if [[ ${rom[1]} =~ \.zip$ ]]; then
    mkdir -p ~/roms/${rom3}
    if [ -z "$(ls -A ~/roms/${rom3})" ]; then
      ~/ratarmount ~/myrient/${rom[1]} ~/roms/${rom3} --index-folders /share/system/.cache/ratarmount
    fi
  fi
done
