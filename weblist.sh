#!/bin/bash
sudo -v ; curl https://rclone.org/install.sh | sudo bash > /dev/null
chmod +x $GITHUB_WORKSPACE/batocera/ratarmount1; sudo ln -s $GITHUB_WORKSPACE/batocera/ratarmount1 /bin/ratarmount-full
mkdir -p $HOME/.config/rclone; cp rclone.conf $HOME/.config/rclone/
echo "user_allow_other" | sudo tee -a /etc/fuse.conf
sudo apt install bindfs fuse-zip imagemagick > /dev/null

bash ./fantasy/wasm4.sh
bash ./fantasy/voxatron.sh
bash ./fantasy/tic80.sh
bash ./fantasy/pico8.sh
bash ./fantasy/lowresnx.sh
bash ./webflix.sh
bash ./generate.sh

cd ~/gamelists
rm -f "$GITHUB_WORKSPACE/batocera/gamelist.zip"
zip -q -r "$GITHUB_WORKSPACE/batocera/gamelist.zip" *
cd "$GITHUB_WORKSPACE"
git add "$GITHUB_WORKSPACE/batocera/gamelist.zip"
cd ~/gameflix
rm -f "$GITHUB_WORKSPACE/gameflix.zip"
zip -q -r "$GITHUB_WORKSPACE/gameflix.zip" *
cd "$GITHUB_WORKSPACE"
git add "$GITHUB_WORKSPACE/gameflix.zip"
git config --global user.name "GitHub Actions"
git config --global user.email "actions@github.com"
git commit -m "Auto update ($(date +'%Y-%m-%d %H:%M:%S'))"
git push
