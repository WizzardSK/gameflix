#!/bin/bash

URL="https://lowresnx.inutilis.com/programs.php?category=game&sort=new&page=1"
OUTPUT_FILE="lowresnx.txt"

echo "ID,Názov,Obrázok,NX_Súbor" > "$OUTPUT_FILE"

curl -s "$URL" | grep -oP 'topic.php\?id=\K[0-9]+' | while read id; do
    echo $id
    topic_page=$(curl -s "https://lowresnx.inutilis.com/topic.php?id=$id")

    title=$(echo "$topic_page" | grep -oP '(?<=<h1>).*?(?=</h1>)' | head -n 1)
    image=$(echo "$topic_page" | grep -oP '(?<=<img class="screenshot pixelated" src="uploads/)[^"]+')
    nx_url=$(echo "$topic_page" | grep -oP 'href="([^"]+\.nx)"' | head -n 1 | sed 's/href="//;s/"//;s/^uploads\///')

    if [ -n "$nx_url" ]; then
        echo "$id,$title,$image,$nx_url" >> "$OUTPUT_FILE"
    else
        echo "$id,$title,$image," >> "$OUTPUT_FILE"
    fi
done

echo "Hotovo! ID, názvy hier, názvy obrázkov a .nx súbory boli uložené do $OUTPUT_FILE"

git config --global user.name "GitHub Actions"
git config --global user.email "actions@github.com"
git add "$OUTPUT_FILE"
git commit -m "Automatická aktualizácia ($(date +'%Y-%m-%d %H:%M:%S'))"
git push
