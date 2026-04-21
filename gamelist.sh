#!/bin/bash
if [[ -z "$CI" ]]; then
  sudo -v ; curl https://rclone.org/install.sh | sudo bash > /dev/null 2>&1
  mkdir -p $HOME/.config/rclone; cp rclone.conf $HOME/.config/rclone/
  echo "user_allow_other" | sudo tee -a /etc/fuse.conf > /dev/null
  sudo rm -f /var/lib/dpkg/info/man-db.triggers
  sudo apt install bindfs fuse-zip unzip > /dev/null

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
