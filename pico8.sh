#!/bin/bash

BASE_URL="https://www.lexaloffle.com/bbs/?cat=7&carts_tab=1#sub=2&page=1&mode=carts"
CSV_FILE="pico8.csv"
DETAIL_URL="https://www.lexaloffle.com/bbs/?pid="

# Stiahnutie hlavnej stránky a získanie PID čísel
echo "Fetching PID list..."
pids=$(curl -s "$BASE_URL" | grep -oP '(?<=tid=)\d+' | sort -u)

echo "Found $(echo "$pids" | wc -l) PIDs"

echo "PID,Image File" > "$CSV_FILE"

# Spracovanie jednotlivých PID
echo "$pids" | while read pid; do
    url="${DETAIL_URL}${pid}#p"
    echo "Fetching $url"
    page=$(curl -s "$url")
    
    img_file=$(echo "$page" | grep -oP 'carts/[^" ]+\.p8\.png' | head -n 1)
    
    if [ -n "$img_file" ]; then
        img_file="https://www.lexaloffle.com/$img_file"
    fi
    
    echo "$pid,$img_file" >> "$CSV_FILE"
done

echo "Data saved to $CSV_FILE"


git config --global user.name "GitHub Actions"
git config --global user.email "actions@github.com"
git add "$CSV_FILE"
git commit -m "Auto update ($(date +'%Y-%m-%d %H:%M:%S'))"
git push
