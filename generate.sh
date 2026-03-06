#!/bin/bash
shopt -s nocasematch;
declare -A sys thumb separator; sysorder=(); needsep=0; while IFS=',' read -r k v t; do if [[ -z "$k" ]]; then needsep=1; sepname="$v"; continue; fi; sys[$k]="$v"; thumb[$k]="$t"; sysorder+=("$k"); if [[ $needsep -eq 1 ]]; then separator[$k]="$sepname"; needsep=0; fi; done < <(tail -n +2 systems.csv)
declare -A sysroms; while IFS=';' read -r k rest; do sysroms[$k]+="$k;$rest;${thumb[$k]};${sys[$k]}"$'\n'; done < <(awk '{o="";i=1;n=length($0);while(i<=n){c=substr($0,i,1);if(c==","){o=o";";i++}else if(c=="\""){i++;while(i<=n){c=substr($0,i,1);if(c=="\""){if(substr($0,i+1,1)=="\""){o=o"\"";i+=2}else{i++;break}}else{o=o c;i++}}}else{o=o c;i++}};print o}' <(tail -n +2 platforms.csv ))
roms=(); for k in "${sysorder[@]}"; do while IFS= read -r line; do [[ -n "$line" ]] && roms+=("$line"); done <<< "${sysroms[$k]}"; done
mkdir -p ~/{gameflix,rom,gamelists,zip,zips,mount} ~/gamelists/{tic80,wasm4,lowresnx,pico8,voxatron,switch}
echo "<link rel=\"stylesheet\" type=\"text/css\" href=\"style.css\" />" > ~/gameflix/systems.html; cp ~/gameflix/systems.html ~/gameflix/main.html
echo "<link rel=\"icon\" type=\"image/png\" href=\"/favicon.png\"><title>gameflix</title><frameset border=0 cols='260, 100%'><frame name='menu' src='systems.html'><frame name='main' src='main.html'></frameset>" > ~/gameflix/index.html
for file in retroarch.sh style.css script.js platform.js; do cp $file ~/gameflix/$file; done

# Pre-fetch all directory listings in parallel (rclone mount is slow per-request)
echo "Pre-fetching directory listings..."
cache=~/dircache; mkdir -p "$cache"
jobs_running=0
while IFS= read -r path; do
  h=$(echo -n "$path" | md5sum | cut -d' ' -f1)
  (ls "$HOME/myrient/$path" 2>/dev/null > "$cache/$h.txt" || true) &
  ((jobs_running++))
  if ((jobs_running >= 20)); then wait -n; ((jobs_running--)); fi
done < <(cut -d',' -f2 platforms.csv | tail -n +2 | sort -u)
wait
echo "Pre-fetch done."

echo "<b>Fantasy & Homebrew</b><br />" >> ~/gameflix/systems.html; echo "<h3 style=\"width:100%\">Fantasy & Homebrew</h3>" >> ~/gameflix/main.html

# TIC-80 - all categories fetched in parallel
pocet=0; echo "TIC-80"; cp platform.html ~/gameflix/TIC-80.html; ((platforms++))
echo "<gameList>" > ~/gamelists/tic80/gamelist.xml
echo "*\"TIC-80/\"*) core=\"tic80_libretro\";;" >> ~/gameflix/retroarch.sh
tic_cache=~/tic_cache; mkdir -p "$tic_cache"
for tic_cat in Games Tech Tools Music WIP Demoscene Livecoding; do
  curl -s "https://tic80.com/api?fn=dir&path=play/$tic_cat" > "$tic_cache/$tic_cat" &
