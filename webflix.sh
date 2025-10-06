#!/bin/bash
export LD_LIBRARY_PATH=/usr/local/lib
mkdir -p ~/myrient ~/roms/{TIC-80,LowresNX,WASM-4} ~/iso ~/zips ~/gameflix
wget -nv -O ~/.config/rclone/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/rclone.conf
archives=(https://wizzardsk.github.io/{lowresnx,tic80,wasm4}.zip)

if ! mountpoint -q "$HOME/myrient"; then rclone mount myrient: ~/myrient --http-no-head --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h --allow-non-empty --daemon --no-check-certificate --allow-other; fi
if ! mountpoint -q "$HOME/zips"; then nohup ratarmount-full -o attr_timeout=3600 --disable-union-mount "${archives[@]}" ~/zips -f & fi
while ! mountpoint -q "$HOME/zips"; do sleep 5; done

bindfs --perms=0755 --force-user=$(whoami) --force-group=$(id -gn) $HOME/zips/lowresnx.zip "$HOME/roms/LowresNX"
bindfs --perms=0755 --force-user=$(whoami) --force-group=$(id -gn) $HOME/zips/tic80.zip "$HOME/roms/TIC-80"
bindfs --perms=0755 --force-user=$(whoami) --force-group=$(id -gn) $HOME/zips/wasm4.zip "$HOME/roms/WASM-4"
