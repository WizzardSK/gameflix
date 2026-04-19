#!/bin/bash
export LD_LIBRARY_PATH=/usr/local/lib
mkdir -p ~/roms/{LowresNX,WASM-4} ~/iso ~/gameflix
wget -nv -O ~/.config/rclone/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/rclone.conf

if [ ! -f $HOME/ratarmount-full ]; then wget -nv -O $HOME/ratarmount-full https://github.com/mxmlnkn/ratarmount/releases/download/v1.2.0/ratarmount-1.2.0-x86_64.AppImage; chmod +x $HOME/ratarmount-full; fi

csv=$(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.csv | tail -n +2 | cut -d',' -f2 | sort -u | grep '\.zip$')

while read path; do
  [[ "$path" != archive:* ]] && continue
  remote="${path#archive:}"
  remote="${remote%%/*}"
  zipfile="${path##*/}"
  
  mkdir -p ~/roms/"$remote"
  target=~/roms/"$remote"/"$zipfile"
  [[ -f "$target" ]] && continue
  
  rclone copy "archive:$path" "$target" --no-check-dest -v 2>&1 | tail -1 &
  
  while (( $(jobs -r | wc -l) >= 5 )); do sleep 2; done
done <<< "$csv"

wait
echo "Done"