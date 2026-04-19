#!/bin/bash
export LD_LIBRARY_PATH=/usr/local/lib
mkdir -p ~/roms/{LowresNX,WASM-4} ~/iso ~/gameflix
wget -nv -O ~/.config/rclone/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/rclone.conf

if [ ! -f $HOME/ratarmount-full ]; then wget -nv -O $HOME/ratarmount-full https://github.com/mxmlnkn/ratarmount/releases/download/v1.2.0/ratarmount-1.2.0-x86_64.AppImage; chmod +x $HOME/ratarmount-full; fi

csv=$(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.csv | tail -n +2)

while IFS=',' read -ra rom; do
  platform="${rom[0]}" path="${rom[1]}" display="${rom[2]}"
  [[ "$path" =~ ^archive:([^/]+)/(.+\.zip)(/.*)? ]] && remote="${BASH_REMATCH[1]}" zipfile="${BASH_REMATCH[2]}" subpath="${BASH_REMATCH[3]}"
  [[ -n "$remote" ]] || continue
  display=$(sed 's/<[^>]*>//g' <<< "$display")
  
  mkdir -p ~/roms/$platform/"$display"
  target=~/roms/$platform/"$display"/"$zipfile"
  [[ -f "$target" ]] && continue
  
  rclone copy "archive:$remote/$zipfile" "$target" --no-check-dest --no-gzip-progress 2>/dev/null &
  
  while (( $(jobs -r | wc -l) >= 10 )); do sleep 1; done
done <<< "$csv"

wait