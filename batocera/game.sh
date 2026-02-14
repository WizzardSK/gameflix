#!/bin/bash
if [ -d "$2" ]; then exit 0; fi
if [[ "$1" =~ ^(lowresnx|pico8|steam|tic80|voxatron|wasm4)$ ]]; then exit 0; fi
SYSTEM="$1"; GAMENAME="$2"

SYSTEMS_CSV="/userdata/system/systems.csv"
[ ! -f "$SYSTEMS_CSV" ] && curl -s -o "$SYSTEMS_CSV" https://raw.githubusercontent.com/WizzardSK/gameflix/main/systems.csv
DIR_NAME=$(awk -F',' -v sys="$SYSTEM" '$1==sys {print $3; exit}' "$SYSTEMS_CSV")
[ -z "$DIR_NAME" ] && DIR_NAME="$SYSTEM"
REPO_NAME="${DIR_NAME// /_}"
DIR="$HOME/../thumbs/$DIR_NAME/Named_Snaps"
mkdir -p "$DIR"

BASENAME=$(basename "$GAMENAME")
BASENAME="${BASENAME%.*}"

if [[ "$BASENAME" == *")"* ]]; then FILENAME="${BASENAME%%)*})"; else FILENAME="$BASENAME"; fi

FULLPATH="$DIR/$FILENAME.png"
if [ -e "$FULLPATH" ]; then exit 0; fi

ENCODED_NAME="${FILENAME// /%20}"
ENCODED_NAME="${ENCODED_NAME//#/%23}"

URL="https://raw.githubusercontent.com/WizzardSK/$REPO_NAME/refs/heads/master/Named_Snaps/$ENCODED_NAME.png"
curl -s -L -f "$URL" -o "$FULLPATH"