done; wait
for tic_cat in Games Tech Tools Music WIP Demoscene Livecoding; do
  data=$(<"$tic_cache/$tic_cat")
  cat_count=$(echo "$data" | grep -o 'filename' | wc -l)
  [[ $cat_count -eq 0 ]] && continue
  pocet=$((pocet+cat_count)); total=$((total+cat_count))
  echo -e "<h3 id=\"$tic_cat\" class=\"section-header\">$tic_cat</h3>\n<script>bgImage(\"tic80\")\nfileNames = [" >> ~/gameflix/TIC-80.html
  echo "$data" | sed 's/},/}\n/g' | awk '
    match($0, /id *= *([0-9]+)/, a) && match($0, /hash *= *"([a-f0-9]+)"/, b) && match($0, /name *= *"([^"]+)"/, c) {
      sub(/\.tic$/, "", c[1]); print a[1] "\t" b[1] "\t" c[1]
    }' | sort -nr -k1,1 | awk '{ print "\"" $0 "\"," }' >> ~/gameflix/TIC-80.html
  printf ']; generateTicLinks("roms/TIC-80", "TIC-80");</script>\n' >> ~/gameflix/TIC-80.html
done
echo "<script src=\"script.js\"></script>" >> ~/gameflix/TIC-80.html
echo "<figure><a href='TIC-80.html'><img src='https://raw.githubusercontent.com/wizzardsk/es-theme-carbon/master/art/background/tic80.jpg'><figcaption>TIC-80</figcaption></a>$pocet</figure>" >> ~/gameflix/main.html
echo "<a href=\"TIC-80.html\" target=\"main\">TIC-80</a> <small>$pocet</small><br />" >> ~/gameflix/systems.html
echo "<game><path>./surf.tic</path><name>TIC-80 surf</name><image>./tic80.png</image></game></gameList>" >> ~/gamelists/tic80/gamelist.xml

# LowresNX - categories with section headers
pocet=0; echo "LowresNX"; cp platform.html ~/gameflix/LowresNX.html; ((platforms++))
echo "*\"LowresNX/\"*) core=\"lowresnx_libretro\";;" >> ~/gameflix/retroarch.sh
declare -A lrnx_names=([game]=Games [art]=Art [tool]=Tools [example]=Examples)
section_open=0
{
  echo "<gameList>"
  while IFS=$'\t' read -r id rest; do
    if [[ "$id" == "---" ]]; then
      if [[ $section_open -eq 1 ]]; then
        printf ']; generateLrNXLinks("roms/LowresNX", "LowresNX");</script>\n' >> ~/gameflix/LowresNX.html
      fi
      section_name="${lrnx_names[$rest]:-$rest}"
      echo -e "<h3 id=\"$section_name\" class=\"section-header\">$section_name</h3>\n<script>bgImage(\"lowresnx\")\nfileNames = [" >> ~/gameflix/LowresNX.html
      section_open=1; continue
    fi
    IFS=$'\t' read -r name picture cart <<< "$rest"
    if [[ -n "$cart" && -n "$picture" ]]; then
      echo "\"$cart\t$picture\t$name\t$id\"," >> ~/gameflix/LowresNX.html
      ((pocet++)); ((total++))
    fi
    echo "<game><path>./${cart}</path><name>${name}</name><image>./${picture}</image></game>"
  done < fantasy/lowresnx.txt
  echo "</gameList>"
} > ~/gamelists/lowresnx/gamelist.xml
printf ']; generateLrNXLinks("roms/LowresNX", "LowresNX");</script>\n' >> ~/gameflix/LowresNX.html
echo "<script src=\"script.js\"></script>" >> ~/gameflix/LowresNX.html
echo "<figure><a href='LowresNX.html'><img src='https://raw.githubusercontent.com/wizzardsk/es-theme-carbon/master/art/background/lowresnx.jpg'><figcaption>LowresNX</figcaption></a>$pocet</figure>" >> ~/gameflix/main.html
echo "<a href=\"LowresNX.html\" target=\"main\">LowresNX</a> <small>$pocet</small><br />" >> ~/gameflix/systems.html

