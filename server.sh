#!/bin/bash

API_URL="https://tic80.com/api?fn=dir&path=play/Games"; BASE_URL="https://tic80.com/cart"; DOWNLOAD_DIR="$HOME/roms/tic80"; RESPONSE=$(curl -s "$API_URL")
FILES=$(echo "$RESPONSE" | grep -oP '{\s*name\s*=\s*"[^"]+",\s*hash\s*=\s*"[^"]+",\s*id\s*=\s*\d+,\s*filename\s*=\s*"[^"]+"\s*}'); mkdir -p "$HOME/share/thumbs/TIC-80"
echo "$FILES" | while read -r LINE; do
  HASH=$(echo "$LINE" | sed -n 's/.*hash\s*=\s*"\([^"]*\)".*/\1/p'); FILENAME=$(echo "$LINE" | sed -n 's/.*filename\s*=\s*"\([^"]*\)".*/\1/p')
  FILE_PATH="${DOWNLOAD_DIR}/${HASH}.tic"; DOWNLOAD_URL="${BASE_URL}/${HASH}/cart.tic"
  SNAP_PATH="$HOME/share/thumbs/TIC-80/${HASH}.gif"; SNAPSHOT_URL="${BASE_URL}/${HASH}/cover.gif"
  if [ ! -f "$FILE_PATH" ]; then wget -nv -O "$FILE_PATH" "$DOWNLOAD_URL"; fi; if [ ! -f "$SNAP_PATH" ]; then wget -nv -O "$SNAP_PATH" "$SNAPSHOT_URL"; fi
done

BASE_URL="https://wasm4.org/play"; CRTS_URL="https://wasm4.org/carts"; ROM_DIR="$HOME/roms/wasm4"; IMG_DIR="$HOME/share/thumbs/WASM-4"
mkdir -p "$ROM_DIR" "$IMG_DIR"; curl -s "$BASE_URL" | grep -oP '(?<=href="/play/)[^"]+' | sort -u | while read -r GAME; do
  for EXT in wasm png; do FILE="${ROM_DIR}/$GAME.$EXT"; [[ "$EXT" == "png" ]] && FILE="${IMG_DIR}/$GAME.$EXT"; [[ -f "$FILE" ]] || wget -nv -O "$FILE" "$CARTS_URL/$GAME.$EXT"; done
done

if [ ! -f "$HOME/share/zip/uzebox.zip" ]; then wget -O /userdata/zip/uzebox.zip https://nicksen782.net/a_demos/downloads/games_20180105.zip; unzip -j "$HOME/share/zip/uzebox.zip" -d "$HOME/roms/uzebox"; fi

FILE_URL="https://raw.githubusercontent.com/WizzardSK/gameflix/refs/heads/main/lowresnx.txt"; DOWNLOAD_DIR="$HOME/roms/lowresnx"; mkdir -p "$HOME/share/thumbs/LowresNX"
curl "$FILE_URL" | while IFS=$'\t' read -r id title image nx_file; do
    if [ ! -s "$DOWNLOAD_DIR/$nx_file" ]; then download_url="https://lowresnx.inutilis.com/uploads/$nx_file"; wget -nv "$download_url" -O "$DOWNLOAD_DIR/$nx_file"; fi
    if [ ! -s "$HOME/share/thumbs/LowresNX/$image" ]; then download_url="https://lowresnx.inutilis.com/uploads/$image"; wget -nv "$download_url" -O "$HOME/share/thumbs/LowresNX/$image"; fi
done

