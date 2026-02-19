#!/bin/bash
shopt -s nocasematch;
declare -A sys thumb; sysorder=(); while IFS=',' read -r k v t; do sys[$k]="$v"; thumb[$k]="$t"; sysorder+=("$k"); done < <(tail -n +2 systems.csv)
declare -A sysroms; while IFS=';' read -r k rest; do sysroms[$k]+="$k;$rest;${thumb[$k]};${sys[$k]}"$'\n'; done < <(awk '{o="";i=1;n=length($0);while(i<=n){c=substr($0,i,1);if(c==","){o=o";";i++}else if(c=="\""){i++;while(i<=n){c=substr($0,i,1);if(c=="\""){if(substr($0,i+1,1)=="\""){o=o"\"";i+=2}else{i++;break}}else{o=o c;i++}}}else{o=o c;i++}};print o}' <(tail -n +2 platforms.csv))
roms=(); for k in "${sysorder[@]}"; do while IFS= read -r line; do [[ -n "$line" ]] && roms+=("$line"); done <<< "${sysroms[$k]}"; done
mkdir -p ~/{gameflix,rom,gamelists,zip,zips,mount} ~/gamelists/{tic80,wasm4,lowresnx,pico8,voxatron,switch}
echo "<link rel=\"stylesheet\" type=\"text/css\" href=\"style.css\" />" > ~/gameflix/systems.html; cp ~/gameflix/systems.html ~/gameflix/main.html
echo "<link rel=\"icon\" type=\"image/png\" href=\"/favicon.png\"><title>gameflix</title><frameset border=0 cols='260, 100%'><frame name='menu' src='systems.html'><frame name='main' src='main.html'></frameset>" > ~/gameflix/index.html
for file in retroarch.sh style.css script.js platform.js; do cp $file ~/gameflix/$file; done

