#!/bin/bash

#if [ ! -f ~/fuse-zip ];   then wget -O ~/fuse-zip   https://github.com/WizzardSK/gameflix/raw/main/batocera/fuse-zip;  chmod +x ~/fuse-zip; fi
if [ ! -f ~/atari2600roms.zip ]; then wget -O ~/atari2600roms.zip https://www.atarimania.com/roms/Atari-2600-VCS-ROM-Collection.zip; fi

sudo -v ; curl https://rclone.org/install.sh | sudo bash
sudo apt install fuse-zip
mkdir -p ~/rom ~/roms ~/zip ~/zip/atari2600roms ~/dos
rclone mount ":http,urls=https://myrient.erista.me/files/" ~/rom --daemon

fuse-zip ~/atari2600roms.zip ~/zip/atari2600roms
IFS=$'\n' read -d '' -ra roms <<< "$(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.txt)"

IFS=";"; for each in "${roms[@]}"; do read -ra rom < <(printf '%s' "$each"); mkdir -p ~/roms/${rom[0]}; done
for each in "${roms[@]}"; do 
  read -ra rom < <(printf '%s' "$each")
  #if [ ! -f ~/userdata/thumb/${rom[0]}.png ]; then wget -nv -O /userdata/thumb/${rom[0]}.png https://raw.githubusercontent.com/fabricecaruso/es-theme-carbon/master/art/consoles/${rom[0]}.png; fi
  rom3=$(sed 's/<[^>]*>//g' <<< "${rom[3]}")
  echo "${rom3}"; mkdir -p ~/roms/${rom[0]}/${rom3}
#  if [[ ${rom[1]} =~ \.zip$ ]]; then
#    if [ ! -f ~/zip/${rom3}.zip ]; then wget -O ~/zip/${rom3}.zip https://myrient.erista.me/files/${rom[1]}; fi
#    fuse-zip ~/zip/${rom3}.zip ~/roms/${rom[0]}/${rom3}
#  else
#    if grep -q ":" <<< "${rom[1]}"; then
#      rclone mount ${rom[1]} ~/roms/${rom[0]}/${rom3} --http-no-head --no-checksum --no-modtime --dir-cache-time 1000h --allow-non-empty --attr-timeout 1000h --poll-interval 1000h --daemon --config=/userdata/system/rclone.conf
#    else sudo mount -o bind ~/rom/${rom[1]} ~/roms/${rom[0]}/${rom3}; fi
#  fi
  if ! grep -Fxq "<gameList>" ~/roms/${rom[0]}/gamelist.xml > /dev/null 2>&1; then
    ls ~/roms/${rom[0]}/${rom3} | while read line; do
      line2=${line%.*}
      hra="<game><path>./${rom3}/${line}</path><name>${line2}</name><image>~/../thumbs/${rom[2]}/Named_Snaps/${line2}.png</image><titleshot>~/../thumbs/${rom[2]}/Named_Titles/${line2}.png</titleshot><thumbnail>~/../thumbs/${rom[2]}/Named_Boxarts/${line2}.png</thumbnail><marquee>~/../thumbs/${rom[2]}/Named_Logos/${line2}.png</marquee>"
      if ! grep -iqE '\[(bios|a[0-9]{0,2}|b[0-9]{0,2}|c|f|h ?.*|o ?.*|p ?.*|t ?.*|cr ?.*)\]|\((demo( [0-9]+)?|beta( [0-9]+)?|alpha( [0-9]+)?|(disk|side)( [2-9B-Z]).*|pre-release|aftermarket|alt|alternate|unl|channel|system|dlc)\)' <<< "$line"; then
        echo "${hra}</game>" >> ~/roms/${rom[0]}/gamelist.xml
      else echo "${hra}<hidden>true</hidden></game>" >> ~/roms/${rom[0]}/gamelist.xml; fi    
    done
    echo "<folder><path>./${rom3}</path><name>${rom3}</name><image>~/../thumb/${rom[0]}.png</image></folder>" >> ~/roms/${rom[0]}/gamelist.xml
  fi
done

ls ~/roms/atari2600/Atari\ 2600\ ROMS | while read line; do
  line2=${line%.*}
  hra="<game><path>./Atari 2600 ROMS/${line}</path><name>${line2}</name><image>~/../thumbs/Atari - 2600/Named_Snaps/${line2}.png</image><titleshot>~/../thumbs/Atari - 2600/Named_Titles/${line2}.png</titleshot><thumbnail>~/../thumbs/Atari - 2600/Named_Boxarts/${line2}.png</thumbnail><marquee>~/../thumbs/Atari - 2600/Named_Logos/${line2}.png</marquee>"
  if ! grep -iqE '\[(bios|a[0-9]{0,2}|b[0-9]{0,2}|c|f|h ?.*|o ?.*|p ?.*|t ?.*|cr ?.*)\]|\((demo( [0-9]+)?|beta( [0-9]+)?|alpha( [0-9]+)?|(disk|side)( [2-9B-Z]).*|pre-release|aftermarket|alt|alternate|unl|channel|system|dlc)\)' <<< "$line"; then
    echo "${hra}</game>" >> ~/roms/atari2600/gamelist.xml
  else echo "${hra}<hidden>true</hidden></game>" >> ~/roms/atari2600/gamelist.xml; fi    
done; echo "<folder><path>./Atari 2600 ROMS</path><name>Atari 2600 ROMS</name><image>~/../thumb/atari2600.png</image></folder>" >> ~/atari2600/gamelist.xml

for each in "${roms[@]}"; do 
  read -ra rom < <(printf '%s' "$each")
  if ! grep -Fxq "<gameList>" ~/roms/${rom[0]}/gamelist.xml; then sed -i "1i <gameList>" ~/roms/${rom[0]}/gamelist.xml; fi
  if ! grep -Fxq "</gameList>" ~/roms/${rom[0]}/gamelist.xml; then sed -i "\$a </gameList>" ~/roms/${rom[0]}/gamelist.xml; fi
done

ROMLIST="neogeo.dat"; curl -s "https://raw.githubusercontent.com/WizzardSK/gameflix/refs/heads/main/neogeo.dat" -o "$ROMLIST"
HTMLFILES=("~/roms/neogeo/gamelist.xml")
for HTMLFILE in "${HTMLFILES[@]}"; do
  while IFS=$'\t' read -r filename title; do
    base="${filename%.*}"; escaped_title=$(printf '%s\n' "$title" | sed 's/[&/\]/\\&/g')
    sed -i -E "s/${base}</${escaped_title}</g" "$HTMLFILE"
  done < "$ROMLIST"
done
