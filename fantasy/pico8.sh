#!/bin/bash
OUTPUT_FILE="$GITHUB_WORKSPACE/fantasy/pico8.txt"
BASE_LIST_URL="https://www.lexaloffle.com/bbs/lister.php?cat=7&sub=2&mode=carts&page="
BASE_CART_URL="https://www.lexaloffle.com/bbs/?tid="
mkdir -p ~/pico8_tmp

fetch_pico_cart() {
  local TID=$1 TITLE=$2 outdir=$3
  CART_HTML=$(curl -s "${BASE_CART_URL}${TID}")
  PNG_NAME=$(echo "$CART_HTML" | grep -oP 'href="[^"]+\.p8\.png"' | head -n1 | sed -E 's/.*\/([^/]+\.p8\.png)".*/\1/')
  [[ -z "$PNG_NAME" ]] && return
  echo -e "$TID\t$TITLE\t$PNG_NAME" > "$outdir/$TID.txt"
}
export -f fetch_pico_cart
export BASE_CART_URL

PAGE=1; all_items=""
while true; do
    echo "Page $PAGE..."
    HTML=$(curl -s "${BASE_LIST_URL}${PAGE}")
    echo "$HTML" | grep -q '\[no posts found\]' && break
    echo "$HTML" | grep '<div style="padding:10px; display:table; margin:auto">' | sed -E 's/.*>([^<]+)<.*/\1/' > titles.txt
    echo "$HTML" | grep -oP '<a href="\?tid=\d+"' | grep -oP '\d+' | uniq > tids.txt
    while IFS=$'\t' read -r TID TITLE; do
        all_items+="$TID"$'\t'"$TITLE"$'\n'
    done < <(paste tids.txt titles.txt)
    rm -f titles.txt tids.txt
    PAGE=$((PAGE + 1))
done
echo "Fetching $(echo "$all_items" | grep -c .) carts with 10 parallel workers..."
printf '%s' "$all_items" | xargs -P10 -d$'\n' -I{} bash -c '
  IFS=$'"'"'\t'"'"' read -r TID TITLE <<< "{}"
  [[ -z "$TID" ]] && exit
  fetch_pico_cart "$TID" "$TITLE" ~/pico8_tmp
'

cat ~/pico8_tmp/*.txt 2>/dev/null | sort -nr > "$OUTPUT_FILE"
rm -rf ~/pico8_tmp
cd "$GITHUB_WORKSPACE"
git add "$OUTPUT_FILE"
