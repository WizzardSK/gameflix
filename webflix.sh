#!/bin/bash
export LD_LIBRARY_PATH=/usr/local/lib
IFS=$'\n' read -d '' -ra roms <<< "$(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.txt)"
mkdir -p ~/myrient ~/roms ~/iso ~/gameflix ~/share/system/.cache/ratarmount ~/share/system/.cache/rclone ~/share/zip/atari2600roms ~/roms/Atari\ 2600\ ROMS ~/roms/TIC-80 ~/roms/Uzebox ~/roms/WASM-4

if [ ! -f ~/share/zip/atari2600roms.zip ]; then wget -O ~/share/zip/atari2600roms.zip https://www.atarimania.com/roms/Atari-2600-VCS-ROM-Collection.zip; fi
fuse-zip ~/share/zip/atari2600roms.zip ~/share/zip/atari2600roms; bindfs ~/share/zip/atari2600roms/ROMS ~/roms/Atari\ 2600\ ROMS
wget -O ~/.config/rclone/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/rclone.conf
rclone mount myrient: ~/myrient --http-no-head --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h --allow-non-empty --daemon --no-check-certificate

API_URL="https://tic80.com/api?fn=dir&path=play/Games"; BASE_URL="https://tic80.com/cart"; DOWNLOAD_DIR="$HOME/roms/TIC-80"; RESPONSE=$(curl -s "$API_URL")
FILES=$(echo "$RESPONSE" | grep -oP '{\s*name\s*=\s*"[^"]+",\s*hash\s*=\s*"[^"]+",\s*id\s*=\s*\d+,\s*filename\s*=\s*"[^"]+"\s*}')
echo "$FILES" | while read -r LINE; do
  HASH=$(echo "$LINE" | sed -n 's/.*hash\s*=\s*"\([^"]*\)".*/\1/p'); FILENAME=$(echo "$LINE" | sed -n 's/.* name\s*=\s*"\([^"]*\)".*/\1/p')
  FILE_PATH="${DOWNLOAD_DIR}/${HASH}.tic"; DOWNLOAD_URL="${BASE_URL}/${HASH}/cart.tic"; if [ ! -f "$FILE_PATH" ]; then wget -O "$FILE_PATH" "$DOWNLOAD_URL"; fi
done

BASE_URL="https://wasm4.org/play"; CARTS_URL="https://wasm4.org/carts"; ROM_DIR="$HOME/roms/WASM-4"
curl -s "$BASE_URL" | grep -oP '(?<=href="/play/)[^"]+' | sort -u | while read -r GAME; do
  FILE="${ROM_DIR}/$GAME.wasm"
  [[ -f "$FILE" ]] || wget -O "$FILE" "$CARTS_URL/$GAME.wasm"
done

if [ ! -f ~/share/zip/uzebox.zip ]; then wget -O ~/share/zip/uzebox.zip https://nicksen782.net/a_demos/downloads/games_20180105.zip; unzip -j ~/share/zip/uzebox.zip -d ~/roms/Uzebox; fi

FILE_URL="https://raw.githubusercontent.com/WizzardSK/gameflix/refs/heads/main/lowresnx.txt"; DOWNLOAD_DIR="$HOME/roms/LowresNX"; mkdir -p "$DOWNLOAD_DIR"
curl "$FILE_URL" | while IFS="|"; read -r id title image nx_file; do
    if [ ! -s "$DOWNLOAD_DIR/$nx_file" ]; then download_url="https://lowresnx.inutilis.com/uploads/$nx_file"; wget "$download_url" -O "$DOWNLOAD_DIR/$nx_file"; fi
done

REMOTE_LIST_URL="https://raw.githubusercontent.com/WizzardSK/gameflix/refs/heads/main/pico8.txt"; OUTPUT_DIR="$HOME/roms/PICO-8"; mkdir -p "$OUTPUT_DIR"
LIST=$(curl -s "$REMOTE_LIST_URL"); echo "$LIST" | while IFS=$'\t' read -r ID NAME FILENAME; do
    if [[ -n "$FILENAME" ]]; then
        if [[ $FILENAME =~ ^[0-9] ]]; then PREFIX="${FILENAME:0:1}"; else PREFIX="${FILENAME:0:2}"; fi
        OUTPUT_PATH="${OUTPUT_DIR}/${FILENAME}"; FILE_URL="https://www.lexaloffle.com/bbs/cposts/${PREFIX}/${FILENAME}"
        if [[ ! -s "$OUTPUT_PATH" ]]; then wget -nv -O "$OUTPUT_PATH" "$FILE_URL"; fi
    fi
done

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
