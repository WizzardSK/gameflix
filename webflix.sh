#!/bin/bash
export LD_LIBRARY_PATH=/usr/local/lib
mkdir -p ~/share/zip/ni-roms ~/share/zip/mame-sl ~/share/zip/tosec-main ~/gameflix
wget -nv -O ~/.config/rclone/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/rclone.conf

csv=$(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.csv | tail -n +2 | cut -d',' -f2 | sort -u | grep '\.zip$')

while read path; do
  [[ "$path" != archive:* ]] && continue
  
  case "$path" in
    archive:ni-roms/*)
      subpath="${path#archive:ni-roms/}"
      target=~/share/zip/ni-roms/"${subpath##*/}"
      ;;
    archive:mame-sl/*)
      subpath="${path#archive:mame-sl/}"
      subpath="${subpath#*/}"
      target=~/share/zip/mame-sl/"$subpath"
      ;;
    archive:tosec-main/*)
      subpath="${path#archive:tosec-main/}"
      target=~/share/zip/tosec-main/"${subpath##*/}"
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