#!/bin/bash
sudo -v ; curl https://rclone.org/install.sh | sudo bash > /dev/null
chmod +x batocera/ratarmount1
sudo ln -s batocera/ratarmount1 /usr/bin/ratarmount
mkdir -p $HOME/.config/rclone
ln -s rclone.conf $HOME/.config/rclone/rclone.conf
bash ./webflix.sh
bash ./generate.sh
