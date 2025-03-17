#!/bin/bash
export LD_LIBRARY_PATH=/usr/local/lib
IFS=$'\n' read -d '' -ra roms <<< "$(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.txt)"
mkdir -p ~/myrient ~/roms ~/iso ~/gameflix ~/share/system/.cache/ratarmount ~/share/system/.cache/rclone ~/share/zip/atari2600roms ~/roms/Atari\ 2600\ ROMS ~/roms/TIC-80 ~/roms/Uzebox

if [ ! -f ~/share/zip/atari2600roms.zip ]; then wget -O ~/share/zip/atari2600roms.zip https://www.atarimania.com/roms/Atari-2600-VCS-ROM-Collection.zip; fi
fuse-zip ~/share/zip/atari2600roms.zip ~/share/zip/atari2600roms; bindfs ~/share/zip/atari2600roms/ROMS ~/roms/Atari\ 2600\ ROMS
wget -O ~/.config/rclone/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/rclone.conf
rclone mount myrient: ~/myrient --http-no-head --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h --allow-non-empty --daemon --no-check-certificate

API_URL="https://tic80.com/api?fn=dir&path=play/Games"; BASE_URL="https://tic80.com/cart"; DOWNLOAD_DIR="$HOME/roms/TIC-80"; RESPONSE=$(curl -s "$API_URL")
FILES=$(echo "$RESPONSE" | grep -oP '{\s*name\s*=\s*"[^"]+",\s*hash\s*=\s*"[^"]+",\s*id\s*=\s*\d+,\s*filename\s*=\s*"[^"]+"\s*}')
echo "$FILES" | while read -r LINE; do
  HASH=$(echo "$LINE" | sed -n 's/.*hash\s*=\s*"\([^"]*\)".*/\1/p'); FILENAME=$(echo "$LINE" | sed -n 's/.*filename\s*=\s*"\([^"]*\)".*/\1/p')
  FILE_PATH="${DOWNLOAD_DIR}/${HASH} ${FILENAME}"; DOWNLOAD_URL="${BASE_URL}/${HASH}/cart.tic"; if [ ! -f "$FILE_PATH" ]; then wget -O "$FILE_PATH" "$DOWNLOAD_URL"; fi
done

if [ ! -f ~/share/zip/uzebox.zip ]; then wget -O ~/share/zip/uzebox.zip https://nicksen782.net/a_demos/downloads/games_20180105.zip; fi
unzip -j ~/share/zip/uzebox.zip -d ~/roms/Uzebox

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
      if [ ! -f ~/share/zip/${rom3}.zip ]; then wget -O ~/share/zip/${rom3}.zip https://myrient.erista.me/files/${rom[1]}; fi
      fuse-zip ~/share/zip/${rom3}.zip ~/roms/${rom3}
    fi
  fi
done; wait
