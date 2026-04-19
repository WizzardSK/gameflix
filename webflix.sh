#!/bin/bash
export LD_LIBRARY_PATH=/usr/local/lib
mkdir -p ~/roms/{LowresNX,WASM-4} ~/rom/{mame-sl,ni-roms,tosec-main,tosec-iso-ibm,tosec-iso-namco-sega-nintendo,tosec-iso-nec,tosec-iso-philips,tosec-iso-sega,tosec-iso-sony,tosec-iso-3do,tosec-iso-commodore,exov5_2,all_vircon32_roms_and_media,a2600_romhunter,mame-software-list-chds-2,MAME0.106-Reference-Set-ROMs-CHDs-Samples,MAME0.37b5_MAME2000_Reference_Set_Update_2_ROMs_Samples,MAME2003_Reference_Set_MAME0.78_ROMs_CHDs_Samples,MAME_2010_full_nonmerged_romsets,MAME_2015_arcade_romsets,MAME_2016_Arcade_Romsets,m2emu1.1a,SegaMD-Enhanced-ROMs,segamodel3} ~/iso ~/zips ~/gameflix
wget -nv -O ~/.config/rclone/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/rclone.conf

if [ ! -f $HOME/ratarmount-full ]; then wget -nv -O $HOME/ratarmount-full https://github.com/mxmlnkn/ratarmount/releases/download/v1.2.0/ratarmount-1.2.0-x86_64.AppImage; chmod +x $HOME/ratarmount-full; fi

csv=$(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.csv | tail -n +2)

remotes_done=()

nohup rclone mount "archive:ni-roms" ~/rom/ni-roms --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --allow-non-empty --allow-other --vfs-cache-mode minimal --vfs-read-chunk-size 1M > /dev/null 2>&1 &

nohup rclone mount "archive:tosec-main" ~/rom/tosec-main --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --allow-non-empty --allow-other --vfs-cache-mode minimal --vfs-read-chunk-size 1M > /dev/null 2>&1 &

nohup rclone mount "archive:mame-sl" ~/rom/mame-sl --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --allow-non-empty --allow-other --vfs-cache-mode minimal --vfs-read-chunk-size 1M > /dev/null 2>&1 &

while ! mountpoint -q ~/rom/ni-roms || ! mountpoint -q ~/rom/tosec-main || ! mountpoint -q ~/rom/mame-sl; do sleep 2; done

nohup $HOME/ratarmount-full -o attr_timeout=3600 --disable-union-mount https://wizzardsk.github.io/lowresnx.zip https://wizzardsk.github.io/wasm4.zip ~/rom/ni-roms/roms ~/rom/tosec-main ~/rom/mame-sl ~/zips -f > /dev/null 2>&1 &
while ! mountpoint -q ~/zips; do sleep 5; done

bindfs --perms=0755 --force-user=$(whoami) --force-group=$(id -gn) ~/zips ~/roms/LowresNX
bindfs --perms=0755 --force-user=$(whoami) --force-group=$(id -gn) ~/zips ~/roms/WASM-4

while IFS=',' read -ra rom; do
  platform="${rom[0]}" path="${rom[1]}" display="${rom[2]}"
  [[ "$path" =~ ^archive:([^/]+)/(.+\.zip)(/.*)? ]] && remote="${BASH_REMATCH[1]}" zipfile="${BASH_REMATCH[2]}" subpath="${BASH_REMATCH[3]}"
  [[ -n "$remote" ]] || continue
  display=$(sed 's/<[^>]*>//g' <<< "$display")
  
  mkdir -p ~/roms/$platform/"$display"
  bindfs --perms=0755 --force-user=$(whoami) --force-group=$(id -gn) ~/zips ~/roms/$platform/"$display"
done <<< "$csv"