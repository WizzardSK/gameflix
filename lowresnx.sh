#!/bin/bash

# URL na stiahnutie
URL="https://lowresnx.inutilis.com/programs.php?category=game&sort=new&page=1"

# Stiahnutie obsahu stránky do pamäte
CONTENT=$(curl -s "$URL")

# Cieľový CSV súbor
CSV_FILE="output.csv"

# Zápis hlavičky CSV
echo "ID,Názov,Obrázok" > "$CSV_FILE"

# Extrakcia ID, názvu a obrázka
IDs=($(echo "$CONTENT" | grep -oP 'topic.php\?id=\K[0-9]+'))
Titles=($(echo "$CONTENT" | grep -oP '<h3>\K[^<]+'))
Images=($(echo "$CONTENT" | grep -oP 'uploads/\K[^"]+'))

# Skombinovanie a uloženie do CSV
for i in "${!IDs[@]}"; do
    echo "${IDs[$i]},${Titles[$i]},${Images[$i]}" >> "$CSV_FILE"
done

echo "Hotovo! Dáta boli uložené do $CSV_FILE"

git config --global user.name "GitHub Actions"
git config --global user.email "actions@github.com"
git add "$IMAGE_LIST"
git commit -m "Automatická aktualizácia image_list.txt ($(date +'%Y-%m-%d %H:%M:%S'))"
git push
