#!/bin/bash
shopt -s nocasematch;
# What the gamelist hides: bad dumps, hacks, demos, betas, extra disks... The
# pattern is kept in a variable: written out in [[ =~ ]], bash broke the
# bracket expression [^]] and every test failed (invalid regex), hiding all.
hidden_re='\[(bios|a[0-9]{0,2}|b[0-9]{0,2}|c|f|h [^]]*|o ?.*|p ?.*|t ?.*|cr ?.*)\]|\((demo( [0-9]+)?|beta( [0-9]+)?|alpha( [0-9]+)?|(disk|side)( [2-9B-Z]).*|pre-release|aftermarket|alt|alternate|unl|channel|system|dlc)\)'
urlenc() { local s="$1" out="" i c; for ((i=0;i<${#s};i++)); do c="${s:i:1}"; case "$c" in [a-zA-Z0-9._~/-]) out+="$c";; *) printf -v c '%%%02X' "'$c"; out+="$c";; esac; done; printf '%s' "$out"; }
declare -A sys thumb separator; sysorder=(); needsep=0; while IFS=',' read -r k v t; do if [[ -z "$k" ]]; then needsep=1; sepname="$v"; continue; fi; sys[$k]="$v"; thumb[$k]="$t"; sysorder+=("$k"); if [[ $needsep -eq 1 ]]; then separator[$k]="$sepname"; needsep=0; fi; done < <(tail -n +2 systems.csv)
declare -A sysroms; while IFS=';' read -r k rest; do [[ -z "$k" ]] && continue; sysroms[$k]+="$k;$rest;${thumb[$k]};${sys[$k]}"$'\n'; done < <(awk '{o="";i=1;n=length($0);while(i<=n){c=substr($0,i,1);if(c==","){o=o";";i++}else if(c=="\""){i++;while(i<=n){c=substr($0,i,1);if(c=="\""){if(substr($0,i+1,1)=="\""){o=o"\"";i+=2}else{i++;break}}else{o=o c;i++}}}else{o=o c;i++}};print o}' <(tail -n +2 platforms.csv ))
roms=(); for k in "${sysorder[@]}"; do while IFS= read -r line; do [[ -n "$line" ]] && roms+=("$line"); done <<< "${sysroms[$k]}"; done
mkdir -p ~/{gameflix,rom,gamelists,zip,zips,mount} ~/gamelists/{tic80,wasm4,lowresnx,pico8,voxatron,lutro,chailove,vaporspec,switch}
echo '<link rel="stylesheet" type="text/css" href="style.css" /><div id="filterBar"><input type="text" id="filterInput" placeholder="Filter..." style="width:100%;box-sizing:border-box"></div>' > ~/gameflix/systems.html
echo '<link rel="stylesheet" type="text/css" href="style.css" /><div id="topbar"><div id="navlinks"></div></div>' > ~/gameflix/main.html
echo "<link rel=\"icon\" type=\"image/png\" href=\"/favicon.png\"><title>gameflix</title><frameset border=0 cols='260, 100%'><frame name='menu' src='systems.html'><frame name='main' src='main.html'></frameset>" > ~/gameflix/index.html
# cores.json is NOT copied here — it is generated from launch.tsv at the end so
# the Android intent map can never drift from platforms.csv (see gen_cores.py).
for file in retroarch.sh retroarch.ps1 mame_deps.tsv webflix.ps1 style.css script.js platform.js intent.js intent-test.html; do cp $file ~/gameflix/$file; done
echo 'gameflix_lookup_src() { src=""; case "$1" in' > ~/gameflix/urls.sh
# Windows launcher data: KEY<TAB>core<TAB>ext<TAB>src (parsed by retroarch.ps1)
: > ~/gameflix/launch.tsv

# Mount IA items via rclone, then use ratarmount for zips
echo "=== MOUNTING IA ITEMS ==="
item_count=0
mount_start=$(date +%s)
mkdir -p ~/mount ~/dircache
cache=~/dircache
ia_ziplist="$PWD/ia_ziplist.py"  # authenticated HTTP fallback lister for archive:*.zip
mounted_file=$(mktemp)

# Mount each unique IA item once: archive:ni-roms -> ~/mount/ni-roms
while IFS= read -r path; do
  [[ "$path" != *:* || "$path" == https://* ]] && continue
  aftercolon="${path#*:}"; item="${aftercolon%%/*}"
  if ! grep -qx "$item" "$mounted_file" 2>/dev/null; then
    ((item_count++))
    mkdir -p ~/mount/"$item"
    rclone mount "archive:$item/" ~/mount/"$item" --daemon --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h --vfs-cache-mode minimal --allow-non-empty 2>/dev/null
    echo "$item" >> "$mounted_file"
    if ((item_count % 20 == 0)); then echo "Mounted $item_count items..."; fi
  fi
done < <(awk '{o="";i=1;n=length($0);while(i<=n){c=substr($0,i,1);if(c==","){o=o";";i++}else if(c=="\""){i++;while(i<=n){c=substr($0,i,1);if(c=="\""){if(substr($0,i+1,1)=="\""){o=o"\"";i+=2}else{i++;break}}else{o=o c;i++}}}else{o=o c;i++}};print o}' <(tail -n +2 platforms.csv) | cut -d';' -f2 | sort -u)
sleep 10
mount_end=$(date +%s)
echo "=== MOUNTING DONE: $item_count items in $((mount_end - mount_start))s ==="

# Pre-fetch directory listings
echo "=== PRE-FETCHING DIRECTORY LISTINGS ==="
prefetch_start=$(date +%s)
jobs_running=0
path_count=0
while IFS= read -r path; do
  h=$(echo -n "$path" | md5sum | cut -d' ' -f1)
  [ -s "$cache/$h.txt" ] && continue
  (
    if [[ "$path" == https://* ]]; then
      url="${path%%#*}"; subdir="${path#*#}"; [ "$subdir" = "$path" ] && subdir=""
      tmp=$(mktemp); wget -q "$url" -O "$tmp"
      # awk in the C locale throughout: zips name files in CP437 as often as
      # in UTF-8, and in a UTF-8 locale those names were invalid multibyte data
      unzip -l "$tmp" 2>/dev/null | LC_ALL=C awk '$2 ~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/ && $3 ~ /^[0-9]{2}:[0-9]{2}$/ {match($0,/^ *[0-9]+ +[0-9-]+ +[0-9:]+ +/); name=substr($0,RLENGTH+1); sub(/^[a-z0-9_]+\//, "", name); print name}' > "$cache/$h.txt"
      rm -f "$tmp"
    elif [[ "$path" == *:* ]]; then
      aftercolon="${path#*:}"
      localpath="$HOME/mount/$aftercolon"
      if [[ "$localpath" == *.zip ]]; then
        unzip -l "$localpath" 2>/dev/null | LC_ALL=C awk -v px="$cache/$h.prefix" '$2 ~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/ && $3 ~ /^[0-9]{2}:[0-9]{2}$/ {match($0,/^ *[0-9]+ +[0-9-]+ +[0-9:]+ +/); name=substr($0,RLENGTH+1); if (!seen) { seen=1; if (match(name,/^[a-z0-9_]+\//)) { print substr(name,RSTART,RLENGTH) > px } else { print "" > px } } sub(/^[a-z0-9_]+\//, "", name); print name}' > "$cache/$h.txt"
        # Mounted listing came back empty (IA intermittently errors on the rclone
        # mount for large restricted zips) -> read the ZIP central directory
        # directly over authenticated HTTP so the platform page is never silently empty.
        if [[ ! -s "$cache/$h.txt" && "$path" == archive:* ]]; then
          python3 "$ia_ziplist" "$path" "$cache/$h.txt" "$cache/$h.prefix" 2>/dev/null || true
        fi
      else
        zipcount=$(find "$localpath" -maxdepth 1 -name "*.zip" 2>/dev/null | wc -l)
        # the item's other files: a lone zip beside the games (ChihiroNetboot's
        # "Chihiro BIOS.zip") is not a bundle of them
        othercount=$(find "$localpath" -maxdepth 1 -type f ! -name "*.zip" ! -name "__ia_thumb.jpg" ! -name "*_files.xml" ! -name "*_meta.xml" ! -name "*_reviews.xml" ! -name "*_meta.sqlite" ! -name "*_archive.torrent" 2>/dev/null | wc -l)
        if [ "$zipcount" -eq 1 ] && [ "$othercount" -eq 0 ]; then
          # single bundled zip — list its contents
          zipfile=$(find "$localpath" -maxdepth 1 -name "*.zip" 2>/dev/null | head -1)
          unzip -l "$zipfile" 2>/dev/null | LC_ALL=C awk -v px="$cache/$h.prefix" '$2 ~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/ && $3 ~ /^[0-9]{2}:[0-9]{2}$/ {match($0,/^ *[0-9]+ +[0-9-]+ +[0-9:]+ +/); name=substr($0,RLENGTH+1); if (!seen) { seen=1; if (match(name,/^[a-z0-9_]+\//)) { print substr(name,RSTART,RLENGTH) > px } else { print "" > px } } sub(/^[a-z0-9_]+\//, "", name); print name}' > "$cache/$h.txt"
          echo "$path/$(basename "$zipfile")" > "$cache/$h.path"
        else
          # directory of files (each file = one ROM, even if many .zip files),
          # without the files archive.org adds to an item: its metadata
          # (<item>_files.xml, _meta.xml, _meta.sqlite, _reviews.xml,
          # _archive.torrent), the tile __ia_thumb.jpg and the uploader's
          # pictures with their _thumb.jpg derivatives, and a BIOS zip kept
          # beside the games (ChihiroNetboot's "Chihiro BIOS.zip")
          ls "$localpath" 2>/dev/null | grep -viE '^__ia_thumb\.jpg$|_(files|meta|reviews)\.xml$|_meta\.sqlite$|_archive\.torrent$|\.(jpe?g|png|gif)$| BIOS\.zip$' > "$cache/$h.txt"
        fi
      fi
    else
      ls "$HOME/$path" 2>/dev/null > "$cache/$h.txt" || true
    fi
  ) &
  ((jobs_running++))
  ((path_count++))
  if ((path_count % 50 == 0)); then echo "Processing path $path_count..."; fi
  if ((jobs_running >= 20)); then wait -n; ((jobs_running--)); fi
done < <(awk '{o="";i=1;n=length($0);while(i<=n){c=substr($0,i,1);if(c==","){o=o";";i++}else if(c=="\""){i++;while(i<=n){c=substr($0,i,1);if(c=="\""){if(substr($0,i+1,1)=="\""){o=o"\"";i+=2}else{i++;break}}else{o=o c;i++}}}else{o=o c;i++}};print o}' <(tail -n +2 platforms.csv) | cut -d';' -f2 | sort -u)
wait
prefetch_end=$(date +%s)
echo "=== PRE-FETCH DONE: $path_count paths in $((prefetch_end - prefetch_start))s ==="

# Fetch MAME software list display names — short ROM names (e.g. "mslug") -> "Metal Slug (NGM-201 ~ NGH-201)"
echo "=== FETCHING MAME SOFTLIST NAMES ==="
mame_names_dir=~/dircache/mame-names
mkdir -p "$mame_names_dir"
mame_fetch_start=$(date +%s)
mame_jobs=0
while IFS= read -r softlist; do
  [[ -z "$softlist" ]] && continue
  cached="$mame_names_dir/$softlist.tsv"
  [ -e "$cached" ] && continue
  (
    src=""
    if [ -s "/usr/share/games/mame/hash/$softlist.xml" ]; then
      src="/usr/share/games/mame/hash/$softlist.xml"
    else
      tmp=$(mktemp)
      if curl -fsSL "https://raw.githubusercontent.com/mamedev/mame/master/hash/$softlist.xml" -o "$tmp" 2>/dev/null && [ -s "$tmp" ]; then
        src="$tmp"
      fi
    fi
    if [ -n "$src" ]; then
      awk '
        /<software name=/ { if (match($0, /name="([^"]+)"/, a)) name=a[1] }
        /<description>/ {
          if (match($0, /<description>([^<]+)<\/description>/, a) && name && a[1]) print name "\t" a[1]
          name=""
        }
      ' "$src" > "$cached"
    else
      : > "$cached"  # mark as tried so we don't retry
    fi
    [[ "$src" == /tmp/* ]] && rm -f "$src"
  ) &
  ((mame_jobs++))
  if ((mame_jobs >= 20)); then wait -n; ((mame_jobs--)); fi
done < <(awk -F',' '$2 ~ /^archive:mame-sl\// { n=$2; sub(/.*\//, "", n); sub(/\.zip$/, "", n); print n }' platforms.csv | sort -u)

# Fetch MAME arcade listxml (~19 MB zip → 322 MB XML, 50k <machine> entries)
arcade_mame_cache="$mame_names_dir/arcade-mame.tsv"
# Devices and BIOS sets (model1io, hd44780, ...) sit beside the games in some
# arcade folders; they are left out of the lists.
arcade_mame_nogame="$mame_names_dir/arcade-mame-nogame.txt"
# Clone -> parent set, for the snap of a clone that has none of its own
arcade_mame_parent="$mame_names_dir/arcade-mame-parent.txt"
if [ ! -e "$arcade_mame_cache" ] || [ ! -e "$arcade_mame_nogame" ] || [ ! -e "$arcade_mame_parent" ]; then
  (
    mame_tag=$(curl -sIL "https://github.com/mamedev/mame/releases/latest" 2>/dev/null | awk 'tolower($1)=="location:" { sub(/\r$/,""); n=split($2,p,"/"); print p[n] }' | tail -1)
    if [[ -n "$mame_tag" ]]; then
      mame_ver="${mame_tag#mame}"
      tmpzip=$(mktemp --suffix=.zip)
      if curl -fsSL -o "$tmpzip" "https://github.com/mamedev/mame/releases/download/$mame_tag/${mame_tag}lx.zip" && [ -s "$tmpzip" ]; then
        unzip -p "$tmpzip" "mame${mame_ver}.xml" 2>/dev/null | awk -v nogame="$arcade_mame_nogame" -v parent="$arcade_mame_parent" '
          /<machine name=/ { if (match($0, /name="([^"]+)"/, a)) name=a[1]; if (/isdevice="yes"|isbios="yes"/) print name > nogame; if (match($0, /cloneof="([^"]+)"/, c)) print name "\t" c[1] > parent }
          /<description>/ { if (match($0, /<description>([^<]+)<\/description>/, a) && name && a[1]) print name "\t" a[1]; name="" }
        ' > "$arcade_mame_cache"
      else
        : > "$arcade_mame_cache"
      fi
      rm -f "$tmpzip"
    else
      : > "$arcade_mame_cache"
    fi
    touch "$arcade_mame_nogame" "$arcade_mame_parent"
  ) &
fi

# Fetch FBNeo arcade dat (~14 MB, 8k <game> entries)
arcade_fbneo_cache="$mame_names_dir/arcade-fbneo.tsv"
if [ ! -e "$arcade_fbneo_cache" ]; then
  (
    tmpdat=$(mktemp)
    if curl -fsSL -o "$tmpdat" "https://raw.githubusercontent.com/libretro/FBNeo/master/dats/FinalBurn%20Neo%20(ClrMame%20Pro%20XML%2C%20Arcade%20only).dat" && [ -s "$tmpdat" ]; then
      awk '
        /<game name=/ { if (match($0, /name="([^"]+)"/, a)) name=a[1] }
        /<description>/ { if (match($0, /<description>([^<]+)<\/description>/, a) && name && a[1]) print name "\t" a[1]; name="" }
      ' "$tmpdat" > "$arcade_fbneo_cache"
    else
      : > "$arcade_fbneo_cache"
    fi
    rm -f "$tmpdat"
  ) &
fi

wait
declare -A mame_name
for tsv in "$mame_names_dir"/*.tsv; do
  [ -s "$tsv" ] || continue
  softlist=$(basename "$tsv" .tsv)
  while IFS=$'\t' read -r sn desc; do
    [[ -n "$sn" ]] && mame_name["$softlist:$sn"]="$desc"
  done < "$tsv"
done
declare -A mame_nogame
while IFS= read -r sn; do [[ -n "$sn" ]] && mame_nogame["$sn"]=1; done < "$arcade_mame_nogame"
declare -A mame_parent
while IFS=$'\t' read -r sn par; do [[ -n "$sn" ]] && mame_parent["$sn"]="$par"; done < "$arcade_mame_parent"
# Sets MAME no longer has, by the set whose snap they take (Magical Truck
# Adventure's old bad dump, in the Model 3 list)
mame_parent[mgtrkbad]=magtruck

# Sega Lindbergh and Chihiro: MAME emulates neither, but its database names
# their games, and the MAME thumbnail repo has snaps of many of them under the
# short names. A game of those lists takes the snap of the MAME set whose title
# matches its own: game_key, the title before its brackets in small letters
# and figures, II to IV as figures, each part of a title "A / B"; else a set
# whose title starts its own or the other way round, by at most 8 letters
# that are not a number (Hummer Extreme Edition, Hummer Extreme); a title
# "X - Y" also as Y (Loving Deads - The House of the Dead EX).
game_key() { local s="$1"; s="${s%% (*}"; s="${s%% [*}"; s=" ${s,,} "; s="${s// iii / 3 }"; s="${s// ii / 2 }"; s="${s// iv / 4 }"; s="${s//&/and}"; REPLY="${s//[^a-z0-9]/}"; }
declare -A mame_snap mame_by_key
while IFS= read -r sn; do mame_snap["$sn"]=1; done < <(curl -fsSL "https://api.github.com/repos/WizzardSK/MAME/git/trees/master:Named_Snaps" | grep -o '"path": *"[a-z0-9_]*\.png"' | sed 's/.*"path": *"//; s/\.png"$//')
for k in "${!mame_name[@]}"; do
  [[ "$k" == arcade-mame:* ]] || continue
  sn="${k#arcade-mame:}"
  [[ -n "${mame_snap[$sn]}" ]] || continue
  desc="${mame_name[$k]}"
  IFS='/' read -ra parts <<< "${desc%% (*}"
  for part in "${parts[@]}"; do
    game_key "$part"
    [[ -n "$REPLY" && -z "${mame_by_key[$REPLY]}" ]] && mame_by_key[$REPLY]="$sn"
  done
done
# Lindbergh games MAME has no set for (or names otherwise), with snaps in the
# MAME repo under lindbergh_* names
for a in harleydavidsonkingoftheroad=lindbergh_harley virtuafighter5finalshowdown=lindbergh_vf5fs initialdarcadestage4=initiad4 \
         initialdarcadestage5=lindbergh_id5 rtunedultimatestreetracing=lindbergh_rtuned seganetworkcasinoclub=lindbergh_casino \
         networktaisenquizanswerxanswer=lindbergh_quiz networktaisenquizanswerxanswerlive=lindbergh_quizlive \
         seganetworktaisenmahjongmj4=lindbergh_mj4 seganetworktaisenmahjongmj4evolution=lindbergh_mj4; do
  k="${a%%=*}"; sn="${a#*=}"
  [[ -n "${mame_snap[$sn]}" && -z "${mame_by_key[$k]}" ]] && mame_by_key[$k]="$sn"
done
echo "=== MAME SNAPS: ${#mame_snap[@]} short names, ${#mame_by_key[@]} titles ==="
mame_snap_of() {
  local title="$1" key k rest part
  for part in "$title" "${title#* - }"; do
    game_key "$part"; key="$REPLY"
    REPLY="${mame_by_key[$key]}"
    [[ -n "$REPLY" ]] && return
  done
  game_key "$title"; key="$REPLY"
  REPLY=""
  [[ ${#key} -lt 6 ]] && return
  # a title that starts the other, by a few letters that are not a number
  # (Initial D Arcade Stage 4 is not Initial D Arcade Stage)
  for k in "${!mame_by_key[@]}"; do
    rest=""
    if [[ "$key" == "$k"* && ${#k} -ge 6 ]]; then rest="${key#"$k"}"; elif [[ "$k" == "$key"* ]]; then rest="${k#"$key"}"; else continue; fi
    if [[ -n "$rest" && ${#rest} -le 8 && "$rest" != [0-9]* ]]; then
      REPLY="${mame_by_key[$k]}"; return
    fi
  done
}
mame_fetch_end=$(date +%s)
echo "=== MAME SOFTLIST NAMES DONE: ${#mame_name[@]} entries in $((mame_fetch_end - mame_fetch_start))s ==="

# Each platform page links its logo back to its section of main.html (gfGroup)
group="Fantasy, Homebrew & Ports"; platform_head() { printf '<script>var gfGroup = "%s";</script><script src="platform.js"></script>\n' "$group"; }
# fileNames entries are JS string literals: escape backslashes and double quotes
jsstr() { local s="${1//\\/\\\\}"; printf '%s' "${s//\"/\\\"}"; }
echo "<b>Fantasy, Homebrew & Ports</b><br />" >> ~/gameflix/systems.html; echo "<h3 id=\"Fantasy, Homebrew &amp; Ports\" class=\"section-header\" style=\"width:100%\">Fantasy, Homebrew & Ports</h3>" >> ~/gameflix/main.html

# TIC-80 - all categories fetched in parallel
pocet=0; echo "TIC-80"; platform_head > ~/gameflix/TIC-80.html; ((platforms++))
echo "<gameList>" > ~/gamelists/tic80/gamelist.xml
# tic80.com serves a cart at /cart/<hash>/<anything>.tic, so the carts are
# fetched from the site itself and played in tic80_libretro, exactly like any
# other platform's ROM. (Linking the site's own player instead does not work:
# tic80.com sends X-Frame-Options: SAMEORIGIN and gameflix is a frameset.)
echo "*\"/TIC-80/\"*) core=\"tic80_libretro\"; src=\"https://tic80.com/cart/\";;" >> ~/gameflix/retroarch.sh
printf '/TIC-80/\ttic80_libretro\t\thttps://tic80.com/cart/\n' >> ~/gameflix/launch.tsv
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
    match($0, /id *= *([0-9]+)/, a) && match($0, /hash *= *"([a-f0-9]+)"/, b) && match($0, /name *= *"([^"]+)"/, c) && match($0, /filename *= *"([^"]+)"/, d) {
      sub(/\.tic$/, "", c[1]); gsub(/[\t\r\n]/, " ", c[1]); print a[1] "\t" b[1] "\t" c[1] "\t" d[1]
    }' | sort -nr -k1,1 | awk '{ print "\"" $0 "\"," }' >> ~/gameflix/TIC-80.html
  printf ']; generateTicLinks("roms/TIC-80", "TIC-80");</script>\n' >> ~/gameflix/TIC-80.html
done
echo "<script src=\"script.js\"></script>" >> ~/gameflix/TIC-80.html
echo "<figure><a href='TIC-80.html'><img src='https://raw.githubusercontent.com/WizzardSK/gameflix/master/art/background/tic80.jpg'><figcaption>TIC-80</figcaption></a>$pocet</figure>" >> ~/gameflix/main.html
echo "<a href=\"TIC-80.html\" target=\"main\">TIC-80</a> <small>$pocet</small><br />" >> ~/gameflix/systems.html
echo "<game><path>./surf.tic</path><name>TIC-80 surf</name><image>./tic80.png</image></game></gameList>" >> ~/gamelists/tic80/gamelist.xml

# LowresNX - categories with section headers
pocet=0; echo "LowresNX"; platform_head > ~/gameflix/LowresNX.html; ((platforms++))
echo "*\"LowresNX/\"*) core=\"lowresnx_libretro\";;" >> ~/gameflix/retroarch.sh
printf 'LowresNX/\tlowresnx_libretro\t\t\n' >> ~/gameflix/launch.tsv
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
      echo "\"$(jsstr "$cart")\t$(jsstr "$picture")\t$(jsstr "$name")\t$id\"," >> ~/gameflix/LowresNX.html
      ((pocet++)); ((total++))
    fi
    echo "<game><path>./${cart}</path><name>${name}</name><image>./${picture}</image></game>"
  done < fantasy/lowresnx.txt
  echo "</gameList>"
} > ~/gamelists/lowresnx/gamelist.xml
printf ']; generateLrNXLinks("roms/LowresNX", "LowresNX");</script>\n' >> ~/gameflix/LowresNX.html
echo "<script src=\"script.js\"></script>" >> ~/gameflix/LowresNX.html
echo "<figure><a href='LowresNX.html'><img src='https://raw.githubusercontent.com/WizzardSK/gameflix/master/art/background/lowresnx.jpg'><figcaption>LowresNX</figcaption></a>$pocet</figure>" >> ~/gameflix/main.html
echo "<a href=\"LowresNX.html\" target=\"main\">LowresNX</a> <small>$pocet</small><br />" >> ~/gameflix/systems.html

# WASM-4 - dual fd output (count from wasm4.org/play, works in CI without local ROMs)
echo "WASM-4"; platform_head > ~/gameflix/WASM-4.html; echo "<script>bgImage(\"wasm4\"); fileNames = [" >> ~/gameflix/WASM-4.html; ((platforms++))
wasm_html=$(curl -s "https://wasm4.org/play/")
wasm_entries=$(echo "$wasm_html" | grep -oP '<img src="/carts/[^"]+\.png" alt="[^"]+"')
pocet=$(echo "$wasm_entries" | grep -c '.'); total=$((pocet+total))
echo "*\"/wasm4/\"*) core=\"wasm4_libretro\";;" >> ~/gameflix/retroarch.sh
printf '/wasm4/\twasm4_libretro\t\t\n' >> ~/gameflix/launch.tsv
exec 3>> ~/gameflix/WASM-4.html
{
  echo "<gameList>"
  while read -r line; do
    image=$(echo "$line" | grep -oP '(?<=src=")/carts/[^"]+'); title=$(echo "$line" | grep -oP '(?<=alt=")[^"]+'); image_name=$(basename "$image" .png)
    echo "\"$(jsstr "$image_name")\t$(jsstr "$title")\"," >&3
    echo "<game><path>./${image_name}.wasm</path><name>${title}</name><image>./${image_name}.png</image></game>"
  done <<< "$wasm_entries"
  echo "</gameList>"
} > ~/gamelists/wasm4/gamelist.xml
exec 3>&-
echo "<figure><a href='WASM-4.html'><img src='https://raw.githubusercontent.com/WizzardSK/gameflix/master/art/background/wasm4.jpg'><figcaption>WASM-4</figcaption></a>$pocet</figure>" >> ~/gameflix/main.html
echo "<a href=\"WASM-4.html\" target=\"main\">WASM-4</a> <small>$pocet</small><br />" >> ~/gameflix/systems.html
printf ']; generateWasmLinks("roms/WASM-4", "WASM-4");</script><script src=\"script.js\"></script>' >> ~/gameflix/WASM-4.html

# PICO-8 - categories with section headers
pocet=0; echo "PICO-8"; platform_head > ~/gameflix/PICO-8.html; ((platforms++))
echo "*\"PICO-8/\"*) core=\"pico8 -run\";;" >> ~/gameflix/retroarch.sh
printf 'PICO-8/\tpico8 -run\t\t\n' >> ~/gameflix/launch.tsv
pico_section=0
while IFS=$'\t' read -r id rest; do
  if [[ "$id" == "---" ]]; then
    [[ $pico_section -eq 1 ]] && printf ']; generatePicoLinks("roms/PICO-8", "PICO-8");</script>\n' >> ~/gameflix/PICO-8.html
    echo -e "<h3 id=\"$rest\" class=\"section-header\">$rest</h3>\n<script>bgImage(\"pico8\")\nfileNames = [" >> ~/gameflix/PICO-8.html
    pico_section=1; continue
  fi
  IFS=$'\t' read -r name cart <<< "$rest"
  echo "\"$id\t$(jsstr "$name")\t$(jsstr "$cart")\"," >> ~/gameflix/PICO-8.html
  ((pocet++)); ((total++))
done < fantasy/pico8.txt
printf ']; generatePicoLinks("roms/PICO-8", "PICO-8");</script>\n' >> ~/gameflix/PICO-8.html
echo "<script src=\"script.js\"></script>" >> ~/gameflix/PICO-8.html
echo "<figure><a href='PICO-8.html'><img src='https://raw.githubusercontent.com/WizzardSK/gameflix/master/art/background/pico8.jpg'><figcaption>PICO-8</figcaption></a>$pocet</figure>" >> ~/gameflix/main.html
echo "<a href=\"PICO-8.html\" target=\"main\">PICO-8</a> <small>$pocet</small><br />" >> ~/gameflix/systems.html
echo "<gameList></gameList>" > ~/gamelists/pico8/gamelist.xml

# Voxatron - categories with section headers
pocet=0; echo "Voxatron"; platform_head > ~/gameflix/Voxatron.html; ((platforms++))
echo "*\"Voxatron/\"*) core=\"vox\";;" >> ~/gameflix/retroarch.sh
printf 'Voxatron/\tvox\t\t\n' >> ~/gameflix/launch.tsv
vox_section=0
while IFS=$'\t' read -r id rest; do
  if [[ "$id" == "---" ]]; then
    [[ $vox_section -eq 1 ]] && printf ']; generateVoxLinks("roms/Voxatron", "Voxatron");</script>\n' >> ~/gameflix/Voxatron.html
    echo -e "<h3 id=\"$rest\" class=\"section-header\">$rest</h3>\n<script>bgImage(\"voxatron\")\nfileNames = [" >> ~/gameflix/Voxatron.html
    vox_section=1; continue
  fi
  IFS=$'\t' read -r name cart <<< "$rest"
  echo "\"$id\t$(jsstr "$name")\t$(jsstr "$cart")\"," >> ~/gameflix/Voxatron.html
  ((pocet++)); ((total++))
done < fantasy/voxatron.txt
printf ']; generateVoxLinks("roms/Voxatron", "Voxatron");</script>\n' >> ~/gameflix/Voxatron.html
echo "<script src=\"script.js\"></script>" >> ~/gameflix/Voxatron.html
echo "<figure><a href='Voxatron.html'><img src='https://raw.githubusercontent.com/WizzardSK/gameflix/master/art/background/voxatron.jpg'><figcaption>Voxatron</figcaption></a>$pocet</figure>" >> ~/gameflix/main.html
echo "<a href=\"Voxatron.html\" target=\"main\">Voxatron</a> <small>$pocet</small><br />" >> ~/gameflix/systems.html
echo "<gameList></gameList>" > ~/gamelists/voxatron/gamelist.xml

# Lutro, ChaiLove, VaporSpec - the games libretro hosts on its buildbot, each
# played in its own core (play:///<Page>/Games/<file>, fetched from the
# buildbot like an archive.org ROM). buildbot_platform PAGE FOLDER CORE EXTS SKIP BG
buildbot_platform() {
  local page=$1 folder=$2 core=$3 exts=$4 skip=$5 bg=$6
  local src="https://buildbot.libretro.com/assets/cores/$folder/"
  pocet=0; echo "$page"; platform_head > ~/gameflix/$page.html; ((platforms++))
  echo "*\"/$page/\"*) core=\"$core\"; src=\"$src\";;" >> ~/gameflix/retroarch.sh
  printf '/%s/\t%s\t\t%s\n' "$page" "$core" "$src" >> ~/gameflix/launch.tsv
  echo -e "<h3 id=\"Games\" class=\"section-header\">Games</h3>\n<script>bgImage(\"$bg\")\nfileNames = [" >> ~/gameflix/$page.html
  mkdir -p ~/gamelists/$bg
  {
    echo "<gameList>"
    while IFS= read -r cart; do
      echo "\"$(jsstr "$cart")\"," >> ~/gameflix/$page.html
      echo "<game><path>./${cart}</path><name>${cart%.*}</name></game>"
      ((pocet++)); ((total++))
    done < <(curl -s "$src" | grep -oP "(?<=href=\"/assets/cores/$folder/)[^\"]+\.($exts)(?=\")" | while IFS= read -r f; do printf '%b\n' "${f//%/\\x}"; done | grep -vE "$skip" | sort -u)
    echo "</gameList>"
  } > ~/gamelists/$bg/gamelist.xml
  printf ']; generateFileLinks("roms/%s", "%s");</script>\n<script src="script.js"></script>\n' "$page" "$page" >> ~/gameflix/$page.html
  echo "<figure><a href='$page.html'><img src='https://raw.githubusercontent.com/WizzardSK/gameflix/master/art/background/$bg.jpg'><figcaption>$page</figcaption></a>$pocet</figure>" >> ~/gameflix/main.html
  echo "<a href=\"$page.html\" target=\"main\">$page</a> <small>$pocet</small><br />" >> ~/gameflix/systems.html
}
# BIOS Check, Launcher and JSTest are the cores' own test and menu carts, not games
buildbot_platform Lutro Lutro lutro_libretro 'lutro' '^BIOS Check' lutro
buildbot_platform ChaiLove ChaiLove chailove_libretro 'chailove|chai' '^(Launcher|JSTest)\.' chailove
buildbot_platform VaporSpec VaporSpec vaporspec_libretro 'vaporbin' '^$' vaporspec

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
      echo "<figure><a href='${rom3}.html'><img src='https://raw.githubusercontent.com/WizzardSK/gameflix/master/art/background/${rom3}.jpg'><figcaption>${rom6}</figcaption></a>$pocet</figure>" >> ~/gameflix/main.html
      echo "<a href=\"${rom3}.html\" target=\"main\">${rom6}</a> <small>$pocet</small><br />" >> ~/gameflix/systems.html; ((platforms++))
    fi
    [[ -n "${separator[${rom[0]}]}" ]] && group="${separator[${rom[0]}]}" && echo "<br /><b>${separator[${rom[0]}]}</b><br />" >> ~/gameflix/systems.html && echo "<h3 id=\"${separator[${rom[0]}]}\" class=\"section-header\" style=\"width:100%\">${separator[${rom[0]}]}</h3>" >> ~/gameflix/main.html
    platform_head > ~/gameflix/${rom[0]}.html
    pocet=0
    # Open new fds
    exec {html_fd}>> ~/gameflix/${rom[0]}.html
  else
    # Close section, keep fds open for same platform
    echo ']; generateFileLinks("'"$prev_romfolder"'", "'"${prev_imagepath}"'");</script>' >&$html_fd
  fi
  rom3="${rom[0]}"; rom6="${rom[6]}"
  mkdir -p ~/mount/${rom[0]} ~/gamelists/${rom[0]}; romfolder="${rom[1]}"; emufolder="${rom[1]}"
  foldername="${rom[2]//<[^>]*>/}"
  # Write <gameList> header once per platform and open xml fd
  if [[ -z "${gamelist_started[${rom[0]}]}" ]]; then
    echo "<gameList>" > ~/gamelists/${rom[0]}/gamelist.xml
    exec {xml_fd}>> ~/gamelists/${rom[0]}/gamelist.xml
    gamelist_started[${rom[0]}]=1
  fi
  cachehash=$(echo -n "${rom[1]}" | md5sum | cut -d' ' -f1)
  cachefile="$cache/$cachehash.txt"
  catcount=$(grep -c . "$cachefile" 2>/dev/null); catcount=${catcount:-0}
  # the shown title without the dump group (PS3's "Redump A1" is shown as "A1"); the id stays the folder name
  echo -e "<h3 id=\"${rom[2]}\" data-count=\"${catcount}\" class=\"section-header\">${rom[2]#Redump }</h3>\n<script>bgImage(\"${rom[0]}\")\nfileNames = [" >&$html_fd
  if [ -f "$cache/$cachehash.path" ]; then romfolder=$(<"$cache/$cachehash.path"); fi
  romdir=~/"${romfolder}"
  # Detect MAME software list source — used to map short ROM names to real game titles
  softlist=""
  if [[ "${rom[1]}" == archive:mame-sl/*/*.zip ]]; then
    softlist="${rom[1]##*/}"; softlist="${softlist%.zip}"
  fi
  arcade_src=""
  case "${rom[0]}" in
    mame|model1|model2|model3|naomi|naomi2|atomiswave|hikaru|gaelco|stv) arcade_src="arcade-mame" ;;
    fbneo) arcade_src="arcade-fbneo" ;;
  esac
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    line2="${line%.*}"
    [[ -n "$arcade_src" && -n "${mame_nogame[$line2]}" ]] && continue
    # a disc image lying loose in the NAOMI set (gdl-0032.chd, Radirgy's) is
    # not a game: a GD-ROM game is its zip, the launcher fetches the disc
    [[ "${rom[0]}" == naomi && "$line" == *.chd ]] && continue
    # the Hikaru item keeps the BIOS and other boards' sets beside the games,
    # as .7z (hikaru.7z, mie.7z, naomi.7z...); the games are the zips
    [[ "${rom[0]}" == hikaru && "$line" != *.zip ]] && continue
    # the Atomiswave item keeps the BIOS, Demul and other boards' sets beside
    # the games (awbios.zip, demul*.zip, dolphin.zip, *.7z, artwork); the
    # games are the other zips
    [[ "${rom[0]}" == atomiswave && ( "$line" != *.zip || "$line" =~ ^(awbios|demul|dolphin|Atoms_|Atomiswave_) ) ]] && continue
    # the Triforce item: the games are its GameCube images; Tatsunoko vs.
    # Capcom there is the Wii's and Dolphin's builds, not a Triforce game
    [[ "${rom[0]}" == triforce && ( ! "$line" =~ \.(iso|gcm)$ || "$line" == TATSUNOKO* ) ]] && continue
    # Gaelco's PowerVR boards (Odin): their sets out of the whole non-merged
    # MAME set, the ones Odin's game list knows
    [[ "${rom[0]}" == gaelco && ! "$line" =~ ^(atvtrack|atvtracka|gfootbal|smashdrv|smashdrvb|smashdrvs)\.zip$ ]] && continue
    # the PCSX2x6 collection keeps each game's folder (media, dongle, bootloader)
    # beside its .acgame; the .acgame is the game, shown without its game ID
    [[ "${rom[0]}" == namco2x6 && "$line" != *.acgame ]] && continue
    display_name="$line2"
    [[ "${rom[0]}" == namco2x6 ]] && display_name="${line2#NM[0-9][0-9][0-9][0-9][0-9]* - }"
    # An Atari VCS entry is a folder named after the game, with no extension
    # to strip ("B.S.U - Blow Stuff Up"), and "_ " where the title has a
    # colon ("Adventure_ 2600"); the name goes to the page as written out.
    if [[ "${rom[0]}" == atarivcs ]]; then line2="$line"; display_name="${line//_ /: }"; fi
    if [[ -n "$softlist" && -n "${mame_name[$softlist:$line2]}" ]]; then
      display_name="${mame_name[$softlist:$line2]}"
    elif [[ -n "$arcade_src" && -n "${mame_name[$arcade_src:$line2]}" ]]; then
      display_name="${mame_name[$arcade_src:$line2]}"
    fi
    # Decode the entities, then escape backslashes and double quotes for the JS
    # string literal (MAME names like: Aigiina no Yogen - from "The Legend of ...")
    js_name="$display_name"
    js_name="${js_name//&quot;/\"}"
    js_name="${js_name//&lt;/<}"
    js_name="${js_name//&gt;/>}"
    js_name="${js_name//&amp;/\&}"
    js_name="${js_name//\\/\\\\}"; js_name="${js_name//\"/\\\"}"
    js_line="${line//\\/\\\\}"; js_line="${js_line//\"/\\\"}"
    # the snap of the MAME set of a Lindbergh, Chihiro or Namco 246/256 game, as a third field
    thumbname=""
    if [[ "${rom[0]}" == lindbergh || "${rom[0]}" == chihiro ]]; then mame_snap_of "$line2"; thumbname="$REPLY"; fi
    [[ "${rom[0]}" == namco2x6 ]] && { mame_snap_of "$display_name"; thumbname="$REPLY"; }
    # a Triforce image's MAME set, by its title
    if [[ "${rom[0]}" == triforce ]]; then
      case "$line2" in
        "F-Zero AX (Monster)"*|"F-Zero AX Monster"*) thumbname=fzeroaxm ;;
        "F-Zero AX"*) thumbname=fzeroax ;;
        "Gekitou Pro Yakyuu"*) thumbname=gekpurya ;;
        "Mario Kart Arcade GP 2"*|"Mario Kart Arcade GP2"*) thumbname=mkartag2 ;;
        "Mario Kart Arcade GP"*) thumbname=mkartagp ;;
        "Virtua Striker 3"*) thumbname=vs2002ex ;;
        "Virtua Striker 4"*) thumbname=vs42006 ;;
      esac
    fi
    # a MAME clone without a snap of its own takes its parent's (Virtua
    # Formula, Virtua Racing's)
    if [[ "$arcade_src" == arcade-mame && -z "${mame_snap[$line2]}" ]]; then
      par="${mame_parent[$line2]}"
      [[ -n "$par" && -n "${mame_snap[$par]}" ]] && thumbname="$par"
    fi
    # the page strips an extension after the last dot, which an Atari VCS
    # name with dots has not ("A.R.T.I. 7800"): name its snap outright
    [[ "${rom[0]}" == atarivcs && "$line" == *.* ]] && thumbname="$line"
    if [[ -n "$thumbname" ]]; then
      echo "\"${js_line}	${js_name}	${thumbname}\"," >&$html_fd
    elif [[ "$display_name" != "$line2" || "${rom[0]}" == atarivcs ]]; then
      echo "\"${js_line}	${js_name}\"," >&$html_fd
    else
      echo "\"${js_line}\"," >&$html_fd
    fi
    ((pocet++)); ((total++))
    if [[ "$line2" == *")"* ]]; then thumb="${line2%%)*})"; else thumb="$line2"; fi
    [[ -n "$thumbname" ]] && thumb="$thumbname"
    if [[ "$line" != *.* ]]; then polozka="folder"; else polozka="game"; fi
    hra="<$polozka><path>./$foldername/${line}</path><name>${display_name}</name><image>~/../thumbs/${rom[5]}/Named_Snaps/${thumb}.png</image>"
    if [[ ! "$line" =~ $hidden_re ]]; then
      echo "${hra}</$polozka>" >&$xml_fd
    else echo "${hra}<hidden>true</hidden></$polozka>" >&$xml_fd; fi
  done < "$cachefile"
  prev_romfolder="$romfolder"; prev_imagepath="${rom[5]// /_}"; prev_platform="${rom[0]}"
  src=""
  if [[ "${rom[1]}" == archive:* ]]; then
    if [[ -f "$cache/$cachehash.path" ]]; then
      eff_path=$(<"$cache/$cachehash.path")
    else
      eff_path="${rom[1]}"
    fi
    inner_prefix=""
    [[ -f "$cache/$cachehash.prefix" ]] && inner_prefix=$(<"$cache/$cachehash.prefix")
    aftercolon="${eff_path#archive:}"
    ia_item="${aftercolon%%/*}"
    ia_sub="${aftercolon#$ia_item}"; ia_sub="${ia_sub#/}"
    if [[ -n "$ia_sub" ]]; then
      src="https://archive.org/download/${ia_item}/$(urlenc "$ia_sub")/${inner_prefix}"
    else
      src="https://archive.org/download/${ia_item}/${inner_prefix}"
    fi
  fi
  src_kv=""; [[ -n "$src" ]] && src_kv="; src=\"${src}\""
  platform=${rom[0]}; ext=""; rom4="${rom[4]//$'\r'/}"; if [ -n "$rom4" ]; then ext="; ext=\"${rom4}\""; fi; emu="${rom[3]//\"/\\\"}"; casefolder="${foldername//\$/\\\$}"; echo "*\"/${rom[0]}/${casefolder}/\"*) core=\"${emu}\"${ext}${src_kv};;" >> ~/gameflix/retroarch.sh
  printf '/%s/%s/\t%s\t%s\t%s\n' "${rom[0]}" "$foldername" "${rom[3]}" "$rom4" "$src" >> ~/gameflix/launch.tsv
  [[ -n "$src" ]] && echo "  *\"/${rom[0]}/${foldername}/\"*) src=\"${src}\";;" >> ~/gameflix/urls.sh
  echo "<folder><path>./$foldername</path><name>$foldername</name><image>~/../thumb/${rom[0]}.png</image></folder>" >&$xml_fd
done
# Flush last platform
echo ']; generateFileLinks("'"$prev_romfolder"'", "'"${prev_imagepath}"'");</script>' >&$html_fd
echo "<script src=\"script.js\"></script>" >&$html_fd
exec {html_fd}>&- {xml_fd}>&-
echo "<figure><a href='${rom3}.html'><img src='https://raw.githubusercontent.com/WizzardSK/gameflix/master/art/background/${rom3}.jpg'><figcaption>${rom6}</figcaption></a>$pocet</figure>" >> ~/gameflix/main.html; ((platforms++))
echo "<a href=\"${rom3}.html\" target=\"main\">${rom6}</a> <small>$pocet</small><br />" >> ~/gameflix/systems.html
# Close all gamelist XMLs
for k in "${!gamelist_started[@]}"; do
  echo "</gameList>" >> ~/gamelists/${k}/gamelist.xml
done

echo '<script src="script.js"></script>' >> ~/gameflix/main.html
cat retroarch.end >> ~/gameflix/retroarch.sh; cp favicon.png ~/gameflix/
# Derive the Android intent core map from the launcher table we just built, so
# cores.json always matches retroarch.sh / launch.tsv (core + src + ext).
python3 gen_cores.py ~/gameflix/launch.tsv > ~/gameflix/cores.json
echo '  esac; }' >> ~/gameflix/urls.sh
chmod +x ~/gameflix/retroarch.sh; echo "<p><b>Total: $total</b>" >> ~/gameflix/systems.html; echo "<p><b>Platforms: $platforms</b>" >> ~/gameflix/systems.html
echo '<script src="script.js"></script>' >> ~/gameflix/systems.html
