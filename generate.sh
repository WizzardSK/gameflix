#!/bin/bash
shopt -s nocasematch; 
declare -A sys; while IFS=',' read -r k v; do sys[$k]="$v"; done < systems.csv
roms=(); while IFS=';' read -r k rest; do roms+=("$k;$rest;${sys[$k]}"); done < platforms.csv
mkdir -p ~/{gameflix,rom,gamelists,zip,zips,mount} ~/gamelists/{tic80,wasm4,lowresnx,pico8,voxatron,switch}
echo "<link rel=\"stylesheet\" type=\"text/css\" href=\"style.css\" />" > ~/gameflix/systems.html; cp ~/gameflix/systems.html ~/gameflix/main.html
echo "<link rel=\"icon\" type=\"image/png\" href=\"/favicon.png\"><title>gameflix</title><frameset border=0 cols='260, 100%'><frame name='menu' src='systems.html'><frame name='main' src='main.html'></frameset>" > ~/gameflix/index.html
for file in retroarch.sh style.css script.js script2.js platform.js; do cp $file ~/gameflix/$file; done

pocet=$(curl -s "https://tic80.com/api?fn=dir&path=play/Games" | grep -o 'filename' | wc -l); total=$((pocet+total))
echo "<figure><a href='TIC-80.html'><img src='https://raw.githubusercontent.com/wizzardsk/es-theme-carbon/master/art/background/tic80.jpg'><figcaption>TIC-80</figcaption></a>$pocet</figure>" >> ~/gameflix/main.html
echo "<a href=\"TIC-80.html\" target=\"main\">TIC-80</a> <small>$pocet</small><br />" >> ~/gameflix/systems.html; echo "*\"TIC-80/\"*) core=\"tic80_libretro\";;" >> ~/gameflix/retroarch.sh  
echo "TIC-80"; cp platform.html ~/gameflix/TIC-80.html; echo "<script>bgImage(\"tic80\"); fileNames = [" >> ~/gameflix/TIC-80.html; ((platforms++))
echo "<gameList>" > ~/gamelists/tic80/gamelist.xml; data=$(curl -s "https://tic80.com/api?fn=dir&path=play/Games" | sed 's/},/}\n/g'); records=(); while IFS= read -r line; do
  if [[ "$line" =~ id[[:space:]]*=[[:space:]]*([0-9]+) ]]; then id="${BASH_REMATCH[1]}"; else continue; fi
  if [[ "$line" =~ hash[[:space:]]*=[[:space:]]*\"([a-f0-9]+)\" ]]; then hash="${BASH_REMATCH[1]}"; else continue; fi
  if [[ "$line" =~ name[[:space:]]*=[[:space:]]*\"([^\"]+)\" ]]; then name="${BASH_REMATCH[1]%.tic}"; else continue; fi
  records+=("$id"$'\t'"$hash"$'\t'"$name"); hash=$(echo "$line" | grep -oP 'hash\s*=\s*"\K[a-f0-9]+'); name=$(echo "$line" | grep -oP ' name\s*=\s*"\K[^"]+');
done <<< "$data"; printf "%s\n" "${records[@]}" | sort -nr -k1,1 | awk '{ print "\"" $0 "\"," }' >> ~/gameflix/TIC-80.html
printf ']; generateTicLinks("roms/TIC-80", "TIC-80");</script><script src=\"script.js\"></script><script src="script2.js"></script>' >> ~/gameflix/TIC-80.html; 
echo "<game><path>./surf.tic</path><name>TIC-80 surf</name><image>./tic80.png</image></game></gameList>" >> ~/gamelists/tic80/gamelist.xml

pocet=$(ls ~/roms/LowresNX/*.nx | wc -l); total=$((pocet+total))
echo "<figure><a href='LowresNX.html'><img src='https://raw.githubusercontent.com/wizzardsk/es-theme-carbon/master/art/background/lowresnx.jpg'><figcaption>LowresNX</figcaption></a>$pocet</figure>" >> ~/gameflix/main.html
echo "<a href=\"LowresNX.html\" target=\"main\">LowresNX</a> <small>$pocet</small><br />" >> ~/gameflix/systems.html; echo "*\"LowresNX/\"*) core=\"lowresnx_libretro\";;" >> ~/gameflix/retroarch.sh  
echo "LowresNX"; cp platform.html ~/gameflix/LowresNX.html; echo "<script>bgImage(\"lowresnx\"); fileNames = [" >> ~/gameflix/LowresNX.html; ((platforms++))
echo "<gameList>" > ~/gamelists/lowresnx/gamelist.xml; cat fantasy/lowresnx.txt | while IFS=$'\t' read -r id name picture cart; do 
  if [[ -n "$cart" && -n "$picture" ]]; then echo -e "\"$cart\t$picture\t$name\t$id\"," >> ~/gameflix/LowresNX.html; fi; 
  hra="<game><path>./${cart}</path><name>${name}</name><image>./${picture}</image>"; echo "${hra}</game>" >> ~/gamelists/lowresnx/gamelist.xml
done; printf ']; generateLrNXLinks("roms/LowresNX", "LowresNX");</script><script src=\"script.js\"></script><script src="script2.js"></script>' >> ~/gameflix/LowresNX.html; 
echo "</gameList>" >> ~/gamelists/lowresnx/gamelist.xml

pocet=$(ls ~/roms/WASM-4/*.wasm | wc -l); total=$((pocet+total))
echo "<figure><a href='WASM-4.html'><img src='https://raw.githubusercontent.com/wizzardsk/es-theme-carbon/master/art/background/wasm4.jpg'><figcaption>WASM-4</figcaption></a>$pocet</figure>" >> ~/gameflix/main.html
echo "<a href=\"WASM-4.html\" target=\"main\">WASM-4</a> <small>$pocet</small><br />" >> ~/gameflix/systems.html; echo "*\"WASM-4/\"*) core=\"wasm4_libretro\";;" >> ~/gameflix/retroarch.sh  
echo "WASM-4"; cp platform.html ~/gameflix/WASM-4.html; echo "<script>bgImage(\"wasm4\"); fileNames = [" >> ~/gameflix/WASM-4.html; ((platforms++))
echo "<gameList>" > ~/gamelists/wasm4/gamelist.xml; html=$(curl -s "https://wasm4.org/play/"); echo "$html" | grep -oP '<img src="/carts/[^"]+\.png" alt="[^"]+"' | while read -r line; do 
  image=$(echo "$line" | grep -oP '(?<=src=")/carts/[^"]+'); title=$(echo "$line" | grep -oP '(?<=alt=")[^"]+'); image_name=$(basename "$image" .png); echo -e "\"$image_name\t$title\"," >> ~/gameflix/WASM-4.html; 
  hra="<game><path>./${image_name}.wasm</path><name>${title}</name><image>./${image_name}.png</image>"; echo "${hra}</game>" >> ~/gamelists/wasm4/gamelist.xml
done; printf ']; generateWasmLinks("roms/WASM-4", "WASM-4");</script><script src=\"script.js\"></script><script src="script2.js"></script>' >> ~/gameflix/WASM-4.html; 
echo "</gameList>" >> ~/gamelists/wasm4/gamelist.xml

pocet=$(wc -l < fantasy/pico8.txt); total=$((pocet+total))
echo "<figure><a href='PICO-8.html'><img src='https://raw.githubusercontent.com/wizzardsk/es-theme-carbon/master/art/background/pico8.jpg'><figcaption>PICO-8</figcaption></a>$pocet</figure>" >> ~/gameflix/main.html
echo "<a href=\"PICO-8.html\" target=\"main\">PICO-8</a> <small>$pocet</small><br />" >> ~/gameflix/systems.html; echo "*\"PICO-8/\"*) core=\"pico8 -run\";;" >> ~/gameflix/retroarch.sh  
echo "PICO-8"; cp platform.html ~/gameflix/PICO-8.html; echo "<script>bgImage(\"pico8\"); fileNames = [" >> ~/gameflix/PICO-8.html; ((platforms++))
echo "<gameList>" > ~/gamelists/pico8/gamelist.xml; cat fantasy/pico8.txt | while IFS=$'\t' read -r id name cart; do echo -e "\"$id\t$name\t$cart\"," >> ~/gameflix/PICO-8.html; done
printf ']; generatePicoLinks("roms/PICO-8", "PICO-8");</script><script src=\"script.js\"></script><script src="script2.js"></script>' >> ~/gameflix/PICO-8.html;
echo "</gameList>" >> ~/gamelists/pico8/gamelist.xml

pocet=$(wc -l < fantasy/voxatron.txt); total=$((pocet+total))
echo "<figure><a href='Voxatron.html'><img src='https://raw.githubusercontent.com/wizzardsk/es-theme-carbon/master/art/background/voxatron.jpg'><figcaption>Voxatron</figcaption></a>$pocet</figure>" >> ~/gameflix/main.html
echo "<a href=\"Voxatron.html\" target=\"main\">Voxatron</a> <small>$pocet</small><br />" >> ~/gameflix/systems.html; echo "*\"Voxatron/\"*) core=\"vox\";;" >> ~/gameflix/retroarch.sh  
echo "Voxatron"; cp platform.html ~/gameflix/Voxatron.html; echo "<script>bgImage(\"voxatron\"); fileNames = [" >> ~/gameflix/Voxatron.html; ((platforms++))
echo "<gameList>" > ~/gamelists/voxatron/gamelist.xml; cat fantasy/voxatron.txt | while IFS=$'\t' read -r id name cart; do echo -e "\"$id\t$name\t$cart\"," >> ~/gameflix/Voxatron.html; done
printf ']; generateVoxLinks("roms/Voxatron", "Voxatron");</script><script src=\"script.js\"></script><script src="script2.js"></script>' >> ~/gameflix/Voxatron.html;
echo "</gameList>" >> ~/gamelists/voxatron/gamelist.xml

echo "<gameList>" > ~/gamelists/switch/gamelist.xml; cat switch.txt | while read -r name; do
  echo "<game><path>./${name}.nsp</path><name>${name}</name><image>~/../thumbs/Nintendo - Nintendo Switch/Named_Snaps/${name}.png</image></game>" >> ~/gamelists/switch/gamelist.xml
  echo "<game><path>./${name}.xci</path><name>${name}</name><image>~/../thumbs/Nintendo - Nintendo Switch/Named_Snaps/${name}.png</image></game>" >> ~/gamelists/switch/gamelist.xml
done; echo "</gameList>" >> ~/gamelists/switch/gamelist.xml

IFS=";"; for each in "${roms[@]}"; do
  read -ra rom < <(printf '%s' "$each"); 
  if [[ "$rom3" != "${rom[0]}" ]]; then
    echo ${rom[6]}; echo "<script src="script.js"></script><script src="script2.js"></script>" >> ~/gameflix/${rom3}.html;
    cp platform.html ~/gameflix/${rom[0]}.html
    echo -e "${rom[3]}\n<script>bgImage(\"${rom[0]}\")\nfileNames = [" >> ~/gameflix/${rom[0]}.html
    if [ -n "$rom3" ]; then 
      echo "<figure><a href='${rom3}.html'><img src='https://raw.githubusercontent.com/wizzardsk/es-theme-carbon/master/art/background/"${rom3}".jpg'><figcaption>${rom6}</figcaption></a>$pocet</figure>" >> ~/gameflix/main.html;
      echo "<a href=\"${rom3}.html\" target=\"main\">${rom6}</a> <small>$pocet</small><br />" >> ~/gameflix/systems.html; ((platforms++));
    fi
    pocet=0; 
  else echo -e "<br><br>${rom[3]}\n<script>bgImage(\"${rom3}\")\nfileNames = [" >> ~/gameflix/${rom3}.html; fi
  rom3="${rom[0]}"; rom6="${rom[6]}"; 
  mkdir -p ~/mount/${rom[0]} ~/gamelists/${rom[0]}; romfolder="myrient/${rom[1]}"; emufolder="${rom[1]}";
  foldername=$(sed 's/<[^>]*>//g' <<< "${rom[3]}");
  while IFS= read -r line; do
    line2="${line%.*}"; echo "\"${line}\"," >> ~/gameflix/${rom3}.html; ((pocet++)); ((total++))
    if [[ "$line2" == *")"* ]]; then thumb="${line2%%)*})"; else thumb="$line2"; fi
    if [ -d ~/"${romfolder}/${line}" ]; then polozka="folder"; else polozka="game"; fi    
    #hra="<$polozka><path>./$foldername/${line}</path><name>${line2}</name><image>~/../thumbs/${rom[2]}/Named_Snaps/${thumb}.png</image><titleshot>~/../thumbs/${rom[2]}/Named_Titles/${thumb}.png</titleshot><thumbnail>~/../thumbs/${rom[2]}/Named_Boxarts/${thumb}.png</thumbnail><marquee>~/../thumbs/${rom[2]}/Named_Logos/${thumb}.png</marquee>"
    hra="<$polozka><path>./$foldername/${line}</path><name>${line2}</name><image>~/../thumbs/${rom[2]}/Named_Snaps/${thumb}.png</image>"
    if [[ ! "$line" =~ \[(bios|a[0-9]{0,2}|b[0-9]{0,2}|c|f|h [^]]*|o ?.*|p ?.*|t ?.*|cr ?.*)\]|\((demo( [0-9]+)?|beta( [0-9]+)?|alpha( [0-9]+)?|(disk|side)( [2-9B-Z]).*|pre-release|aftermarket|alt|alternate|unl|channel|system|dlc)\) ]]; then
      echo "${hra}</$polozka>" >> ~/gamelists/${rom[0]}/gamelist.xml
    else echo "${hra}<hidden>true</hidden></$polozka>" >> ~/gamelists/${rom[0]}/gamelist.xml; fi
  done < <(ls ~/"${romfolder}")
  echo ']; generateFileLinks("'"$romfolder"'", "'"${rom[2]// /_}"'");</script>' >> ~/gameflix/${rom3}.html
  platform=${rom[0]}; ext=""; if [ -n "${rom[5]}" ]; then ext="; ext=\"${rom[5]}\""; fi; echo "*\"${emufolder}/\"*) core=\"${rom[4]}\"${ext};;" >> ~/gameflix/retroarch.sh
  echo "<folder><path>./$foldername</path><name>$foldername</name><image>~/../thumb/${rom[0]}.png</image></folder>" >> ~/gamelists/${rom[0]}/gamelist.xml
done
echo "<script src="script.js"></script><script src="script2.js"></script>" >> ~/gameflix/${rom3}.html;
echo "<script src="script2.js"></script>" >> ~/gameflix/main.html;
echo "<figure><a href='${rom3}.html'><img src='https://raw.githubusercontent.com/wizzardsk/es-theme-carbon/master/art/background/"${rom3}".jpg'><figcaption>${rom6}</figcaption></a>$pocet</figure>" >> ~/gameflix/main.html; ((platforms++))
echo "<a href=\"${rom3}.html\" target=\"main\">${rom6}</a> <small>$pocet</small><br />" >> ~/gameflix/systems.html
for each in "${roms[@]}"; do 
  read -ra rom < <(printf '%s' "$each")
  if ! grep -Fxq "<gameList>" ~/gamelists/${rom[0]}/gamelist.xml; then sed -i "1i <gameList>" ~/gamelists/${rom[0]}/gamelist.xml; fi
  if ! grep -Fxq "</gameList>" ~/gamelists/${rom[0]}/gamelist.xml; then sed -i "\$a </gameList>" ~/gamelists/${rom[0]}/gamelist.xml; fi
done

cat retroarch.end >> ~/gameflix/retroarch.sh; cp favicon.png ~/gameflix/
chmod +x ~/gameflix/retroarch.sh; echo "<p><b>Total: $total</b>" >> ~/gameflix/systems.html; echo "<p><b>Platforms: $platforms</b>" >> ~/gameflix/systems.html
