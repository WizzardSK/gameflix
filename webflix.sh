#!/bin/bash
export LD_LIBRARY_PATH=/usr/local/lib
mkdir -p ~/rom/ni-roms ~/rom/mame-sl ~/rom/tosec-main ~/gameflix
wget -nv -O ~/.config/rclone/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/rclone.conf

csv=$(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.csv | tail -n +2 | cut -d',' -f2 | sort -u | grep '\.zip$')

while read path; do
  [[ "$path" != archive:* ]] && continue
  
  case "$path" in
    archive:ni-roms/*)
      target=~/rom/ni-roms/"${path##*/}"
      ;;
    archive:mame-sl/*)
      target=~/rom/mame-sl/"${path##*/}"
      ;;
    archive:tosec-main/*)
      target=~/rom/tosec-main/"${path##*/}"
      ;;
    *)
      continue
      ;;
  esac
  
  [[ -f "$target" ]] && continue
  rclone copy "$path" "$target" --no-check-dest 2>/dev/null &
  
  while (( $(jobs -r | wc -l) >= 10 )); do sleep 2; done
done <<< "$csv"

wait
echo "Done"