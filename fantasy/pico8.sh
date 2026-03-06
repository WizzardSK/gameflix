#!/bin/bash
OUTPUT_FILE="$GITHUB_WORKSPACE/fantasy/pico8.txt"
BASE_CART_URL="https://www.lexaloffle.com/bbs/?tid="
> "$OUTPUT_FILE"

fetch_pico_cart() {
  local TID=$1 outdir=$2 TITLE=$3
  CART_HTML=$(curl -s "${BASE_CART_URL}${TID}")
  PNG_NAME=$(echo "$CART_HTML" | grep -oP 'href="[^"]+\.p8\.png"' | head -n1 | sed -E 's/.*\/([^/]+\.p8\.png)".*/\1/')
  [[ -z "$PNG_NAME" ]] && return
  printf '%s\t%s\t%s\n' "$TID" "$TITLE" "$PNG_NAME" > "$outdir/$TID.txt"
}

declare -A categories=([2]=Releases [3]=WIP [8]=Jam [9]=Code [14]=GFX [15]="SFX / Music")
for sub in 2 3 8 9 14 15; do
  catname="${categories[$sub]}"
  echo "=== $catname (sub=$sub) ==="
  catdir=~/pico8_tmp/$sub; mkdir -p "$catdir"
  PAGE=1; tidlist=""
  declare -A titles=()
  while true; do
    HTML=$(curl -s "https://www.lexaloffle.com/bbs/lister.php?cat=7&sub=$sub&mode=carts&page=$PAGE")
    echo "$HTML" | grep -q '\[no posts found\]' && break
    echo "$HTML" | grep '<div style="padding:10px; display:table; margin:auto">' | sed -E 's/.*>([^<]+)<.*/\1/' > titles.txt
    echo "$HTML" | grep -oP '<a href="\?tid=\d+"' | grep -oP '\d+' | uniq > tids.txt
    while IFS=$'\t' read -r TID TITLE; do
        titles[$TID]="$TITLE"
        tidlist+="$TID"$'\n'
    done < <(paste tids.txt titles.txt)
    rm -f titles.txt tids.txt
    ((PAGE++))
  done
  count=$(printf '%s' "$tidlist" | grep -c .)
  echo "$catname: $((PAGE-1)) pages, $count carts"
  jobs_running=0
  while IFS= read -r TID; do
    [[ -z "$TID" ]] && continue
    fetch_pico_cart "$TID" "$catdir" "${titles[$TID]}" &
    ((jobs_running++))
    if ((jobs_running >= 10)); then wait -n; ((jobs_running--)); fi
  done <<< "$tidlist"
  wait
  echo -e "---\t$catname" >> "$OUTPUT_FILE"
  cat "$catdir"/*.txt 2>/dev/null | sort -nr >> "$OUTPUT_FILE"
done
rm -rf ~/pico8_tmp
cd "$GITHUB_WORKSPACE"
git add "$OUTPUT_FILE"
