#!/bin/bash
# Refreshes the fantasy console lists in fantasy/. The site picks them up the
# next time the update workflow of WizzardSK/wizzardsk.github.io runs.
git config --global user.name "GitHub Actions"
git config --global user.email "actions@github.com"

bash ./fantasy/wasm4.sh
bash ./fantasy/voxatron.sh
#bash ./fantasy/tic80.sh
bash ./fantasy/pico8.sh
bash ./fantasy/lowresnx.sh

cd "$GITHUB_WORKSPACE"
git add fantasy
git commit -m "Auto update ($(date +'%Y-%m-%d %H:%M:%S'))"
git push