#REMOTE_LIST_URL="https://raw.githubusercontent.com/WizzardSK/gameflix/refs/heads/main/pico8.txt"; OUTPUT_DIR="$HOME/roms/pico8"; 
#LIST=$(curl -s "$REMOTE_LIST_URL"); echo "$LIST" | while IFS=$'\t' read -r ID NAME FILENAME; do
#    if [[ -n "$FILENAME" ]]; then
#        if [[ $FILENAME =~ ^[0-9] ]]; then number="${BASH_REMATCH[1]}"; PREFIX=$(( number / 10000 )); else PREFIX="${FILENAME:0:2}"; fi
#        OUTPUT_PATH="${OUTPUT_DIR}/${FILENAME}"; FILE_URL="https://www.lexaloffle.com/bbs/cposts/${PREFIX}/${FILENAME}"; 
#        if [[ ! -s "$OUTPUT_PATH" ]]; then wget -nv -O "$OUTPUT_PATH" "$FILE_URL"; fi
#    fi
#done

#REMOTE_LIST_URL="https://raw.githubusercontent.com/WizzardSK/gameflix/refs/heads/main/voxatron.txt"; OUTPUT_DIR="$HOME/roms/voxatron"; 
#mkdir -p "$OUTPUT_DIR"
#LIST=$(curl -s "$REMOTE_LIST_URL"); echo "$LIST" | while IFS=$'\t' read -r ID NAME FILENAME; do
#    if [[ -n "$FILENAME" ]]; then
#        if [[ $FILENAME == cpost* ]]; then number=${FILENAME//[^0-9]/}; PREFIX=$(( number / 10000 )); else PREFIX="${FILENAME:0:2}"; fi
#        OUTPUT_PATH="${OUTPUT_DIR}/${FILENAME}"; FILE_URL="https://www.lexaloffle.com/bbs/cposts/${PREFIX}/${FILENAME}"; 
#        if [[ ! -s "$OUTPUT_PATH" ]]; then wget -nv -O "$OUTPUT_PATH" "$FILE_URL"; fi
#    fi
#done

if [ ! -f ~/share/zip/atari2600roms.zip ]; then wget -O ~/share/zip/atari2600roms.zip https://www.atarimania.com/roms/Atari-2600-VCS-ROM-Collection.zip; fi
fuse-zip ~/share/zip/atari2600roms.zip ~/share/zip/atari2600roms -o allow_other; bindfs ~/share/zip/atari2600roms/ROMS ~/roms/Atari\ 2600\ ROMS

declare -A seen
mkdir -p "$HOME/share/thumbs"
IFS=$'\n' read -d '' -ra roms <<< "$(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.txt)"
IFS=";"; for each in "${roms[@]}"; do
  echo "${rom3}"; read -ra rom < <(printf '%s' "$each")

  if [[ -z "${seen[${rom[0]}]}" ]]; then
    seen[${rom[0]}]=1; rom2="${rom[2]// /_}"; echo "${rom[2]} thumbs" | tee -a "$HOME/git.log"
    if [ ! -d "$HOME/share/thumbs/${rom[2]}" ]; then git clone --depth 1 "https://github.com/WizzardSK/${rom2}.git" "$HOME/share/thumbs/${rom[2]}" 2>&1 | tee -a "$HOME/git.log"; else
      git config --global --add safe.directory $HOME/share/thumbs/${rom[2]}
      git -C "$HOME/share/thumbs/${rom[2]}" config pull.rebase false 2>&1 | tee -a "$HOME/git.log"
      git -C "$HOME/share/thumbs/${rom[2]}" pull 2>&1 | tee -a "$HOME/git.log"
      sleep 0.5
    fi
  fi  
  
  rom3=$(sed 's/<[^>]*>//g' <<< "${rom[3]}")
  if [[ ${rom[1]} =~ \.zip$ ]]; then
    mkdir -p ~/roms/${rom3}
    if [ -z "$(ls -A ~/roms/${rom3})" ]; then
      if [ ! -f ~/share/zip/${rom3}.zip ]; then wget -O ~/share/zip/${rom3}.zip https://myrient.erista.me/files/${rom[1]}; fi; fuse-zip ~/share/zip/${rom3}.zip ~/roms/${rom3} -o allow_other
    fi
  fi
done

wait

