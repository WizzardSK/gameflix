#!/bin/bash
mkdir -p ~/gameflix
IFS=$'\n' read -d '' -ra roms <<< "$(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.txt)"
echo "<link rel=\"stylesheet\" type=\"text/css\" href=\"style.css\" />" > ~/gameflix/systems.html
cp ~/gameflix/systems.html ~/gameflix/main.html
echo "<title>gameflix</title><frameset border=0 cols='260, 100%'><frame name='menu' src='systems.html'><frame name='main' src='main.html'></frameset>" > ~/gameflix/index.html
wget -O ~/gameflix/retroarch.sh https://raw.githubusercontent.com/WizzardSK/gameflix/main/retroarch.1st
wget -O ~/gameflix/style.css https://raw.githubusercontent.com/WizzardSK/gameflix/main/style.css
wget -O ~/gameflix/script.js https://raw.githubusercontent.com/WizzardSK/gameflix/main/script.js
wget -O ~/gameflix/platform.js https://raw.githubusercontent.com/WizzardSK/gameflix/main/platform.js

echo "<figure><img class=loaded src='https://raw.githubusercontent.com/fabricecaruso/es-theme-carbon/master/art/consoles/tic80.png'><figcaption><a href='TIC-80.html'>TIC-80</a></figcaption></figure><figure><img class=loaded src='https://raw.githubusercontent.com/fabricecaruso/es-theme-carbon/master/art/consoles/wasm4.png'><figcaption><a href='WASM-4.html'>WASM-4</a></figcaption></figure><figure><img class=loaded src='https://raw.githubusercontent.com/fabricecaruso/es-theme-carbon/master/art/consoles/uzebox.png'><figcaption><a href='Uzebox.html'>Uzebox</a></figcaption></figure><figure><img class=loaded src='https://raw.githubusercontent.com/fabricecaruso/es-theme-carbon/master/art/consoles/lowresnx.png'><figcaption><a href='LowresNX.html'>LowresNX</a>" >> ~/gameflix/main.html

pocet=$(ls ~/roms/TIC-80 -1 | wc -l); total=$((pocet+total))
echo "<a href=\"TIC-80.html\" target=\"main\">TIC-80</a> ($pocet)<br />" >> ~/gameflix/systems.html; echo "*\"TIC-80\") core=\"tic80_libretro\";;" >> ~/gameflix/retroarch.sh  
wget -O ~/gameflix/TIC-80.html https://raw.githubusercontent.com/WizzardSK/gameflix/main/platform.html
echo "<script>bgImage(\"tic80\"); const fileNames = [" >> ~/gameflix/TIC-80.html; ((platforms++))
curl -s "https://tic80.com/api?fn=dir&path=play/Games" | sed 's/},/}\n/g' | while IFS= read -r line; do
  hash=$(echo "$line" | grep -oP 'hash\s*=\s*"\K[a-f0-9]+')
  name=$(echo "$line" | grep -oP ' name\s*=\s*"\K[^"]+')
  if [[ -n "$hash" && -n "$name" ]]; then echo "\"$hash $name\"," >> ~/gameflix/TIC-80.html; fi
done
printf ']; generateTicLinks("roms/TIC-80", "TIC-80");</script><script src=\"script.js\"></script>' >> ~/gameflix/TIC-80.html

pocet=$(ls ~/roms/WASM-4 -1 | wc -l); total=$((pocet+total))
echo "<a href=\"WASM-4.html\" target=\"main\">WASM-4</a> ($pocet)<br />" >> ~/gameflix/systems.html; echo "*\"WASM-4\") core=\"wasm4_libretro\";;" >> ~/gameflix/retroarch.sh  
wget -O ~/gameflix/WASM-4.html https://raw.githubusercontent.com/WizzardSK/gameflix/main/platform.html
echo "<script>bgImage(\"wasm4\"); const fileNames = [" >> ~/gameflix/WASM-4.html; ((platforms++))
html=$(curl -s "https://wasm4.org/play/")
echo "$html" | grep -oP '<img src="/carts/[^"]+\.png" alt="[^"]+"' | while read -r line; do
  image=$(echo "$line" | grep -oP '(?<=src=")/carts/[^"]+'); title=$(echo "$line" | grep -oP '(?<=alt=")[^"]+'); image_name=$(basename "$image" .png); echo "\"$image_name,$title\"," >> ~/gameflix/WASM-4.html
