#!/bin/bash

OUTPUT_DIR=lowresnx_pages
IMAGE_LIST="image_list.txt"
> "$IMAGE_LIST"
page=1

while true; do
    curl -o "$filename" "https://lowresnx.inutilis.com/programs.php?category=game&sort=new&page=$page"
    
    if grep -q "No results" "$filename"; then
        echo "Stránka $page neobsahuje výsledky. Končím."
        rm "$filename"
        break
    fi
    
    grep -oE 'src="uploads/[^"]+\.png"' "$filename" | sed 's/src="uploads\///;s/"$//' >> "$IMAGE_LIST"
    
    echo "Stiahnutá stránka $page."
    ((page++))
done
