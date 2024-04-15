#!/bin/bash
mkdir -p ~/gameflix
IFS=";"

url="https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.txt"
content=$(curl -s "$url")
IFS=$'\n' read -d '' -ra roms <<<"$content"
for line in "${roms[@]}"; do
    echo "$line"
done

echo "<link rel=\"stylesheet\" type=\"text/css\" href=\"style.css\" />" > ~/gameflix/systems.html
cp ~/gameflix/systems.html ~/gameflix/main.html
echo "<title>gameflix</title><frameset border=0 cols='260, 100%'><frame name='menu' src='systems.html'><frame name='main' src='main.html'></frameset>" > ~/gameflix/gameflix.html
wget -O ~/gameflix/retroarch.sh https://raw.githubusercontent.com/WizzardSK/gameflix/main/retroarch.1st
wget -O ~/gameflix/style.css https://raw.githubusercontent.com/WizzardSK/gameflix/main/style.css
wget -O ~/gameflix/script.js https://raw.githubusercontent.com/WizzardSK/gameflix/main/script.js

for each in "${roms[@]}"; do
  if [ "$platform" == "${rom[0]}" ]; then ((platforms++)); fi
  platform=${rom[0]}
  read -ra rom < <(printf '%s' "$each")
  rom3=$(sed 's/<[^>]*>//g' <<< "${rom[3]}")
  if [ "${rom[3]}" = "<p>MS-DOS" ]; then rom[1]="../roms/dos-other"; fi
  if [[ ${rom[1]} =~ \.zip$ ]]; then
    romfolder="roms/${rom3}"
    emufolder="${rom3}"  
  else 
    romfolder="myrient/${rom[1]}"
    emufolder="${rom[1]##*/}"
  fi
  if [ -e ~/gameflix/${rom3}.html ]; then
    pocet=$(ls ~/${romfolder} -1 | wc -l)
    total=$((pocet+total))
    echo "<a href='${rom3}.html' target='main'>${rom[3]}</a> ($pocet)<br />" >> ~/gameflix/systems.html
    echo "<figure><a href='${rom3}.html'><img src='https://raw.githubusercontent.com/libretro/retroarch-assets/master/xmb/monochrome/png/"${rom[2]}".png'><figcaption>${rom[2]} ($pocet)</figcaption></a></figure>" >> ~/gameflix/main.html
    ext=""
    if [ -n "${rom[5]}" ]; then ext="; ext=\"${rom[5]}\""; fi
    echo "*\"${emufolder}\") core=\"${rom[4]}\"${ext};;" >> ~/gameflix/retroarch.sh
    continue
  fi
  > ~/gameflix/${rom3}.html
  wget -O ~/gameflix/${rom3}.html https://raw.githubusercontent.com/WizzardSK/gameflix/main/platform.html
  pocet=0    
  {
    while IFS= read -r line; do
      if [[ ! ${line} =~ \[BIOS\] ]]; then
        ahref=$(echo "$line" | sed -e "s/'/\\\'/g")
        thumb=$(echo "$line" | sed -e 's/&/_/g' -e "s/'/\\\'/g" -e 's/#/%23/g')
        echo "<figure onclick=\"window.location.href='../$romfolder/${ahref}'\"><img loading=lazy src=\"http://thumbnails.libretro.com/${rom[2]}/Named_Snaps/${line%.*}.png\"><figcaption>${line%.*}</figcaption></figure>" >> ~/gameflix/${rom3}.html
        ((pocet++))
        ((total++))
      fi
    done
  } < <(ls ~/${romfolder})
  echo "</div><script src=\"script.js\"></script>" >> ~/gameflix/${rom3}.html
  echo "<a href='${rom3}.html' target='main'>${rom[3]}</a> ($pocet)<br />" >> ~/gameflix/systems.html
  echo "<figure><a href='${rom3}.html'><img src='https://raw.githubusercontent.com/libretro/retroarch-assets/master/xmb/monochrome/png/"${rom[2]}".png'><figcaption>${rom[2]} ($pocet)</figcaption></a></figure>" >> ~/gameflix/main.html
  ext=""
  if [ -n "${rom[5]}" ]; then ext="; ext=\"${rom[5]}\""; fi
  echo "*\"${emufolder}\") core=\"${rom[4]}\"${ext};;" >> ~/gameflix/retroarch.sh
done

curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/retroarch.end | tee -a ~/gameflix/retroarch.sh  
chmod +x ~/gameflix/retroarch.sh
echo "<p><b>Total: $total</b>" >> ~/gameflix/systems.html
echo "<p><b>Platforms: $platforms</b>" >> ~/gameflix/systems.html
