#!/bin/bash
source <(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.txt)
if [ ! -f ~/.config/rclone/rclone.conf ]; then wget -O ~/.config/rclone/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/.config/rclone/rclone.conf; fi
wget -O ~/.emulationstation/custom_systems/es_systems.xml https://raw.githubusercontent.com/WizzardSK/gameflix/main/.emulationstation/custom_systems/es_systems.xml
wget -O ~/.emulationstation/es_controller_mappings.cfg https://raw.githubusercontent.com/WizzardSK/gameflix/main/.emulationstation/es_controller_mappings.cfg
wget -O ~/.emulationstation/es_input.xml https://raw.githubusercontent.com/WizzardSK/gameflix/main/.emulationstation/es_input.xml
wget -O ~/.emulationstation/es_settings.xml https://raw.githubusercontent.com/WizzardSK/gameflix/main/.emulationstation/es_settings.xml
wget -O ~/retroarch.sh https://raw.githubusercontent.com/WizzardSK/gameflix/main/retroarch.sh
wget -O ~/style.css https://raw.githubusercontent.com/WizzardSK/gameflix/main/style.css
wget -O ~/.local/share/applications/retroarch.sh.desktop https://raw.githubusercontent.com/WizzardSK/gameflix/main/retroarch.sh.desktop
chmod +x ~/retroarch.sh
xdg-mime default ~/.local/share/applications/retroarch.sh.desktop application/zip

rm -rf ~/.emulationstation/downloaded_media
rm -rf ~/.emulationstation/gamelists
rm -rf ~/.cache/rclone
rm -rf ~/roms
mkdir -p ~/media
mkdir -p ~/myrient
mkdir -p ~/myrient/No-Intro
mkdir -p ~/myrient/Redump
mkdir -p ~/myrient/TOSEC
mkdir -p ~/roms
mkdir -p ~/iso

rclone mount thumbnails: ~/media --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --vfs-cache-mode full --allow-non-empty --daemon
rclone mount myrient:No-Intro ~/myrient/No-Intro --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --vfs-cache-mode full --allow-non-empty --daemon
rclone mount myrient:Redump ~/myrient/Redump --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --allow-non-empty --daemon
rclone mount myrient:TOSEC ~/myrient/TOSEC --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --vfs-cache-mode full --allow-non-empty --daemon

IFS=","
echo "<style>a { font-size: 15; font-family: Arial }</style>" > ~/systems.html
echo "<frameset border=0 cols='240, 100%'><frame name='menu' src='systems.html'><frame name='main'></frameset>" > ~/gameflix.html
for each in "${roms[@]}"; do
  ((platforms++))
  read -ra rom < <(printf '%s' "$each")
  mkdir -p ~/.emulationstation/downloaded_media/${rom[0]}
  if grep -q ":" <<< "${rom[1]}"; then
    mkdir -p ~/roms/${rom[0]}
    rclone mount ${rom[1]} ~/roms/${rom[0]} --no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --vfs-cache-mode full --allow-non-empty --daemon
  else
    ln -s ~/myrient/${rom[1]} ~/roms/${rom[0]}
  fi
  ln -s ~/media/${rom[2]}/Named_Snaps ~/.emulationstation/downloaded_media/${rom[0]}/screenshots
  mkdir -p ~/.emulationstation/gamelists/${rom[0]}
  > ~/.emulationstation/gamelists/${rom[0]}/gamelist.xml
  > ~/${rom[0]}.html
  echo "<gameList>" >> ~/.emulationstation/gamelists/${rom[0]}/gamelist.xml
  echo "<link rel=\"stylesheet\" type=\"text/css\" href=\"style.css\" />" >> ~/${rom[0]}.html
  pocet=0    
  {
    while IFS= read -r line; do
      if [[ ! ${line} =~ (\[BIOS\]|\(Beta|\(Demo\)|\(Aftermarket\)|\(Proto|\(Unl\)|\(Program\)|\(Alt\)|\(Pirate\)) ]]; then
        thumb=$(echo "$line" | tr '&' '_')
        echo "<game><path>./${line}</path></game>" >> ~/.emulationstation/gamelists/${rom[0]}/gamelist.xml
        echo "<figure><a href=\"roms/${rom[0]}/${line}\"><img title=\"${line%.*}\" loading=lazy src=\"http://thumbnails.libretro.com/${rom[2]}/Named_Snaps/${line%.*}.png\" style=\"background-image: url(\'http://thumbnails.libretro.com/${rom[2]}/Named_Snaps/${thumb%.*}.png\'); background-size: cover; object-fit: cover\"><figcaption>${line%.*}</figcaption></a></figure>" >> ~/${rom[0]}.html
        ((pocet++))
        ((total++))
      fi
    done
  } < <(ls ~/roms/${rom[0]})
  echo "</gameList>" >> ~/.emulationstation/gamelists/${rom[0]}/gamelist.xml
  echo "<a href='${rom[0]}.html' target='main'>${rom[3]} ($pocet)</a><br />" >> ~/systems.html
done
for each in "${zips[@]}"; do
  ((platforms++))
  read -ra zip < <(printf '%s' "$each")
  mkdir -p ~/roms/${zip[0]}
  mkdir -p ~/.emulationstation/downloaded_media/${zip[0]}
  ln -s ~/media/${zip[2]}/Named_Snaps ~/.emulationstation/downloaded_media/${zip[0]}/screenshots
  mount-zip ~/myrient/${zip[1]} ~/roms/${zip[O]} -o nonempty -omodules=iconv,from_code=$charset1,to_code=$charset2
  mkdir -p ~/.emulationstation/gamelists/${zip[0]}
  > ~/.emulationstation/gamelists/${zip[0]}/gamelist.xml
  > ~/${zip[0]}.html
  echo "<gameList>" >> ~/.emulationstation/gamelists/${zip[0]}/gamelist.xml
  echo "<link rel=\"stylesheet\" type=\"text/css\" href=\"style.css\" />" >> ~/${zip[0]}.html
  pocet=0
  {
    while IFS= read -r line; do
      if [[ ! ${line} =~ (\[BIOS\]|\(Beta|\(Demo\)|\(Aftermarket\)|\(Proto|\(Unl\)|\(Program\)|\(Alt\)|\(Pirate\)) ]]; then
        thumb=$(echo "$line" | tr '&' '_')        
        echo "<game><path>./${line}</path></game>" >> ~/.emulationstation/gamelists/${zip[0]}/gamelist.xml
        echo "<figure><a href=\"roms/${zip[0]}/${line}\"><img title=\"${line%.*}\" loading=lazy src=\"http://thumbnails.libretro.com/${zip[2]}/Named_Snaps/${line%.*}.png\" style=\"background-image: url(\'http://thumbnails.libretro.com/${zip[2]}/Named_Snaps/${thumb%.*}.png\'); background-size: cover; object-fit: cover\"><figcaption>${line%.*}</figcaption></a></figure>" >> ~/${zip[0]}.html
        ((pocet++))
        ((total++))
      fi
    done
  } < <(ls ~/roms/${zip[0]})
  echo "</gameList>" >> ~/.emulationstation/gamelists/${zip[0]}/gamelist.xml
  echo "<a href='${zip[0]}.html' target='main'>${zip[3]} ($pocet)</a><br />" >> ~/systems.html
done
echo "<p><b>Total: $total</b>" >> ~/systems.html
echo "<p><b>Platforms: $platforms</b>" >> ~/systems.html

# emulationstation &
xdg-open gameflix.html
