#!/bin/bash
mkdir -p ~/gameflix
source <(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.txt)
IFS=";"
echo "<link rel=\"stylesheet\" type=\"text/css\" href=\"style.css\" />" > ~/gameflix/systems.html
cp ~/gameflix/systems.html ~/gameflix/main.html
echo "<title>gameflix</title><frameset border=0 cols='240, 100%'><frame name='menu' src='systems.html'><frame name='main' src='main.html'></frameset>" > ~/gameflix/gameflix.html
wget -O ~/gameflix/retroarch.sh https://raw.githubusercontent.com/WizzardSK/gameflix/main/retroarch.1st
wget -O ~/gameflix/style.css https://raw.githubusercontent.com/WizzardSK/gameflix/main/style.css
wget -O ~/gameflix/script.js https://raw.githubusercontent.com/WizzardSK/gameflix/main/script.js

echo "<h3>No-Intro/Redump</h3>" >> ~/gameflix/systems.html
echo "<h3>No-Intro/Redump</h3>" >> ~/gameflix/main.html
for each in "${roms[@]}"; do
  ((platforms++))
  read -ra rom < <(printf '%s' "$each")
  rom3=$(sed 's/<[^>]*>//g' <<< "${rom[3]}")
  if [ "${rom[3]}" = "<p>MS-DOS" ]; then rom[1]="../roms/dos-other"; fi
  if [ -e ~/gameflix/${rom3}.html ]; then
    pocet=$(ls ~/myrient/${rom[1]} -1 | wc -l)
    total=$((pocet+total))
    echo "<a href='${rom3}.html' target='main'>${rom[3]}</a> ($pocet)<br />" >> ~/gameflix/systems.html
    echo "<figure><a href='${rom3}.html'><img src='https://raw.githubusercontent.com/libretro/retroarch-assets/master/xmb/monochrome/png/"${rom[2]}".png'><figcaption>${rom[2]} ($pocet)</figcaption></a></figure>" >> ~/gameflix/main.html
    ext=""
    if [ -n "${rom[5]}" ]; then ext="; ext=\"${rom[5]}\""; fi
    echo "*\"${rom[1]##*/}\") core=\"${rom[4]}\"${ext};;" >> ~/gameflix/retroarch.sh
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
        echo "<figure onclick=\"window.location.href='../myrient/${rom[1]}/${ahref}'\"><img loading=lazy src=\"http://thumbnails.libretro.com/${rom[2]}/Named_Snaps/${line%.*}.png\"><figcaption>${line%.*}</figcaption></figure>" >> ~/gameflix/${rom3}.html
        ((pocet++))
        ((total++))
      fi
    done
  } < <(ls ~/myrient/${rom[1]})
  echo "</div><script src=\"script.js\"></script>" >> ~/gameflix/${rom3}.html
  echo "<a href='${rom3}.html' target='main'>${rom[3]}</a> ($pocet)<br />" >> ~/gameflix/systems.html
  echo "<figure><a href='${rom3}.html'><img src='https://raw.githubusercontent.com/libretro/retroarch-assets/master/xmb/monochrome/png/"${rom[2]}".png'><figcaption>${rom[2]} ($pocet)</figcaption></a></figure>" >> ~/gameflix/main.html
  ext=""
  if [ -n "${rom[5]}" ]; then ext="; ext=\"${rom[5]}\""; fi
  echo "*\"${rom[1]##*/}\") core=\"${rom[4]}\"${ext};;" >> ~/gameflix/retroarch.sh
done

echo "<h3>TOSEC</h3>" >> ~/gameflix/systems.html
echo "<h3>TOSEC</h3>" >> ~/gameflix/main.html
for each in "${zips[@]}"; do
  ((platforms++))
  read -ra zip < <(printf '%s' "$each")
  rom3=$(sed 's/<[^>]*>//g' <<< "${zip[3]}")
  if [ -e ~/gameflix/${rom3}.html ]; then
    pocet=$(ls ~/roms/${zip[0]} -1 | wc -l)
    total=$((pocet+total))
    echo "<a href='${rom3}.html' target='main'>${zip[3]}</a> ($pocet)<br />" >> ~/gameflix/systems.html  
    echo "<figure><a href='${rom3}.html'><img src='https://raw.githubusercontent.com/libretro/retroarch-assets/master/xmb/monochrome/png/"${zip[2]}".png'><figcaption>${zip[2]} ($pocet)</figcaption></a></figure>" >> ~/gameflix/main.html  
    ext=""
    if [ -n "${zip[5]}" ]; then ext="; ext=\"${zip[5]}\""; fi
    echo "*\"${zip[0]}\") core=\"${zip[4]}\"${ext};;" >> ~/gameflix/retroarch.sh
    continue
  fi
  > ~/gameflix/${rom3}.html
  wget -O ~/gameflix/${rom3}.html https://raw.githubusercontent.com/WizzardSK/gameflix/main/platform.html
  pocet=0
  {
    while IFS= read -r line; do
      if [[ ! ${line} =~ \[BIOS\] ]]; then
        ahref=$(echo "$line" | sed -e "s/'/\\\'/g")
        thumb=$(echo "$line" | sed -e 's/&/_/g' -e "s/'/\\\'/g")    
        echo "<figure onclick=\"window.location.href='../roms/${rom3}/${ahref}'\"><img loading=lazy src=\"http://thumbnails.libretro.com/${zip[2]}/Named_Snaps/${line%.*}.png\"><figcaption>${line%.*}</figcaption></figure>" >> ~/gameflix/${rom3}.html
        ((pocet++))
        ((total++))
      fi
    done
  } < <(ls ~/roms/${rom3})
  echo "</div><script src=\"script.js\"></script>" >> ~/gameflix/${rom3}.html
  echo "<a href='${rom3}.html' target='main'>${zip[3]}</a> ($pocet)<br />" >> ~/gameflix/systems.html  
  echo "<figure><a href='${rom3}.html'><img src='https://raw.githubusercontent.com/libretro/retroarch-assets/master/xmb/monochrome/png/"${zip[2]}".png'><figcaption>${zip[2]} ($pocet)</figcaption></a></figure>" >> ~/gameflix/main.html  
  ext=""
  if [ -n "${zip[5]}" ]; then ext="; ext=\"${zip[5]}\""; fi
  echo "*\"${rom3}\") core=\"${zip[4]}\"${ext};;" >> ~/gameflix/retroarch.sh
done

curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/retroarch.end | tee -a ~/gameflix/retroarch.sh  
chmod +x ~/gameflix/retroarch.sh
echo "<p><b>Total: $total</b>" >> ~/gameflix/systems.html
echo "<p><b>Platforms: $platforms</b>" >> ~/gameflix/systems.html
