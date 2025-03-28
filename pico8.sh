#!/bin/bash
BASE_URL="https://www.lexaloffle.com/bbs/?cat=7&carts_tab=1#sub=2&page=1&mode=carts"
DETAIL_URL="https://www.lexaloffle.com/bbs/?pid="
OUTPUT_FILE="pico8.txt"
pids=$(curl -s "$BASE_URL" | grep -oP 'pid=\K\d+' | sort -u)
> "$OUTPUT_FILE"

echo "$pids" | while read pid; do
    url="${DETAIL_URL}${pid}#p"
    page=$(curl -s "$url")
    title=$(echo "$page" | grep -oP '(?<=<title>).*?(?=</title>)')
    img_url=$(echo "$page" | grep -oP 'carts/.*?\.p8\.png' | head -n 1)
    img_url="https://www.lexaloffle.com/$img_url"
    echo "$pid,$title,$img_url" >> "$OUTPUT_FILE"
done

git config --global user.name "GitHub Actions"
git config --global user.email "actions@github.com"
git add "$OUTPUT_FILE"
git commit -m "Auto update ($(date +'%Y-%m-%d %H:%M:%S'))"
git push
