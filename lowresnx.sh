#!/bin/bash

# URL na stiahnutie
URL="https://lowresnx.inutilis.com/programs.php?category=game&sort=new&page=1"

# Stiahnutie obsahu stránky do pamäte
CONTENT=$(curl -s "$URL")

# Cieľový CSV súbor
CSV_FILE="output.csv"

# Zápis hlavičky CSV
echo "ID,Názov,Obrázok" > "$CSV_FILE"

# Extrakcia ID
IDs=$(echo "$CONTENT" | grep -oP 'topic.php\?id=\K[0-9]+')

# Extrakcia názvov
Titles=$(echo "$CONTENT" | grep -oP '<h3>\K[^<]+')

# Extrakcia obrázkov
Images=$(echo "$CONTENT" | grep -oP 'uploads/\K[^"]+')

# Uloženie do CSV
paste -d ',' <(echo "$IDs") <(echo "$Titles") <(echo "$Images") >> "$CSV_FILE"

echo "Hotovo! Dáta boli uložené do $CSV_FILE"


git config --global user.name "GitHub Actions"
git config --global user.email "actions@github.com"
git add "$IMAGE_LIST"
git commit -m "Automatická aktualizácia image_list.txt ($(date +'%Y-%m-%d %H:%M:%S'))"
git push
