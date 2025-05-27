#!/bin/bash

wget -O rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/rclone.conf > /dev/null 2>&1
sudo -v ; curl https://rclone.org/install.sh | sudo bash  > /dev/null 2>&1
sudo apt install fuse-zip bindfs
mkdir -p ~/rom ~/roms ~/zip ~/zip/atari2600roms ~/dos ~/roms/neogeo 
rclone mount myrient: ~/rom --config=rclone.conf --daemon

IFS=$'\n' read -d '' -ra roms <<< "$(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.txt)"
IFS=";"; for each in "${roms[@]}"; do read -ra rom < <(printf '%s' "$each"); mkdir -p ~/roms/${rom[0]}; done
for each in "${roms[@]}"; do 
  read -ra rom < <(printf '%s' "$each")
  rom3=$(sed 's/<[^>]*>//g' <<< "${rom[3]}")
  mkdir -p ~/roms/${rom[0]}/${rom3}
  sudo mount -o bind ~/rom/${rom[1]} ~/roms/${rom[0]}/${rom3}
  if ! grep -Fxq "<gameList>" ~/roms/${rom[0]}/gamelist.xml > /dev/null 2>&1; then
    ls ~/rom/${rom[1]} | while read line; do
      line2=${line%.*}
      hra="<game><path>./${rom3}/${line}</path><name>${line2}</name><image>~/../thumbs/${rom[2]}/Named_Snaps/${line2}.png</image><titleshot>~/../thumbs/${rom[2]}/Named_Titles/${line2}.png</titleshot><thumbnail>~/../thumbs/${rom[2]}/Named_Boxarts/${line2}.png</thumbnail><marquee>~/../thumbs/${rom[2]}/Named_Logos/${line2}.png</marquee>"
      if ! grep -iqE '\[(bios|a[0-9]{0,2}|b[0-9]{0,2}|c|f|h ?.*|o ?.*|p ?.*|t ?.*|cr ?.*)\]|\((demo( [0-9]+)?|beta( [0-9]+)?|alpha( [0-9]+)?|(disk|side)( [2-9B-Z]).*|pre-release|aftermarket|alt|alternate|unl|channel|system|dlc)\)' <<< "$line"; then
        echo "${hra}</game>" >> ~/roms/${rom[0]}/gamelist.xml
      else echo "${hra}<hidden>true</hidden></game>" >> ~/roms/${rom[0]}/gamelist.xml; fi    
    done
    echo "<folder><path>./${rom3}</path><name>${rom3}</name><image>~/../thumb/${rom[0]}.png</image></folder>" >> ~/roms/${rom[0]}/gamelist.xml
  fi
done

for each in "${roms[@]}"; do 
  read -ra rom < <(printf '%s' "$each")
  if ! grep -Fxq "<gameList>" ~/roms/${rom[0]}/gamelist.xml; then sed -i "1i <gameList>" ~/roms/${rom[0]}/gamelist.xml; fi
  if ! grep -Fxq "</gameList>" ~/roms/${rom[0]}/gamelist.xml; then sed -i "\$a </gameList>" ~/roms/${rom[0]}/gamelist.xml; fi
done

tree ~/roms
cat ~/roms/atari2600/gamelist.xml
