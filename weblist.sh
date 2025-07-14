#!/bin/bash
sudo -v ; curl https://rclone.org/install.sh | sudo bash
ln -s batocera/ratarmount1 /usr/bin/ratarmount
chmod +x /usr/bin/ratarmount
bash ./webflix.sh
bash ./generate.sh
