#!/bin/bash

BASE_URL="https://www.lexaloffle.com/bbs/?cat=7&carts_tab=1#sub=2&page=1&mode=carts"
CSV_FILE="lexaloffle_data.csv"
pids=$(curl -s "$BASE_URL" | grep -oP '(?<=tid=)\d+' | sort -u)
> "$CSV_FILE"

echo "$pids" | while read pid; do
    echo "$pid" >> "$CSV_FILE"
done

git config --global user.name "GitHub Actions"
git config --global user.email "actions@github.com"
git add "$CSV_FILE"
git commit -m "Auto update ($(date +'%Y-%m-%d %H:%M:%S'))"
git push
