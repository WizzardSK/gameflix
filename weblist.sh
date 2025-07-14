#!/bin/bash
sudo -v ; curl https://rclone.org/install.sh | sudo bash > /dev/null
chmod +x $GITHUB_WORKSPACE/batocera/ratarmount1
sudo ln -s $GITHUB_WORKSPACE/batocera/ratarmount1 /bin/ratarmount
mkdir -p $HOME/.config/rclone
cp rclone.conf $HOME/.config/rclone/
echo "user_allow_other" | sudo tee -a /etc/fuse.conf
sudo apt install bindfs
bash ./webflix.sh
bash ./generate.sh
