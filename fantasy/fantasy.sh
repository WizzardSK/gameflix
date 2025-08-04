#!/bin/bash
git config --global user.name "GitHub Actions"
git config --global user.email "actions@github.com"

bash ./fantasy/wasm4.sh
#bash ./fantasy/voxatron.sh
#bash ./fantasy/tic80.sh
#bash ./fantasy/pico8.sh
#bash ./fantasy/lowresnx.sh

git commit -m "Auto update ($(date +'%Y-%m-%d %H:%M:%S'))"
git push
