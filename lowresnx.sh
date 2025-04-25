#!/bin/bash
BASE_URL="https://lowresnx.inutilis.com/programs.php?category=game&sort=new&page="
OUTPUT_FILE="lowresnx.txt"
> "$OUTPUT_FILE"
page=1
while true; do
    URL="${BASE_URL}${page}"
    echo "Page $page..."
    page_content=$(curl -s "$URL")
    if echo "$page_content" | grep -q "No results"; then break; fi
    echo "$page_content" | grep -oP 'topic.php\?id=\K[0-9]+' | while read id; do
        echo "  -> ID $id"
        topic_page=$(curl -s "https://lowresnx.inutilis.com/topic.php?id=$id")
        title=$(echo "$topic_page" | grep -oP '(?<=<h1>).*?(?=</h1>)' | head -n 1)
        image=$(echo "$topic_page" | grep -oP '(?<=<img class="screenshot pixelated" src="uploads/)[^"]+')
        nx_url=$(echo "$topic_page" | grep -oP 'href="uploads/\K[^"]+\.nx' | head -n 1)
        echo -e "$id\t$title\t$image\t$nx_url" >> "$OUTPUT_FILE"
    done
    ((page++)) 
done

git config --global user.name "GitHub Actions"
git config --global user.email "actions@github.com"
git add "$OUTPUT_FILE"
git commit -m "Auto update ($(date +'%Y-%m-%d %H:%M:%S'))"
git push
