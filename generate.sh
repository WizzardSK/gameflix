#!/bin/bash
shopt -s nocasematch; IFS=$'\n' read -d '' -ra roms < platforms.csv
mkdir -p ~/{gameflix,rom,gamelists,zip,zips,mount} ~/gamelists/{tic80,wasm4,lowresnx,pico8,voxatron,switch}
echo "<link rel=\"stylesheet\" type=\"text/css\" href=\"style.css\" />" > ~/gameflix/systems.html; cp ~/gameflix/systems.html ~/gameflix/main.html
echo "<link rel=\"icon\" type=\"image/png\" href=\"/favicon.png\"><title>gameflix</title><frameset border=0 cols='260, 100%'><frame name='menu' src='systems.html'><frame name='main' src='main.html'></frameset>" > ~/gameflix/index.html
for file in retroarch.sh style.css script.js platform.js; do cp $file ~/gameflix/$file; done

echo "<figure><a href='TIC-80.html'><img class=loaded src='https://raw.githubusercontent.com/wizzardsk/es-theme-carbon/master/art/background/tic80.jpg'></a><figcaption>TIC-80</figcaption></figure>
<figure><a href='LowresNX.html'><img class=loaded src='https://raw.githubusercontent.com/wizzardsk/es-theme-carbon/master/art/background/lowresnx.jpg'></a><figcaption>LowresNX</figcaption></figure>
<figure><a href='WASM-4.html'><img class=loaded src='https://raw.githubusercontent.com/wizzardsk/es-theme-carbon/master/art/background/wasm4.jpg'></a><figcaption>WASM-4</figcaption></figure>
<figure><a href='PICO-8.html'><img class=loaded src='https://raw.githubusercontent.com/wizzardsk/es-theme-carbon/master/art/background/pico8.jpg'></a><figcaption>PICO-8</figcaption></figure>
<figure><a href='Voxatron.html'><img class=loaded src='https://wiki.batocera.org/_media/systems:voxatron.png'></a><figcaption>Voxatron</figcaption></figure>" >> ~/gameflix/main.html

