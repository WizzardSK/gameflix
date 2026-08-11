#!/bin/bash
mkdir -p /userdata/system/logs
LOG=/userdata/system/logs/gameflix.log
exec >>"$LOG" 2>&1
status() { echo "$@"; echo "$@" >/dev/console 2>/dev/null; }
status "=== gameflix batocera.sh started at $(date) ==="
status "tail -f $LOG  # for live progress"
emulationstation stop; chvt 3; clear

# -- Install runtime config and helpers -------------------------------------
status "=== installing rclone.conf (IA auth) ==="
wget -nv -O /userdata/system/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/rclone.conf

status "=== installing urls.sh (per-platform IA source lookup) ==="
# urls.sh is a build artifact — lives inside gameflix.zip alongside the web
# interface, not at repo root. Pull it out without exploding the whole archive.
wget -nv -O /tmp/gameflix.zip https://github.com/WizzardSK/gameflix/raw/refs/heads/main/gameflix.zip
unzip -p /tmp/gameflix.zip urls.sh > /userdata/system/urls.sh
rm -f /tmp/gameflix.zip
[[ ! -s /userdata/system/urls.sh ]] && status "WARNING: urls.sh empty — on-demand fetch will not work"

status "=== installing emulator launch wrapper (on-demand fetch + mount-zip) ==="
wget -nv -O /userdata/system/gameflix-launch.sh \
  https://raw.githubusercontent.com/WizzardSK/gameflix/main/batocera/gameflix-launch.sh
chmod +x /userdata/system/gameflix-launch.sh

status "=== installing game-selected hook (thumbnail prefetch) ==="
mkdir -p /userdata/system/configs/emulationstation/scripts/game-selected
wget -nv -O /userdata/system/configs/emulationstation/scripts/game-selected/game.sh \
  https://raw.githubusercontent.com/WizzardSK/gameflix/main/batocera/game.sh
chmod +x /userdata/system/configs/emulationstation/scripts/game-selected/game.sh

status "=== installing systems.csv ==="
wget -nv -O /userdata/system/systems.csv https://raw.githubusercontent.com/WizzardSK/gameflix/main/systems.csv

# -- Pre-populate fantasy console placeholders + thumbnails -----------------
mkdir -p /userdata/{rom,roms,thumb,thumbs} /userdata/roms/{lowresnx/LowresNX,wasm4/WASM-4,voxatron,pico8,tic80}
for name in voxatron pico8; do
  [[ ! -f /userdata/roms/$name/splore.png ]] && wget -nv -O /userdata/roms/$name/splore.png \
    https://github.com/WizzardSK/gameflix/raw/main/fantasy/$name.png
done
touch /userdata/roms/tic80/surf.tic
[[ ! -f /userdata/roms/tic80/tic80.png ]] && wget -nv -O /userdata/roms/tic80/tic80.png \
  https://raw.githubusercontent.com/WizzardSK/gameflix/master/art/consoles/tic80.png

