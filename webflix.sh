#!/bin/bash
export LD_LIBRARY_PATH=/usr/local/lib
mkdir -p ~/roms/{LowresNX,WASM-4} ~/iso ~/zips ~/gameflix
wget -nv -O ~/.config/rclone/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/rclone.conf
archives=(https://wizzardsk.github.io/{lowresnx,wasm4}.zip)

if [ ! -f $HOME/ratarmount-full ]; then wget -nv -O $HOME/ratarmount-full https://github.com/mxmlnkn/ratarmount/releases/download/v1.2.0/ratarmount-1.2.0-x86_64.AppImage; chmod +x $HOME/ratarmount-full; fi
if ! mountpoint -q "$HOME/zips"; then nohup $HOME/ratarmount-full -o attr_timeout=3600 --disable-union-mount "${archives[@]}" ~/zips -f & fi
while ! mountpoint -q "$HOME/zips"; do sleep 5; done

bindfs --perms=0755 --force-user=$(whoami) --force-group=$(id -gn) $HOME/zips/lowresnx.zip "$HOME/roms/LowresNX"
bindfs --perms=0755 --force-user=$(whoami) --force-group=$(id -gn) $HOME/zips/wasm4.zip "$HOME/roms/WASM-4"

csv=$(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.csv | tail -n +2)
mounted=()
while IFS=';' read -ra rom; do
  path="${rom[1]}"
  [[ "$path" =~ ^archive:([^/]+)(.*) ]] && archive="${BASH_REMATCH[1]}" subpath="${BASH_REMATCH[2]}"
  [[ -n "$archive" ]] || continue
  already_mounted=false
  for m in "${mounted[@]}"; do [[ "$m" == "$archive" ]] && already_mounted=true && break; done
  if [[ "$already_mounted" == "false" ]]; then
    mounted+=("$archive")
    mkdir -p ~/zips/$archive
    mountpoint -q ~/zips/$archive || rclone mount "$archive:" ~/zips/$archive --daemon --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h --allow-non-empty --allow-other --vfs-cache-mode minimal --vfs-read-chunk-size 1M
  fi
done <<< "$csv"
while IFS=';' read -ra rom; do
  platform="${rom[0]}" path="${rom[1]}" display="${rom[2]}"
  [[ "$path" =~ ^archive:([^/]+)(.*) ]] && archive="${BASH_REMATCH[1]}" subpath="${BASH_REMATCH[2]}"
  [[ -n "$archive" ]] || continue
  display=$(sed 's/<[^>]*>//g' <<< "$display")
  mkdir -p ~/roms/$platform/$display
  bindfs --perms=0755 --force-user=$(whoami) --force-group=$(id -gn) ~/zips/$archive$subpath ~/roms/$platform/$display
done <<< "$csv"
