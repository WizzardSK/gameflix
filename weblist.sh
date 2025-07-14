#!/bin/bash
sudo -v ; curl https://rclone.org/install.sh | sudo bash
ln -s batocera/ratarmount1 /usr/bin/ratarmount
chmod +x /usr/bin/ratarmount
ln -s rclone.conf /home/runner/.config/rclone/rclone.conf
bash ./webflix.sh
bash ./generate.sh
