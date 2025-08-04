#!/bin/bash
BASE_URL="https://wasm4.org/play"
CARTS_URL="https://wasm4.org/carts"
DIR="$GITHUB_WORKSPACE/wasm4"
mkdir "$DIR" ~/backup
unzip "$GITHUB_WORKSPACE/fantasy/wasm4.zip" ~/backup/
curl -sL "$BASE_URL" | grep -oP '(?<=href="/play/)[^"]+' | sort -u | while read -r GAME; do
  for EXT in wasm png; do
    FILE="$DIR/$GAME.$EXT"; 
    [[ "$EXT" == "png" ]] && FILE="$DIR/$GAME.$EXT"; 
#    [[ -f "$FILE" ]] || wget -nv -O "$FILE" "$CARTS_URL/$GAME.$EXT"; 
    [[ -f "$FILE" ]] || cp "backup/$FILE" "$FILE" || wget -nv -O "$FILE" "$CARTS_URL/$GAME.$EXT"
  done
done
cd "$GITHUB_WORKSPACE/wasm4"
rm -f "$GITHUB_WORKSPACE/fantasy/wasm4.zip" 
zip -r "$GITHUB_WORKSPACE/fantasy/wasm4.zip" *
cd "$GITHUB_WORKSPACE"
git add "$GITHUB_WORKSPACE/fantasy/wasm4.zip"
