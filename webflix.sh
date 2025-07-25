#!/bin/bash
export LD_LIBRARY_PATH=/usr/local/lib
mkdir -p ~/myrient ~/roms/{Atari\ 2600\ ROMS,TIC-80,LowresNX,Uzebox,WASM-4,Vircon32,TDC} ~/iso ~/zips ~/gameflix ~/MS-DOS\ eXoDOS
wget -nv -O ~/.config/rclone/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/rclone.conf
if ! mountpoint -q "$HOME/myrient"; then rclone mount myrient: ~/myrient --http-no-head --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h --allow-non-empty --daemon --no-check-certificate --allow-other; fi
if ! mountpoint -q "$HOME/MS-DOS eXoDOS"; then rclone mount eye:Games/eXo/eXoDOS_v6r2/eXo/eXoDOS/ "$HOME/roms/MS-DOS eXoDOS" --http-no-head --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h --allow-non-empty --daemon --no-check-certificate --allow-other; fi

archives=( "https://www.atarimania.com/roms/Atari-2600-VCS-ROM-Collection.zip" )
archives+=( https://github.com/WizzardSK/gameflix/raw/refs/heads/main/fantasy/{lowresnx,tic80,wasm4,uzebox}.zip )

IFS=$'\n' read -d '' -ra roms <<< "$(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.txt)"
IFS=";"; for each in "${roms[@]}"; do
  read -ra rom < <(printf '%s' "$each")
  rom3=$(sed 's/<[^>]*>//g' <<< "${rom[3]}")
#  if grep -q ":" <<< "${rom[1]}"; then
#    mkdir -p $HOME/roms/${rom3}
#    if ! mountpoint -q "$HOME/roms/${rom3}"; then rclone mount ${rom[1]} ~/roms/${rom3} --http-no-head --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h --allow-non-empty --daemon --no-check-certificate --allow-other; fi
#  fi
done

if ! mountpoint -q "$HOME/zips"; then nohup ratarmount -o attr_timeout=3600 --disable-union-mount "${archives[@]}" ~/zips -f & fi
if ! mountpoint -q "$HOME/roms/Vircon32"; then rclone mount archive:all_vircon32_roms_and_media/all_vircon32_roms_and_media $HOME/roms/Vircon32 --daemon; fi
while ! mountpoint -q "$HOME/zips"; do sleep 5; done

bindfs --perms=0755 --force-user=$(whoami) --force-group=$(id -gn) $HOME/zips/Atari-2600-VCS-ROM-Collection.zip/ROMS "$HOME/roms/Atari 2600 ROMS"
bindfs --perms=0755 --force-user=$(whoami) --force-group=$(id -gn) $HOME/zips/lowresnx.zip "$HOME/roms/LowresNX"
bindfs --perms=0755 --force-user=$(whoami) --force-group=$(id -gn) $HOME/zips/tic80.zip "$HOME/roms/TIC-80"
bindfs --perms=0755 --force-user=$(whoami) --force-group=$(id -gn) $HOME/zips/wasm4.zip "$HOME/roms/WASM-4"
bindfs --perms=0755 --force-user=$(whoami) --force-group=$(id -gn) $HOME/zips/uzebox.zip "$HOME/roms/Uzebox"

for each in "${roms[@]}"; do
  read -ra rom < <(printf '%s' "$each")
  rom3=$(sed 's/<[^>]*>//g' <<< "${rom[3]}")
#  if [[ ${rom[1]} =~ \.zip$ ]]; then
#    rom1="${rom[1]//&/%26}"; rom1="${rom1// /%20}"; rom1="${rom1//[/%5B}"; rom1="${rom1//]/%5D}"; rom1="${rom1//\'/%27}"
#    mkdir -p $HOME/roms/${rom3}
#    bindfs --perms=0755 --force-user=$(whoami) --force-group=$(id -gn) $HOME/zips/${rom1##*/} $HOME/roms/${rom3}
#  fi
done

DAT_URL="https://github.com/WizzardSK/gameflix/raw/refs/heads/main/neogeo.dat"; DAT_FILE="/tmp/neogeo.dat"
SRC_DIR="$HOME/myrient/Internet Archive/chadmaster/fbnarcade-fullnonmerged/arcade"; DEST_DIR="$HOME/roms/Neo Geo"
curl -s -L "$DAT_URL" -o "$DAT_FILE"; mkdir -p "$DEST_DIR"
while IFS= read -r line; do
  neo_file="${line%%[[:space:]]*}"
  [[ -z "$neo_file" || "$neo_file" != *.neo ]] && continue
  base_name="${neo_file%.neo}"; zip_name="$base_name.zip"; src_file="$SRC_DIR/$zip_name"; dest_link="$DEST_DIR/$zip_name"
  if [[ -f "$src_file" ]]; then ln -sf "$src_file" "$dest_link"; fi
done < "$DAT_FILE"
