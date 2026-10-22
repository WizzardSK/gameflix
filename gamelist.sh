#!/bin/bash
# Builds the site into ~/gameflix and the EmulationStation gamelists into
# ~/gamelists, after refreshing the fantasy console lists. Run from this
# repo's root; in CI that is the update workflow of
# WizzardSK/wizzardsk.github.io, which copies the result into the site.
sudo -v
curl -s https://rclone.org/install.sh | sudo bash > /dev/null 2>&1
sudo apt update > /dev/null && sudo apt install -y bindfs fuse-zip unzip zip > /dev/null
mkdir -p $HOME/.config/rclone; cp rclone.conf $HOME/.config/rclone/
echo "user_allow_other" | sudo tee -a /etc/fuse.conf > /dev/null
sudo rm -f /var/lib/dpkg/info/man-db.triggers

# Mount IA items - in CI via rclone mount, locally via webflix.sh
if [[ -n "$CI" ]]; then
  echo "=== MOUNTING IA ITEMS FOR CI ==="
  while IFS= read -r path; do
    [[ "$path" != archive:* ]] && continue
    aftercolon="${path#*:}"; item="${aftercolon%%/*}"
    mkdir -p ~/mount/"$item"
    rclone mount "archive:$item/" ~/mount/"$item" --daemon --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h --vfs-cache-mode minimal --allow-non-empty 2>/dev/null &
    sleep 2
  done < <(cut -d',' -f2 platforms.csv | sort -u | grep '^archive:' | cut -d':' -f2 | cut -d'/' -f1 | sort -u)
  sleep 10
else
  bash ./webflix.sh
fi

# Fantasy console lists (fantasy/*.txt, read by generate.sh). The carts of
# WASM-4 and LowresNX are kept in the site's wasm4.zip and lowresnx.zip, so
# only new ones are downloaded; the scrapers write the zips anew.
for z in wasm4 lowresnx; do curl -sfL -o fantasy/$z.zip https://wizzardsk.github.io/$z.zip; done
for s in wasm4 voxatron pico8 lowresnx; do GITHUB_WORKSPACE="$PWD" bash ./fantasy/$s.sh; done

bash ./generate.sh
