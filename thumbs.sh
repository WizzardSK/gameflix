#!/bin/bash

for dir in Named_Snaps Named_Titles Named_Boxarts Named_Logos; do
    [ -d "$dir" ] || continue
    find "$dir" -type l -exec rm -f {} +
    for file in "$dir"/*; do
        [ -f "$file" ] || continue
        old=$(basename "$file")
        new=$(echo "$old" | sed -E 's/^([^)]*\([^)]*\)).*(\.[^.]*)$/\1\2/')
        [ "$old" != "$new" ] && mv "$file" "$(dirname "$file")/$new" && echo "$old -> $new"
    done
done

rm thumbs.sh
git add .
git config --global user.name "GitHub Actions"
git config --global user.email "actions@github.com"
git commit -m "Auto update ($(date +'%Y-%m-%d %H:%M:%S'))"
git push
