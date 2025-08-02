#!/bin/bash
mkdir -p ~/gameflix
IFS=$'\n' read -d '' -ra roms < platforms.txt
echo "<link rel=\"stylesheet\" type=\"text/css\" href=\"style.css\" />" > ~/gameflix/systems.html; cp ~/gameflix/systems.html ~/gameflix/main.html
echo "<link rel=\"icon\" type=\"image/png\" href=\"/favicon.png\"><title>gameflix</title><frameset border=0 cols='260, 100%'><frame name='menu' src='systems.html'><frame name='main' src='main.html'></frameset>" > ~/gameflix/index.html
for file in retroarch.sh style.css script.js platform.js; do cp $file ~/gameflix/$file; done

echo "<figure><a href='TIC-80.html'><img class=loaded src='https://raw.githubusercontent.com/fabricecaruso/es-theme-carbon/master/art/consoles/tic80.png'></a><figcaption>TIC-80</figcaption></figure>
<figure><a href='WASM-4.html'><img class=loaded src='https://raw.githubusercontent.com/fabricecaruso/es-theme-carbon/master/art/consoles/wasm4.png'></a><figcaption>WASM-4</figcaption></figure>
<figure><a href='Uzebox.html'><img class=loaded src='https://raw.githubusercontent.com/fabricecaruso/es-theme-carbon/master/art/consoles/uzebox.png'></a><figcaption>Uzebox</figcaption></figure>
<figure><a href='LowresNX.html'><img class=loaded src='https://raw.githubusercontent.com/fabricecaruso/es-theme-carbon/master/art/consoles/lowresnx.png'></a><figcaption>LowresNX</figcaption></figure>
<figure><a href='PICO-8.html'><img class=loaded src='https://raw.githubusercontent.com/fabricecaruso/es-theme-carbon/master/art/consoles/pico8.png'></a><figcaption>PICO-8</figcaption></figure>
<figure><a href='Voxatron.html'><img class=loaded src='https://wiki.batocera.org/_media/systems:voxatron.png'></a><figcaption>Voxatron</figcaption></figure>
<figure><a href='Vircon32.html'><img class=loaded src='https://fantasyconsoles.org/w/images/9/9c/Vircon32-logo.png'></a><figcaption>Vircon32</figcaption></figure>" >> ~/gameflix/main.html

