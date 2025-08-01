#!/bin/bash
shopt -s nocasematch
mkdir -p ~/{rom,gamelists,zip,zips,atari2600roms,mount,uzebox,vircon32} ~/gamelists/{neogeo,uzebox,tic80,wasm4,lowresnx,vircon32,pico8,voxatron,dos} ~/mount/dos/MS-DOS\ eXoDOS
sudo apt install fuse-zip > /dev/null
rclone mount myrient: ~/rom --config=rclone.conf --daemon --http-no-head
rclone mount archive:all_vircon32_roms_and_media/all_vircon32_roms_and_media ~/vircon32 --daemon --config=rclone.conf
rclone mount eye:Games/eXo/eXoDOS_v6r2/eXo/eXoDOS/ ~/mount/dos/MS-DOS\ eXoDOS --daemon --config=rclone.conf --http-no-head

echo "Uzebox"; unzip -j fantasy/uzebox.zip -d ~/uzebox > /dev/null
echo "<gameList>" > ~/gamelists/uzebox/gamelist.xml; ls ~/uzebox/*.uze ~/uzebox/*.UZE 2>/dev/null | xargs -I {} basename {} | while read line; do
  line2=${line%.*}; hra="<game><path>./Uzebox/${line}</path><name>${line2}</name><image>~/../thumbs/Uzebox/Named_Snaps/${line2}.png</image>"; echo "${hra}</game>" >> ~/gamelists/uzebox/gamelist.xml
done; echo "</gameList>" >> ~/gamelists/uzebox/gamelist.xml
echo "TIC-80"; echo "<gameList>" > ~/gamelists/tic80/gamelist.xml; curl -s "https://tic80.com/api?fn=dir&path=play/Games" | while read -r line; do
  hash=$(echo "$line" | grep -oP 'hash\s*=\s*"\K[a-f0-9]+'); name=$(echo "$line" | grep -oP ' name\s*=\s*"\K[^"]+');
  hra="<game><path>./TIC-80/${hash}.tic</path><name>${name%.*}</name><image>./TIC-80/${hash}.gif</image>"; if [ -n "$hash" ]; then echo "${hra}</game>" >> ~/gamelists/tic80/gamelist.xml; fi;
done; echo "</gameList>" >> ~/gamelists/tic80/gamelist.xml
echo "WASM-4"; echo "<gameList>" > ~/gamelists/wasm4/gamelist.xml; html=$(curl -s "https://wasm4.org/play/")
echo "$html" | grep -oP '<img src="/carts/[^"]+\.png" alt="[^"]+"' | while read -r line; do
  image=$(echo "$line" | grep -oP '(?<=src=")/carts/[^"]+'); title=$(echo "$line" | grep -oP '(?<=alt=")[^"]+'); image_name=$(basename "$image" .png);
  hra="<game><path>./WASM-4/${image_name}.wasm</path><name>${title}</name><image>./WASM-4/${image_name}.png</image>"; echo "${hra}</game>" >> ~/gamelists/wasm4/gamelist.xml
done; echo "</gameList>" >> ~/gamelists/wasm4/gamelist.xml
echo "LowresNX"; echo "<gameList>" > ~/gamelists/lowresnx/gamelist.xml; cat fantasy/lowresnx.txt | while IFS=$'\t' read -r id name picture cart; do
  hra="<game><path>./LowresNX/${cart}</path><name>${name}</name><image>./LowresNX/${picture}</image>"; echo "${hra}</game>" >> ~/gamelists/lowresnx/gamelist.xml
done; echo "</gameList>" >> ~/gamelists/lowresnx/gamelist.xml
echo "Vircon32"; echo "<gameList>" > ~/gamelists/vircon32/gamelist.xml; basename -a ~/vircon32/*.zip | while read line; do
  line2=${line%.*}; hra="<game><path>./Vircon32/${line}</path><name>${line2}</name><image>~/../thumbs/Vircon32/Named_Snaps/${line2}.png</image>"; echo "${hra}</game>" >> ~/gamelists/vircon32/gamelist.xml
done; echo "</gameList>" >> ~/gamelists/vircon32/gamelist.xml
echo "Pico-8"; echo "<gameList>" > ~/gamelists/pico8/gamelist.xml; cat fantasy/pico8.txt | while IFS=$'\t' read -r id name cart; do
  hra="<game><path>./PICO-8/${cart}</path><name>${name}</name>"; echo "${hra}</game>" >> ~/gamelists/pico8/gamelist.xml
done; echo "<folder><path>./PICO-8</path><name>PICO-8</name><image>./splore.png</image></folder></gameList>" >> ~/gamelists/pico8/gamelist.xml
echo "Voxatron"; echo "<gameList>" > ~/gamelists/voxatron/gamelist.xml; cat fantasy/voxatron.txt | while IFS=$'\t' read -r id name cart; do
  hra="<game><path>./Voxatron/${cart}</path><name>${name}</name>"; echo "${hra}</game>" >> ~/gamelists/voxatron/gamelist.xml
done; echo "<folder><path>./Voxatron</path><name>Voxatron</name><image>./splore.png</image></folder></gameList>" >> ~/gamelists/voxatron/gamelist.xml

IFS=$'\n' read -d '' -ra roms < platforms.txt
IFS=";"; for each in "${roms[@]}"; do read -ra rom < <(printf '%s' "$each"); mkdir -p ~/mount/${rom[0]} ~/gamelists/${rom[0]}; done
for each in "${roms[@]}"; do 
  read -ra rom < <(printf '%s' "$each"); rom3=$(sed 's/<[^>]*>//g' <<< "${rom[3]}"); echo ${rom3}
  folder="$HOME/rom/${rom[1]}"; if [[ "${rom[1]}" == "../gamelists/dos/MS-DOS eXoDOS" ]]; then folder=~/mount/dos/MS-DOS\ eXoDOS; fi
  ls "${folder}" | while read line; do
    line2=${line%.*}
    hra="<game><path>./${rom3}/${line}</path><name>${line2}</name><image>~/../thumbs/${rom[2]}/Named_Snaps/${line2}.png</image><titleshot>~/../thumbs/${rom[2]}/Named_Titles/${line2}.png</titleshot><thumbnail>~/../thumbs/${rom[2]}/Named_Boxarts/${line2}.png</thumbnail><marquee>~/../thumbs/${rom[2]}/Named_Logos/${line2}.png</marquee>"
    if [[ ! "$line" =~ \[(bios|a[0-9]{0,2}|b[0-9]{0,2}|c|f|h ?.*|o ?.*|p ?.*|t ?.*|cr ?.*)\]|\((demo( [0-9]+)?|beta( [0-9]+)?|alpha( [0-9]+)?|(disk|side)( [2-9B-Z]).*|pre-release|aftermarket|alt|alternate|unl|channel|system|dlc)\) ]]; then      
      echo "${hra}</game>" >> ~/gamelists/${rom[0]}/gamelist.xml
    else echo "${hra}<hidden>true</hidden></game>" >> ~/gamelists/${rom[0]}/gamelist.xml; fi    
  done
  echo "<folder><path>./${rom3}</path><name>${rom3}</name><image>~/../thumb/${rom[0]}.png</image></folder>" >> ~/gamelists/${rom[0]}/gamelist.xml
done

echo "Atari 2600 ROMS"; ./batocera/ratarmount1 https://www.atarimania.com/gamelists/Atari-2600-VCS-ROM-Collection.zip ~/atari2600roms -f &
while ! mount | grep -q "on /home/runner/atari2600roms "; do sleep 1; done
ls ~/atari2600roms/gamelists | while read line; do
  line2=${line%.*}
  hra="<game><path>./Atari 2600 ROMS/${line}</path><name>${line2}</name><image>~/../thumbs/Atari - 2600/Named_Snaps/${line2}.png</image><titleshot>~/../thumbs/Atari - 2600/Named_Titles/${line2}.png</titleshot><thumbnail>~/../thumbs/Atari - 2600/Named_Boxarts/${line2}.png</thumbnail><marquee>~/../thumbs/Atari - 2600/Named_Logos/${line2}.png</marquee>"
  if [[ ! "$line" =~ \[(bios|a[0-9]{0,2}|b[0-9]{0,2}|c|f|h ?.*|o ?.*|p ?.*|t ?.*|cr ?.*)\]|\((demo( [0-9]+)?|beta( [0-9]+)?|alpha( [0-9]+)?|(disk|side)( [2-9B-Z]).*|pre-release|aftermarket|alt|alternate|unl|channel|system|dlc)\) ]]; then      
    echo "${hra}</game>" >> ~/gamelists/atari2600/gamelist.xml
  else echo "${hra}<hidden>true</hidden></game>" >> ~/gamelists/atari2600/gamelist.xml; fi
done; echo "<folder><path>./Atari 2600 ROMS</path><name>Atari 2600 ROMS</name><image>~/../thumb/atari2600.png</image></folder>" >> ~/gamelists/atari2600/gamelist.xml

for each in "${roms[@]}"; do 
  read -ra rom < <(printf '%s' "$each")
  if ! grep -Fxq "<gameList>" ~/gamelists/${rom[0]}/gamelist.xml; then sed -i "1i <gameList>" ~/gamelists/${rom[0]}/gamelist.xml; fi
  if ! grep -Fxq "</gameList>" ~/gamelists/${rom[0]}/gamelist.xml; then sed -i "\$a </gameList>" ~/gamelists/${rom[0]}/gamelist.xml; fi
done

echo "Neo Geo"; echo "<gameList>" > ~/gamelists/neogeo/gamelist.xml; ROMLIST="neogeo.dat";
while IFS= read -r riadok; do
  prvy="${riadok%%[[:space:]]*}"; ostatok="${riadok#*[[:space:]]}"; zip="${prvy%.neo}.zip"
  hra="<game><path>./Neo Geo/${zip}</path><name>${ostatok}</name><image>~/../thumbs/MAME/Named_Snaps/${prvy%.neo}.png</image><titleshot>~/../thumbs/MAME/Named_Titles/${prvy%.neo}.png</titleshot><thumbnail>~/../thumbs/MAME/Named_Boxarts/${prvy%.neo}.png</thumbnail><marquee>~/../thumbs/MAME/Named_Logos/${prvy%.neo}.png</marquee>"
  echo "${hra}</game>" >> ~/gamelists/neogeo/gamelist.xml  
done < "$ROMLIST"
echo "<folder><path>./Neo Geo</path><name>Neo Geo</name><image>~/../thumb/neogeo.png</image></folder></gameList>" >> ~/gamelists/neogeo/gamelist.xml

cd ~/gamelists
rm -f "$GITHUB_WORKSPACE/batocera/gamelist.zip"
zip -r "$GITHUB_WORKSPACE/batocera/gamelist.zip" *
cd "$GITHUB_WORKSPACE"
git config --global user.name "GitHub Actions"
git config --global user.email "actions@github.com"
git add "$GITHUB_WORKSPACE/batocera/gamelist.zip"
git commit -m "Auto update ($(date +'%Y-%m-%d %H:%M:%S'))"
git push
