#!/bin/bash
emulationstation stop; chvt 3; clear
mount -o remount,size=6000M /tmp
ln -s /usr/bin/fusermount /usr/bin/fusermount3
curl https://rclone.org/install.sh | bash > /dev/null 2>&1
wget -O /userdata/system/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/rclone.conf > /dev/null 2>&1
if [ ! -f /userdata/system/httpdirfs ];  then wget -O /userdata/system/httpdirfs  https://github.com/WizzardSK/gameflix/raw/main/batocera/share/system/httpdirfs; chmod +x /userdata/system/httpdirfs; fi
if [ ! -f /userdata/system/fuse-zip ];   then wget -O /userdata/system/fuse-zip   https://github.com/WizzardSK/gameflix/raw/main/batocera/share/system/fuse-zip;  chmod +x /userdata/system/fuse-zip; fi
if [ ! -f /userdata/system/mount-zip ];  then wget -O /userdata/system/mount-zip  https://github.com/WizzardSK/gameflix/raw/main/batocera/share/system/mount-zip; chmod +x /userdata/system/mount-zip; fi
if [ ! -f /userdata/system/ratarmount ]; then wget -O /userdata/system/ratarmount https://github.com/mxmlnkn/ratarmount/releases/download/v0.15.2/ratarmount-0.15.2-x86_64.AppImage; chmod +x /userdata/system/ratarmount; fi
if [ ! -f /userdata/system/cli.tar.gz ]; then wget -O /userdata/system/cli.tar.gz https://batocera.pro/app/cli.tar.gz; tar -xf /userdata/system/cli.tar.gz -C /userdata/system/; fi
if [ ! -f /userdata/zip/atari2600roms.zip ]; then wget -O /userdata/zip/atari2600roms.zip https://www.atarimania.com/roms/Atari-2600-VCS-ROM-Collection.zip; fi
/userdata/system/cli/run
mkdir -p /userdata/zip/atari2600roms /userdata/roms/atari2600/Atari\ 2600\ ROMS /userdata/{rom,roms,thumb,thumbs,zip} /userdata/system/.cache/{httpdirfs,ratarmount,rclone} /userdata/thumbs/TIC-80
/userdata/system/fuse-zip /userdata/zip/atari2600roms.zip /userdata/zip/atari2600roms
mount -o bind /userdata/zip/atari2600roms/ROMS /userdata/roms/atari2600/Atari\ 2600\ ROMS
IFS=$'\n' read -d '' -ra roms <<< "$(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.txt)"
rclone mount myrient: /userdata/rom --http-no-head --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h --allow-non-empty --daemon --no-check-certificate --config=/userdata/system/rclone.conf

API_URL="https://tic80.com/api?fn=dir&path=play/Games"; BASE_URL="https://tic80.com/cart"; DOWNLOAD_DIR="/userdata/roms/tic80"; RESPONSE=$(curl -s "$API_URL")
FILES=$(echo "$RESPONSE" | grep -oP '{\s*name\s*=\s*"[^"]+",\s*hash\s*=\s*"[^"]+",\s*id\s*=\s*\d+,\s*filename\s*=\s*"[^"]+"\s*}')
echo "$FILES" | while read -r LINE; do
  HASH=$(echo "$LINE" | sed -n 's/.*hash\s*=\s*"\([^"]*\)".*/\1/p'); FILENAME=$(echo "$LINE" | sed -n 's/.*filename\s*=\s*"\([^"]*\)".*/\1/p')
  FILE_PATH="${DOWNLOAD_DIR}/${HASH} ${FILENAME}"; DOWNLOAD_URL="${BASE_URL}/${HASH}/cart.tic"
  SNAP_PATH="/userdata/thumbs/TIC-80/${HASH} ${FILENAME%.*}.gif"; SNAPSHOT_URL="${BASE_URL}/${HASH}/cover.gif"
  if [ ! -f "$FILE_PATH" ]; then wget -O "$FILE_PATH" "$DOWNLOAD_URL"; fi
  if [ ! -f "$SNAP_PATH" ]; then wget -O "$SNAP_PATH" "$SNAPSHOT_URL"; fi
done

BASE_URL="https://wasm4.org/play"; CARTS_URL="https://wasm4.org/carts"; ROM_DIR="/userdata/roms/wasm4"; IMG_DIR="/userdata/thumbs/WASM-4"
mkdir -p "$ROM_DIR" "$IMG_DIR"
curl -s "$BASE_URL" | grep -oP '(?<=href="/play/)[^"]+' | sort -u | while read -r GAME; do
  for EXT in wasm png; do
    FILE="${ROM_DIR}/$GAME.$EXT"
    [[ "$EXT" == "png" ]] && FILE="${IMG_DIR}/$GAME.$EXT"
    [[ -f "$FILE" ]] || wget -O "$FILE" "$CARTS_URL/$GAME.$EXT"
  done