pocet=$(ls ~/roms/TIC-80/*.tic | wc -l); total=$((pocet+total))
echo "<a href=\"TIC-80.html\" target=\"main\">TIC-80</a> ($pocet)<br />" >> ~/gameflix/systems.html; echo "*\"TIC-80\") core=\"tic80_libretro\";;" >> ~/gameflix/retroarch.sh  
echo "TIC-80"; cp platform.html ~/gameflix/TIC-80.html; echo "<script>bgImage(\"tic80\"); const fileNames = [" >> ~/gameflix/TIC-80.html; ((platforms++))
data=$(curl -s "https://tic80.com/api?fn=dir&path=play/Games" | sed 's/},/}\n/g'); records=(); while IFS= read -r line; do
  if [[ "$line" =~ id[[:space:]]*=[[:space:]]*([0-9]+) ]]; then id="${BASH_REMATCH[1]}"; else continue; fi
  if [[ "$line" =~ hash[[:space:]]*=[[:space:]]*\"([a-f0-9]+)\" ]]; then hash="${BASH_REMATCH[1]}"; else continue; fi
  if [[ "$line" =~ name[[:space:]]*=[[:space:]]*\"([^\"]+)\" ]]; then name="${BASH_REMATCH[1]%.tic}"; else continue; fi
  records+=("$id"$'\t'"$hash"$'\t'"$name")
done <<< "$data"
printf "%s\n" "${records[@]}" | sort -nr -k1,1 | awk '{ print "\"" $0 "\"," }' >> ~/gameflix/TIC-80.html
printf ']; generateTicLinks("roms/TIC-80", "TIC-80");</script><script src=\"script.js\"></script>' >> ~/gameflix/TIC-80.html

pocet=$(ls ~/roms/WASM-4/*.wasm | wc -l); total=$((pocet+total))
echo "<a href=\"WASM-4.html\" target=\"main\">WASM-4</a> ($pocet)<br />" >> ~/gameflix/systems.html; echo "*\"WASM-4\") core=\"wasm4_libretro\";;" >> ~/gameflix/retroarch.sh  
echo "WASM-4"; cp platform.html ~/gameflix/WASM-4.html; echo "<script>bgImage(\"wasm4\"); const fileNames = [" >> ~/gameflix/WASM-4.html; ((platforms++))
html=$(curl -s "https://wasm4.org/play/"); echo "$html" | grep -oP '<img src="/carts/[^"]+\.png" alt="[^"]+"' | while read -r line; do
  image=$(echo "$line" | grep -oP '(?<=src=")/carts/[^"]+'); title=$(echo "$line" | grep -oP '(?<=alt=")[^"]+'); image_name=$(basename "$image" .png); echo -e "\"$image_name\t$title\"," >> ~/gameflix/WASM-4.html
done; printf ']; generateWasmLinks("roms/WASM-4", "WASM-4");</script><script src=\"script.js\"></script>' >> ~/gameflix/WASM-4.html

pocet=$(curl -s "https://raw.githubusercontent.com/WizzardSK/gameflix/refs/heads/main/fantasy/uzebox.txt" | wc -l); total=$((pocet+total))
echo "<a href=\"Uzebox.html\" target=\"main\">Uzebox</a> ($pocet)<br />" >> ~/gameflix/systems.html; echo "*\"Uzebox\") core=\"uzem_libretro\";;" >> ~/gameflix/retroarch.sh  
echo "Uzebox"; cp platform.html ~/gameflix/Uzebox.html; echo "<script>bgImage(\"uzebox\"); const fileNames = [" >> ~/gameflix/Uzebox.html; ((platforms++))
curl -s "https://raw.githubusercontent.com/WizzardSK/gameflix/refs/heads/main/fantasy/uzebox.txt" | while IFS=$'\t' read -r id cart name; do echo -e "\"$id\t$cart\t$name\"," >> ~/gameflix/Uzebox.html; done
printf ']; generateUzeLinks("roms/Uzebox", "Uzebox");</script><script src=\"script.js\"></script>' >> ~/gameflix/Uzebox.html

pocet=$(ls ~/roms/LowresNX/*.nx | wc -l); total=$((pocet+total))
echo "<a href=\"LowresNX.html\" target=\"main\">LowresNX</a> ($pocet)<br />" >> ~/gameflix/systems.html; echo "*\"LowresNX\") core=\"lowresnx_libretro\";;" >> ~/gameflix/retroarch.sh  
echo "LowresNX"; cp platform.html ~/gameflix/LowresNX.html; echo "<script>bgImage(\"lowresnx\"); const fileNames = [" >> ~/gameflix/LowresNX.html; ((platforms++))
curl -s "https://raw.githubusercontent.com/WizzardSK/gameflix/refs/heads/main/fantasy/lowresnx.txt" | while IFS=$'\t' read -r id name picture cart; do if [[ -n "$cart" && -n "$picture" ]]; then echo -e "\"$cart\t$picture\t$name\t$id\"," >> ~/gameflix/LowresNX.html; fi; done
printf ']; generateLrNXLinks("roms/LowresNX", "LowresNX");</script><script src=\"script.js\"></script>' >> ~/gameflix/LowresNX.html

pocet=$(curl -s "https://raw.githubusercontent.com/WizzardSK/gameflix/refs/heads/main/fantasy/pico8.txt" | wc -l); total=$((pocet+total))
echo "<a href=\"PICO-8.html\" target=\"main\">PICO-8</a> ($pocet)<br />" >> ~/gameflix/systems.html; echo "*\"PICO-8\") core=\"pico8 -run\";;" >> ~/gameflix/retroarch.sh  
echo "PICO-8"; cp platform.html ~/gameflix/PICO-8.html; echo "<script>bgImage(\"pico8\"); const fileNames = [" >> ~/gameflix/PICO-8.html; ((platforms++))
curl -s "https://raw.githubusercontent.com/WizzardSK/gameflix/refs/heads/main/fantasy/pico8.txt" | while IFS=$'\t' read -r id name cart; do echo -e "\"$id\t$name\t$cart\"," >> ~/gameflix/PICO-8.html; done
printf ']; generatePicoLinks("roms/PICO-8", "PICO-8");</script><script src=\"script.js\"></script>' >> ~/gameflix/PICO-8.html

pocet=$(curl -s "https://raw.githubusercontent.com/WizzardSK/gameflix/refs/heads/main/fantasy/voxatron.txt" | wc -l); total=$((pocet+total))
echo "<a href=\"Voxatron.html\" target=\"main\">Voxatron</a> ($pocet)<br />" >> ~/gameflix/systems.html; echo "*\"Voxatron\") core=\"vox\";;" >> ~/gameflix/retroarch.sh  
echo "Voxatron"; cp platform.html ~/gameflix/Voxatron.html; echo "<script>bgImage(\"voxatron\"); const fileNames = [" >> ~/gameflix/Voxatron.html; ((platforms++))
curl -s "https://raw.githubusercontent.com/WizzardSK/gameflix/refs/heads/main/fantasy/voxatron.txt" | while IFS=$'\t' read -r id name cart; do echo -e "\"$id\t$name\t$cart\"," >> ~/gameflix/Voxatron.html; done
printf ']; generateVoxLinks("roms/Voxatron", "Voxatron");</script><script src=\"script.js\"></script>' >> ~/gameflix/Voxatron.html

pocet=$(ls ~/roms/Vircon32/*.zip | wc -l); total=$((pocet+total))
echo "<a href=\"Vircon32.html\" target=\"main\">Vircon32</a> ($pocet)<br />" >> ~/gameflix/systems.html; echo "*\"Vircon32\") core=\"vircon32_libretro\";;" >> ~/gameflix/retroarch.sh  
echo "Vircon32"; cp platform.html ~/gameflix/Vircon32.html; echo "<script>bgImage(\"vircon32\"); const fileNames = [" >> ~/gameflix/Vircon32.html
{ while IFS= read -r line; do echo "\"${line}\"," >> ~/gameflix/Vircon32.html; ((pocet++)); ((total++)); done } < <(basename -a ~/roms/Vircon32/*.zip)
printf ']; generateFileLinks("roms/Vircon32", "Vircon32");</script><script src=\"script.js\"></script>' >> ~/gameflix/Vircon32.html

pocet=$(ls ~/roms/Atari\ 2600\ ROMS -1 | wc -l); total=$((pocet+total))
echo "<a href=\"Atari 2600 ROMS.html\" target=\"main\"><p>Atari 2600 ROMS</a> ($pocet)<br />" >> ~/gameflix/systems.html; echo "*\"Atari 2600 ROMS\") core=\"stella_libretro\";;" >> ~/gameflix/retroarch.sh  
echo "Atari 2600 ROMS"; cp platform.html ~/gameflix/Atari\ 2600\ ROMS.html; echo "<script>bgImage(\"atari2600\"); const fileNames = [" >> ~/gameflix/Atari\ 2600\ ROMS.html
{ while IFS= read -r line; do echo "\"${line}\"," >> ~/gameflix/Atari\ 2600\ ROMS.html; ((pocet++)); ((total++)); done } < <(ls ~/roms/Atari\ 2600\ ROMS)
printf ']; generateFileLinks("roms/Atari 2600 ROMS", "Atari_-_2600");</script><script src=\"script.js\"></script>' >> ~/gameflix/Atari\ 2600\ ROMS.html

#IFS=";"; for each in "${roms[@]}"; do
#  read -ra rom < <(printf '%s' "$each"); rom3=$(sed 's/<[^>]*>//g' <<< "${rom[3]}")
#  romfolder="myrient/${rom[1]}"; emufolder="${rom[1]}";
#  if [[ "${rom[1]}" == *"eXoDOS"* ]]; then romfolder="roms/MS-DOS eXoDOS"; emufolder="roms/MS-DOS eXoDOS"; fi
#  > ~/gameflix/${rom3}.html; echo ${rom3}; cp platform.html ~/gameflix/${rom3}.html
#  echo "<script>bgImage(\"${rom[0]}\"); const fileNames = [" >> ~/gameflix/${rom3}.html
#  pocet=0
#  { while IFS= read -r line; do echo "\"${line}\"," >> ~/gameflix/${rom3}.html; ((pocet++)); ((total++)); done } < <(ls ~/${romfolder})
#  echo ']; generateFileLinks("'"$romfolder"'", "'"${rom[2]// /_}"'");</script><script src="script.js"></script>' >> ~/gameflix/${rom3}.html
#  echo "<a href=\"${rom3}.html\" target=\"main\">${rom[3]}</a> ($pocet)<br />" >> ~/gameflix/systems.html
#  if [ "$platform" != "${rom[0]}" ]; then
#    echo "<figure><a href='${rom3}.html'><img class=loaded src='https://raw.githubusercontent.com/fabricecaruso/es-theme-carbon/master/art/consoles/"${rom[0]}".png'></a><figcaption>${rom[2]}</figcaption></figure>" >> ~/gameflix/main.html; ((platforms++))
#  fi
#  platform=${rom[0]}; ext=""; if [ -n "${rom[5]}" ]; then ext="; ext=\"${rom[5]}\""; fi; echo "*\"${emufolder}\") core=\"${rom[4]}\"${ext};;" >> ~/gameflix/retroarch.sh
#done

IFS=$'\n'; platform=""; platforms=0; total=0
for each in "${roms[@]}"; do
  IFS=";" read -ra rom <<< "$each"
  rom0="${rom[0]}"; rom1="${rom[1]}"; rom2="${rom[2]}"; rom3=$(sed 's/<[^>]*>//g' <<< "${rom[3]}"); rom4="${rom[4]}"; rom5="${rom[5]}"
  romfolder="myrient/$rom1"; emufolder="$rom1"
  [[ "$rom1" == *"eXoDOS"* ]] && romfolder="roms/MS-DOS eXoDOS" && emufolder="roms/MS-DOS eXoDOS"
  [[ "$rom1" == "../roms/dos/MS-DOS eXoDOS" ]] && romfolder="roms/MS-DOS eXoDOS"
  html="$HOME/gameflix/${rom3}.html"; > "$html"; cp platform.html "$html"
  echo "$rom3"; echo "<script>bgImage(\"$rom0\"); const fileNames = [" >> "$html"
  mkdir -p ~/mount/$rom0 ~/gamelists/$rom0; pocet=0
  for f in ~/"$romfolder"/*; do
    fn=$(basename "$f"); base="${fn%.*}"; echo "\"$fn\"," >> "$html"; ((pocet++)); ((total++))
    hra="<game><path>./${rom3}/${fn}</path><name>${base}</name><image>~/../thumbs/${rom2}/Named_Snaps/${base}.png</image><titleshot>~/../thumbs/${rom2}/Named_Titles/${base}.png</titleshot><thumbnail>~/../thumbs/${rom2}/Named_Boxarts/${base}.png</thumbnail><marquee>~/../thumbs/${rom2}/Named_Logos/${base}.png</marquee>"
    if [[ ! "$fn" =~ \[(bios|a[0-9]{0,2}|b[0-9]{0,2}|c|f|h ?.*|o ?.*|p ?.*|t ?.*|cr ?.*)\]|\((demo( [0-9]+)?|beta( [0-9]+)?|alpha( [0-9]+)?|(disk|side)( [2-9B-Z]).*|pre-release|aftermarket|alt|alternate|unl|channel|system|dlc)\) ]]; then
      echo "$hra</game>" >> ~/gamelists/$rom0/gamelist.xml
    else echo "$hra<hidden>true</hidden></game>" >> ~/gamelists/$rom0/gamelist.xml; fi
  done
  echo "]; generateFileLinks(\"$romfolder\", \"${rom2// /_}\");</script><script src=\"script.js\"></script>" >> "$html"
  echo "<a href=\"${rom3}.html\" target=\"main\">${rom[3]}</a> ($pocet)<br />" >> ~/gameflix/systems.html
  [[ "$platform" != "$rom0" ]] && echo "<figure><a href='${rom3}.html'><img class=loaded src='https://raw.githubusercontent.com/fabricecaruso/es-theme-carbon/master/art/consoles/${rom0}.png'></a><figcaption>${rom2}</figcaption></figure>" >> ~/gameflix/main.html && ((platforms++))
  echo "<folder><path>./${rom3}</path><name>${rom3}</name><image>~/../thumb/${rom0}.png</image></folder>" >> ~/gamelists/$rom0/gamelist.xml
  platform="$rom0"; ext=""; [[ -n "$rom5" ]] && ext="; ext=\"$rom5\""; echo "*\"$emufolder\") core=\"$rom4\"$ext;;" >> ~/gameflix/retroarch.sh
done

#IFS=";"; for each in "${roms[@]}"; do read -ra rom < <(printf '%s' "$each"); mkdir -p ~/mount/${rom[0]} ~/gamelists/${rom[0]}; done
#for each in "${roms[@]}"; do 
#  read -ra rom < <(printf '%s' "$each"); rom3=$(sed 's/<[^>]*>//g' <<< "${rom[3]}"); echo ${rom3}
#  folder="$HOME/myrient/${rom[1]}"; if [[ "${rom[1]}" == "../roms/dos/MS-DOS eXoDOS" ]]; then folder=~/roms/MS-DOS\ eXoDOS; fi
#  ls "${folder}" | while read line; do
#    line2=${line%.*}
#    hra="<game><path>./${rom3}/${line}</path><name>${line2}</name><image>~/../thumbs/${rom[2]}/Named_Snaps/${line2}.png</image><titleshot>~/../thumbs/${rom[2]}/Named_Titles/${line2}.png</titleshot><thumbnail>~/../thumbs/${rom[2]}/Named_Boxarts/${line2}.png</thumbnail><marquee>~/../thumbs/${rom[2]}/Named_Logos/${line2}.png</marquee>"
#    if [[ ! "$line" =~ \[(bios|a[0-9]{0,2}|b[0-9]{0,2}|c|f|h ?.*|o ?.*|p ?.*|t ?.*|cr ?.*)\]|\((demo( [0-9]+)?|beta( [0-9]+)?|alpha( [0-9]+)?|(disk|side)( [2-9B-Z]).*|pre-release|aftermarket|alt|alternate|unl|channel|system|dlc)\) ]]; then      
#      echo "${hra}</game>" >> ~/gamelists/${rom[0]}/gamelist.xml
#    else echo "${hra}<hidden>true</hidden></game>" >> ~/gamelists/${rom[0]}/gamelist.xml; fi    
#  done
#  echo "<folder><path>./${rom3}</path><name>${rom3}</name><image>~/../thumb/${rom[0]}.png</image></folder>" >> ~/gamelists/${rom[0]}/gamelist.xml
#done

ROMLIST="neogeo.dat"; curl -s "https://raw.githubusercontent.com/WizzardSK/gameflix/refs/heads/main/neogeo.dat" -o $ROMLIST; pocet=0
echo "Neo Geo"; cp platform.html ~/gameflix/Neo\ Geo.html; echo "<script>bgImage(\"neogeo\"); const fileNames = [" >> ~/gameflix/Neo\ Geo.html
while IFS= read -r riadok; do prvy="${riadok%%[[:space:]]*}"; ostatok="${riadok#*[[:space:]]}"; zip="${prvy%.neo}.zip"; printf '"%s\t%s",\n' "$zip" "$ostatok" >> ~/gameflix/Neo\ Geo.html; ((pocet++)); done < "$ROMLIST"
printf ']; generateFileLinks("roms/Neo Geo", "MAME");</script><script src=\"script.js\"></script>' >> ~/gameflix/Neo\ Geo.html; ((platforms++))
echo "<a href=\"Neo Geo.html\" target=\"main\">Neo Geo</a> ($pocet)<br />" >> ~/gameflix/systems.html; echo "*\"Neo Geo\") core=\"fbneo_libretro\";;" >> ~/gameflix/retroarch.sh  
echo "<figure><a href='Neo Geo.html'><img class=loaded src='https://raw.githubusercontent.com/fabricecaruso/es-theme-carbon/master/art/consoles/neogeo.png'></a><figcaption>Neo Geo</figcaption></figure>" >> ~/gameflix/main.html

curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/retroarch.end >> ~/gameflix/retroarch.sh
chmod +x ~/gameflix/retroarch.sh; echo "<p><b>Total: $total</b>" >> ~/gameflix/systems.html; echo "<p><b>Platforms: $platforms</b>" >> ~/gameflix/systems.html
cp favicon.png ~/gameflix/
