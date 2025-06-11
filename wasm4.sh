#!/bin/bash
BASE_URL="https://wasm4.org/play"
CARTS_URL="https://wasm4.org/carts"
ROM_DIR="$HOME/wasm4"
IMG_DIR="$HOME/wasm4"
mkdir "$HOME/wasm4"
mkdir -p "$ROM_DIR" "$IMG_DIR"; curl -s "$BASE_URL" | grep -oP '(?<=href="/play/)[^"]+' | sort -u | while read -r GAME; do
  for EXT in wasm png; do FILE="${ROM_DIR}/$GAME.$EXT"; [[ "$EXT" == "png" ]] && FILE="${IMG_DIR}/$GAME.$EXT"; [[ -f "$FILE" ]] || wget -nv -O "$FILE" "$CARTS_URL/$GAME.$EXT"; done
done

cd ~/wasm4
zip -r "$GITHUB_WORKSPACE/fantasy/wasm4.zip" *
cd "$GITHUB_WORKSPACE"
git config --global user.name "GitHub Actions"
git config --global user.email "actions@github.com"
git add "$OUTPUT_FILE"
git add "$GITHUB_WORKSPACE/fantasy/wasm4.zip"
git commit -m "Auto update ($(date +'%Y-%m-%d %H:%M:%S'))"
git push