done

if [ ! -f /userdata/zip/uzebox.zip ]; then wget -O /userdata/zip/uzebox.zip https://nicksen782.net/a_demos/downloads/games_20180105.zip; unzip -j /userdata/zip/uzebox.zip -d /userdata/roms/uzebox; fi

echo "<gameList>" > /userdata/roms/tic80/gamelist.xml; ls /userdata/roms/tic80 | while read line; do
  line2=${line%.*}; hra="<game><path>./${line}</path><name>${line2:33}</name><image>~/../thumbs/TIC-80/${line2}.gif</image>"; echo "${hra}</game>" >> /userdata/roms/tic80/gamelist.xml
done; echo "</gameList>" >> /userdata/roms/tic80/gamelist.xml

echo "<gameList>" > /userdata/roms/wasm4/gamelist.xml; ls /userdata/roms/wasm4 | while read line; do
  line2=${line%.*}; hra="<game><path>./${line}</path><name>${line2}</name><image>~/../thumbs/WASM-4/${line2}.png</image>"; echo "${hra}</game>" >> /userdata/roms/wasm4/gamelist.xml
done; echo "</gameList>" >> /userdata/roms/wasm4/gamelist.xml

echo "<gameList>" > /userdata/roms/uzebox/gamelist.xml; ls /userdata/roms/uzebox | while read line; do
  line2=${line%.*}; hra="<game><path>./${line}</path><name>${line2}</name><image>~/../thumbs/Uzebox/Named_Snaps/${line2}.png</image>"; echo "${hra}</game>" >> /userdata/roms/uzebox/gamelist.xml
done; echo "</gameList>" >> /userdata/roms/uzebox/gamelist.xml

if [ ! -d "/userdata/thumbs/Uzebox" ]; then
  git clone --depth 1 "https://github.com/WizzardSK/Uzebox.git" /userdata/thumbs/Uzebox 2>&1 | tee -a /userdata/system/logs/git.log
else
  git config --global --add safe.directory /userdata/thumbs/Uzebox
  git -C /userdata/thumbs/Uzebox config pull.rebase false 2>&1 | tee -a /userdata/system/logs/git.log
  git -C /userdata/thumbs/Uzebox pull 2>&1 | tee -a /userdata/system/logs/git.log
fi

IFS=";"
> /userdata/system/logs/git.log
declare -A seen
for each in "${roms[@]}"; do 
  read -ra rom < <(printf '%s' "$each")
  > /userdata/roms/${rom[0]}/gamelist.xml;
