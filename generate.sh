#!/bin/bash
source <(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.txt)
IFS=";"
echo "<h3>Redump/online</h3><link rel=\"stylesheet\" type=\"text/css\" href=\"style.css\" />" > ~/gameflix/systems.html
cp ~/gameflix/systems.html ~/gameflix/main.html
echo "<title>gameflix</title><frameset border=0 cols='240, 100%'><frame name='menu' src='systems.html'><frame name='main' src='main.html'></frameset>" > ~/gameflix/gameflix.html
wget -O ~/gameflix/retroarch.sh https://raw.githubusercontent.com/WizzardSK/gameflix/main/retroarch.1st
wget -O ~/gameflix/style.css https://raw.githubusercontent.com/WizzardSK/gameflix/main/style.css
wget -O ~/gameflix/script.js https://raw.githubusercontent.com/WizzardSK/gameflix/main/script.js

echo "<h3>No-Intro</h3>" >> ~/gameflix/systems.html
for each in "${romz[@]}"; do
  ((platforms++))
  read -ra zip < <(printf '%s' "$each")
  if [ -e ~/gameflix/${zip[0]}-rom.html ]; then
    pocet=$(ls ~/roms/${zip[0]}-zip -1 | wc -l)
    total=$((pocet+total))
    echo "<a href='${zip[0]}-rom.html' target='main'>${zip[3]}</a> ($pocet)<br />" >> ~/gameflix/systems.html  
    echo "<figure><a href='${zip[0]}-rom.html'><img src='https://raw.githubusercontent.com/libretro/retroarch-assets/master/xmb/monochrome/png/"${zip[2]}".png'><figcaption>${zip[2]} ($pocet)</figcaption></a></figure>" >> ~/gameflix/main.html  
    ext=""
    if [ -n "${zip[5]}" ]; then ext="; ext=\"${zip[5]}\""; fi
    echo "*\"${zip[0]}-zip\") core=\"${zip[4]}\"${ext};;" >> ~/gameflix/retroarch.sh
    continue
  fi  
  > ~/gameflix/${zip[0]}-rom.html
  wget -O ~/gameflix/${zip[0]}-rom.html https://raw.githubusercontent.com/WizzardSK/gameflix/main/platform.html
  pocet=0
  {
    while IFS= read -r line; do
      if [[ ! ${line} =~ \[BIOS\] ]]; then
        ahref=$(echo "$line" | sed -e "s/'/\\\'/g")
        thumb=$(echo "$line" | sed -e 's/&/_/g' -e "s/'/\\\'/g")    
        echo "<figure onclick=\"window.location.href='../roms/${zip[0]}-zip/${ahref}'\"><img loading=lazy src=\"http://thumbnails.libretro.com/${zip[2]}/Named_Snaps/${line%.*}.png\"><figcaption>${line%.*}</figcaption></figure>" >> ~/gameflix/${zip[0]}-rom.html
        ((pocet++))
        ((total++))
      fi
    done
  } < <(ls ~/roms/${zip[0]}-zip)
  echo "</div><script src=\"script.js\"></script>" >> ~/gameflix/${zip[0]}-rom.html
  echo "<a href='${zip[0]}-rom.html' target='main'>${zip[3]}</a> ($pocet)<br />" >> ~/gameflix/systems.html  
  echo "<figure><a href='${zip[0]}-rom.html'><img src='https://raw.githubusercontent.com/libretro/retroarch-assets/master/xmb/monochrome/png/"${zip[2]}".png'><figcaption>${zip[2]} ($pocet)</figcaption></a></figure>" >> ~/gameflix/main.html  
  ext=""
  if [ -n "${zip[5]}" ]; then ext="; ext=\"${zip[5]}\""; fi
  echo "*\"${zip[0]}-zip\") core=\"${zip[4]}\"${ext};;" >> ~/gameflix/retroarch.sh
done

