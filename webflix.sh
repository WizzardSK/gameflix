#!/bin/bash
export LD_LIBRARY_PATH=/usr/local/lib
mkdir -p ~/myrient ~/roms/{Atari\ 2600\ ROMS,TIC-80,LowresNX,Uzebox,WASM-4,Vircon32,Socrates,TI99} ~/iso ~/zips ~/gameflix
wget -nv -O ~/.config/rclone/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/rclone.conf
archives=("https://www.atarimania.com/roms/Atari-2600-VCS-ROM-Collection.zip" https://wizzardsk.github.io/{lowresnx,tic80,wasm4,uzebox,socrates}.zip)

if ! mountpoint -q "$HOME/myrient"; then rclone mount myrient: ~/myrient --http-no-head --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h --allow-non-empty --daemon --no-check-certificate --allow-other; fi
if ! mountpoint -q "$HOME/zips"; then nohup ratarmount-full -o attr_timeout=3600 --disable-union-mount "${archives[@]}" ~/zips -f & fi
if ! mountpoint -q "$HOME/roms/Vircon32"; then rclone mount archive:all_vircon32_roms_and_media/all_vircon32_roms_and_media $HOME/roms/Vircon32 --daemon; fi
if ! mountpoint -q "$HOME/roms/TI99"; then rclone mount whtech:MAME/rpk $HOME/roms/TI99 --daemon; fi
while ! mountpoint -q "$HOME/zips"; do sleep 5; done

bindfs --perms=0755 --force-user=$(whoami) --force-group=$(id -gn) $HOME/zips/Atari-2600-VCS-ROM-Collection.zip/ROMS "$HOME/roms/Atari 2600 ROMS"
bindfs --perms=0755 --force-user=$(whoami) --force-group=$(id -gn) $HOME/zips/lowresnx.zip "$HOME/roms/LowresNX"
bindfs --perms=0755 --force-user=$(whoami) --force-group=$(id -gn) $HOME/zips/tic80.zip "$HOME/roms/TIC-80"
bindfs --perms=0755 --force-user=$(whoami) --force-group=$(id -gn) $HOME/zips/wasm4.zip "$HOME/roms/WASM-4"
bindfs --perms=0755 --force-user=$(whoami) --force-group=$(id -gn) $HOME/zips/uzebox.zip "$HOME/roms/Uzebox"
bindfs --perms=0755 --force-user=$(whoami) --force-group=$(id -gn) $HOME/zips/socrates.zip "$HOME/roms/Socrates"
