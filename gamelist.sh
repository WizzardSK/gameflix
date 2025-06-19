#!/bin/bash
sudo -v ; curl https://rclone.org/install.sh | sudo bash > /dev/null
mkdir -p ~/rom ~/roms ~/zip ~/atari2600roms ~/roms/neogeo ~/mount ~/uzebox ~/roms/uzebox ~/roms/tic80 ~/roms/wasm4 ~/roms/lowresnx ~/roms/pico8 ~/roms/voxatron
sudo apt install fuse-zip > /dev/null
rclone mount myrient: ~/rom --config=rclone.conf --daemon --http-no-head

echo "Uzebox"; wget -nv -O uzebox.zip https://github.com/WizzardSK/gameflix/raw/refs/heads/main/fantasy/uzebox.zip > /dev/null; unzip -j uzebox.zip -d ~/uzebox > /dev/null
echo "<gameList>" > ~/roms/uzebox/gamelist.xml; ls ~/uzebox/*.uze ~/uzebox/*.UZE 2>/dev/null | xargs -I {} basename {} | while read line; do
  line2=${line%.*}; hra="<game><path>./Uzebox/${line}</path><name>${line2}</name><image>~/../thumbs/Uzebox/Named_Snaps/${line2}.png</image>"; echo "${hra}</game>" >> ~/roms/uzebox/gamelist.xml
done; echo "</gameList>" >> ~/roms/uzebox/gamelist.xml

echo "TIC-80"; echo "<gameList>" > ~/roms/tic80/gamelist.xml; curl -s "https://tic80.com/api?fn=dir&path=play/Games" | while read -r line; do
  hash=$(echo "$line" | grep -oP 'hash\s*=\s*"\K[a-f0-9]+'); name=$(echo "$line" | grep -oP ' name\s*=\s*"\K[^"]+');
  hra="<game><path>./TIC-80/${hash}.tic</path><name>${name%.*}</name><image>./TIC-80/${hash}.gif</image>"; if [ -n "$hash" ]; then echo "${hra}</game>" >> ~/roms/tic80/gamelist.xml; fi;
done; echo "</gameList>" >> ~/roms/tic80/gamelist.xml

echo "WASM-4"; echo "<gameList>" > ~/roms/wasm4/gamelist.xml; html=$(curl -s "https://wasm4.org/play/")
echo "$html" | grep -oP '<img src="/carts/[^"]+\.png" alt="[^"]+"' | while read -r line; do
  image=$(echo "$line" | grep -oP '(?<=src=")/carts/[^"]+'); title=$(echo "$line" | grep -oP '(?<=alt=")[^"]+'); image_name=$(basename "$image" .png);
  hra="<game><path>./WASM-4/${image_name}.wasm</path><name>${title}</name><image>./WASM-4/${image_name}.png</image>"; echo "${hra}</game>" >> ~/roms/wasm4/gamelist.xml
done; echo "</gameList>" >> ~/roms/wasm4/gamelist.xml

echo "LowresNX"; echo "<gameList>" > ~/roms/lowresnx/gamelist.xml; cat fantasy/lowresnx.txt | while IFS=$'\t' read -r id name picture cart; do
  hra="<game><path>./LowresNX/${cart}</path><name>${name}</name><image>./LowresNX/${picture}</image>"; echo "${hra}</game>" >> ~/roms/lowresnx/gamelist.xml
done; echo "</gameList>" >> ~/roms/lowresnx/gamelist.xml

echo "Pico-8"; echo "<gameList>" > ~/roms/pico8/gamelist.xml; cat fantasy/pico8.txt | while IFS=$'\t' read -r id name cart; do
  hra="<game><path>./PICO-8/${cart}</path><name>${name}</name>"; echo "${hra}</game>" >> ~/roms/pico8/gamelist.xml
done; echo "</gameList>" >> ~/roms/pico8/gamelist.xml

echo "Voxatron"; echo "<gameList>" > ~/roms/voxatron/gamelist.xml; cat fantasy/voxatron.txt | while IFS=$'\t' read -r id name cart; do
  hra="<game><path>./Voxatron/${cart}</path><name>${name}</name>"; echo "${hra}</game>" >> ~/roms/voxatron/gamelist.xml
done; echo "</gameList>" >> ~/roms/voxatron/gamelist.xml

IFS=$'\n' read -d '' -ra roms < platforms.txt
IFS=";"; for each in "${roms[@]}"; do read -ra rom < <(printf '%s' "$each"); mkdir -p ~/mount/${rom[0]} ~/roms/${rom[0]}; done
for each in "${roms[@]}"; do 
  read -ra rom < <(printf '%s' "$each")
  rom3=$(sed 's/<[^>]*>//g' <<< "${rom[3]}")
  echo ${rom3}
  mkdir -p ~/mount/${rom[0]}/${rom3}
  if [[ ${rom[1]} =~ \.zip$ ]]; then
    ./batocera/ratarmount ~/rom/${rom[1]} ~/mount/${rom[0]}/${rom3} > /dev/null
    folder="$HOME/mount/${rom[0]}/${rom3}"
  else folder="$HOME/rom/${rom[1]}"; fi
  if grep -q ":" <<< "${rom[1]}"; then
    mkdir -p ~/mount/${rom[0]}/${rom3}
    folder="$HOME/mount/${rom[0]}/${rom3}"
    rclone mount ${rom[1]} ~/mount/${rom[0]}/${rom3} --daemon --config=rclone.conf --http-no-head
  fi
  if ! grep -Fxq "<gameList>" ~/roms/${rom[0]}/gamelist.xml > /dev/null 2>&1; then
    ls "${folder}" | while read line; do
      line2=${line%.*}
      hra="<game><path>./${rom3}/${line}</path><name>${line2}</name><image>~/../thumbs/${rom[2]}/Named_Snaps/${line2}.png</image><titleshot>~/../thumbs/${rom[2]}/Named_Titles/${line2}.png</titleshot><thumbnail>~/../thumbs/${rom[2]}/Named_Boxarts/${line2}.png</thumbnail><marquee>~/../thumbs/${rom[2]}/Named_Logos/${line2}.png</marquee>"
      if ! grep -iqE '\[(bios|a[0-9]{0,2}|b[0-9]{0,2}|c|f|h ?.*|o ?.*|p ?.*|t ?.*|cr ?.*)\]|\((demo( [0-9]+)?|beta( [0-9]+)?|alpha( [0-9]+)?|(disk|side)( [2-9B-Z]).*|pre-release|aftermarket|alt|alternate|unl|channel|system|dlc)\)' <<< "$line"; then
        echo "${hra}</game>" >> ~/roms/${rom[0]}/gamelist.xml
      else echo "${hra}<hidden>true</hidden></game>" >> ~/roms/${rom[0]}/gamelist.xml; fi    
    done
    echo "<folder><path>./${rom3}</path><name>${rom3}</name><image>~/../thumb/${rom[0]}.png</image></folder>" >> ~/roms/${rom[0]}/gamelist.xml
  fi
done

echo "Atari 2600 ROMS"; wget -nv -O atari2600roms.zip https://www.atarimania.com/roms/Atari-2600-VCS-ROM-Collection.zip > /dev/null
fuse-zip atari2600roms.zip ~/atari2600roms
ls ~/atari2600roms/ROMS | while read line; do
  line2=${line%.*}
  hra="<game><path>./Atari 2600 ROMS/${line}</path><name>${line2}</name><image>~/../thumbs/Atari - 2600/Named_Snaps/${line2}.png</image><titleshot>~/../thumbs/Atari - 2600/Named_Titles/${line2}.png</titleshot><thumbnail>~/../thumbs/Atari - 2600/Named_Boxarts/${line2}.png</thumbnail><marquee>~/../thumbs/Atari - 2600/Named_Logos/${line2}.png</marquee>"
  if ! grep -iqE '\[(bios|a[0-9]{0,2}|b[0-9]{0,2}|c|f|h ?.*|o ?.*|p ?.*|t ?.*|cr ?.*)\]|\((demo( [0-9]+)?|beta( [0-9]+)?|alpha( [0-9]+)?|(disk|side)( [2-9B-Z]).*|pre-release|aftermarket|alt|alternate|unl|channel|system|dlc)\)' <<< "$line"; then
    echo "${hra}</game>" >> ~/roms/atari2600/gamelist.xml
  else echo "${hra}<hidden>true</hidden></game>" >> ~/roms/atari2600/gamelist.xml; fi
done; echo "<folder><path>./Atari 2600 ROMS</path><name>Atari 2600 ROMS</name><image>~/../thumb/atari2600.png</image></folder>" >> ~/roms/atari2600/gamelist.xml

for each in "${roms[@]}"; do 
  read -ra rom < <(printf '%s' "$each")
  if ! grep -Fxq "<gameList>" ~/roms/${rom[0]}/gamelist.xml; then sed -i "1i <gameList>" ~/roms/${rom[0]}/gamelist.xml; fi
  if ! grep -Fxq "</gameList>" ~/roms/${rom[0]}/gamelist.xml; then sed -i "\$a </gameList>" ~/roms/${rom[0]}/gamelist.xml; fi
done

echo "Neo Geo"; ROMLIST="neogeo.dat"; HTMLFILES=("$HOME/roms/neogeo/gamelist.xml")
for HTMLFILE in "${HTMLFILES[@]}"; do
  while IFS=$'\t' read -r filename title; do
    base="${filename%.*}"; escaped_title=$(printf '%s\n' "$title" | sed 's/[&/\]/\\&/g'); sed -i -E "s/${base}</${escaped_title}</g" "$HTMLFILE"
  done < "$ROMLIST"
done

cd ~/roms
zip -r "$GITHUB_WORKSPACE/batocera/gamelist.zip" *
cd "$GITHUB_WORKSPACE"
git config --global user.name "GitHub Actions"
git config --global user.email "actions@github.com"
git add "$GITHUB_WORKSPACE/batocera/gamelist.zip"
git commit -m "Auto update ($(date +'%Y-%m-%d %H:%M:%S'))"
git push
