#!/bin/bash
IFS=$'\n' read -d '' -ra roms <<< "$(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.txt)"
mkdir -p ~/myrient
mkdir -p ~/roms
mkdir -p ~/iso
mkdir -p ~/zip
mkdir -p ~/romz
mkdir -p ~/gameflix
wget -O ~/.config/rclone/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/rclone.conf
httpdirfs --cache --no-range-check --cache-location ~/share/cache https://myrient.erista.me/files ~/myrient
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
    #if [ ! -f ~/zip/${rom3}.zip ]; then 
    #  if [[ "${rom[1]}" == *://* ]]; then
    #    wget -O ~/zip/${rom3}.zip ${rom[1]};
    #  else
    #    wget -O ~/zip/${rom3}.zip https://myrient.erista.me/files/${rom[1]};
    #  fi
    #fi  
    #mount-zip ~/zip/${rom3}.zip ~/roms/${rom3} -o nonempty -omodules=iconv,from_code=$charset1,to_code=$charset2
    ~/ratarmount ~/myrient/${rom[1]} ~/roms/${rom3}
  fi
done
