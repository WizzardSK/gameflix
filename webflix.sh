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

IFS=$'\n' read -d '' -ra roms <<< "$(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.csv | tail -n +2 | awk '{o="";i=1;n=length($0);while(i<=n){c=substr($0,i,1);if(c==","){o=o";";i++}else if(c=="\""){i++;while(i<=n){c=substr($0,i,1);if(c=="\""){if(substr($0,i+1,1)=="\""){o=o"\"";i+=2}else{i++;break}}else{o=o c;i++}}}else{o=o c;i++}};print o}')"
IFS=";"; for each in "${roms[@]}"; do
  read -ra rom < <(printf '%s' "$each")
  if grep -q ":" <<< "${rom[1]}" && [[ "${rom[1]}" != *.zip ]]; then
    rom3=$(sed 's/<[^>]*>//g' <<< "${rom[2]}"); mkdir -p ~/roms/${rom[0]}/${rom3}
    rclone mount "${rom[1]}" ~/roms/${rom[0]}/${rom3} --daemon --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h --allow-non-empty --allow-other --vfs-cache-mode minimal --vfs-read-chunk-size 1M
  fi
done
