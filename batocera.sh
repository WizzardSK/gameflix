#!/bin/bash
mount -o remount,size=6000M /tmp
ln -s /usr/bin/fusermount /usr/bin/fusermount3
curl https://rclone.org/install.sh | bash
wget -O /userdata/system/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/rclone.conf
if [ ! -f /userdata/system/mount-zip ]; then wget -O /userdata/system/mount-zip https://github.com/WizzardSK/gameflix/raw/main/batocera/share/system/mount-zip; chmod +x /userdata/system/mount-zip; fi
if [ ! -f /userdata/system/httpdirfs ]; then wget -O /userdata/system/httpdirfs https://github.com/WizzardSK/gameflix/raw/main/batocera/share/system/httpdirfs; chmod +x /userdata/system/httpdirfs; fi
if [ ! -f /userdata/system/ratarmount ]; then wget -O /userdata/system/ratarmount https://github.com/WizzardSK/gameflix/raw/main/batocera/share/system/ratarmount; chmod +x /userdata/system/ratarmount; fi
IFS=$'\n' read -d '' -ra roms <<< "$(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.txt)"

emulationstation stop; chvt 3; clear

mkdir -p /userdata/rom
mkdir -p /userdata/roms
mkdir -p /userdata/thumbs
mkdir -p /userdata/zip
mkdir -p /userdata/romz
mkdir -p /userdata/system/.cache/httpdirfs

echo "Mounting thumbs"
/userdata/system/httpdirfs --cache --no-range-check --cache-location /userdata/system/.cache/httpdirfs http://thumbnails.libretro.com /userdata/thumbs
echo "Mounting roms"
/userdata/system/httpdirfs --cache --no-range-check --cache-location /userdata/system/.cache/httpdirfs https://myrient.erista.me/files /userdata/rom

IFS=";"
for each in "${roms[@]}"; do
  read -ra rom < <(printf '%s' "$each")
  rom3=$(sed 's/<[^>]*>//g' <<< "${rom[3]}")
  echo "${rom3}"
  mkdir -p /userdata/roms/${rom[0]}/${rom3}
  mkdir -p /userdata/roms/${rom[0]}/images  
  if [[ ${rom[1]} =~ \.zip$ ]]; then
    #if [ ! -f /userdata/zip/${rom3}.zip ]; then wget -O /userdata/zip/${rom3}.zip https://myrient.erista.me/files/${rom[1]}; fi  
    #/userdata/system/mount-zip /userdata/zip/${rom3}.zip /userdata/roms/${rom[O]}/${rom3} -o nonempty -omodules=iconv,from_code=$charset1,to_code=$charset2
    /userdata/system/ratarmount /userdata/rom/${rom[1]} /userdata/roms/${rom3} -o nonempty -omodules=iconv,from_code=$charset1,to_code=$charset2
  else
    if grep -q ":" <<< "${rom[1]}"; then
      rclone mount ${rom[1]} /userdata/roms/${rom[0]}/${rom3} --http-no-head --no-checksum --no-modtime --dir-cache-time 1000h --allow-non-empty --attr-timeout 1000h --poll-interval 1000h --daemon --config=/userdata/system/rclone.conf
    else
      mount -o bind /userdata/rom/${rom[1]} /userdata/roms/${rom[0]}/${rom3}
    fi
  fi  
  mount -o bind /userdata/thumbs/${rom[2]}/Named_Snaps /userdata/roms/${rom[0]}/images
done

wget -O /usr/share/emulationstation/es_systems.cfg https://github.com/WizzardSK/gameflix/raw/main/batocera/share/system/es_systems.cfg
chvt 2
curl http://127.0.0.1:1234/reloadgames
