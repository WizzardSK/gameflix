#!/bin/bash
export LD_LIBRARY_PATH=/usr/local/lib

mkdir -p ~/myrient ~/iso ~/gameflix
wget -nv -O ~/.config/rclone/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/rclone.conf

if ! mountpoint -q "$HOME/myrient"; then 
  rclone mount myrient: ~/myrient --http-no-head --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h --allow-non-empty --daemon --no-check-certificate --allow-other
fi
