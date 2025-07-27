#!/bin/bash
OUTPUT_FILE="$GITHUB_WORKSPACE/fantasy/pico8.txt"
TEMP_FILE="pico8_temp.txt"
BASE_LIST_URL="https://www.lexaloffle.com/bbs/lister.php?cat=7&sub=2&mode=carts&page="
BASE_CART_URL="https://www.lexaloffle.com/bbs/?tid="
PAGE=1; > "$TEMP_FILE"
while true; do
    echo "➡️ Page $PAGE..."
    HTML=$(curl -s "${BASE_LIST_URL}${PAGE}")
    if echo "$HTML" | grep -q '\[no posts found\]'; then break; fi
    echo "$HTML" | grep '<div style="padding:10px; display:table; margin:auto">' | sed -E 's/.*>([^<]+)<.*/\1/' > titles.txt
    echo "$HTML" | grep -oP '<a href="\?tid=\d+"' | grep -oP '\d+' | uniq > tids.txt
    paste tids.txt titles.txt | while IFS=$'\t' read -r TID TITLE; do
        CART_HTML=$(curl -s "${BASE_CART_URL}${TID}")
        PNG_NAME=$(echo "$CART_HTML" | grep -oP 'href="[^"]+\.p8\.png"' | head -n1 | sed -E 's/.*\/([^/]+\.p8\.png)".*/\1/')
        PNG_URL=$(echo "$CART_HTML" | grep -oP 'href="\K[^"]+\.p8\.png' | head -n1)
        if [[ -z "$PNG_NAME" ]]; then continue; fi
        echo -e "$TID\t$TITLE\t$PNG_NAME" >> "$TEMP_FILE"
    done
    rm -f titles.txt tids.txt
    PAGE=$((PAGE + 1))
done
sort -nr "$TEMP_FILE" > "$OUTPUT_FILE"
rm -f "$TEMP_FILE"
cd "$GITHUB_WORKSPACE"
git add "$OUTPUT_FILE"