# Bundled wasm4/lowresnx zips (fantasy consoles use local files, not on-demand fetch)
for name in wasm4 lowresnx; do
  wget -q -O "/userdata/system/$name.zip" "https://wizzardsk.github.io/$name.zip"
  rm -rf "/userdata/roms/$name"/*
  unzip -oq "/userdata/system/$name.zip" -d "/userdata/roms/$name"
done

# Per-platform console thumbnails (used by ES grid background)
status "=== fetching per-platform console icons ==="
while IFS=',' read -r platform _; do
  [[ -z "$platform" || "$platform" == "platform" ]] && continue
  if [[ ! -f /userdata/thumb/${platform}.png ]]; then
    wget -nv -O /userdata/thumb/${platform}.png \
      https://raw.githubusercontent.com/WizzardSK/gameflix/master/art/consoles/${platform}.png 2>/dev/null
  fi
done < <(awk -F',' 'NR>1{print $1}' /userdata/system/systems.csv | sort -u)

# -- Install gamelists + es_systems --------------------------------------------
status "=== installing gamelists ==="
wget -nv -O /userdata/system/gamelist.zip https://github.com/WizzardSK/gameflix/raw/main/batocera/gamelist.zip
unzip -q -o /userdata/system/gamelist.zip -d /userdata/roms

status "=== regenerating Switch gamelist from local files ==="
SWITCH_DIR=/userdata/roms/switch
if [[ -d "$SWITCH_DIR" ]]; then
  {
    echo '<gameList>'
    find "$SWITCH_DIR" -maxdepth 1 -type f \( -name '*.nsp' -o -name '*.xci' \) -printf '%f\n' | sort | \
    while IFS= read -r fname; do
      name="${fname%.*}"
      # Strip "(region) [tag]" suffix for thumbnail lookup
      short="${name%% (*}"; short="${short%% [*}"
      echo "<game><path>./${fname}</path><name>${name}</name><image>~/../thumbs/Nintendo - Nintendo Switch/Named_Snaps/${short}.png</image></game>"
    done
    echo '</gameList>'
  } > "$SWITCH_DIR/gamelist.xml"
  status "Switch gamelist: $(grep -c '<game>' "$SWITCH_DIR/gamelist.xml") entries"
fi

status "=== regenerating PS3 gamelist from local files ==="
PS3_DIR=/userdata/roms/ps3
if [[ -d "$PS3_DIR" ]]; then
  {
    echo '<gameList>'
    # PS3 games are usually directories (.ps3 JB folders, .psn) but ISO/squashfs
    # disc images are plain files — list both at maxdepth 1.
    find "$PS3_DIR" -maxdepth 1 -mindepth 1 \
      \( \( -type d \( -name '*.ps3' -o -name '*.ps3dir' -o -name '*.psn' \) \) -o \
         \( -type f \( -name '*.ps3' -o -name '*.psn' -o -name '*.iso' -o -name '*.squashfs' \) \) \) \
      -printf '%f\n' | sort | \
    while IFS= read -r fname; do
      name="${fname%.*}"
      # Strip "(region) [tag]" suffix for thumbnail lookup
      short="${name%% (*}"; short="${short%% [*}"
      echo "<game><path>./${fname}</path><name>${name}</name><image>~/../thumbs/Sony - PlayStation 3/Named_Snaps/${short}.png</image></game>"
    done
    echo '</gameList>'
  } > "$PS3_DIR/gamelist.xml"
  status "PS3 gamelist: $(grep -c '<game>' "$PS3_DIR/gamelist.xml") entries"
fi

# -- Mark everything already on disk as a favorite -----------------------------
# The gamelists list every game on archive.org; only the ones actually fetched
# have a file behind them, so the Favorites collection becomes "what is really
# on this box". The launch wrapper flags each new download, but the gamelists
# above were just reinstalled from scratch, which drops every flag — so re-mark
# them here, while ES is stopped. (ES itself never writes gamelist.xml back:
# SaveGamelistsOnExit is set to false further down, which also turns
# saveToGamelistRecovery into a no-op, so the file is the only place this
# can live.)
#
# Skipped: the fantasy consoles, whose games are bundled with the installer
# rather than downloaded — marking a few hundred of them would bury the real
# downloads in the collection.
status "=== marking downloaded games as favorites ==="
fav_total=0
for gl in /userdata/roms/*/gamelist.xml; do
  [[ -f "$gl" ]] || continue
  sysdir=$(dirname "$gl"); sysname=$(basename "$sysdir")
  case "$sysname" in wasm4|lowresnx|pico8|voxatron|tic80) continue ;; esac

  # Everything present, as ./relative/path — the shape <path> entries use.
  # Directories count too: PS3 titles are .ps3/.psn folders, not files.
  ( cd "$sysdir" && find . -mindepth 1 \( -type f -o -type d \) ! -name gamelist.xml ) \
    > /tmp/gf-present.txt 2>/dev/null

  # Most systems have nothing downloaded at all. Walking their ROM directory
  # costs nothing — it is empty — but reading the gamelist does, and together
  # they are ~200 MB of XML. So when the walk came up empty, never open it.
  [[ -s /tmp/gf-present.txt ]] || continue

  n=$(awk -v out="$gl.gf" '
        NR==FNR { present[$0]=1; next }
        index($0, "<game>") && index($0, "<favorite>") == 0 {
          p = $0
          sub(/.*<path>/, "", p); sub(/<\/path>.*/, "", p)
          if (p in present) { sub(/<\/game>/, "<favorite>true</favorite></game>"); n++ }
        }
        { print > out }
        END { print n+0 }
      ' /tmp/gf-present.txt "$gl" 2>>"$LOG")

  if [[ -s "$gl.gf" && "${n:-0}" -gt 0 ]]; then
    mv "$gl.gf" "$gl"
    status "favorites: $sysname — $n"
    fav_total=$((fav_total + n))
  else
    rm -f "$gl.gf"
  fi
done
rm -f /tmp/gf-present.txt
status "favorites: $fav_total game(s) marked"

cp /usr/share/emulationstation/es_systems.cfg /userdata/system/es_systems.bak
wget -nv -O /usr/share/emulationstation/es_systems.cfg \
  https://github.com/WizzardSK/gameflix/raw/main/batocera/es_systems.cfg
cp /usr/share/emulationstation/es_systems.cfg /userdata/system/es_systems.cfg

ES_SETTINGS=/userdata/system/.emulationstation/es_settings.cfg
mkdir -p "$(dirname "$ES_SETTINGS")"
if [[ ! -s "$ES_SETTINGS" ]] || ! grep -q '<config>' "$ES_SETTINGS"; then
  # Initialise with a valid skeleton — ES doesn't fall back to defaults if it
  # fails to parse the file, it would just ignore our setting.
  printf '<?xml version="1.0"?>\n<config>\n</config>\n' > "$ES_SETTINGS"
fi
if grep -q 'name="ParseGamelistOnly"' "$ES_SETTINGS"; then
  sed -i 's|<bool name="ParseGamelistOnly" value="[^"]*"|<bool name="ParseGamelistOnly" value="true"|' "$ES_SETTINGS"
else
  sed -i 's|</config>|\t<bool name="ParseGamelistOnly" value="true" />\n</config>|' "$ES_SETTINGS"
fi

if grep -q 'name="SaveGamelistsOnExit"' "$ES_SETTINGS"; then
  sed -i 's|<bool name="SaveGamelistsOnExit" value="[^"]*"|<bool name="SaveGamelistsOnExit" value="false"|' "$ES_SETTINGS"
else
  sed -i 's|</config>|\t<bool name="SaveGamelistsOnExit" value="false" />\n</config>|' "$ES_SETTINGS"
fi

# Sync to the configs path too — Batocera reads from
# /userdata/system/configs/emulationstation/es_settings.cfg
ES_CFG=/userdata/system/configs/emulationstation/es_settings.cfg
if [[ -f "$ES_CFG" ]]; then
  for k in ParseGamelistOnly SaveGamelistsOnExit; do
    v=true
    [[ "$k" == SaveGamelistsOnExit ]] && v=false
    if grep -q "name=\"$k\"" "$ES_CFG"; then
      sed -i "s|<bool name=\"$k\" value=\"[^\"]*\"|<bool name=\"$k\" value=\"$v\"|" "$ES_CFG"
    else
      sed -i "s|</config>|\t<bool name=\"$k\" value=\"$v\" />\n</config>|" "$ES_CFG"
    fi
  done
fi

status "=== done — restarting EmulationStation ==="
chvt 1; batocera-es-swissknife --restart &