pocet=$(ls ~/roms/TIC-80/*.tic | wc -l); total=$((pocet+total))
echo "<a href=\"TIC-80.html\" target=\"main\">TIC-80</a> ($pocet)<br />" >> ~/gameflix/systems.html; echo "*\"TIC-80/\"*) core=\"tic80_libretro\";;" >> ~/gameflix/retroarch.sh  
echo "TIC-80"; cp platform.html ~/gameflix/TIC-80.html; echo "<script>bgImage(\"tic80\"); fileNames = [" >> ~/gameflix/TIC-80.html; ((platforms++))
echo "<gameList>" > ~/gamelists/tic80/gamelist.xml; data=$(curl -s "https://tic80.com/api?fn=dir&path=play/Games" | sed 's/},/}\n/g'); records=(); while IFS= read -r line; do
  if [[ "$line" =~ id[[:space:]]*=[[:space:]]*([0-9]+) ]]; then id="${BASH_REMATCH[1]}"; else continue; fi
  if [[ "$line" =~ hash[[:space:]]*=[[:space:]]*\"([a-f0-9]+)\" ]]; then hash="${BASH_REMATCH[1]}"; else continue; fi
  if [[ "$line" =~ name[[:space:]]*=[[:space:]]*\"([^\"]+)\" ]]; then name="${BASH_REMATCH[1]%.tic}"; else continue; fi
  records+=("$id"$'\t'"$hash"$'\t'"$name"); hash=$(echo "$line" | grep -oP 'hash\s*=\s*"\K[a-f0-9]+'); name=$(echo "$line" | grep -oP ' name\s*=\s*"\K[^"]+');
  hra="<game><path>./TIC-80/${hash}.tic</path><name>${name%.*}</name><image>./TIC-80/${hash}.png</image>"; if [ -n "$hash" ]; then echo "${hra}</game>" >> ~/gamelists/tic80/gamelist.xml; fi;
done <<< "$data"; printf "%s\n" "${records[@]}" | sort -nr -k1,1 | awk '{ print "\"" $0 "\"," }' >> ~/gameflix/TIC-80.html
printf ']; generateTicLinks("roms/TIC-80", "TIC-80");</script><script src=\"script.js\"></script>' >> ~/gameflix/TIC-80.html; echo "</gameList>" >> ~/gamelists/tic80/gamelist.xml

pocet=$(ls ~/roms/LowresNX/*.nx | wc -l); total=$((pocet+total))
echo "<a href=\"LowresNX.html\" target=\"main\">LowresNX</a> ($pocet)<br />" >> ~/gameflix/systems.html; echo "*\"LowresNX/\"*) core=\"lowresnx_libretro\";;" >> ~/gameflix/retroarch.sh  
echo "LowresNX"; cp platform.html ~/gameflix/LowresNX.html; echo "<script>bgImage(\"lowresnx\"); fileNames = [" >> ~/gameflix/LowresNX.html; ((platforms++))
echo "<gameList>" > ~/gamelists/lowresnx/gamelist.xml; cat fantasy/lowresnx.txt | while IFS=$'\t' read -r id name picture cart; do 
  if [[ -n "$cart" && -n "$picture" ]]; then echo -e "\"$cart\t$picture\t$name\t$id\"," >> ~/gameflix/LowresNX.html; fi; 
  hra="<game><path>./LowresNX/${cart}</path><name>${name}</name><image>./LowresNX/${picture}</image>"; echo "${hra}</game>" >> ~/gamelists/lowresnx/gamelist.xml
done; printf ']; generateLrNXLinks("roms/LowresNX", "LowresNX");</script><script src=\"script.js\"></script>' >> ~/gameflix/LowresNX.html; echo "</gameList>" >> ~/gamelists/lowresnx/gamelist.xml

pocet=$(ls ~/roms/WASM-4/*.wasm | wc -l); total=$((pocet+total))
echo "<a href=\"WASM-4.html\" target=\"main\">WASM-4</a> ($pocet)<br />" >> ~/gameflix/systems.html; echo "*\"WASM-4/\"*) core=\"wasm4_libretro\";;" >> ~/gameflix/retroarch.sh  
echo "WASM-4"; cp platform.html ~/gameflix/WASM-4.html; echo "<script>bgImage(\"wasm4\"); fileNames = [" >> ~/gameflix/WASM-4.html; ((platforms++))
echo "<gameList>" > ~/gamelists/wasm4/gamelist.xml; html=$(curl -s "https://wasm4.org/play/"); echo "$html" | grep -oP '<img src="/carts/[^"]+\.png" alt="[^"]+"' | while read -r line; do 
  image=$(echo "$line" | grep -oP '(?<=src=")/carts/[^"]+'); title=$(echo "$line" | grep -oP '(?<=alt=")[^"]+'); image_name=$(basename "$image" .png); echo -e "\"$image_name\t$title\"," >> ~/gameflix/WASM-4.html; 
  hra="<game><path>./WASM-4/${image_name}.wasm</path><name>${title}</name><image>./WASM-4/${image_name}.png</image>"; echo "${hra}</game>" >> ~/gamelists/wasm4/gamelist.xml
done; printf ']; generateWasmLinks("roms/WASM-4", "WASM-4");</script><script src=\"script.js\"></script>' >> ~/gameflix/WASM-4.html; echo "</gameList>" >> ~/gamelists/wasm4/gamelist.xml

pocet=$(wc -l < fantasy/pico8.txt); total=$((pocet+total))
echo "<a href=\"PICO-8.html\" target=\"main\">PICO-8</a> ($pocet)<br />" >> ~/gameflix/systems.html; echo "*\"PICO-8/\"*) core=\"pico8 -run\";;" >> ~/gameflix/retroarch.sh  
echo "PICO-8"; cp platform.html ~/gameflix/PICO-8.html; echo "<script>bgImage(\"pico8\"); fileNames = [" >> ~/gameflix/PICO-8.html; ((platforms++))
echo "<gameList>" > ~/gamelists/pico8/gamelist.xml; cat fantasy/pico8.txt | while IFS=$'\t' read -r id name cart; do 
  echo -e "\"$id\t$name\t$cart\"," >> ~/gameflix/PICO-8.html; hra="<game><path>./PICO-8/${cart}</path><name>${name}</name>"; echo "${hra}</game>" >> ~/gamelists/pico8/gamelist.xml
done; printf ']; generatePicoLinks("roms/PICO-8", "PICO-8");</script><script src=\"script.js\"></script>' >> ~/gameflix/PICO-8.html
echo "<folder><path>./PICO-8</path><name>PICO-8</name><image>./splore.png</image></folder></gameList>" >> ~/gamelists/pico8/gamelist.xml

pocet=$(wc -l < fantasy/voxatron.txt); total=$((pocet+total))
echo "<a href=\"Voxatron.html\" target=\"main\">Voxatron</a> ($pocet)<br />" >> ~/gameflix/systems.html; echo "*\"Voxatron/\"*) core=\"vox\";;" >> ~/gameflix/retroarch.sh  
echo "Voxatron"; cp platform.html ~/gameflix/Voxatron.html; echo "<script>bgImage(\"voxatron\"); fileNames = [" >> ~/gameflix/Voxatron.html; ((platforms++))
echo "<gameList>" > ~/gamelists/voxatron/gamelist.xml; cat fantasy/voxatron.txt | while IFS=$'\t' read -r id name cart; do 
  echo -e "\"$id\t$name\t$cart\"," >> ~/gameflix/Voxatron.html; hra="<game><path>./Voxatron/${cart}</path><name>${name}</name>"; echo "${hra}</game>" >> ~/gamelists/voxatron/gamelist.xml
done; printf ']; generateVoxLinks("roms/Voxatron", "Voxatron");</script><script src=\"script.js\"></script>' >> ~/gameflix/Voxatron.html
echo "<folder><path>./Voxatron</path><name>Voxatron</name><image>./splore.png</image></folder></gameList>" >> ~/gamelists/voxatron/gamelist.xml

echo "<gameList>" > ~/gamelists/switch/gamelist.xml; cat switch.txt | while read -r name; do
  echo "<game><path>./${name}.nsp</path><name>${name}</name><image>~/../thumbs/Nintendo - Nintendo Switch/Named_Snaps/${name}.png</image></game>" >> ~/gamelists/switch/gamelist.xml
  echo "<game><path>./${name}.xci</path><name>${name}</name><image>~/../thumbs/Nintendo - Nintendo Switch/Named_Snaps/${name}.png</image></game>" >> ~/gamelists/switch/gamelist.xml
done; echo "</gameList>" >> ~/gamelists/switch/gamelist.xml

IFS=";"; for each in "${roms[@]}"; do
  read -ra rom < <(printf '%s' "$each"); 
  if [[ "$rom3" != "${rom[0]}" ]]; then
    echo ${rom[0]};
    echo "<script src="script.js"></script>" >> ~/gameflix/${rom3}.html;    
    cp platform.html ~/gameflix/${rom[0]}.html
    echo "${rom[3]}" >> ~/gameflix/${rom[0]}.html;
    echo "<script>bgImage(\"${rom[0]}\")" >> ~/gameflix/${rom[0]}.html;
    echo "fileNames = [" >> ~/gameflix/${rom[0]}.html;
    if [ -n "$rom3" ]; then echo "<a href=\"${rom3}.html\" target=\"main\">${rom3}</a> ($pocet)<br />" >> ~/gameflix/systems.html; fi
    pocet=0; 
  else
    echo "${rom[3]}" >> ~/gameflix/${rom3}.html;
    echo "<script>bgImage(\"${rom3}\")" >> ~/gameflix/${rom3}.html;
    echo "fileNames = [" >> ~/gameflix/${rom3}.html;
  fi
  rom3="${rom[0]}"; mkdir -p ~/mount/${rom[0]} ~/gamelists/${rom[0]}; romfolder="myrient/${rom[1]}"; emufolder="${rom[1]}";
  while IFS= read -r line; do
    line2="${line%.*}"; echo "\"${line}\"," >> ~/gameflix/${rom3}.html; ((pocet++)); ((total++))
    if [[ "$line2" == *")"* ]]; then thumb="${line2%%)*})"; else thumb="$line2"; fi
    if [ -d ~/"${romfolder}/${line}" ]; then polozka="folder"; else polozka="game"; fi    
    hra="<$polozka><path>./${rom3}/${line}</path><name>${line2}</name><image>~/../thumbs/${rom[2]}/Named_Snaps/${thumb}.png</image><titleshot>~/../thumbs/${rom[2]}/Named_Titles/${thumb}.png</titleshot><thumbnail>~/../thumbs/${rom[2]}/Named_Boxarts/${thumb}.png</thumbnail><marquee>~/../thumbs/${rom[2]}/Named_Logos/${thumb}.png</marquee>"
    if [[ ! "$line" =~ \[(bios|a[0-9]{0,2}|b[0-9]{0,2}|c|f|h [^]]*|o ?.*|p ?.*|t ?.*|cr ?.*)\]|\((demo( [0-9]+)?|beta( [0-9]+)?|alpha( [0-9]+)?|(disk|side)( [2-9B-Z]).*|pre-release|aftermarket|alt|alternate|unl|channel|system|dlc)\) ]]; then
      echo "${hra}</$polozka>" >> ~/gamelists/${rom[0]}/gamelist.xml
    else echo "${hra}<hidden>true</hidden></$polozka>" >> ~/gamelists/${rom[0]}/gamelist.xml; fi
  done < <(ls ~/"${romfolder}")
  echo ']; generateFileLinks("'"$romfolder"'", "'"${rom[2]// /_}"'");</script>' >> ~/gameflix/${rom3}.html
  if [ "$platform" != "${rom[0]}" ]; then
    echo "<figure><a href='${rom3}.html'><img class=loaded src='https://raw.githubusercontent.com/wizzardsk/es-theme-carbon/master/art/background/"${rom[0]}".jpg'></a><figcaption>${rom[2]}</figcaption></figure>" >> ~/gameflix/main.html; ((platforms++))
  fi
  platform=${rom[0]}; ext=""; if [ -n "${rom[5]}" ]; then ext="; ext=\"${rom[5]}\""; fi; echo "*\"${emufolder}/\"*) core=\"${rom[4]}\"${ext};;" >> ~/gameflix/retroarch.sh
  echo "<folder><path>./${rom3}</path><name>${rom3}</name><image>~/../thumb/${rom[0]}.png</image></folder>" >> ~/gamelists/${rom[0]}/gamelist.xml
done
echo "<script src="script.js"></script>" >> ~/gameflix/${rom3}.html;
echo "<a href=\"${rom3}.html\" target=\"main\">${rom3}</a> ($pocet)<br />" >> ~/gameflix/systems.html
for each in "${roms[@]}"; do 
  read -ra rom < <(printf '%s' "$each")
  if ! grep -Fxq "<gameList>" ~/gamelists/${rom[0]}/gamelist.xml; then sed -i "1i <gameList>" ~/gamelists/${rom[0]}/gamelist.xml; fi
  if ! grep -Fxq "</gameList>" ~/gamelists/${rom[0]}/gamelist.xml; then sed -i "\$a </gameList>" ~/gamelists/${rom[0]}/gamelist.xml; fi
done

cat retroarch.end >> ~/gameflix/retroarch.sh; cp favicon.png ~/gameflix/
chmod +x ~/gameflix/retroarch.sh; echo "<p><b>Total: $total</b>" >> ~/gameflix/systems.html; echo "<p><b>Platforms: $platforms</b>" >> ~/gameflix/systems.html
