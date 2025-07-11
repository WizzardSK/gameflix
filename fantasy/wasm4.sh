#!/bin/bash
BASE_URL="https://wasm4.org/play"
CARTS_URL="https://wasm4.org/carts"
DIR="$GITHUB_WORKSPACE/wasm4"
mkdir "$DIR"
curl -s "$BASE_URL" | grep -oP '(?<=href="/play/)[^"]+' | sort -u | while read -r GAME; do
  for EXT in wasm png; do
    FILE="$DIR/$GAME.$EXT"; 
    [[ "$EXT" == "png" ]] && FILE="$DIR/$GAME.$EXT"; 
    [[ -f "$FILE" ]] || wget -nv -O "$FILE" "$CARTS_URL/$GAME.$EXT"; 
  done
done

cd "$GITHUB_WORKSPACE/wasm4"
zip -r "$GITHUB_WORKSPACE/fantasy/wasm4.zip" *
cd "$GITHUB_WORKSPACE"
git config --global user.name "GitHub Actions"
git config --global user.email "actions@github.com"
git add "$GITHUB_WORKSPACE/fantasy/wasm4.zip"
git commit -m "Auto update ($(date +'%Y-%m-%d %H:%M:%S'))"
git push
