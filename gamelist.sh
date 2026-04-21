#!/bin/bash
sudo -v
curl -s https://rclone.org/install.sh | sudo bash > /dev/null 2>&1
sudo apt update > /dev/null && sudo apt install -y bindfs fuse-zip unzip > /dev/null
mkdir -p $HOME/.config/rclone; cp rclone.conf $HOME/.config/rclone/
echo "user_allow_other" | sudo tee -a /etc/fuse.conf > /dev/null
sudo rm -f /var/lib/dpkg/info/man-db.triggers

# In CI: download zip files directly; locally: use webflix.sh for mounting
if [[ -n "$CI" ]]; then
  echo "=== DOWNLOADING IA ITEMS FOR CI ==="
  while IFS= read -r path; do
    [[ "$path" != archive:* ]] && continue
    aftercolon="${path#*:}"
    target="$HOME/share/zip/$aftercolon"
    mkdir -p "$(dirname "$target")"
    [[ -f "$target" ]] && continue
    rclone copyto "$path" "$target" --no-check-dest 2>/dev/null &
    while (( $(jobs -r | wc -l) >= 10 )); do sleep 2; done
  done < <(cut -d',' -f2 platforms.csv | sort -u | grep '\.zip$')
  wait
else
  bash ./webflix.sh
fi

bash ./generate.sh

WORKSPACE="${GITHUB_WORKSPACE:-$PWD}"
cd ~ && mkdir -p gamelists gameflix
cd gamelists
rm -f "$WORKSPACE/batocera/gamelist.zip"
zip -q -r "$WORKSPACE/batocera/gamelist.zip" *
cd "$WORKSPACE"
git add "$WORKSPACE/batocera/gamelist.zip"
cd ~/gameflix
rm -f "$WORKSPACE/gameflix.zip"
zip -q -r "$WORKSPACE/gameflix.zip" *
cd "$WORKSPACE"
git add "$WORKSPACE/gameflix.zip"
git config --global user.name "GitHub Actions"
git config --global user.email "actions@github.com"
git commit -m "Auto update ($(date +'%Y-%m-%d %H:%M:%S'))"
git push
