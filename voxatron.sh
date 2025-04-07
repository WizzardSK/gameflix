#!/bin/bash
OUTPUT_FILE="voxatron.txt"
BASE_LIST_URL="https://www.lexaloffle.com/bbs/lister.php?cat=6&sub=2&mode=carts&page="
BASE_CART_URL="https://www.lexaloffle.com/bbs/?tid="
PAGE=1; > "$OUTPUT_FILE"
while true; do
    echo "➡️  Page $PAGE..."
    HTML=$(curl -s "${BASE_LIST_URL}${PAGE}")
    if echo "$HTML" | grep -q '\[no posts found\]'; then break; fi
    echo "$HTML" | grep '<div style="padding:10px; display:table; margin:auto">' | sed -E 's/.*>([^<]+)<.*/\1/' > titles.txt
    echo "$HTML" | grep -oP '<a href="\?tid=\d+"' | grep -oP '\d+' | uniq > tids.txt
    paste tids.txt titles.txt | ( while IFS=$'\t' read -r TID TITLE; do
        CART_HTML=$(curl -s "${BASE_CART_URL}${TID}")
        #PNG_NAME=$(echo "$CART_HTML" | grep -oP 'href="[^"]+\.vx\.png"' | head -n1 | sed -E 's/.*\/([^/]+\.vx\.png)".*/\1/')
        PNG_NAME=$(echo "$CART_HTML" | grep -oP 'href="[^"]+/(?:[^"/]+\.vx\.png|cpost[0-9]+\.png)"' | head -n1 | sed -E 's/.*\/([^/]+\.png)".*/\1/')
        if [[ -z "$PNG_NAME" ]]; then continue; fi
        echo -e "$TITLE\t$PNG_NAME" >> "$OUTPUT_FILE"
    done ) &
    sleep 1
    rm -f titles.txt tids.txt
    PAGE=$((PAGE + 1))
done
wait

git config --global user.name "GitHub Actions"
git config --global user.email "actions@github.com"
git add "$OUTPUT_FILE"
git commit -m "Auto update ($(date +'%Y-%m-%d %H:%M:%S'))"
git push
