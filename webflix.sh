#!/bin/bash
export LD_LIBRARY_PATH=/usr/local/lib
mkdir -p ~/share/zip/ni-roms ~/share/zip/mame-sl ~/share/zip/tosec-main \
         ~/share/roms ~/share/roms-mount ~/share/zips ~/gameflix
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

# Phase 2: rebuild symlink tree at ~/share/zips/<platform>/<foldername>.zip
echo "=== BUILDING ZIP TREE ==="
rm -rf ~/share/zips
mkdir -p ~/share/zips
linked=0
while IFS=',' read -r platform path foldername rest; do
  [[ "$path" != archive:* || "$path" != *.zip ]] && continue
  compute_zip "$path" || continue
  [[ ! -f "$zip" ]] && continue
  cleanfolder="${foldername//<[^>]*>/}"
  mkdir -p ~/share/zips/"$platform"
  ln -sfn "$zip" ~/share/zips/"$platform"/"$cleanfolder.zip"
  ((linked++))
done < "$csv_file"
echo "Linked $linked zip(s)"

# Phase 3: single ratarmount process for the whole tree
# --recursion-depth 1: mount only the top-level zips, not ROM zips inside them
# --transform: strip MAME-style <shortname>/ prefix from contents
# entry/attr_timeout=86400: kernel caches stat for a day -> fast repeat ls
echo "=== MOUNTING ==="
mountpoint -q ~/share/roms-mount && fusermount -u -z ~/share/roms-mount 2>/dev/null
ratarmount --recursion-depth 1 -s --transform '^[a-z0-9_]+/' '' \
  -o entry_timeout=86400,attr_timeout=86400,negative_timeout=86400 \
  ~/share/zips ~/share/roms-mount
sleep 2
if mountpoint -q ~/share/roms-mount; then
  echo "Mounted ~/share/roms-mount"
else
  echo "Mount failed" >&2; rm -f "$csv_file"; exit 1
fi

# Phase 4: symlinks ~/share/roms/<platform>/<foldername> -> ~/share/roms-mount/<platform>/<foldername>
echo "=== LINKING INTO ROMS ==="
symlinked=0
while IFS=',' read -r platform path foldername rest; do
  [[ "$path" != archive:* || "$path" != *.zip ]] && continue
  compute_zip "$path" || continue
  [[ ! -f "$zip" ]] && continue
  cleanfolder="${foldername//<[^>]*>/}"
  src=~/share/roms-mount/"$platform"/"$cleanfolder"
  dst=~/share/roms/"$platform"/"$cleanfolder"
  mkdir -p ~/share/roms/"$platform"
  # Replace only existing symlinks; never clobber a real directory
  if [[ -L "$dst" || ! -e "$dst" ]]; then
    ln -sfn "$src" "$dst"
    ((symlinked++))
  fi
done < "$csv_file"
echo "Symlinked $symlinked target(s)"

# Phase 5: rclone-mount IA items live for non-zip archive: paths (redump, full-folder bundles)
echo "=== MOUNTING IA ITEMS LIVE ==="
declare -A items_mounted
ia_mounted=0; ia_linked=0
while IFS=',' read -r platform path foldername rest; do
  [[ "$path" != archive:* || "$path" == *.zip ]] && continue
  aftercolon="${path#archive:}"
  item="${aftercolon%%/*}"
  subpath="${aftercolon#$item}"; subpath="${subpath#/}"
  if [[ -z "${items_mounted[$item]}" ]]; then
    mkdir -p ~/mount/"$item"
    if ! mountpoint -q ~/mount/"$item"; then
      rclone mount "archive:$item" ~/mount/"$item" --daemon --no-checksum --no-modtime \
        --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h \
        --vfs-cache-mode minimal --allow-non-empty 2>/dev/null && ((ia_mounted++))
    fi
    items_mounted[$item]=1
  fi
  cleanfolder="${foldername//<[^>]*>/}"
  src="$HOME/mount/$item${subpath:+/$subpath}"
  dst=~/share/roms/"$platform"/"$cleanfolder"
  mkdir -p ~/share/roms/"$platform"
  if [[ -L "$dst" || ! -e "$dst" ]]; then
    ln -sfn "$src" "$dst"
    ((ia_linked++))
  fi
done < "$csv_file"
echo "IA: mounted $ia_mounted item(s), linked $ia_linked target(s)"

rm -f "$csv_file"
echo "Done"
