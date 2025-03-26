#!/bin/bash

IMAGE_LIST="image_list.txt"
> "$IMAGE_LIST"
page=1

while true; do
    echo "Spracovávam stránku $page..."
    content=$(curl -s "https://lowresnx.inutilis.com/programs.php?category=game&sort=new&page=$page")
    [[ "$content" == *"No results"* ]] && echo "Koniec stránok." && break

    while read -r image id; do
        nx_file="${image%.png}.nx"
        nx_url="https://lowresnx.inutilis.com/uploads/$nx_file"

        if [[ $(curl --head --silent --output /dev/null --write-out "%{http_code}" "$nx_url") == "200" ]]; then
            echo "$image,$nx_file" >> "$IMAGE_LIST"
            continue
        fi

        topic_page=$(curl -s "https://lowresnx.inutilis.com/topic.php?id=$id")
        found_nx=$(echo "$topic_page" | grep -oP 'href="uploads/\K[^"]+\.nx"' | head -n 1)

        if [[ -n "$found_nx" ]]; then
            echo "$image,$found_nx" >> "$IMAGE_LIST"
        else
            echo "$image" >> "$IMAGE_LIST"
        fi
    done < <(echo "$content" | grep -oP 'src="uploads/\K[^"]+\.png"|topic\.php\?id=\K\d+' | paste - -)

    ((page++))
done

git config --global user.name "GitHub Actions"
git config --global user.email "actions@github.com"
git add "$IMAGE_LIST"
git commit -m "Automatická aktualizácia image_list.txt ($(date +'%Y-%m-%d %H:%M:%S'))"
git push
