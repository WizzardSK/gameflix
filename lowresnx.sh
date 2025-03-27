#!/bin/bash

# URL na stiahnutie
URL="https://lowresnx.inutilis.com/programs.php?category=game&sort=new&page=1"

# Cieľový CSV súbor
CSV_FILE="output.csv"

# Zápis hlavičky CSV
echo "ID,Názov,Obrázok" > "$CSV_FILE"

# Stiahnutie a spracovanie obsahu
curl -s "$URL" | grep -oP '(?<=topic.php\?id=)[0-9]+' > ids.txt
curl -s "$URL" | grep -oP '(?<=<h3>)[^<]+' > titles.txt
curl -s "$URL" | grep -oP '(?<=uploads/)[^"]+' > images.txt

# Spojenie dát a uloženie do CSV
paste -d ',' ids.txt titles.txt images.txt >> "$CSV_FILE"

# Odstránenie dočasných súborov
rm ids.txt titles.txt images.txt

echo "Hotovo! Dáta boli uložené do $CSV_FILE"



git config --global user.name "GitHub Actions"
git config --global user.email "actions@github.com"
git add "$IMAGE_LIST"
git commit -m "Automatická aktualizácia image_list.txt ($(date +'%Y-%m-%d %H:%M:%S'))"
git push
