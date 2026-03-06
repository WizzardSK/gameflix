#!/bin/bash
BASE_URL="https://wasm4.org/play"
CARTS_URL="https://wasm4.org/carts"
DIR="$GITHUB_WORKSPACE/wasm4"
mkdir "$DIR" ~/backup
unzip -q "$GITHUB_WORKSPACE/fantasy/wasm4.zip" -d ~/backup/

fetch_wasm_game() {
  local GAME=$1
  for EXT in wasm png; do
    FILE="$DIR/$GAME.$EXT"
    [[ -f "$FILE" ]] || ([[ -f "$HOME/backup/$GAME.$EXT" ]] && cp "$HOME/backup/$GAME.$EXT" "$FILE") || wget -q -O "$FILE" "$CARTS_URL/$GAME.$EXT"
  done
}
export -f fetch_wasm_game
export DIR CARTS_URL

curl -sL "$BASE_URL" | grep -oP '(?<=href="/play/)[^"]+' | sort -u | xargs -P10 -I{} bash -c 'fetch_wasm_game "{}"'
cd "$GITHUB_WORKSPACE/wasm4"
rm -f "$GITHUB_WORKSPACE/fantasy/wasm4.zip" 
zip -q -r "$GITHUB_WORKSPACE/fantasy/wasm4.zip" *
cd "$GITHUB_WORKSPACE"
git add "$GITHUB_WORKSPACE/fantasy/wasm4.zip"
