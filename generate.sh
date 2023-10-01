#!/bin/bash
source <(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.txt)
IFS=","
echo "<div id=\"topbar\"><h3 id=\"platforma\">gameflix</h3></div><link rel=\"stylesheet\" type=\"text/css\" href=\"style.css\" /><br /><br /><br />" > ~/systems.html
echo "<frameset border=0 cols='240, 100%'><frame name='menu' src='systems.html'><frame name='main' src='systems.html'></frameset>" > ~/gameflix.html
for each in "${roms[@]}"; do
  ((platforms++))
  read -ra rom < <(printf '%s' "$each")
  if grep -q ":" <<< "${rom[1]}"; then
    location="the-eye.eu/public"
    mkdir -p ~/roms/${rom[0]}
    rclone mount ${rom[1]} ~/roms/${rom[0]} --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --vfs-cache-mode full --allow-non-empty --daemon
    rom[1]="${rom[1]/archive:/}"
  else
    location="myrient.erista.me/files"
    ln -s ~/myrient/${rom[1]} ~/roms/${rom[0]}
  fi
  > ~/${rom[0]}.html
  #> ~/${rom[0]}.txt
  wget -O ~/${rom[0]}.html https://raw.githubusercontent.com/WizzardSK/gameflix/main/platform.html
  #wget -O ~/online/${rom[0]}.html https://raw.githubusercontent.com/WizzardSK/gameflix/main/platform.html
  pocet=0    
  {
    while IFS= read -r line; do
      if [[ ! ${line} =~ \[BIOS\] ]]; then
        ahref=$(echo "$line" | sed -e "s/'/\\\'/g")
        thumb=$(echo "$line" | sed -e 's/&/_/g' -e "s/'/\\\'/g")
        echo "<figure onclick=\"window.location.href='roms/${rom[0]}/${ahref}'\"><img loading=lazy src=\"http://thumbnails.libretro.com/${rom[2]}/Named_Snaps/${line%.*}.png\"><figcaption>${line%.*}</figcaption></figure>" >> ~/${rom[0]}.html
        #echo "<figure onclick=\"window.location.href='https://${location}/${rom[1]}/${ahref}'\"><img loading=lazy src=\"http://thumbnails.libretro.com/${rom[2]}/Named_Snaps/${line%.*}.png\"><figcaption>${line%.*}</figcaption></figure>" >> ~/online/${rom[0]}.html        
        #echo ${line} >> ~/${rom[0]}.txt;
        ((pocet++))
        ((total++))
      fi
    done
  } < <(ls ~/roms/${rom[0]})
  echo "</div><script src=\"script.js\"></script>" >> ~/${rom[0]}.html
  #echo "</div><script src=\"script.js\"></script>" >> ~/online/${rom[0]}.html
  echo "<a href='${rom[0]}.html' target='main' onclick=\"document.getElementById('platforma').innerHTML = this.innerText\">${rom[3]}</a> ($pocet)<br />" >> ~/systems.html
done
for each in "${zips[@]}"; do
  ((platforms++))
  read -ra zip < <(printf '%s' "$each")
  mkdir -p ~/roms/${zip[0]}
  mount-zip ~/myrient/${zip[1]} ~/roms/${zip[O]} -o nonempty -omodules=iconv,from_code=$charset1,to_code=$charset2
  > ~/${zip[0]}.html
  #> ~/${zip[0]}.txt
  wget -O ~/${zip[0]}.html https://raw.githubusercontent.com/WizzardSK/gameflix/main/platform.html
  #wget -O ~/online/${zip[0]}.html https://raw.githubusercontent.com/WizzardSK/gameflix/main/platform.html
  pocet=0
  {
    while IFS= read -r line; do
      if [[ ! ${line} =~ \[BIOS\] ]]; then
        ahref=$(echo "$line" | sed -e "s/'/\\\'/g")
        thumb=$(echo "$line" | sed -e 's/&/_/g' -e "s/'/\\\'/g")    
        echo "<figure onclick=\"window.location.href='roms/${zip[0]}/${ahref}'\"><img loading=lazy src=\"http://thumbnails.libretro.com/${zip[2]}/Named_Snaps/${line%.*}.png\"><figcaption>${line%.*}</figcaption></figure>" >> ~/${zip[0]}.html
        #echo "<figure onclick=\"window.location.href='https://myrient.erista.me/files/${zip[1]}'\"><img loading=lazy src=\"http://thumbnails.libretro.com/${zip[2]}/Named_Snaps/${line%.*}.png\"><figcaption>${line%.*}</figcaption></figure>" >> ~/online/${zip[0]}.html
        #echo ${line} >> ~/${zip[0]}.txt;        
        ((pocet++))
        ((total++))
      fi
    done
  } < <(ls ~/roms/${zip[0]})
  echo "</div><script src=\"script.js\"></script>" >> ~/${zip[0]}.html
  #echo "</div><script src=\"script.js\"></script>" >> ~/online/${zip[0]}.html
  echo "<a href='${zip[0]}.html' target='main' target='main' onclick=\"document.getElementById('platforma').innerHTML = this.innerText\">${zip[3]}</a> ($pocet)<br />" >> ~/systems.html
done
echo "<p><b>Total: $total</b>" >> ~/systems.html
echo "<p><b>Platforms: $platforms</b>" >> ~/systems.html
