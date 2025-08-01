#!/bin/bash
sudo -v ; curl https://rclone.org/install.sh | sudo bash > /dev/null
chmod +x $GITHUB_WORKSPACE/batocera/ratarmount1
sudo ln -s $GITHUB_WORKSPACE/batocera/ratarmount1 /bin/ratarmount
mkdir -p $HOME/.config/rclone
cp rclone.conf $HOME/.config/rclone/
echo "user_allow_other" | sudo tee -a /etc/fuse.conf
sudo apt install bindfs > /dev/null

bash ./batocera/gamelist.sh
bash ./webflix.sh
bash ./generate.sh

cd ~/gameflix
rm -f "$GITHUB_WORKSPACE/gameflix.zip"
zip -r "$GITHUB_WORKSPACE/gameflix.zip" *
cd "$GITHUB_WORKSPACE"
git config --global user.name "GitHub Actions"
git config --global user.email "actions@github.com"
git add "$GITHUB_WORKSPACE/gameflix.zip"
git commit -m "Auto update ($(date +'%Y-%m-%d %H:%M:%S'))"
git push
