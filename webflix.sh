#!/bin/bash
export LD_LIBRARY_PATH=/usr/local/lib
mkdir -p ~/rom/ni-roms ~/rom/mame-sl ~/rom/tosec-main ~/gameflix
wget -nv -O ~/.config/rclone/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/rclone.conf

csv=$(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.csv | tail -n +2 | cut -d',' -f2 | sort -u | grep '\.zip$')

while read path; do
  [[ "$path" != archive:* ]] && continue
  
  case "$path" in
    archive:ni-roms/*)
      subpath="${path#archive:ni-roms/}"
      target=~/rom/ni-roms/"$subpath"
      ;;
    archive:mame-sl/*)
      subpath="${path#archive:mame-sl/}"
      target=~/rom/mame-sl/"$subpath"
      ;;
    archive:tosec-main/*)
      subpath="${path#archive:tosec-main/}"
      target=~/rom/tosec-main/"$subpath"
      ;;
    *)
      continue
      ;;
  esac
  
  mkdir -p "$(dirname "$target")"
  [[ -f "$target" ]] && continue
  rclone copyto "$path" "$target" --no-check-dest 2>/dev/null &
  
  while (( $(jobs -r | wc -l) >= 10 )); do sleep 2; done
done <<< "$csv"

wait
echo "Done"