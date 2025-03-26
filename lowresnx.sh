#!/bin/bash

IMAGE_LIST="image_list.txt"
> "$IMAGE_LIST"
page=1

while true; do
    # Stiahneme stránku do pamäte
    content=$(curl -s "https://lowresnx.inutilis.com/programs.php?category=game&sort=new&page=$page")

    # Ak stránka neobsahuje výsledky, skončíme
    [[ "$content" == *"No results"* ]] && echo "Koniec stránok." && break

    # Získame dvojice (obrázok, ID programu)
    while read -r image id; do
        nx_file="${image%.png}.nx"
        nx_url="https://lowresnx.inutilis.com/uploads/$nx_file"

        # Ak existuje .nx s rovnakým názvom, pridá ho
        if [[ $(curl --head --silent --output /dev/null --write-out "%{http_code}" "$nx_url") == "200" ]]; then
            echo "$image,$nx_file" >> "$IMAGE_LIST"
            continue
        fi

        # Ak .nx neexistuje, načíta stránku detailu a hľadá prvý .nx súbor
        program_page=$(curl -s "https://lowresnx.inutilis.com/program.php?id=$id")
        found_nx=$(echo "$program_page" | grep -oE 'href="uploads/[^"]+\.nx"' | head -n 1 | sed 's/href="uploads\///;s/"$//')

        [[ -n "$found_nx" ]] && echo "$image,$found_nx" >> "$IMAGE_LIST" || echo "$image" >> "$IMAGE_LIST"
    done < <(echo "$content" | grep -oP 'src="uploads/\K[^"]+\.png"|href="program\.php\?id=\K\d+' | paste - -)

    ((page++))
done

git config --global user.name "GitHub Actions"
git config --global user.email "actions@github.com"
git add "$IMAGE_LIST"
git commit -m "Automatická aktualizácia image_list.txt ($(date +'%Y-%m-%d %H:%M:%S'))"
git push
