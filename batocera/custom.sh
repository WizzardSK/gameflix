#!/bin/bash

URL="https://raw.githubusercontent.com/WizzardSK/gameflix/main/batocera.sh"
until curl -fsI "$URL" >/dev/null 2>&1; do
    sleep 2
done

if [ "$1" = "start" ]; then
    curl -s -L "$URL" | bash
fi
