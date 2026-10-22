#!/bin/bash
# Refreshes the fantasy console lists in fantasy/. The site picks them up the
# next time the update workflow of WizzardSK/wizzardsk.github.io runs.
sudo -v ; curl https://rclone.org/install.sh | sudo bash > /dev/null 2>&1
chmod +x $GITHUB_WORKSPACE/batocera/ratarmount1; sudo ln -s $GITHUB_WORKSPACE/batocera/ratarmount1 /bin/ratarmount-full
mkdir -p $HOME/.config/rclone; cp rclone.conf $HOME/.config/rclone/
echo "user_allow_other" | sudo tee -a /etc/fuse.conf > /dev/null
sudo rm -f /var/lib/dpkg/info/man-db.triggers
sudo apt install bindfs fuse-zip imagemagick > /dev/null

bash ./fantasy/wasm4.sh
bash ./fantasy/voxatron.sh
bash ./fantasy/pico8.sh
bash ./fantasy/lowresnx.sh

cd "$GITHUB_WORKSPACE"
git add fantasy
git config --global user.name "GitHub Actions"
git config --global user.email "actions@github.com"
git commit -m "Auto update ($(date +'%Y-%m-%d %H:%M:%S'))"
git push
