#!/bin/bash
export LD_LIBRARY_PATH=/usr/local/lib
mkdir -p ~/myrient ~/roms ~/dos ~/iso ~/zips ~/gameflix ~/share/system/.cache/ratarmount ~/share/system/.cache/rclone ~/share/zip/atari2600roms ~/roms/Atari\ 2600\ ROMS ~/roms/TIC-80 ~/roms/LowresNX ~/roms/Uzebox ~/roms/WASM-4
wget -nv -O ~/.config/rclone/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/rclone.conf
if ! mountpoint -q "$HOME/myrient"; then rclone mount myrient: ~/myrient --http-no-head --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h --allow-non-empty --daemon --no-check-certificate --allow-other; fi

archives=( "https://www.atarimania.com/roms/Atari-2600-VCS-ROM-Collection.zip" )
archives=( "https://nicksen782.net/a_demos/downloads/games_20180105.zip" )
archives=( "https://github.com/WizzardSK/gameflix/raw/refs/heads/main/fantasy/lowresnx.zip" )
archives=( "https://github.com/WizzardSK/gameflix/raw/refs/heads/main/fantasy/tic80.zip" )
archives=( "https://github.com/WizzardSK/gameflix/raw/refs/heads/main/fantasy/wasm4.zip" )

IFS=$'\n' read -d '' -ra roms <<< "$(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.txt)"
IFS=";"; for each in "${roms[@]}"; do
  read -ra rom < <(printf '%s' "$each")
  if grep -q ":" <<< "${rom[1]}"; then
    mkdir -p ~/${rom[0]}
    rclone mount ${rom[1]} ~/${rom[0]} --http-no-head --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h --allow-non-empty --daemon --no-check-certificate --allow-other
  fi
  if [[ ${rom[1]} =~ \.zip$ ]]; then
    rom1="${rom[1]//&/%26}"; rom1="${rom1// /%20}"; rom1="${rom1//[/%5B}"; rom1="${rom1//]/%5D}"; rom1="${rom1//\'/%27}"
    archives+=( "https://myrient.erista.me/files/${rom1}" )
  fi
done

if ! mountpoint -q "$HOME/zips"; then nohup ratarmount --disable-union-mount "${archives[@]}" ~/zips -f & fi; wait
bindfs --perms=0755 --force-user=$(whoami) --force-group=$(id -gn) $HOME/zips/Atari-2600-VCS-ROM-Collection.zip/ROMS "$HOME/roms/Atari 2600 ROMS"
bindfs --perms=0755 --force-user=$(whoami) --force-group=$(id -gn) $HOME/zips/games_20180105.zip "$HOME/roms/Uzebox"
bindfs --perms=0755 --force-user=$(whoami) --force-group=$(id -gn) $HOME/zips/lowresnx.zip "$HOME/roms/LowresNX"
bindfs --perms=0755 --force-user=$(whoami) --force-group=$(id -gn) $HOME/zips/tic80.zip "$HOME/roms/TIC-80"
bindfs --perms=0755 --force-user=$(whoami) --force-group=$(id -gn) $HOME/zips/wasm4.zip "$HOME/roms/WASM-4"

for each in "${roms[@]}"; do
  read -ra rom < <(printf '%s' "$each")
  rom3=$(sed 's/<[^>]*>//g' <<< "${rom[3]}")
  if [[ ${rom[1]} =~ \.zip$ ]]; then
    rom1="${rom[1]//&/%26}"; rom1="${rom1// /%20}"; rom1="${rom1//[/%5B}"; rom1="${rom1//]/%5D}"; rom1="${rom1//\'/%27}"
    mkdir -p $HOME/roms/${rom3}
    bindfs --perms=0755 --force-user=$(whoami) --force-group=$(id -gn) $HOME/zips/${rom1##*/} $HOME/roms/${rom3}
  fi
done
