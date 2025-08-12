#!/bin/bash
BASE_URL="https://lowresnx.inutilis.com/programs.php?category=game&sort=new&page="
OUTPUT_FILE="$GITHUB_WORKSPACE/fantasy/lowresnx.txt"
> "$OUTPUT_FILE"
page=1
mkdir ~/lowresnx ~/backup
unzip -q "$GITHUB_WORKSPACE/fantasy/lowresnx.zip" -d ~/backup/
while true; do
  URL="${BASE_URL}${page}"
  echo "Page $page..."
  page_content=$(curl -s "$URL")
  if echo "$page_content" | grep -q "No results"; then break; fi
  echo "$page_content" | grep -oP 'topic.php\?id=\K[0-9]+' | while read id; do
    topic_page=$(curl -s "https://lowresnx.inutilis.com/topic.php?id=$id")
    title=$(echo "$topic_page" | grep -oP '(?<=<h1>).*?(?=</h1>)' | head -n 1)
    image=$(echo "$topic_page" | grep -oP '(?<=<img class="screenshot pixelated" src="uploads/)[^"]+')
    nx_url=$(echo "$topic_page" | grep -oP 'href="uploads/\K[^"]+\.nx' | head -n 1)
    echo -e "$id\t$title\t$image\t$nx_url" >> "$OUTPUT_FILE"
    ([[ -f "$HOME/backup/$nx_url" ]] && cp "$HOME/backup/$nx_url" ~/lowresnx/$nx_url) || wget -nv -O ~/lowresnx/$nx_url https://lowresnx.inutilis.com/upload/$nx_url
    ([[ -f "$HOME/backup/$image"  ]] && cp "$HOME/backup/$image"  ~/lowresnx/$image)  || wget -nv -O ~/lowresnx/$image  https://lowresnx.inutilis.com/upload/$image
  done
  ((page++)) 
done
cd ~/lowresnx
rm -f "$GITHUB_WORKSPACE/fantasy/lowresnx.zip" 
zip -q -r "$GITHUB_WORKSPACE/fantasy/lowresnx.zip" *
cd "$GITHUB_WORKSPACE"
git add "$OUTPUT_FILE"
git add "$GITHUB_WORKSPACE/fantasy/lowresnx.zip"
