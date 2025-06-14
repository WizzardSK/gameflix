#!/bin/bash
API_URL="https://tic80.com/api?fn=dir&path=play/Games"
BASE_URL="https://tic80.com/cart"
DOWNLOAD_DIR="$HOME/tic80"
mkdir $DOWNLOAD_DIR
RESPONSE=$(curl -s "$API_URL")
FILES=$(echo "$RESPONSE" | grep -oP '{\s*name\s*=\s*"[^"]+",\s*hash\s*=\s*"[^"]+",\s*id\s*=\s*\d+,\s*filename\s*=\s*"[^"]+"\s*}')
echo "$FILES" | while read -r LINE; do
    HASH=$(echo "$LINE" | sed -n 's/.*hash\s*=\s*"\([^"]*\)".*/\1/p')
    FILENAME=$(echo "$LINE" | sed -n 's/.*filename\s*=\s*"\([^"]*\)".*/\1/p')
    FILE_PATH="${DOWNLOAD_DIR}/${HASH}"
    DOWNLOAD_URL="${BASE_URL}/${HASH}/cart.tic"
    COVER_URL="${BASE_URL}/${HASH}/cover.gif"
    if [ ! -f "$FILE_PATH" ]; then 
        wget -nv -O "$FILE_PATH" "$DOWNLOAD_URL"
        wget -nv -O "${FILE_PATH%.tic}.gif" "$COVER_URL"
    fi
done
cd $DOWNLOAD_DIR
zip -r "$GITHUB_WORKSPACE/fantasy/tic80.zip" *
cd "$GITHUB_WORKSPACE"
git config --global user.name "GitHub Actions"
git config --global user.email "actions@github.com"
git add "$GITHUB_WORKSPACE/fantasy/tic80.zip"
git commit -m "Auto update ($(date +'%Y-%m-%d %H:%M:%S'))"
git push