# WASM-4 - dual fd output
pocet=$(ls ~/roms/WASM-4/*.wasm | wc -l); total=$((pocet+total))
echo "<figure><a href='WASM-4.html'><img src='https://raw.githubusercontent.com/wizzardsk/es-theme-carbon/master/art/background/wasm4.jpg'><figcaption>WASM-4</figcaption></a>$pocet</figure>" >> ~/gameflix/main.html
echo "<a href=\"WASM-4.html\" target=\"main\">WASM-4</a> <small>$pocet</small><br />" >> ~/gameflix/systems.html; echo "*\"WASM-4/\"*) core=\"wasm4_libretro\";;" >> ~/gameflix/retroarch.sh
echo "WASM-4"; cp platform.html ~/gameflix/WASM-4.html; echo "<script>bgImage(\"wasm4\"); fileNames = [" >> ~/gameflix/WASM-4.html; ((platforms++))
exec 3>> ~/gameflix/WASM-4.html
{
  echo "<gameList>"
  html=$(curl -s "https://wasm4.org/play/"); while read -r line; do
    image=$(echo "$line" | grep -oP '(?<=src=")/carts/[^"]+'); title=$(echo "$line" | grep -oP '(?<=alt=")[^"]+'); image_name=$(basename "$image" .png)
    echo "\"$image_name\t$title\"," >&3
    echo "<game><path>./${image_name}.wasm</path><name>${title}</name><image>./${image_name}.png</image></game>"
  done <<< "$(echo "$html" | grep -oP '<img src="/carts/[^"]+\.png" alt="[^"]+"')"
  echo "</gameList>"
} > ~/gamelists/wasm4/gamelist.xml
exec 3>&-
printf ']; generateWasmLinks("roms/WASM-4", "WASM-4");</script><script src=\"script.js\"></script>' >> ~/gameflix/WASM-4.html

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

# Main ROM loop - file descriptors for HTML and XML, no string buffering
declare -A gamelist_started
html_fd=3; xml_fd=4
IFS=";"; for each in "${roms[@]}"; do
  read -ra rom < <(printf '%s' "$each");
  if [[ "$rom3" != "${rom[0]}" ]]; then
    # Close previous platform fds and finalize
    if [ -n "$rom3" ]; then
      echo ']; generateFileLinks("'"$prev_romfolder"'", "'"${prev_imagepath}"'");</script>' >&$html_fd
      echo "<script src=\"script.js\"></script>" >&$html_fd
      exec {html_fd}>&- {xml_fd}>&-
      echo ${rom[6]}
      echo "<figure><a href='${rom3}.html'><img src='https://raw.githubusercontent.com/wizzardsk/es-theme-carbon/master/art/background/${rom3}.jpg'><figcaption>${rom6}</figcaption></a>$pocet</figure>" >> ~/gameflix/main.html
      echo "<a href=\"${rom3}.html\" target=\"main\">${rom6}</a> <small>$pocet</small><br />" >> ~/gameflix/systems.html; ((platforms++))
    fi
    [[ -n "${separator[${rom[0]}]}" ]] && echo "<br /><b>${separator[${rom[0]}]}</b><br />" >> ~/gameflix/systems.html && echo "<h3 style=\"width:100%\">${separator[${rom[0]}]}</h3>" >> ~/gameflix/main.html
    cp platform.html ~/gameflix/${rom[0]}.html
    pocet=0
    # Open new fds
    exec {html_fd}>> ~/gameflix/${rom[0]}.html
  else
    # Close section, keep fds open for same platform
    echo ']; generateFileLinks("'"$prev_romfolder"'", "'"${prev_imagepath}"'");</script>' >&$html_fd
  fi
  echo -e "<h3 id=\"${rom[2]}\" class=\"section-header\">${rom[2]}</h3>\n<script>bgImage(\"${rom[0]}\")\nfileNames = [" >&$html_fd
  rom3="${rom[0]}"; rom6="${rom[6]}"
  mkdir -p ~/mount/${rom[0]} ~/gamelists/${rom[0]}; romfolder="myrient/${rom[1]}"; emufolder="${rom[1]}"
  foldername="${rom[2]//<[^>]*>/}"
  # Write <gameList> header once per platform and open xml fd
  if [[ -z "${gamelist_started[${rom[0]}]}" ]]; then
    echo "<gameList>" > ~/gamelists/${rom[0]}/gamelist.xml
    exec {xml_fd}>> ~/gamelists/${rom[0]}/gamelist.xml
    gamelist_started[${rom[0]}]=1
  fi
  cachefile="$cache/$(echo -n "${rom[1]}" | md5sum | cut -d' ' -f1).txt"
  romdir=~/"${romfolder}"
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    line2="${line%.*}"; echo "\"${line}\"," >&$html_fd; ((pocet++)); ((total++))
    if [[ "$line2" == *")"* ]]; then thumb="${line2%%)*})"; else thumb="$line2"; fi
    if [[ "$line" != *.* ]]; then polozka="folder"; else polozka="game"; fi
    hra="<$polozka><path>./$foldername/${line}</path><name>${line2}</name><image>~/../thumbs/${rom[5]}/Named_Snaps/${thumb}.png</image>"
    if [[ ! "$line" =~ \[(bios|a[0-9]{0,2}|b[0-9]{0,2}|c|f|h [^]]*|o ?.*|p ?.*|t ?.*|cr ?.*)\]|\((demo( [0-9]+)?|beta( [0-9]+)?|alpha( [0-9]+)?|(disk|side)( [2-9B-Z]).*|pre-release|aftermarket|alt|alternate|unl|channel|system|dlc)\) ]]; then
      echo "${hra}</$polozka>" >&$xml_fd
    else echo "${hra}<hidden>true</hidden></$polozka>" >&$xml_fd; fi
  done < "$cachefile"
  prev_romfolder="$romfolder"; prev_imagepath="${rom[5]// /_}"; prev_platform="${rom[0]}"
  platform=${rom[0]}; ext=""; if [ -n "${rom[4]}" ]; then ext="; ext=\"${rom[4]}\""; fi; emu="${rom[3]//\"/\\\"}"; echo "*\"${emufolder}/\"*) core=\"${emu}\"${ext};;" >> ~/gameflix/retroarch.sh
  echo "<folder><path>./$foldername</path><name>$foldername</name><image>~/../thumb/${rom[0]}.png</image></folder>" >&$xml_fd
done
# Flush last platform
echo ']; generateFileLinks("'"$prev_romfolder"'", "'"${prev_imagepath}"'");</script>' >&$html_fd
echo "<script src=\"script.js\"></script>" >&$html_fd
exec {html_fd}>&- {xml_fd}>&-
echo "<figure><a href='${rom3}.html'><img src='https://raw.githubusercontent.com/wizzardsk/es-theme-carbon/master/art/background/${rom3}.jpg'><figcaption>${rom6}</figcaption></a>$pocet</figure>" >> ~/gameflix/main.html; ((platforms++))
echo "<a href=\"${rom3}.html\" target=\"main\">${rom6}</a> <small>$pocet</small><br />" >> ~/gameflix/systems.html
# Close all gamelist XMLs
for k in "${!gamelist_started[@]}"; do
  echo "</gameList>" >> ~/gamelists/${k}/gamelist.xml
done

echo '<script>document.querySelectorAll("img").forEach(function(i){if(i.complete)i.classList.add("loaded");else i.onload=function(){this.classList.add("loaded")}})</script>' >> ~/gameflix/main.html
cat retroarch.end >> ~/gameflix/retroarch.sh; cp favicon.png ~/gameflix/
chmod +x ~/gameflix/retroarch.sh; echo "<p><b>Total: $total</b>" >> ~/gameflix/systems.html; echo "<p><b>Platforms: $platforms</b>" >> ~/gameflix/systems.html
