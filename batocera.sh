#!/bin/bash
emulationstation stop; chvt 3; clear; mount -o remount,size=6000M /tmp; ln -s /usr/bin/fusermount /usr/bin/fusermount3; curl https://rclone.org/install.sh | bash > /dev/null 2>&1
wget -O /userdata/system/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/rclone.conf > /dev/null 2>&1
if [ ! -f /userdata/system/httpdirfs ];  then wget -O /userdata/system/httpdirfs  https://github.com/WizzardSK/gameflix/raw/main/batocera/httpdirfs; chmod +x /userdata/system/httpdirfs; fi
if [ ! -f /userdata/system/fuse-zip ];   then wget -O /userdata/system/fuse-zip   https://github.com/WizzardSK/gameflix/raw/main/batocera/fuse-zip;  chmod +x /userdata/system/fuse-zip; fi
if [ ! -f /userdata/system/mount-zip ];  then wget -O /userdata/system/mount-zip  https://github.com/WizzardSK/gameflix/raw/main/batocera/mount-zip; chmod +x /userdata/system/mount-zip; fi
if [ ! -f /userdata/system/ratarmount ]; then wget -O /userdata/system/ratarmount https://github.com/mxmlnkn/ratarmount/releases/download/v0.15.2/ratarmount-0.15.2-x86_64.AppImage; chmod +x /userdata/system/ratarmount; fi

mkdir -p /userdata/{rom,roms,thumb,thumbs,zip,zips} /userdata/system/.cache/{httpdirfs,ratarmount,rclone}
IFS=$'\n' read -d '' -ra roms <<< "$(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.txt)"
rclone mount myrient: /userdata/rom --http-no-head --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h --allow-non-empty --daemon --no-check-certificate --config=/userdata/system/rclone.conf
rclone mount thumbs:Data/share/thumbs /userdata/thumbs --vfs-cache-mode full --daemon --config=/userdata/system/rclone.conf --cache-dir=/userdata/system/.cache/rclone --allow-non-empty --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h

archives=( "https://www.atarimania.com/roms/Atari-2600-VCS-ROM-Collection.zip" )
archives+=( "https://nicksen782.net/a_demos/downloads/games_20180105.zip" )
archives+=( "https://github.com/WizzardSK/gameflix/raw/refs/heads/main/fantasy/lowresnx.zip" )
archives+=( "https://github.com/WizzardSK/gameflix/raw/refs/heads/main/fantasy/tic80.zip" )
archives+=( "https://github.com/WizzardSK/gameflix/raw/refs/heads/main/fantasy/wasm4.zip" )

IFS=";"
for each in "${roms[@]}"; do 
  read -ra rom < <(printf '%s' "$each")
  if [ ! -f /userdata/thumb/${rom[0]}.png ]; then wget -nv -O /userdata/thumb/${rom[0]}.png https://raw.githubusercontent.com/fabricecaruso/es-theme-carbon/master/art/consoles/${rom[0]}.png; fi
  rom3=$(sed 's/<[^>]*>//g' <<< "${rom[3]}")
  echo "${rom3}"; mkdir -p /userdata/roms/${rom[0]}/${rom3}
  if [[ ${rom[1]} =~ \.zip$ ]]; then
    #/userdata/system/ratarmount /userdata/rom/${rom[1]} /userdata/roms/${rom[0]}/${rom3} --index-folders /userdata/system/.cache/ratarmount > /dev/null &
    rom1="${rom[1]//&/%26}"; rom1="${rom1// /%20}"; rom1="${rom1//[/%5B}"; rom1="${rom1//]/%5D}"; rom1="${rom1//\'/%27}"
    archives+=( "https://myrient.erista.me/files/${rom1}" )
  else
    if grep -q ":" <<< "${rom[1]}"; then
      rclone mount ${rom[1]} /userdata/roms/${rom[0]}/${rom3} --http-no-head --no-checksum --no-modtime --dir-cache-time 1000h --allow-non-empty --attr-timeout 1000h --poll-interval 1000h --daemon --config=/userdata/system/rclone.conf
    else mount -o bind /userdata/rom/${rom[1]} /userdata/roms/${rom[0]}/${rom3}; fi
  fi
done
/userdata/system/ratarmount -o attr_timeout=60 --disable-union-mount "${archives[@]}" /userdata/zips -f & 
while ! mountpoint -q "/userdata/zips" do sleep 5; done

for each in "${roms[@]}"; do
  read -ra rom < <(printf '%s' "$each")
  rom3=$(sed 's/<[^>]*>//g' <<< "${rom[3]}")
  if [[ ${rom[1]} =~ \.zip$ ]]; then
    rom1="${rom[1]//&/%26}"; rom1="${rom1// /%20}"; rom1="${rom1//[/%5B}"; rom1="${rom1//]/%5D}"; rom1="${rom1//\'/%27}"
    mkdir -p /userdata/roms/${rom[0]}/${rom3}
    mount -o bind /userdata/zips/${rom1##*/} /userdata/roms/${rom[0]}/${rom3}
  fi
done

wget -nv -O /userdata/system/gamelist.zip https://github.com/WizzardSK/gameflix/raw/main/batocera/gamelist.zip
unzip -o /userdata/system/gamelist.zip -d /userdata/roms

cp /usr/share/emulationstation/es_systems.cfg /usr/share/emulationstation/es_systems.bak
wget -nv -O /usr/share/emulationstation/es_systems.cfg https://github.com/WizzardSK/gameflix/raw/main/batocera/es_systems.cfg > /dev/null 2>&1
chvt 2; wget http://127.0.0.1:1234/reloadgames > /dev/null 2>&1
