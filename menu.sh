#!/bin/bash
# Rebuilds only the site's front page - main.html, the menu systems.html and
# index.html - into ~/gameflix, without generating any platform page or
# fantasy console list. The game counts are taken from the deployed menu
# given as $1 (the site's systems.html); a platform not in it yet gets 0.
# The order, names and section headers come from systems.csv and
# platforms.csv as in generate.sh, whose markup this must keep matching.
#   bash menu.sh <site checkout>/systems.html
shopt -s nocasematch
old_menu="$1"
[[ -f "$old_menu" ]] || { echo "menu.sh: no menu at '$old_menu'" >&2; exit 1; }
declare -A count
while IFS=$'\t' read -r page n; do count[$page]=$n; done < <(
  sed -n 's/^<a href="\([^"]*\)\.html" target="main">.*<\/a> <small>\([0-9]*\)<\/small><br \/>$/\1\t\2/p' "$old_menu")

declare -A sys separator haspage; sysorder=(); needsep=0
while IFS=',' read -r k v t; do
  if [[ -z "$k" ]]; then needsep=1; sepname="$v"; continue; fi
  sys[$k]="$v"; sysorder+=("$k")
  if [[ $needsep -eq 1 ]]; then separator[$k]="$sepname"; needsep=0; fi
done < <(tail -n +2 systems.csv)
while IFS=',' read -r k rest; do [[ -n "$k" ]] && haspage[$k]=1; done < <(tail -n +2 platforms.csv)

mkdir -p ~/gameflix
main=~/gameflix/main.html; menu=~/gameflix/systems.html
echo '<link rel="stylesheet" type="text/css" href="style.css" /><div id="filterBar"><input type="text" id="filterInput" placeholder="Filter..." style="width:100%;box-sizing:border-box"></div>' > $menu
echo '<link rel="stylesheet" type="text/css" href="style.css" /><div id="topbar"><div id="navlinks"></div></div>' > $main
echo "<link rel=\"icon\" type=\"image/png\" href=\"/favicon.png\"><title>gameflix</title><frameset border=0 cols='260, 100%'><frame name='menu' src='systems.html'><frame name='main' src='main.html'></frameset>" > ~/gameflix/index.html

total=0; platforms=0
entry() { # PAGE CAPTION BACKGROUND
  local n=${count[$1]:-0}
  echo "<figure><a href='$1.html'><img src='https://raw.githubusercontent.com/WizzardSK/gameflix/master/art/thumbs/$3.jpg'><figcaption>$2</figcaption></a>$n</figure>" >> $main
  echo "<a href=\"$1.html\" target=\"main\">$2</a> <small>$n</small><br />" >> $menu
  ((total += n)); ((platforms++))
}

echo "<b>Fantasy, Homebrew & Ports</b><br />" >> $menu
echo "<h3 id=\"Fantasy, Homebrew &amp; Ports\" class=\"section-header\" style=\"width:100%\">Fantasy, Homebrew & Ports</h3>" >> $main
for f in TIC-80:tic80 LowresNX:lowresnx WASM-4:wasm4 PICO-8:pico8 Voxatron:voxatron Lutro:lutro ChaiLove:chailove VaporSpec:vaporspec; do
  entry "${f%%:*}" "${f%%:*}" "${f#*:}"
done
for k in "${sysorder[@]}"; do
  [[ -n "${haspage[$k]}" ]] || continue
  if [[ -n "${separator[$k]}" ]]; then
    echo "<br /><b>${separator[$k]}</b><br />" >> $menu
    echo "<h3 id=\"${separator[$k]}\" class=\"section-header\" style=\"width:100%\">${separator[$k]}</h3>" >> $main
  fi
  entry "$k" "${sys[$k]}" "$k"
done

echo '<script src="script.js"></script>' >> $main
echo "<p><b>Total: $total</b>" >> $menu; echo "<p><b>Platforms: $platforms</b>" >> $menu
echo '<script src="script.js"></script>' >> $menu
echo "menu.sh: $platforms platforms, $total games"
