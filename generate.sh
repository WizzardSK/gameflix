#!/bin/bash
mkdir -p ~/gameflix
IFS=$'\n' read -d '' -ra roms <<< "$(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.txt)"
echo "<link rel=\"stylesheet\" type=\"text/css\" href=\"style.css\" />" > ~/gameflix/systems.html; cp ~/gameflix/systems.html ~/gameflix/main.html
echo "<link rel=\"icon\" type=\"image/png\" href=\"/favicon.png\"><title>gameflix</title><frameset border=0 cols='260, 100%'><frame name='menu' src='systems.html'><frame name='main' src='main.html'></frameset>" > ~/gameflix/index.html
for file in retroarch.sh style.css script.js platform.js; do wget -nv -O ~/gameflix/$file https://raw.githubusercontent.com/WizzardSK/gameflix/main/$file; done

echo "<figure><a href='TIC-80.html'><img class=loaded src='https://raw.githubusercontent.com/fabricecaruso/es-theme-carbon/master/art/consoles/tic80.png'></a><figcaption>TIC-80</figcaption></figure>
<figure><a href='WASM-4.html'><img class=loaded src='https://raw.githubusercontent.com/fabricecaruso/es-theme-carbon/master/art/consoles/wasm4.png'></a><figcaption>WASM-4</figcaption></figure>
<figure><a href='Uzebox.html'><img class=loaded src='https://raw.githubusercontent.com/fabricecaruso/es-theme-carbon/master/art/consoles/uzebox.png'></a><figcaption>Uzebox</figcaption></figure>
<figure><a href='LowresNX.html'><img class=loaded src='https://raw.githubusercontent.com/fabricecaruso/es-theme-carbon/master/art/consoles/lowresnx.png'></a><figcaption>LowresNX</figcaption></figure>
<figure><a href='PICO-8.html'><img class=loaded src='https://raw.githubusercontent.com/fabricecaruso/es-theme-carbon/master/art/consoles/pico8.png'></a><figcaption>PICO-8</figcaption></figure>
<figure><a href='Voxatron.html'><img class=loaded src='https://wiki.batocera.org/_media/systems:voxatron.png'></a><figcaption>Voxatron</figcaption></figure>
<figure><a href='Vircon32.html'><img class=loaded src='https://fantasyconsoles.org/w/images/9/9c/Vircon32-logo.png'></a><figcaption>Vircon32</figcaption></figure>" >> ~/gameflix/main.html

