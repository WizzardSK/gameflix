#!/bin/bash
export LD_LIBRARY_PATH=/usr/local/lib
mkdir -p ~/share/zip/ni-roms ~/share/zip/mame-sl ~/share/zip/tosec-main \
         ~/share/roms ~/share/roms-mount ~/gameflix
wget -nv -O ~/.config/rclone/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/rclone.conf

csv_file=$(mktemp)
curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.csv | tail -n +2 > "$csv_file"

# Compute local zip path for archive: paths; sets $zip on success, returns 1 otherwise
compute_zip() {
  local path="$1" subpath
  case "$path" in
    archive:ni-roms/*)
      subpath="${path#archive:ni-roms/}"
      zip=~/share/zip/ni-roms/"${subpath##*/}"
      ;;
    archive:mame-sl/*)
      subpath="${path#archive:mame-sl/}"
      subpath="${subpath#*/}"
      zip=~/share/zip/mame-sl/"$subpath"
      ;;
    archive:tosec-main/*)
      subpath="${path#archive:tosec-main/}"
      zip=~/share/zip/tosec-main/"${subpath##*/}"
      ;;
    *) return 1 ;;
  esac
}

# Phase 1: download unique zips from archive.org via rclone
echo "=== DOWNLOADING ZIPS ==="
declare -A seen
total=0; pending=0
while IFS=',' read -r platform path foldername rest; do
  [[ "$path" != archive:* || "$path" != *.zip ]] && continue
  [[ -n "${seen[$path]}" ]] && continue
  seen[$path]=1; ((total++))
  compute_zip "$path" || continue
  mkdir -p "$(dirname "$zip")"
  [[ -f "$zip" ]] && continue
  ((pending++))
  echo "[$pending] $zip"
  rclone copyto "$path" "$zip" --no-check-dest 2>/dev/null &
  while (( $(jobs -r | wc -l) >= 3 )); do sleep 2; done
done < "$csv_file"
wait
echo "Download done: $((total - pending))/$total already present, $pending downloaded"

# Phase 2: mount each zip via mount-zip into ~/share/roms-mount/<platform>/<foldername>/
# Then symlink ~/share/roms/<platform>/<foldername> to the appropriate inner path
# (for MAME-SL zips the contents are under <shortname>/, so the symlink targets that subdir)
echo "=== MOUNTING ZIPS ==="
mounted=0; relinked=0
while IFS=',' read -r platform path foldername rest; do
  [[ "$path" != archive:* || "$path" != *.zip ]] && continue
  compute_zip "$path" || continue
  [[ ! -f "$zip" ]] && continue
  cleanfolder="${foldername//<[^>]*>/}"
  mp=~/share/roms-mount/"$platform"/"$cleanfolder"
  mkdir -p "$mp"
  if ! mountpoint -q "$mp"; then
    mount-zip -o quiet "$zip" "$mp" 2>/dev/null && ((mounted++))
  fi
  # MAME software list zips wrap contents in <shortname>/ — strip via symlink
  if [[ "$path" == archive:mame-sl/* ]]; then
    shortname="${zip##*/}"; shortname="${shortname%.zip}"
    src="$mp/$shortname"
  else
    src="$mp"
  fi
  dst=~/share/roms/"$platform"/"$cleanfolder"
  mkdir -p ~/share/roms/"$platform"
  # Replace only existing symlinks; never clobber a real directory
  if [[ -L "$dst" || ! -e "$dst" ]]; then
    ln -sfn "$src" "$dst"
    ((relinked++))
  fi
done < "$csv_file"
echo "Mounted $mounted zip(s), relinked $relinked target(s)"

rm -f "$csv_file"
echo "Done"
