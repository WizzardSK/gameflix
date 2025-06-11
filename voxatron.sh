#!/bin/bash
OUTPUT_FILE="voxatron.txt"
TEMP_FILE="voxatron_temp.txt"
BASE_LIST_URL="https://www.lexaloffle.com/bbs/lister.php?cat=6&sub=2&mode=carts&page="
BASE_CART_URL="https://www.lexaloffle.com/bbs/?tid="
mkdir ~/voxatron
PAGE=1; > "$TEMP_FILE"
while true; do
    echo "➡️ Page $PAGE..."
    HTML=$(curl -s "${BASE_LIST_URL}${PAGE}")
    if echo "$HTML" | grep -q '\[no posts found\]'; then break; fi
    echo "$HTML" | grep '<div style="padding:10px; display:table; margin:auto">' | sed -E 's/.*>([^<]+)<.*/\1/' > titles.txt
    echo "$HTML" | grep -oP '<a href="\?tid=\d+"' | grep -oP '\d+' | uniq > tids.txt
    paste tids.txt titles.txt | while IFS=$'\t' read -r TID TITLE; do
        CART_HTML=$(curl -s "${BASE_CART_URL}${TID}")
        PNG_NAME=$(echo "$CART_HTML" | grep -oP 'href="[^"]+/(?:[^"/]+\.vx\.png|cpost[0-9]+\.png)"' | head -n1 | sed -E 's/.*\/([^/]+\.png)".*/\1/')
        PNG_URL=$(echo "$CART_HTML" | grep -oP 'href="\K[^"]+/(?:[^"/]+\.vx\.png|cpost[0-9]+\.png)' | head -n1)
        wget -nv -O ~/voxatron/$PNG_NAME "https://www.lexaloffle.com${PNG_URL}"
        if [[ -z "$PNG_NAME" ]]; then continue; fi
        echo -e "$TID\t$TITLE\t$PNG_NAME" >> "$TEMP_FILE"
    done
    rm -f titles.txt tids.txt
    PAGE=$((PAGE + 1))
done
sort -nr "$TEMP_FILE" > "$OUTPUT_FILE"
rm -f "$TEMP_FILE"
cd ~/voxatron
zip -r "$GITHUB_WORKSPACE/fantasy/voxatron.zip" *
cd "$GITHUB_WORKSPACE"
git config --global user.name "GitHub Actions"
git config --global user.email "actions@github.com"
git add "$OUTPUT_FILE"
git add "$GITHUB_WORKSPACE/fantasy/voxatron.zip"
git commit -m "Auto update ($(date +'%Y-%m-%d %H:%M:%S'))"
git push
