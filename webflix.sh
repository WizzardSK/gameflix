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
    if [ ! -f ~/zip/${rom3}.zip ]; then 
      if [[ "${rom[1]}" == *://* ]]; then
        wget -O ~/zip/${rom3}.zip ${rom[1]};
      else
        wget -O ~/zip/${rom3}.zip https://myrient.erista.me/files/${rom[1]};
      fi
    fi  
    mount-zip ~/zip/${rom3}.zip ~/roms/${rom3} -o nonempty -omodules=iconv,from_code=$charset1,to_code=$charset2
  fi
done

#for each in "${zips[@]}"; do
#  read -ra zip < <(printf '%s' "$each")
#  rom3=$(sed 's/<[^>]*>//g' <<< "${zip[3]}")
#  mkdir -p ~/roms/${rom3}
#  if [ ! -f ~/zip/${rom3}.zip ]; then 
#    if [[ "${zip[1]}" == *://* ]]; then
#      wget -O ~/zip/${rom3}.zip ${zip[1]};
#    else
#      wget -O ~/zip/${rom3}.zip https://myrient.erista.me/files/${zip[1]};
#    fi
#  fi  
#  mount-zip ~/zip/${rom3}.zip ~/roms/${rom3} -o nonempty -omodules=iconv,from_code=$charset1,to_code=$charset2
#done
