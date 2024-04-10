#!/bin/bash
source <(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.txt)

mkdir -p ~/myrient
mkdir -p ~/roms
mkdir -p ~/iso
mkdir -p ~/zip
mkdir -p ~/romz
mkdir -p ~/gameflix

wget -O ~/.config/rclone/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/rclone.conf
httpdirfs --cache --no-range-check https://myrient.erista.me/files ~/myrient
#rclone mount myrient: ~/myrient --http-no-head --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h --allow-non-empty --daemon --no-check-certificate 

IFS=";"
for each in "${roms[@]}"; do
  read -ra rom < <(printf '%s' "$each")
  if grep -q ":" <<< "${rom[1]}"; then
    mkdir -p ~/roms/${rom[0]}-other
    rclone mount ${rom[1]} ~/roms/${rom[0]}-other --http-no-head --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h --allow-non-empty --daemon --no-check-certificate 
  fi
done

for each in "${zips[@]}"; do
  read -ra zip < <(printf '%s' "$each")
  mkdir -p ~/roms/${zip[0]}
  if [ ! -f ~/zip/${zip[0]}.zip ]; then 
    if [[ "${zip[1]}" == *://* ]]; then
      wget -O ~/zip/${zip[0]}.zip ${zip[1]};
    else
      wget -O ~/zip/${zip[0]}.zip https://myrient.erista.me/files/${zip[1]};
    fi
  fi  
  mount-zip ~/zip/${zip[0]}.zip ~/roms/${zip[O]} -o nonempty -omodules=iconv,from_code=$charset1,to_code=$charset2
done