for each in "${roms[@]}"; do
  ((platforms++))
  read -ra rom < <(printf '%s' "$each")
  if [ "${rom[0]}" = "dos" ]; then rom[1]="../roms/dos-other"; fi
  if [ -e ~/gameflix/${rom[0]}.html ]; then
    pocet=$(ls ~/myrient/${rom[1]} -1 | wc -l)
    total=$((pocet+total))
    echo "<a href='${rom[0]}.html' target='main'>${rom[3]}</a> ($pocet)<br />" >> ~/gameflix/systems.html
    echo "<figure><a href='${rom[0]}.html'><img src='https://raw.githubusercontent.com/libretro/retroarch-assets/master/xmb/monochrome/png/"${rom[2]}".png'><figcaption>${rom[2]} ($pocet)</figcaption></a></figure>" >> ~/gameflix/main.html
    ext=""
    if [ -n "${rom[5]}" ]; then ext="; ext=\"${rom[5]}\""; fi
    echo "*\"${rom[1]##*/}\") core=\"${rom[4]}\"${ext};;" >> ~/gameflix/retroarch.sh
    continue
  fi
  > ~/gameflix/${rom[0]}.html
  wget -O ~/gameflix/${rom[0]}.html https://raw.githubusercontent.com/WizzardSK/gameflix/main/platform.html
  pocet=0    
  {
    while IFS= read -r line; do
      if [[ ! ${line} =~ \[BIOS\] ]]; then
        ahref=$(echo "$line" | sed -e "s/'/\\\'/g")
        thumb=$(echo "$line" | sed -e 's/&/_/g' -e "s/'/\\\'/g" -e 's/#/%23/g')
        echo "<figure onclick=\"window.location.href='../myrient/${rom[1]}/${ahref}'\"><img loading=lazy src=\"http://thumbnails.libretro.com/${rom[2]}/Named_Snaps/${line%.*}.png\"><figcaption>${line%.*}</figcaption></figure>" >> ~/gameflix/${rom[0]}.html
        ((pocet++))
        ((total++))
      fi
    done
  } < <(ls ~/myrient/${rom[1]})
  echo "</div><script src=\"script.js\"></script>" >> ~/gameflix/${rom[0]}.html
  echo "<a href='${rom[0]}.html' target='main'>${rom[3]}</a> ($pocet)<br />" >> ~/gameflix/systems.html
  echo "<figure><a href='${rom[0]}.html'><img src='https://raw.githubusercontent.com/libretro/retroarch-assets/master/xmb/monochrome/png/"${rom[2]}".png'><figcaption>${rom[2]} ($pocet)</figcaption></a></figure>" >> ~/gameflix/main.html
  ext=""
  if [ -n "${rom[5]}" ]; then ext="; ext=\"${rom[5]}\""; fi
  echo "*\"${rom[1]##*/}\") core=\"${rom[4]}\"${ext};;" >> ~/gameflix/retroarch.sh
done

echo "<h3>TOSEC</h3>" >> ~/gameflix/systems.html
for each in "${zips[@]}"; do
  ((platforms++))
  read -ra zip < <(printf '%s' "$each")
  if [ -e ~/gameflix/${zip[0]}-zip.html ]; then
    pocet=$(ls ~/roms/${zip[0]} -1 | wc -l)
    total=$((pocet+total))
    echo "<a href='${zip[0]}-zip.html' target='main'>${zip[3]}</a> ($pocet)<br />" >> ~/gameflix/systems.html  
    echo "<figure><a href='${zip[0]}-zip.html'><img src='https://raw.githubusercontent.com/libretro/retroarch-assets/master/xmb/monochrome/png/"${zip[2]}".png'><figcaption>${zip[2]} ($pocet)</figcaption></a></figure>" >> ~/gameflix/main.html  
    ext=""
    if [ -n "${zip[5]}" ]; then ext="; ext=\"${zip[5]}\""; fi
    echo "*\"${zip[0]}\") core=\"${zip[4]}\"${ext};;" >> ~/gameflix/retroarch.sh
    continue
  fi
  > ~/gameflix/${zip[0]}-zip.html
  wget -O ~/gameflix/${zip[0]}-zip.html https://raw.githubusercontent.com/WizzardSK/gameflix/main/platform.html
  pocet=0
  {
    while IFS= read -r line; do
      if [[ ! ${line} =~ \[BIOS\] ]]; then
        ahref=$(echo "$line" | sed -e "s/'/\\\'/g")
        thumb=$(echo "$line" | sed -e 's/&/_/g' -e "s/'/\\\'/g")    
        echo "<figure onclick=\"window.location.href='../roms/${zip[0]}/${ahref}'\"><img loading=lazy src=\"http://thumbnails.libretro.com/${zip[2]}/Named_Snaps/${line%.*}.png\"><figcaption>${line%.*}</figcaption></figure>" >> ~/gameflix/${zip[0]}-zip.html
        ((pocet++))
        ((total++))
      fi
    done
  } < <(ls ~/roms/${zip[0]})
  echo "</div><script src=\"script.js\"></script>" >> ~/gameflix/${zip[0]}-zip.html
  echo "<a href='${zip[0]}-zip.html' target='main'>${zip[3]}</a> ($pocet)<br />" >> ~/gameflix/systems.html  
  echo "<figure><a href='${zip[0]}-zip.html'><img src='https://raw.githubusercontent.com/libretro/retroarch-assets/master/xmb/monochrome/png/"${zip[2]}".png'><figcaption>${zip[2]} ($pocet)</figcaption></a></figure>" >> ~/gameflix/main.html  
  ext=""
  if [ -n "${zip[5]}" ]; then ext="; ext=\"${zip[5]}\""; fi
  echo "*\"${zip[0]}\") core=\"${zip[4]}\"${ext};;" >> ~/gameflix/retroarch.sh