done
printf ']; generateWasmLinks("roms/WASM-4", "WASM-4");</script><script src=\"script.js\"></script>' >> ~/gameflix/WASM-4.html

pocet=$(ls ~/roms/Uzebox/*.uze ~/roms/Uzebox/*.UZE -1 | wc -l); total=$((pocet+total))
echo "<a href=\"Uzebox.html\" target=\"main\">Uzebox</a> ($pocet)<br />" >> ~/gameflix/systems.html; echo "*\"Uzebox\") core=\"uzem_libretro\";;" >> ~/gameflix/retroarch.sh  
wget -O ~/gameflix/Uzebox.html https://raw.githubusercontent.com/WizzardSK/gameflix/main/platform.html
echo "<script>bgImage(\"uzebox\"); const fileNames = [" >> ~/gameflix/Uzebox.html; ((platforms++))
{ while IFS= read -r line; do echo "\"${line}\"," >> ~/gameflix/Uzebox.html; ((pocet++)); ((total++)); done } < <(ls ~/roms/Uzebox/*.uze ~/roms/Uzebox/*.UZE 2>/dev/null | xargs -I {} basename {})
printf ']; generateUzeLinks("roms/Uzebox", "Uzebox");</script><script src=\"script.js\"></script>' >> ~/gameflix/Uzebox.html

pocet=$(curl -s "https://raw.githubusercontent.com/WizzardSK/gameflix/refs/heads/main/lowresnx.txt" | wc -l); total=$((pocet+total))
echo "<a href=\"LowresNX.html\" target=\"main\">LowresNX</a> ($pocet)<br />" >> ~/gameflix/systems.html; echo "*\"LowresNX\") core=\"lowresnx_libretro\";;" >> ~/gameflix/retroarch.sh  
wget -O ~/gameflix/LowresNX.html https://raw.githubusercontent.com/WizzardSK/gameflix/main/platform.html
echo "<script>bgImage(\"lowresnx\"); const fileNames = [" >> ~/gameflix/LowresNX.html; ((platforms++))
curl -s "https://raw.githubusercontent.com/WizzardSK/gameflix/refs/heads/main/lowresnx.txt" | while IFS="|" read -r id name picture cart; do if [[ -n "$cart" && -n "$picture" ]]; then echo "'$cart|$picture|$name'," >> ~/gameflix/LowresNX.html; fi; done
printf ']; generateLrNXLinks("roms/LowresNX", "LowresNX");</script><script src=\"script.js\"></script>' >> ~/gameflix/LowresNX.html

pocet=$(curl -s "https://raw.githubusercontent.com/WizzardSK/gameflix/refs/heads/main/pico8.txt" | wc -l); total=$((pocet+total))
echo "<a href=\"PICO-8.html\" target=\"main\">PICO-8</a> ($pocet)<br />" >> ~/gameflix/systems.html; echo "*\"PICO-8\") core=\"retro8_libretro\";;" >> ~/gameflix/retroarch.sh  
wget -O ~/gameflix/PICO-8.html https://raw.githubusercontent.com/WizzardSK/gameflix/main/platform.html
echo "<script>bgImage(\"pico8\"); const fileNames = [" >> ~/gameflix/PICO-8.html; ((platforms++))
curl -s "https://raw.githubusercontent.com/WizzardSK/gameflix/refs/heads/main/pico8.txt" | while IFS=$'\t' read -r id name cart; do if [[ -n "$cart" && -n "$picture" ]]; then echo -e "'$cart\t$cart'," >> ~/gameflix/PICO-8.html; fi; done
printf ']; generatePicoLinks("roms/PICO-8", "PICO-8");</script><script src=\"script.js\"></script>' >> ~/gameflix/PICO-8.html

pocet=$(ls ~/roms/Atari\ 2600\ ROMS -1 | wc -l); total=$((pocet+total))
echo "<a href=\"Atari 2600 ROMS.html\" target=\"main\"><p>Atari 2600 ROMS</a> ($pocet)<br />" >> ~/gameflix/systems.html; echo "*\"Atari 2600 ROMS\") core=\"stella_libretro\";;" >> ~/gameflix/retroarch.sh  
wget -O ~/gameflix/Atari\ 2600\ ROMS.html https://raw.githubusercontent.com/WizzardSK/gameflix/main/platform.html
echo "<script>bgImage(\"atari2600\"); const fileNames = [" >> ~/gameflix/Atari\ 2600\ ROMS.html
{ while IFS= read -r line; do echo "\"${line}\"," >> ~/gameflix/Atari\ 2600\ ROMS.html; ((pocet++)); ((total++)); done } < <(ls ~/roms/Atari\ 2600\ ROMS)
printf ']; generateFileLinks("roms/Atari 2600 ROMS", "Atari_-_2600");</script><script src=\"script.js\"></script>' >> ~/gameflix/Atari\ 2600\ ROMS.html

IFS=";"
for each in "${roms[@]}"; do
  read -ra rom < <(printf '%s' "$each")
  rom3=$(sed 's/<[^>]*>//g' <<< "${rom[3]}")
  if [[ "${rom[3]}" == *"eXoDOS"* ]]; then rom[1]="../roms/dos-other"; fi
  if [[ ${rom[1]} =~ \.zip$ ]]; then romfolder="roms/${rom3}"; emufolder="${rom3}"; else romfolder="myrient/${rom[1]}"; emufolder="${rom[1]}"; fi
  if [[ "${rom[3]}" == *"eXoDOS"* ]]; then emufolder="roms/dos-other"; fi
  if [ -e ~/gameflix/${rom3}.html ]; then
    pocet=$(ls ~/${romfolder} -1 | wc -l)
    total=$((pocet+total))
    echo "<a href=\"${rom3}.html\" target=\"main\">${rom[3]}</a> ($pocet)<br />" >> ~/gameflix/systems.html
    if [ "$platform" != "${rom[0]}" ]; then
      echo "</figcaption></figure><figure><img class=loaded src='https://raw.githubusercontent.com/fabricecaruso/es-theme-carbon/master/art/consoles/"${rom[0]}".png'><figcaption>" >> ~/gameflix/main.html
      ((platforms++))
    fi
    echo "<a href=\"${rom3}.html\">${rom3}</a><br>" >> ~/gameflix/main.html
    platform=${rom[0]}
    ext=""
    if [ -n "${rom[5]}" ]; then ext="; ext=\"${rom[5]}\""; fi
    echo "*\"${emufolder}\") core=\"${rom[4]}\"${ext};;" >> ~/gameflix/retroarch.sh
    continue
  fi
  > ~/gameflix/${rom3}.html
  wget -O ~/gameflix/${rom3}.html https://raw.githubusercontent.com/WizzardSK/gameflix/main/platform.html
  echo "<script>bgImage(\"${rom[0]}\"); const fileNames = [" >> ~/gameflix/${rom3}.html
  pocet=0
  { while IFS= read -r line; do
    echo "\"${line}\"," >> ~/gameflix/${rom3}.html; ((pocet++)); ((total++));
  done } < <(ls ~/${romfolder})
  echo ']; generateFileLinks("'"$romfolder"'", "'"${rom[2]// /_}"'");</script><script src="script.js"></script>' >> ~/gameflix/${rom3}.html
  echo "<a href=\"${rom3}.html\" target=\"main\">${rom[3]}</a> ($pocet)<br />" >> ~/gameflix/systems.html
  if [ "$platform" != "${rom[0]}" ]; then
    echo "</figcaption></figure><figure><img class=loaded src='https://raw.githubusercontent.com/fabricecaruso/es-theme-carbon/master/art/consoles/"${rom[0]}".png'><figcaption>" >> ~/gameflix/main.html
    ((platforms++))
  fi
  echo "<a href=\"${rom3}.html\">${rom3}</a><br>" >> ~/gameflix/main.html
  platform=${rom[0]}
  ext=""
  if [ -n "${rom[5]}" ]; then ext="; ext=\"${rom[5]}\""; fi
  echo "*\"${emufolder}\") core=\"${rom[4]}\"${ext};;" >> ~/gameflix/retroarch.sh
done
curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/retroarch.end | tee -a ~/gameflix/retroarch.sh
chmod +x ~/gameflix/retroarch.sh
echo "<p><b>Total: $total</b>" >> ~/gameflix/systems.html
echo "<p><b>Platforms: $platforms</b>" >> ~/gameflix/systems.html
