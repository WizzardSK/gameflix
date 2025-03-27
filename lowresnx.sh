#!/bin/bash

# URL na stiahnutie
URL="https://lowresnx.inutilis.com/programs.php?category=game&sort=new&page=1"

# Cieľový CSV súbor
CSV_FILE="output.csv"

# Zápis hlavičky CSV
echo "ID,Názov,Obrázok" > "$CSV_FILE"

# Stiahnutie obsahu stránky a spracovanie iba v <div class="grid">
curl -s "$URL" | awk '
    # Hľadáme začiatok a koniec div.grid
    /<div class="grid">/,/<\/div>/ {
        if (/<a href="topic.php\?id=/) {
            match($0, /topic.php\?id=([0-9]+)/, id);
            match($0, /uploads\/([^"]+)/, img);
            match($0, /<h3>([^<]+)/, title);
            if (id[1] && title[1] && img[1]) {
                print id[1] "," title[1] "," img[1];
            }
        }
    }
' >> "$CSV_FILE"

echo "Hotovo! Dáta boli uložené do $CSV_FILE"



git config --global user.name "GitHub Actions"
git config --global user.email "actions@github.com"
git add "$IMAGE_LIST"
git commit -m "Automatická aktualizácia image_list.txt ($(date +'%Y-%m-%d %H:%M:%S'))"
git push
