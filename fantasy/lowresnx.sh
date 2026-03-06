#!/bin/bash
OUTPUT_FILE="$GITHUB_WORKSPACE/fantasy/lowresnx.txt"
> "$OUTPUT_FILE"
mkdir -p ~/lowresnx ~/backup ~/lowresnx_tmp
unzip -q "$GITHUB_WORKSPACE/fantasy/lowresnx.zip" -d ~/backup/

fetch_topic() {
  local id=$1 category=$2 outdir=$3
  topic_page=$(curl -s "https://lowresnx.inutilis.com/topic.php?id=$id")
  title=$(echo "$topic_page" | grep -oP '(?<=<h1>).*?(?=</h1>)' | head -n 1)
  image=$(echo "$topic_page" | grep -oP '(?<=<img class="screenshot pixelated" src="uploads/)[^"]+')
  nx_url=$(echo "$topic_page" | grep -oP 'href="uploads/\K[^"]+\.nx' | head -n 1)
  [[ -z "$nx_url" || -z "$image" ]] && return
  echo -e "$id\t$title\t$image\t$nx_url" > "$outdir/$id.txt"
  ([[ -f "$HOME/backup/$nx_url" ]] && cp "$HOME/backup/$nx_url" ~/lowresnx/$nx_url) || wget -q -O ~/lowresnx/$nx_url "https://lowresnx.inutilis.com/uploads/$nx_url"
  ([[ -f "$HOME/backup/$image"  ]] && cp "$HOME/backup/$image"  ~/lowresnx/$image)  || wget -q -O ~/lowresnx/$image  "https://lowresnx.inutilis.com/uploads/$image"
}
export -f fetch_topic

for category in game art tool example; do
  echo "=== $category ==="
  catdir=~/lowresnx_tmp/$category; mkdir -p "$catdir"
  page=1; ids=""
  while true; do
    page_content=$(curl -s "https://lowresnx.inutilis.com/programs.php?category=$category&sort=new&page=${page}")
    echo "$page_content" | grep -q "No results" 2>/dev/null && break
    ids+=" $(echo "$page_content" | grep -oP 'topic.php\?id=\K[0-9]+')"
    ((page++))
  done
  echo "$category: $((page-1)) pages, $(echo $ids | wc -w) topics"
  echo $ids | tr ' ' '\n' | xargs -P10 -I{} bash -c 'fetch_topic "$@"' _ {} "$category" "$catdir"
  echo -e "---\t$category" >> "$OUTPUT_FILE"
  cat "$catdir"/*.txt 2>/dev/null | sort -rn >> "$OUTPUT_FILE"
done
cd ~/lowresnx
rm -f "$GITHUB_WORKSPACE/fantasy/lowresnx.zip" 
zip -q -r "$GITHUB_WORKSPACE/fantasy/lowresnx.zip" *
cd "$GITHUB_WORKSPACE"
git add "$OUTPUT_FILE"
git add "$GITHUB_WORKSPACE/fantasy/lowresnx.zip"