pocet=$(ls ~/roms/TIC-80/*.tic | wc -l); total=$((pocet+total))
echo "<a href=\"TIC-80.html\" target=\"main\">TIC-80</a> ($pocet)<br />" >> ~/gameflix/systems.html; echo "*\"TIC-80\") core=\"tic80_libretro\";;" >> ~/gameflix/retroarch.sh  
wget -nv -O ~/gameflix/TIC-80.html https://raw.githubusercontent.com/WizzardSK/gameflix/main/platform.html
echo "<script>bgImage(\"tic80\"); const fileNames = [" >> ~/gameflix/TIC-80.html; ((platforms++))
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
wget -nv -O ~/gameflix/WASM-4.html https://raw.githubusercontent.com/WizzardSK/gameflix/main/platform.html
echo "<script>bgImage(\"wasm4\"); const fileNames = [" >> ~/gameflix/WASM-4.html; ((platforms++))
html=$(curl -s "https://wasm4.org/play/"); echo "$html" | grep -oP '<img src="/carts/[^"]+\.png" alt="[^"]+"' | while read -r line; do
  image=$(echo "$line" | grep -oP '(?<=src=")/carts/[^"]+'); title=$(echo "$line" | grep -oP '(?<=alt=")[^"]+'); image_name=$(basename "$image" .png); echo -e "\"$image_name\t$title\"," >> ~/gameflix/WASM-4.html
done; printf ']; generateWasmLinks("roms/WASM-4", "WASM-4");</script><script src=\"script.js\"></script>' >> ~/gameflix/WASM-4.html

pocet=$(curl -s "https://raw.githubusercontent.com/WizzardSK/gameflix/refs/heads/main/fantasy/uzebox.txt" | wc -l); total=$((pocet+total))
echo "<a href=\"Uzebox.html\" target=\"main\">Uzebox</a> ($pocet)<br />" >> ~/gameflix/systems.html; echo "*\"Uzebox\") core=\"uzem_libretro\";;" >> ~/gameflix/retroarch.sh  
wget -nv -O ~/gameflix/Uzebox.html https://raw.githubusercontent.com/WizzardSK/gameflix/main/platform.html
echo "<script>bgImage(\"uzebox\"); const fileNames = [" >> ~/gameflix/Uzebox.html; ((platforms++))
curl -s "https://raw.githubusercontent.com/WizzardSK/gameflix/refs/heads/main/fantasy/uzebox.txt" | while IFS=$'\t' read -r id cart name; do echo -e "\"$id\t$cart\t$name\"," >> ~/gameflix/Uzebox.html; done
printf ']; generateUzeLinks("roms/Uzebox", "Uzebox");</script><script src=\"script.js\"></script>' >> ~/gameflix/Uzebox.html

pocet=$(ls ~/roms/LowresNX/*.nx | wc -l); total=$((pocet+total))
echo "<a href=\"LowresNX.html\" target=\"main\">LowresNX</a> ($pocet)<br />" >> ~/gameflix/systems.html; echo "*\"LowresNX\") core=\"lowresnx_libretro\";;" >> ~/gameflix/retroarch.sh  
wget -nv -O ~/gameflix/LowresNX.html https://raw.githubusercontent.com/WizzardSK/gameflix/main/platform.html
echo "<script>bgImage(\"lowresnx\"); const fileNames = [" >> ~/gameflix/LowresNX.html; ((platforms++))
curl -s "https://raw.githubusercontent.com/WizzardSK/gameflix/refs/heads/main/fantasy/lowresnx.txt" | while IFS=$'\t' read -r id name picture cart; do if [[ -n "$cart" && -n "$picture" ]]; then echo -e "\"$cart\t$picture\t$name\t$id\"," >> ~/gameflix/LowresNX.html; fi; done
printf ']; generateLrNXLinks("roms/LowresNX", "LowresNX");</script><script src=\"script.js\"></script>' >> ~/gameflix/LowresNX.html

pocet=$(curl -s "https://raw.githubusercontent.com/WizzardSK/gameflix/refs/heads/main/fantasy/pico8.txt" | wc -l); total=$((pocet+total))
echo "<a href=\"PICO-8.html\" target=\"main\">PICO-8</a> ($pocet)<br />" >> ~/gameflix/systems.html; echo "*\"PICO-8\") core=\"pico8 -run\";;" >> ~/gameflix/retroarch.sh  
wget -nv -O ~/gameflix/PICO-8.html https://raw.githubusercontent.com/WizzardSK/gameflix/main/platform.html
echo "<script>bgImage(\"pico8\"); const fileNames = [" >> ~/gameflix/PICO-8.html; ((platforms++))
curl -s "https://raw.githubusercontent.com/WizzardSK/gameflix/refs/heads/main/fantasy/pico8.txt" | while IFS=$'\t' read -r id name cart; do echo -e "\"$id\t$name\t$cart\"," >> ~/gameflix/PICO-8.html; done
printf ']; generatePicoLinks("roms/PICO-8", "PICO-8");</script><script src=\"script.js\"></script>' >> ~/gameflix/PICO-8.html

pocet=$(curl -s "https://raw.githubusercontent.com/WizzardSK/gameflix/refs/heads/main/fantasy/voxatron.txt" | wc -l); total=$((pocet+total))
echo "<a href=\"Voxatron.html\" target=\"main\">Voxatron</a> ($pocet)<br />" >> ~/gameflix/systems.html; echo "*\"Voxatron\") core=\"vox\";;" >> ~/gameflix/retroarch.sh  
wget -nv -O ~/gameflix/Voxatron.html https://raw.githubusercontent.com/WizzardSK/gameflix/main/platform.html
echo "<script>bgImage(\"voxatron\"); const fileNames = [" >> ~/gameflix/Voxatron.html; ((platforms++))
curl -s "https://raw.githubusercontent.com/WizzardSK/gameflix/refs/heads/main/fantasy/voxatron.txt" | while IFS=$'\t' read -r id name cart; do echo -e "\"$id\t$name\t$cart\"," >> ~/gameflix/Voxatron.html; done
printf ']; generateVoxLinks("roms/Voxatron", "Voxatron");</script><script src=\"script.js\"></script>' >> ~/gameflix/Voxatron.html

pocet=$(ls ~/roms/Vircon32/*.zip | wc -l); total=$((pocet+total))
echo "<a href=\"Vircon32.html\" target=\"main\">Vircon32</a> ($pocet)<br />" >> ~/gameflix/systems.html; echo "*\"Vircon32\") core=\"vircon32_libretro\";;" >> ~/gameflix/retroarch.sh  
wget -nv -O ~/gameflix/Vircon32.html https://raw.githubusercontent.com/WizzardSK/gameflix/main/platform.html
echo "<script>bgImage(\"vircon32\"); const fileNames = [" >> ~/gameflix/Vircon32.html
{ while IFS= read -r line; do echo "\"${line}\"," >> ~/gameflix/Vircon32.html; ((pocet++)); ((total++)); done } < <(basename -a ~/roms/Vircon32/*.zip)
printf ']; generateFileLinks("roms/Vircon32", "Vircon32");</script><script src=\"script.js\"></script>' >> ~/gameflix/Vircon32.html

pocet=$(ls ~/roms/Atari\ 2600\ ROMS -1 | wc -l); total=$((pocet+total))
echo "<a href=\"Atari 2600 ROMS.html\" target=\"main\"><p>Atari 2600 ROMS</a> ($pocet)<br />" >> ~/gameflix/systems.html; echo "*\"Atari 2600 ROMS\") core=\"stella_libretro\";;" >> ~/gameflix/retroarch.sh  
wget -nv -O ~/gameflix/Atari\ 2600\ ROMS.html https://raw.githubusercontent.com/WizzardSK/gameflix/main/platform.html
echo "<script>bgImage(\"atari2600\"); const fileNames = [" >> ~/gameflix/Atari\ 2600\ ROMS.html
{ while IFS= read -r line; do echo "\"${line}\"," >> ~/gameflix/Atari\ 2600\ ROMS.html; ((pocet++)); ((total++)); done } < <(ls ~/roms/Atari\ 2600\ ROMS)
printf ']; generateFileLinks("roms/Atari 2600 ROMS", "Atari_-_2600");</script><script src=\"script.js\"></script>' >> ~/gameflix/Atari\ 2600\ ROMS.html

IFS=";"; for each in "${roms[@]}"; do
  read -ra rom < <(printf '%s' "$each"); rom3=$(sed 's/<[^>]*>//g' <<< "${rom[3]}")
  romfolder="myrient/${rom[1]}"; emufolder="${rom[1]}";
  if [[ "${rom[1]}" == *"eXoDOS"* ]]; then romfolder="roms/MS-DOS eXoDOS"; emufolder="roms/MS-DOS eXoDOS"; fi
  > ~/gameflix/${rom3}.html
  wget -nv -O ~/gameflix/${rom3}.html https://raw.githubusercontent.com/WizzardSK/gameflix/main/platform.html
  echo "<script>bgImage(\"${rom[0]}\"); const fileNames = [" >> ~/gameflix/${rom3}.html
  pocet=0
  { while IFS= read -r line; do echo "\"${line}\"," >> ~/gameflix/${rom3}.html; ((pocet++)); ((total++)); done } < <(ls ~/${romfolder})
  echo ']; generateFileLinks("'"$romfolder"'", "'"${rom[2]// /_}"'");</script><script src="script.js"></script>' >> ~/gameflix/${rom3}.html
  echo "<a href=\"${rom3}.html\" target=\"main\">${rom[3]}</a> ($pocet)<br />" >> ~/gameflix/systems.html
  if [ "$platform" != "${rom[0]}" ]; then
    echo "<figure><a href='${rom3}.html'><img class=loaded src='https://raw.githubusercontent.com/fabricecaruso/es-theme-carbon/master/art/consoles/"${rom[0]}".png'></a><figcaption>${rom[2]}</figcaption></figure>" >> ~/gameflix/main.html; ((platforms++))
  fi
  platform=${rom[0]}; ext=""; if [ -n "${rom[5]}" ]; then ext="; ext=\"${rom[5]}\""; fi; echo "*\"${emufolder}\") core=\"${rom[4]}\"${ext};;" >> ~/gameflix/retroarch.sh
done

ROMLIST="neogeo.dat"; curl -s "https://raw.githubusercontent.com/WizzardSK/gameflix/refs/heads/main/neogeo.dat" -o $ROMLIST; pocet=0
wget -nv -O ~/gameflix/Neo\ Geo.html https://raw.githubusercontent.com/WizzardSK/gameflix/main/platform.html
echo "<script>bgImage(\"neogeo\"); const fileNames = [" >> ~/gameflix/Neo\ Geo.html
while IFS= read -r riadok; do prvy="${riadok%%[[:space:]]*}"; ostatok="${riadok#*[[:space:]]}"; zip="${prvy%.neo}.zip"; printf '"%s\t%s",\n' "$zip" "$ostatok" >> ~/gameflix/Neo\ Geo.html; ((pocet++)); done < "$ROMLIST"
printf ']; generateFileLinks("roms/Neo Geo", "MAME");</script><script src=\"script.js\"></script>' >> ~/gameflix/Neo\ Geo.html; ((platforms++))
echo "<a href=\"Neo Geo.html\" target=\"main\">Neo Geo</a> ($pocet)<br />" >> ~/gameflix/systems.html; echo "*\"Neo Geo\") core=\"fbneo_libretro\";;" >> ~/gameflix/retroarch.sh  
echo "<figure><a href='Neo Geo.html'><img class=loaded src='https://raw.githubusercontent.com/fabricecaruso/es-theme-carbon/master/art/consoles/neogeo.png'></a><figcaption>Neo Geo</figcaption></figure>" >> ~/gameflix/main.html

curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/retroarch.end >> ~/gameflix/retroarch.sh
chmod +x ~/gameflix/retroarch.sh; echo "<p><b>Total: $total</b>" >> ~/gameflix/systems.html; echo "<p><b>Platforms: $platforms</b>" >> ~/gameflix/systems.html
cp favicon.png ~/gameflix/