done

echo "<h3>TOSEC-ISO</h3>" >> ~/gameflix/systems.html
for each in "${isos[@]}"; do
  ((platforms++))
  read -ra rom < <(printf '%s' "$each")
  if [ -e ~/gameflix/${rom[0]}-iso.html ]; then
    pocet=$(ls ~/myrient/${rom[1]} -1 | wc -l)
    total=$((pocet+total))
    echo "<a href='${rom[0]}-iso.html' target='main'>${rom[3]}</a> ($pocet)<br />" >> ~/gameflix/systems.html
    echo "<figure><a href='${rom[0]}-iso.html'><img src='https://raw.githubusercontent.com/libretro/retroarch-assets/master/xmb/monochrome/png/"${rom[2]}".png'><figcaption>${rom[2]} ($pocet)</figcaption></a></figure>" >> ~/gameflix/main.html
    ext=""
    if [ -n "${rom[5]}" ]; then ext="; ext=\"${rom[5]}\""; fi
    echo "*\"${rom[1]}\") core=\"${rom[4]}\"${ext};;" >> ~/gameflix/retroarch.sh
    continue
  fi
  > ~/gameflix/${rom[0]}-iso.html
  wget -O ~/gameflix/${rom[0]}-iso.html https://raw.githubusercontent.com/WizzardSK/gameflix/main/platform.html
  pocet=0    
  {
    while IFS= read -r line; do
      if [[ ! ${line} =~ \[BIOS\] ]]; then
        ahref=$(echo "$line" | sed -e "s/'/\\\'/g")
        thumb=$(echo "$line" | sed -e 's/&/_/g' -e "s/'/\\\'/g" -e 's/#/%23/g')
        echo "<figure onclick=\"window.location.href='../myrient/${rom[1]}/${ahref}'\"><img loading=lazy src=\"http://thumbnails.libretro.com/${rom[2]}/Named_Snaps/${line%.*}.png\"><figcaption>${line%.*}</figcaption></figure>" >> ~/gameflix/${rom[0]}-iso.html
        ((pocet++))
        ((total++))
      fi
    done
  } < <(ls ~/myrient/${rom[1]})
  echo "</div><script src=\"script.js\"></script>" >> ~/gameflix/${rom[0]}-iso.html
  echo "<a href='${rom[0]}-iso.html' target='main'>${rom[3]}</a> ($pocet)<br />" >> ~/gameflix/systems.html
  echo "<figure><a href='${rom[0]}-iso.html'><img src='https://raw.githubusercontent.com/libretro/retroarch-assets/master/xmb/monochrome/png/"${rom[2]}".png'><figcaption>${rom[2]} ($pocet)</figcaption></a></figure>" >> ~/gameflix/main.html
  ext=""
  if [ -n "${rom[5]}" ]; then ext="; ext=\"${rom[5]}\""; fi
  echo "*\"${rom[1]}\") core=\"${rom[4]}\"${ext};;" >> ~/gameflix/retroarch.sh
done

curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/retroarch.end | tee -a ~/gameflix/retroarch.sh  
chmod +x ~/gameflix/retroarch.sh
echo "<p><b>Total: $total</b>" >> ~/gameflix/systems.html
echo "<p><b>Platforms: $platforms</b>" >> ~/gameflix/systems.html