done
for each in "${roms[@]}"; do 
  read -ra rom < <(printf '%s' "$each")
  if [ ! -f /userdata/thumb/${rom[0]}.png ]; then wget -O /userdata/thumb/${rom[0]}.png https://raw.githubusercontent.com/fabricecaruso/es-theme-carbon/master/art/consoles/${rom[0]}.png; fi
  if [[ -z "${seen[${rom[0]}]}" ]]; then
    seen[${rom[0]}]=1
    rom2="${rom[2]// /_}"
    echo "${rom[2]} thumbs" | tee -a /userdata/system/logs/git.log
    if [ ! -d "/userdata/thumbs/${rom[2]}" ]; then
      git clone --depth 1 "https://github.com/WizzardSK/${rom2}.git" /userdata/thumbs/${rom[2]} 2>&1 | tee -a /userdata/system/logs/git.log
    else
      git config --global --add safe.directory /userdata/thumbs/${rom[2]}
      git -C /userdata/thumbs/${rom[2]} config pull.rebase false 2>&1 | tee -a /userdata/system/logs/git.log
      git -C /userdata/thumbs/${rom[2]} pull 2>&1 | tee -a /userdata/system/logs/git.log
      sleep 0.5
    fi
  fi  
  ( rom3=$(sed 's/<[^>]*>//g' <<< "${rom[3]}")
  echo "${rom3}"
  mkdir -p /userdata/roms/${rom[0]}/${rom3}
  if [[ ${rom[1]} =~ \.zip$ ]]; then
    if [ ! -f /userdata/zip/${rom3}.zip ]; then wget -O /userdata/zip/${rom3}.zip https://myrient.erista.me/files/${rom[1]}; fi
    /userdata/system/fuse-zip /userdata/zip/${rom3}.zip /userdata/roms/${rom[0]}/${rom3}
  else
    if grep -q ":" <<< "${rom[1]}"; then
      rclone mount ${rom[1]} /userdata/roms/${rom[0]}/${rom3} --http-no-head --no-checksum --no-modtime --dir-cache-time 1000h --allow-non-empty --attr-timeout 1000h --poll-interval 1000h --daemon --config=/userdata/system/rclone.conf
    else mount -o bind /userdata/rom/${rom[1]} /userdata/roms/${rom[0]}/${rom3}; fi
  fi
  if ! grep -Fxq "<gameList>" /userdata/roms/${rom[0]}/gamelist.xml > /dev/null 2>&1; then
    ls /userdata/roms/${rom[0]}/${rom3} | while read line; do
      line2=${line%.*}
      hra="<game><path>./${rom3}/${line}</path><name>${line2}</name><image>~/../thumbs/${rom[2]}/Named_Snaps/${line2}.png</image><titleshot>~/../thumbs/${rom[2]}/Named_Titles/${line2}.png</titleshot><thumbnail>~/../thumbs/${rom[2]}/Named_Boxarts/${line2}.png</thumbnail><marquee>~/../thumbs/${rom[2]}/Named_Logos/${line2}.png</marquee>"
      if ! grep -iqE '\[(bios|a[0-9]{0,2}|b[0-9]{0,2}|c|f|h ?.*|o ?.*|p ?.*|t ?.*|cr ?.*)\]|\((demo( [0-9]+)?|beta( [0-9]+)?|alpha( [0-9]+)?|(disk|side)( [2-9B-Z]).*|pre-release|aftermarket|alt|alternate|unl|channel|system|dlc)\)' <<< "$line"; then
        echo "${hra}</game>" >> /userdata/roms/${rom[0]}/gamelist.xml
      else echo "${hra}<hidden>true</hidden></game>" >> /userdata/roms/${rom[0]}/gamelist.xml; fi    
    done
    echo "<folder><path>./${rom3}</path><name>${rom3}</name><image>~/../thumb/${rom[0]}.png</image></folder>" >> /userdata/roms/${rom[0]}/gamelist.xml
  fi ) &
done; wait

ls /userdata/roms/atari2600/Atari\ 2600\ ROMS | while read line; do
  line2=${line%.*}
  hra="<game><path>./Atari 2600 ROMS/${line}</path><name>${line2}</name><image>~/../thumbs/Atari - 2600/Named_Snaps/${line2}.png</image><titleshot>~/../thumbs/Atari - 2600/Named_Titles/${line2}.png</titleshot><thumbnail>~/../thumbs/Atari - 2600/Named_Boxarts/${line2}.png</thumbnail><marquee>~/../thumbs/Atari - 2600/Named_Logos/${line2}.png</marquee>"
  if ! grep -iqE '\[(bios|a[0-9]{0,2}|b[0-9]{0,2}|c|f|h ?.*|o ?.*|p ?.*|t ?.*|cr ?.*)\]|\((demo( [0-9]+)?|beta( [0-9]+)?|alpha( [0-9]+)?|(disk|side)( [2-9B-Z]).*|pre-release|aftermarket|alt|alternate|unl|channel|system|dlc)\)' <<< "$line"; then
    echo "${hra}</game>" >> /userdata/roms/atari2600/gamelist.xml
  else echo "${hra}<hidden>true</hidden></game>" >> /userdata/roms/atari2600/gamelist.xml; fi    
done; echo "<folder><path>./Atari 2600 ROMS</path><name>Atari 2600 ROMS</name><image>~/../thumb/atari2600.png</image></folder>" >> /userdata/roms/atari2600/gamelist.xml

for each in "${roms[@]}"; do 
  read -ra rom < <(printf '%s' "$each")
  if ! grep -Fxq "<gameList>" /userdata/roms/${rom[0]}/gamelist.xml; then sed -i "1i <gameList>" /userdata/roms/${rom[0]}/gamelist.xml; fi
  if ! grep -Fxq "</gameList>" /userdata/roms/${rom[0]}/gamelist.xml; then sed -i "\$a </gameList>" /userdata/roms/${rom[0]}/gamelist.xml; fi
done
cp /usr/share/emulationstation/es_systems.cfg /usr/share/emulationstation/es_systems.bak
wget -O /usr/share/emulationstation/es_systems.cfg https://github.com/WizzardSK/gameflix/raw/main/batocera/share/system/es_systems.cfg > /dev/null 2>&1
chvt 2; wget http://127.0.0.1:1234/reloadgames > /dev/null 2>&1
