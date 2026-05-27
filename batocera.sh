#!/bin/bash
# gameflix Batocera setup — on-demand per-game fetch (no bulk romset downloads,
# no rclone/ratarmount mounts). EmulationStation runs with ParseGamelistOnly=true
# so it shows dlaždice straight from gamelist.xml without stat()ing each ROM;
# the game-start hook materializes each picked ROM via archive.org HTTPS just
# before launch.
#
# Logs to /userdata/system/logs/gameflix.log; status banners echoed to TTY3.
mkdir -p /userdata/system/logs
LOG=/userdata/system/logs/gameflix.log
exec >>"$LOG" 2>&1
status() { echo "$@"; echo "$@" >/dev/console 2>/dev/null; }
status "=== gameflix batocera.sh started at $(date) ==="
status "tail -f $LOG  # for live progress"
emulationstation stop; chvt 3; clear

# -- Cleanup any prior gameflix mounts and zip caches -----------------------
status "=== unmounting legacy FUSE mounts ==="
for mp in /userdata/zips-mount /userdata/share/roms-mount /userdata/iso; do
  [[ -d "$mp" ]] && mountpoint -q "$mp" 2>/dev/null && fusermount -u -z "$mp"
done
for d in /userdata/mount/*/; do
  [[ -d "$d" ]] || continue
  mountpoint -q "$d" 2>/dev/null && fusermount -u -z "$d"
done

status "=== deleting cached romset zips ==="
rm -rf /userdata/zip /userdata/zips /userdata/zips-mount /userdata/share/roms-mount
rmdir /userdata/mount/*/ 2>/dev/null
rmdir /userdata/mount 2>/dev/null

# The pre-refactor batocera.sh populated /userdata/roms/<plat>/<fold> with
# symlinks pointing into /userdata/zips-mount and /userdata/mount. Those
# targets are now gone, so the symlinks are dangling — mkdir -p can't create
# a real directory underneath them, which blocks the on-demand fetch with
# "No such file or directory" inside <plat>/<fold>/.
dangling=$(find /userdata/roms -maxdepth 3 -type l ! -exec test -e {} \; -print -delete 2>/dev/null | wc -l)
status "removed $dangling dangling symlinks from /userdata/roms"

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
# We can't use a game-start hook for the fetch because on Linux,
# Batocera ES sets psi.waitForExit=false for non-quit events
# (es-core/src/Scripting.cpp), so ES launches the emulator immediately
# regardless of -wait suffix and races a multi-megabyte download.
# Instead we wire the wrapper into es_systems.cfg <command>, which ES
# DOES wait for (it's the launch itself).
wget -nv -O /userdata/system/gameflix-launch.sh \
  https://raw.githubusercontent.com/WizzardSK/gameflix/main/batocera/gameflix-launch.sh
chmod +x /userdata/system/gameflix-launch.sh
# Disable legacy game-start hook (does nothing useful on Linux, still in
# repo for the standalone web flow which doesn't share this script)
rm -f /userdata/system/configs/emulationstation/scripts/game-start/gameflix-wait.sh \
      /userdata/system/configs/emulationstation/scripts/game-start/gameflix.sh

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

# Switch has no on-demand fetch source (no NoIntro/TOSEC/Redump on archive.org).
# Replace the bundled full-catalog gamelist with one containing only games the
# user has actually placed in /userdata/roms/switch/, so ES doesn't show
# thousands of unlaunchable tiles.
# ParseGamelistOnly bypasses Utils::FileSystem::exists(path) but ES still
# rejects entries whose PARENT DIRECTORY doesn't exist ("Error finding/creating
# FileData ... skipping" in es_log.txt). For each gamelist <path>./sub/file</path>
# create the sub/ directory so ES can register the entry even with no ROM file
# present.
status "=== materialising parent dirs for gamelist entries ==="
python3 <<'PYEOF'
import os, re, glob
n = 0
for gl in glob.glob('/userdata/roms/*/gamelist.xml'):
    pdir = os.path.dirname(gl)
    seen = set()
    with open(gl) as f:
        for m in re.finditer(r'<path>\./([^<]+)</path>', f.read()):
            d = os.path.dirname(m.group(1))
            if d and d not in seen:
                seen.add(d)
                os.makedirs(os.path.join(pdir, d), exist_ok=True)
                n += 1
print(f'ensured {n} directories')
PYEOF

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

cp /usr/share/emulationstation/es_systems.cfg /userdata/system/es_systems.bak
wget -nv -O /usr/share/emulationstation/es_systems.cfg \
  https://github.com/WizzardSK/gameflix/raw/main/batocera/es_systems.cfg
cp /usr/share/emulationstation/es_systems.cfg /userdata/system/es_systems.cfg

# -- Enable ParseGamelistOnly so ES trusts gamelist entries (skips
#    Utils::FileSystem::exists check in es-app/src/Gamelist.cpp:findOrCreateFile,
#    confirmed in batocera-emulationstation master). Without this, ES filters
#    out every gamelist row whose target ROM isn't already on disk → platforms
#    appear empty → SystemData::isVisible() hides them.
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

# SaveGamelistsOnExit=false is CRITICAL — without it, ES's cleanupGamelist
# rewrites every /userdata/roms/<plat>/gamelist.xml on shutdown, dropping
# every entry whose ROM file isn't physically present on disk. After one
# ES restart, a freshly-installed 8514-entry psx gamelist.xml is reduced to
# just the few CHDs that on-demand fetch happened to download — and ES then
# treats the system as "almost empty" on the next boot.
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
