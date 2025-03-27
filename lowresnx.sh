#!/bin/bash

# URL na stiahnutie
URL="https://lowresnx.inutilis.com/programs.php?category=game&sort=new&page=1"

# Stiahnutie obsahu stránky do pamäte
CONTENT=$(curl -s "$URL")

# Cieľový CSV súbor
CSV_FILE="output.csv"

# Zápis hlavičky CSV
echo "ID,Názov,Obrázok" > "$CSV_FILE"

# Parsovanie obsahu stránky
echo "$CONTENT" | grep -oP '<a href="topic.php\?id=\K[0-9]+(?=">).*?<h3>\K.*?(?=</h3>).*?src="uploads/\K[^"]+' | \
while IFS= read -r line; do
    ID=$(echo "$line" | cut -d' ' -f1)
    TITLE=$(echo "$line" | cut -d' ' -f2- | rev | cut -d' ' -f2- | rev)
    IMAGE=$(echo "$line" | awk '{print $NF}')
    echo "$ID,$TITLE,$IMAGE" >> "$CSV_FILE"
done

echo "Hotovo! Dáta boli uložené do $CSV_FILE"

git config --global user.name "GitHub Actions"
git config --global user.email "actions@github.com"
git add "$IMAGE_LIST"
git commit -m "Automatická aktualizácia image_list.txt ($(date +'%Y-%m-%d %H:%M:%S'))"
git push
