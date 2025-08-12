#!/bin/bash
API_URL="https://tic80.com/api?fn=dir&path=play/Games"
BASE_URL="https://tic80.com/cart"
DOWNLOAD_DIR="$HOME/tic80"
mkdir $DOWNLOAD_DIR ~/backup
unzip -q "$GITHUB_WORKSPACE/fantasy/tic80.zip" -d ~/backup/
RESPONSE=$(curl -s "$API_URL")
FILES=$(echo "$RESPONSE" | grep -oP '{\s*name\s*=\s*"[^"]+",\s*hash\s*=\s*"[^"]+",\s*id\s*=\s*\d+,\s*filename\s*=\s*"[^"]+"\s*}')
echo "$FILES" | while read -r LINE; do
  HASH=$(echo "$LINE" | sed -n 's/.*hash\s*=\s*"\([^"]*\)".*/\1/p')
  FILENAME=$(echo "$LINE" | sed -n 's/.*filename\s*=\s*"\([^"]*\)".*/\1/p')
  FILE_PATH="${DOWNLOAD_DIR}/${HASH}.tic"
  DOWNLOAD_URL="${BASE_URL}/${HASH}/cart.tic"
  COVER_URL="${BASE_URL}/${HASH}/cover.gif"
  [[ -f "$FILE_PATH" ]] || ([[ -f "$HOME/backup/${HASH}.tic" ]] && cp "$HOME/backup/${HASH}.tic" "$FILE_PATH") || wget -nv -O "$FILE_PATH" "$DOWNLOAD_URL"
  [[ -f "${FILE_PATH%.tic}.gif" ]] || ([[ -f "$HOME/backup/${HASH}.gif" ]] && cp "$HOME/backup/${HASH}.gif" "${FILE_PATH%.tic}.gif") || wget -nv -O "${FILE_PATH%.tic}.gif" "$COVER_URL"
done
cd $DOWNLOAD_DIR
rm -f "$GITHUB_WORKSPACE/fantasy/tic80.zip" 
zip -q -r "$GITHUB_WORKSPACE/fantasy/tic80.zip" *
cd "$GITHUB_WORKSPACE"
git add "$GITHUB_WORKSPACE/fantasy/tic80.zip"
