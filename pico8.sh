#!/bin/bash

BASE_URL="https://www.lexaloffle.com/bbs/?cat=7&carts_tab=1#sub=2&page=1&mode=carts"
CSV_FILE="lexaloffle_data.csv"

# Stiahnutie hlavnej stránky a získanie PID čísel
pids=$(curl -s "$BASE_URL" | grep -oP 'tid=(\d+)' | grep -oP '\d+' | sort -u)

echo "PID" > "$CSV_FILE"

echo "$pids" | while read pid; do
    echo "$pid" >> "$CSV_FILE"
done

echo "Data saved to $CSV_FILE"

git config --global user.name "GitHub Actions"
git config --global user.email "actions@github.com"
git add "$OUTPUT_FILE"
git commit -m "Auto update ($(date +'%Y-%m-%d %H:%M:%S'))"
git push
