#!/bin/bash
API_URL="https://tic80.com/api?fn=dir&path=play/Games"
BASE_URL="https://tic80.com/cart"
DOWNLOAD_DIR="$HOME/tic80"
mkdir $DOWNLOAD_DIR ~/backup
unzip -q "$GITHUB_WORKSPACE/fantasy/tic80.zip" -d ~/backup/
RESPONSE=$(curl -s "$API_URL")
FILES=$(echo "$RESPONSE" | grep -oP '{\s*name\s*=\s*"[^"]+",\s*hash\s*=\s*"[^"]+",\s*id\s*=\s*\d+,\s*filename\s*=\s*"[^"]+"\s*}')
fetch_tic_cart() {
  local HASH=$1
  local FILE_PATH="${DOWNLOAD_DIR}/${HASH}.tic"
  [[ -f "$FILE_PATH" ]] || ([[ -f "$HOME/backup/${HASH}.tic" ]] && cp "$HOME/backup/${HASH}.tic" "$FILE_PATH") || wget -q -O "$FILE_PATH" "${BASE_URL}/${HASH}/cart.tic"
  [[ -f "${FILE_PATH%.tic}.gif" ]] || ([[ -f "$HOME/backup/${HASH}.gif" ]] && cp "$HOME/backup/${HASH}.gif" "${FILE_PATH%.tic}.gif") || wget -q -O "${FILE_PATH%.tic}.gif" "${BASE_URL}/${HASH}/cover.gif"
}
export -f fetch_tic_cart
export DOWNLOAD_DIR BASE_URL

echo "$FILES" | grep -oP 'hash\s*=\s*"\K[^"]+' | xargs -P10 -I{} bash -c 'fetch_tic_cart "{}"'
cd $DOWNLOAD_DIR
mogrify -format png *.gif
rm -f "$GITHUB_WORKSPACE/fantasy/tic80.zip" 
zip -q -r "$GITHUB_WORKSPACE/fantasy/tic80.zip" *
cd "$GITHUB_WORKSPACE"
git add "$GITHUB_WORKSPACE/fantasy/tic80.zip"
