#!/bin/bash

IMAGE_LIST="image_list.txt"
> "$IMAGE_LIST"  # Vyprázdni súbor pred začiatkom
page=1

while true; do
    # Stiahneme stránku do premennej
    content=$(curl -s "https://lowresnx.inutilis.com/programs.php?category=game&sort=new&page=$page")

    # Ak stránka neobsahuje výsledky, skončíme
    if [[ "$content" == *"No results"* ]]; then
        echo "Stránka $page neobsahuje výsledky. Končím."
        break
    fi

    # Extrahujeme zoznam obrázkov
    images=($(echo "$content" | grep -oE 'src="uploads/[^"]+\.png"' | sed 's/src="uploads\///;s/"$//'))

    for image in "${images[@]}"; do
        nx_file="${image%.png}.nx"  # Nahradíme .png za .nx
        nx_url="https://lowresnx.inutilis.com/uploads/$nx_file"

        # Skontrolujeme, či existuje súbor .nx na serveri
        if curl --head --silent --fail "$nx_url" > /dev/null; then
            echo "$image,$nx_file" >> "$IMAGE_LIST"  # Zapíšeme PNG aj NX
        else
            echo "$image" >> "$IMAGE_LIST"  # Zapíšeme iba PNG
        fi
    done

    echo "Spracovaná stránka $page."
    ((page++))
done

git config --global user.name "GitHub Actions"
git config --global user.email "actions@github.com"

git add "$IMAGE_LIST"
git commit -m "Automatická aktualizácia image_list.txt ($(date +'%Y-%m-%d %H:%M:%S'))"
git push