# TIC-80 - single API call
data=$(curl -s "https://tic80.com/api?fn=dir&path=play/Games")
pocet=$(echo "$data" | grep -o 'filename' | wc -l); total=$((pocet+total))
echo "<figure><a href='TIC-80.html'><img src='https://raw.githubusercontent.com/wizzardsk/es-theme-carbon/master/art/background/tic80.jpg'><figcaption>TIC-80</figcaption></a>$pocet</figure>" >> ~/gameflix/main.html
echo "<a href=\"TIC-80.html\" target=\"main\">TIC-80</a> <small>$pocet</small><br />" >> ~/gameflix/systems.html; echo "*\"TIC-80/\"*) core=\"tic80_libretro\";;" >> ~/gameflix/retroarch.sh
echo "TIC-80"; cp platform.html ~/gameflix/TIC-80.html; echo "<script>bgImage(\"tic80\"); fileNames = [" >> ~/gameflix/TIC-80.html; ((platforms++))
echo "<gameList>" > ~/gamelists/tic80/gamelist.xml; records=(); while IFS= read -r line; do
  if [[ "$line" =~ id[[:space:]]*=[[:space:]]*([0-9]+) ]]; then id="${BASH_REMATCH[1]}"; else continue; fi
  if [[ "$line" =~ hash[[:space:]]*=[[:space:]]*\"([a-f0-9]+)\" ]]; then hash="${BASH_REMATCH[1]}"; else continue; fi
  if [[ "$line" =~ name[[:space:]]*=[[:space:]]*\"([^\"]+)\" ]]; then name="${BASH_REMATCH[1]%.tic}"; else continue; fi
  records+=("$id"$'\t'"$hash"$'\t'"$name")
done <<< "$(echo "$data" | sed 's/},/}\n/g')"; printf "%s\n" "${records[@]}" | sort -nr -k1,1 | awk '{ print "\"" $0 "\"," }' >> ~/gameflix/TIC-80.html
printf ']; generateTicLinks("roms/TIC-80", "TIC-80");</script><script src=\"script.js\"></script>' >> ~/gameflix/TIC-80.html;
echo "<game><path>./surf.tic</path><name>TIC-80 surf</name><image>./tic80.png</image></game></gameList>" >> ~/gamelists/tic80/gamelist.xml

# LowresNX - redirect stdin, buffer output
pocet=$(ls ~/roms/LowresNX/*.nx | wc -l); total=$((pocet+total))
echo "<figure><a href='LowresNX.html'><img src='https://raw.githubusercontent.com/wizzardsk/es-theme-carbon/master/art/background/lowresnx.jpg'><figcaption>LowresNX</figcaption></a>$pocet</figure>" >> ~/gameflix/main.html
echo "<a href=\"LowresNX.html\" target=\"main\">LowresNX</a> <small>$pocet</small><br />" >> ~/gameflix/systems.html; echo "*\"LowresNX/\"*) core=\"lowresnx_libretro\";;" >> ~/gameflix/retroarch.sh
echo "LowresNX"; cp platform.html ~/gameflix/LowresNX.html; echo "<script>bgImage(\"lowresnx\"); fileNames = [" >> ~/gameflix/LowresNX.html; ((platforms++))
{
  echo "<gameList>"
  htmlbuf=""
  while IFS=$'\t' read -r id name picture cart; do
    if [[ -n "$cart" && -n "$picture" ]]; then htmlbuf+="\"$cart\t$picture\t$name\t$id\","$'\n'; fi
    echo "<game><path>./${cart}</path><name>${name}</name><image>./${picture}</image></game>"
  done < fantasy/lowresnx.txt
  echo "</gameList>"
} > ~/gamelists/lowresnx/gamelist.xml
printf '%s' "$htmlbuf" >> ~/gameflix/LowresNX.html
printf ']; generateLrNXLinks("roms/LowresNX", "LowresNX");</script><script src=\"script.js\"></script>' >> ~/gameflix/LowresNX.html

# WASM-4 - buffer output
pocet=$(ls ~/roms/WASM-4/*.wasm | wc -l); total=$((pocet+total))
echo "<figure><a href='WASM-4.html'><img src='https://raw.githubusercontent.com/wizzardsk/es-theme-carbon/master/art/background/wasm4.jpg'><figcaption>WASM-4</figcaption></a>$pocet</figure>" >> ~/gameflix/main.html
echo "<a href=\"WASM-4.html\" target=\"main\">WASM-4</a> <small>$pocet</small><br />" >> ~/gameflix/systems.html; echo "*\"WASM-4/\"*) core=\"wasm4_libretro\";;" >> ~/gameflix/retroarch.sh
echo "WASM-4"; cp platform.html ~/gameflix/WASM-4.html; echo "<script>bgImage(\"wasm4\"); fileNames = [" >> ~/gameflix/WASM-4.html; ((platforms++))
htmlbuf=""; xmlbuf="<gameList>"$'\n'
html=$(curl -s "https://wasm4.org/play/"); while read -r line; do
  image=$(echo "$line" | grep -oP '(?<=src=")/carts/[^"]+'); title=$(echo "$line" | grep -oP '(?<=alt=")[^"]+'); image_name=$(basename "$image" .png)
  htmlbuf+="\"$image_name\t$title\","$'\n'
  xmlbuf+="<game><path>./${image_name}.wasm</path><name>${title}</name><image>./${image_name}.png</image></game>"$'\n'
done <<< "$(echo "$html" | grep -oP '<img src="/carts/[^"]+\.png" alt="[^"]+"')"
printf '%s' "$htmlbuf" >> ~/gameflix/WASM-4.html
printf ']; generateWasmLinks("roms/WASM-4", "WASM-4");</script><script src=\"script.js\"></script>' >> ~/gameflix/WASM-4.html
echo "${xmlbuf}</gameList>" > ~/gamelists/wasm4/gamelist.xml

# PICO-8 - redirect stdin
pocet=$(wc -l < fantasy/pico8.txt); total=$((pocet+total))
echo "<figure><a href='PICO-8.html'><img src='https://raw.githubusercontent.com/wizzardsk/es-theme-carbon/master/art/background/pico8.jpg'><figcaption>PICO-8</figcaption></a>$pocet</figure>" >> ~/gameflix/main.html
echo "<a href=\"PICO-8.html\" target=\"main\">PICO-8</a> <small>$pocet</small><br />" >> ~/gameflix/systems.html; echo "*\"PICO-8/\"*) core=\"pico8 -run\";;" >> ~/gameflix/retroarch.sh
echo "PICO-8"; cp platform.html ~/gameflix/PICO-8.html; ((platforms++))
{
  echo "<script>bgImage(\"pico8\"); fileNames = ["
  while IFS=$'\t' read -r id name cart; do echo "\"$id\t$name\t$cart\","; done < fantasy/pico8.txt
  printf ']; generatePicoLinks("roms/PICO-8", "PICO-8");</script><script src="script.js"></script>'
} >> ~/gameflix/PICO-8.html
echo "<gameList></gameList>" > ~/gamelists/pico8/gamelist.xml

# Voxatron - redirect stdin
pocet=$(wc -l < fantasy/voxatron.txt); total=$((pocet+total))
echo "<figure><a href='Voxatron.html'><img src='https://raw.githubusercontent.com/wizzardsk/es-theme-carbon/master/art/background/voxatron.jpg'><figcaption>Voxatron</figcaption></a>$pocet</figure>" >> ~/gameflix/main.html
echo "<a href=\"Voxatron.html\" target=\"main\">Voxatron</a> <small>$pocet</small><br />" >> ~/gameflix/systems.html; echo "*\"Voxatron/\"*) core=\"vox\";;" >> ~/gameflix/retroarch.sh
echo "Voxatron"; cp platform.html ~/gameflix/Voxatron.html; ((platforms++))
{
  echo "<script>bgImage(\"voxatron\"); fileNames = ["
  while IFS=$'\t' read -r id name cart; do echo "\"$id\t$name\t$cart\","; done < fantasy/voxatron.txt
  printf ']; generateVoxLinks("roms/Voxatron", "Voxatron");</script><script src="script.js"></script>'
} >> ~/gameflix/Voxatron.html
echo "<gameList></gameList>" > ~/gamelists/voxatron/gamelist.xml

# Switch - redirect stdin, single write
{
  echo "<gameList>"
  while read -r name; do
    echo "<game><path>./${name}.nsp</path><name>${name}</name><image>~/../thumbs/Nintendo - Nintendo Switch/Named_Snaps/${name}.png</image></game>"
    echo "<game><path>./${name}.xci</path><name>${name}</name><image>~/../thumbs/Nintendo - Nintendo Switch/Named_Snaps/${name}.png</image></game>"
  done < switch.txt
  echo "</gameList>"
} > ~/gamelists/switch/gamelist.xml

# Main ROM loop - buffered writes, inline foldername strip, prebuilt dir list
declare -A gamelist_started
IFS=";"; for each in "${roms[@]}"; do
  read -ra rom < <(printf '%s' "$each");
  if [[ "$rom3" != "${rom[0]}" ]]; then
    # Flush previous platform
    if [ -n "$rom3" ]; then
      echo "$htmlbuf" >> ~/gameflix/${rom3}.html
      echo ']; generateFileLinks("'"$prev_romfolder"'", "'"${prev_imagepath}"'");</script>' >> ~/gameflix/${rom3}.html
      echo "<script src=\"script.js\"></script>" >> ~/gameflix/${rom3}.html
      echo "$xmlbuf" >> ~/gamelists/${prev_platform}/gamelist.xml
      echo ${rom[6]}
      echo "<figure><a href='${rom3}.html'><img src='https://raw.githubusercontent.com/wizzardsk/es-theme-carbon/master/art/background/${rom3}.jpg'><figcaption>${rom6}</figcaption></a>$pocet</figure>" >> ~/gameflix/main.html
      echo "<a href=\"${rom3}.html\" target=\"main\">${rom6}</a> <small>$pocet</small><br />" >> ~/gameflix/systems.html; ((platforms++))
    fi
    cp platform.html ~/gameflix/${rom[0]}.html
    pocet=0; htmlbuf=""; xmlbuf=""
  else
    # Flush previous section of same platform
    echo "$htmlbuf" >> ~/gameflix/${rom3}.html
    echo ']; generateFileLinks("'"$prev_romfolder"'", "'"${prev_imagepath}"'");</script>' >> ~/gameflix/${rom3}.html
    echo "$xmlbuf" >> ~/gamelists/${prev_platform}/gamelist.xml
    htmlbuf=""; xmlbuf=""
  fi
  echo -e "<h3 id=\"${rom[2]}\" class=\"section-header\">${rom[2]}</h3>\n<script>bgImage(\"${rom[0]}\")\nfileNames = [" >> ~/gameflix/${rom[0]}.html
  rom3="${rom[0]}"; rom6="${rom[6]}"
  mkdir -p ~/mount/${rom[0]} ~/gamelists/${rom[0]}; romfolder="myrient/${rom[1]}"; emufolder="${rom[1]}"
  foldername="${rom[2]//\<[^>]*\>/}"; foldername="${foldername//<*/}"
  # Write <gameList> header once per platform
  if [[ -z "${gamelist_started[${rom[0]}]}" ]]; then
    echo "<gameList>" > ~/gamelists/${rom[0]}/gamelist.xml
    gamelist_started[${rom[0]}]=1
  fi
  # Build directory listing and detect folders once
  romdir=~/"${romfolder}"
  while IFS= read -r line; do
    line2="${line%.*}"; htmlbuf+="\"${line}\","$'\n'; ((pocet++)); ((total++))
    if [[ "$line2" == *")"* ]]; then thumb="${line2%%)*})"; else thumb="$line2"; fi
    if [ -d "${romdir}/${line}" ]; then polozka="folder"; else polozka="game"; fi
    hra="<$polozka><path>./$foldername/${line}</path><name>${line2}</name><image>~/../thumbs/${rom[5]}/Named_Snaps/${thumb}.png</image>"
    if [[ ! "$line" =~ \[(bios|a[0-9]{0,2}|b[0-9]{0,2}|c|f|h [^]]*|o ?.*|p ?.*|t ?.*|cr ?.*)\]|\((demo( [0-9]+)?|beta( [0-9]+)?|alpha( [0-9]+)?|(disk|side)( [2-9B-Z]).*|pre-release|aftermarket|alt|alternate|unl|channel|system|dlc)\) ]]; then
      xmlbuf+="${hra}</$polozka>"$'\n'
    else xmlbuf+="${hra}<hidden>true</hidden></$polozka>"$'\n'; fi
  done < <(ls "$romdir")
  prev_romfolder="$romfolder"; prev_imagepath="${rom[5]// /_}"; prev_platform="${rom[0]}"
  platform=${rom[0]}; ext=""; if [ -n "${rom[4]}" ]; then ext="; ext=\"${rom[4]}\""; fi; emu="${rom[3]//\"/\\\"}"; echo "*\"${emufolder}/\"*) core=\"${emu}\"${ext};;" >> ~/gameflix/retroarch.sh
  xmlbuf+="<folder><path>./$foldername</path><name>$foldername</name><image>~/../thumb/${rom[0]}.png</image></folder>"$'\n'
done
# Flush last platform
echo "$htmlbuf" >> ~/gameflix/${rom3}.html
echo ']; generateFileLinks("'"$prev_romfolder"'", "'"${prev_imagepath}"'");</script>' >> ~/gameflix/${rom3}.html
echo "<script src=\"script.js\"></script>" >> ~/gameflix/${rom3}.html
echo "$xmlbuf" >> ~/gamelists/${prev_platform}/gamelist.xml
echo "<figure><a href='${rom3}.html'><img src='https://raw.githubusercontent.com/wizzardsk/es-theme-carbon/master/art/background/${rom3}.jpg'><figcaption>${rom6}</figcaption></a>$pocet</figure>" >> ~/gameflix/main.html; ((platforms++))
echo "<a href=\"${rom3}.html\" target=\"main\">${rom6}</a> <small>$pocet</small><br />" >> ~/gameflix/systems.html
# Close all gamelist XMLs
for k in "${!gamelist_started[@]}"; do
  echo "</gameList>" >> ~/gamelists/${k}/gamelist.xml
done

cat retroarch.end >> ~/gameflix/retroarch.sh; cp favicon.png ~/gameflix/
chmod +x ~/gameflix/retroarch.sh; echo "<p><b>Total: $total</b>" >> ~/gameflix/systems.html; echo "<p><b>Platforms: $platforms</b>" >> ~/gameflix/systems.html
