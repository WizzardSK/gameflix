#!/bin/bash

OUTPUT_DIR="lowresnx_pages"
IMAGE_LIST="image_list.txt"
> "$IMAGE_LIST"
page=1

while true; do
    # Stiahneme stránku do premennej
    content=$(curl -s "https://lowresnx.inutilis.com/programs.php?category=game&sort=new&page=$page")

    # Skontrolujeme, či stránka obsahuje "No results" (čo znamená koniec)
    if [[ "$content" == *"No results"* ]]; then
        echo "Stránka $page neobsahuje výsledky. Končím."
        break
    fi

    # Extrahujeme odkazy na obrázky a pridáme do súboru
    echo "$content" | grep -oE 'src="uploads/[^"]+\.png"' | sed 's/src="uploads\///;s/"$//' >> "$IMAGE_LIST"

    echo "Stiahnutá stránka $page."
    ((page++))
done
