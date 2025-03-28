#!/bin/bash

BASE_URL="https://www.lexaloffle.com/bbs/?cat=7&carts_tab=1#sub=2&page=1&mode=carts"
DETAIL_URL="https://www.lexaloffle.com/bbs/?pid="
CSV_FILE="lexaloffle_data.csv"

# Stiahnutie hlavnej stránky a získanie PID čísel
echo "Fetching PID list..."
pids=$(curl -s "$BASE_URL" | grep -oP 'pid=(\d+)' | grep -oP '\d+' | sort -u)

echo "Found $(echo "$pids" | wc -l) PIDs"

echo "PID,Title,Image URL" > "$CSV_FILE"

# Spracovanie jednotlivých PID
echo "$pids" | while read pid; do
    url="${DETAIL_URL}${pid}#p"
    echo "Fetching $url"
    page=$(curl -s "$url")
    
    title=$(echo "$page" | grep -oP '(?<=<title>)[^<]+' | head -n 1 | sed 's/,//g')
    img_url=$(echo "$page" | grep -oP 'carts/[^" ]+\.p8\.png' | head -n 1)
    
    if [ -n "$img_url" ]; then
        img_url="https://www.lexaloffle.com/$img_url"
    fi
    
    if [ -n "$pid" ] && [ -n "$title" ] && [ -n "$img_url" ]; then
        echo "$pid,$title,$img_url" >> "$CSV_FILE"
    fi
done

echo "Data saved to $CSV_FILE"


git config --global user.name "GitHub Actions"
git config --global user.email "actions@github.com"
git add "$OUTPUT_FILE"
git commit -m "Auto update ($(date +'%Y-%m-%d %H:%M:%S'))"
git push
