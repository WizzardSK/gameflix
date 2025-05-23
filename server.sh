if [ ! -f ~/share/zip/atari2600roms.zip ]; then wget -O ~/share/zip/atari2600roms.zip https://www.atarimania.com/roms/Atari-2600-VCS-ROM-Collection.zip; fi
fuse-zip ~/share/zip/atari2600roms.zip ~/share/zip/atari2600roms -o allow_other; bindfs ~/share/zip/atari2600roms/ROMS ~/roms/Atari\ 2600\ ROMS

API_URL="https://tic80.com/api?fn=dir&path=play/Games"; BASE_URL="https://tic80.com/cart"; DOWNLOAD_DIR="$HOME/roms/TIC-80"; RESPONSE=$(curl -s "$API_URL")
FILES=$(echo "$RESPONSE" | grep -oP '{\s*name\s*=\s*"[^"]+",\s*hash\s*=\s*"[^"]+",\s*id\s*=\s*\d+,\s*filename\s*=\s*"[^"]+"\s*}')
echo "$FILES" | while read -r LINE; do
  HASH=$(echo "$LINE" | sed -n 's/.*hash\s*=\s*"\([^"]*\)".*/\1/p'); FILENAME=$(echo "$LINE" | sed -n 's/.* name\s*=\s*"\([^"]*\)".*/\1/p')
  FILE_PATH="${DOWNLOAD_DIR}/${HASH}.tic"; DOWNLOAD_URL="${BASE_URL}/${HASH}/cart.tic"; if [ ! -f "$FILE_PATH" ]; then wget -nv -O "$FILE_PATH" "$DOWNLOAD_URL"; fi
done

BASE_URL="https://wasm4.org/play"; CARTS_URL="https://wasm4.org/carts"; ROM_DIR="$HOME/roms/WASM-4"
curl -s "$BASE_URL" | grep -oP '(?<=href="/play/)[^"]+' | sort -u | while read -r GAME; do FILE="${ROM_DIR}/$GAME.wasm"; [[ -f "$FILE" ]] || wget -nv -O "$FILE" "$CARTS_URL/$GAME.wasm"; done

if [ ! -f ~/share/zip/uzebox.zip ]; then wget -O ~/share/zip/uzebox.zip https://nicksen782.net/a_demos/downloads/games_20180105.zip; unzip -j ~/share/zip/uzebox.zip -d ~/roms/Uzebox; fi

FILE_URL="https://raw.githubusercontent.com/WizzardSK/gameflix/refs/heads/main/lowresnx.txt"; DOWNLOAD_DIR="$HOME/roms/LowresNX"; mkdir -p "$DOWNLOAD_DIR"
curl "$FILE_URL" | while IFS=$'\t'; read -r id title image nx_file; do
  if [ ! -s "$DOWNLOAD_DIR/$nx_file" ]; then download_url="https://lowresnx.inutilis.com/uploads/$nx_file"; wget -nv "$download_url" -O "$DOWNLOAD_DIR/$nx_file"; fi
done
