#!/bin/bash
# All output goes to a log file (avoids tee/process-substitution buffer issues on
# busybox), with status banners echoed live to /dev/console so the user sees
# something on TTY3. Tail the log via SSH for full progress.
mkdir -p /userdata/system/logs
LOG=/userdata/system/logs/gameflix.log
exec >>"$LOG" 2>&1
status() { echo "$@"; echo "$@" >/dev/console 2>/dev/null; }
status "=== gameflix batocera.sh started at $(date) ==="
status "tail -f $LOG  # for live progress"
emulationstation stop; chvt 3; clear; mount -o remount,size=6000M /tmp
wget -O /userdata/system/rclone.conf https://raw.githubusercontent.com/WizzardSK/gameflix/main/rclone.conf > /dev/null 2>&1
for file in httpdirfs fuse-zip mount-zip; do [ ! -f /userdata/system/$file ] && wget -nv -O /userdata/system/$file https://github.com/WizzardSK/gameflix/raw/main/batocera/$file && chmod +x /userdata/system/$file; done
if [ ! -f /userdata/system/ratarmount-full ]; then wget -nv -O /userdata/system/ratarmount-full https://github.com/mxmlnkn/ratarmount/releases/download/v1.2.0/ratarmount-1.2.0-x86_64.AppImage; chmod +x /userdata/system/ratarmount-full; fi
if [ ! -f /userdata/system/ratarmount ]; then wget -nv -O /userdata/system/ratarmount https://github.com/mxmlnkn/ratarmount/releases/download/v1.2.0/ratarmount-1.2.0-slim-x86_64.AppImage; chmod +x /userdata/system/ratarmount; fi
mkdir -p /userdata/system/configs/emulationstation/scripts/game-selected
wget -nv -O /userdata/system/configs/emulationstation/scripts/game-selected/game.sh https://github.com/WizzardSK/gameflix/raw/main/batocera/game.sh > /dev/null 2>&1; chmod +x /userdata/system/configs/emulationstation/scripts/game-selected/game.sh
#wget -nv -O /usr/share/batocera/configgen/data/mame/messSystems.csv https://github.com/WizzardSK/gameflix/raw/main/batocera/messSystems.csv > /dev/null 2>&1
for name in voxatron pico8; do [ ! -f /userdata/roms/$name/splore.png ] && wget -nv -O /userdata/roms/$name/splore.png https://github.com/WizzardSK/gameflix/raw/main/fantasy/$name.png; done
touch /userdata/roms/tic80/surf.tic
if [ ! -f /userdata/roms/tic80/tic80.png ]; then wget -nv -O /userdata/roms/tic80/tic80.png https://raw.githubusercontent.com/WizzardSK/gameflix/master/art/consoles/tic80.png; fi

mkdir -p /userdata/{rom,roms,thumb,thumbs,zip,zips} /userdata/system/.cache/{httpdirfs,ratarmount,rclone} /userdata/roms/{lowresnx/LowresNX,wasm4/WASM-4}
wget -nv -O /userdata/system/systems.csv https://raw.githubusercontent.com/WizzardSK/gameflix/main/systems.csv > /dev/null 2>&1
IFS=$'\n' read -d '' -ra roms <<< "$(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.csv | tail -n +2 | awk '{o="";i=1;n=length($0);while(i<=n){c=substr($0,i,1);if(c==","){o=o";";i++}else if(c=="\""){i++;while(i<=n){c=substr($0,i,1);if(c=="\""){if(substr($0,i+1,1)=="\""){o=o"\"";i+=2}else{i++;break}}else{o=o c;i++}}}else{o=o c;i++}};print o}')"

mkdir -p /userdata/zips /userdata/zips-mount /userdata/mount

# Resolve archive:<bucket>/<path> -> /userdata/zip/<bucket>/<filename> (matches webflix.sh)
local_zip_path() {
  local p="$1"
  case "$p" in
    archive:ni-roms/*)    echo "/userdata/zip/ni-roms/$(basename "$p")" ;;
    archive:mame-sl/*)    s="${p#archive:mame-sl/}"; s="${s#*/}"; echo "/userdata/zip/mame-sl/$s" ;;
    archive:tosec-main/*) echo "/userdata/zip/tosec-main/$(basename "$p")" ;;
    *) return 1 ;;
  esac
}

# Phase 1: download missing zips to /userdata/zip/<bucket>/ (in parallel, like webflix.sh)
status "=== downloading missing zips ==="
declare -A seen_path ia_dir_mounted
download_pending=0
for each in "${roms[@]}"; do
  IFS=";" read -ra rom <<< "$each"
  [[ "${rom[1]}" != archive:* || "${rom[1]}" != *.zip ]] && continue
  [[ -n "${seen_path[${rom[1]}]}" ]] && continue
  seen_path[${rom[1]}]=1
  local_path=$(local_zip_path "${rom[1]}") || continue
  [[ -f "$local_path" ]] && continue
  mkdir -p "$(dirname "$local_path")"
  ((download_pending++))
  echo "[$download_pending] downloading ${rom[1]}"
  rclone copyto "${rom[1]}" "$local_path" --config=/userdata/system/rclone.conf --no-check-dest &
  while (( $(jobs -r | wc -l) >= 3 )); do sleep 2; done
done
wait
status "=== downloaded $download_pending zip(s) ==="

zip_count=0; ia_count=0; bind_count=0; rclone_count=0
total=${#roms[@]}; idx=0
status "=== mounting/linking $total platform entries ==="
IFS=";"; for each in "${roms[@]}"; do
  read -ra rom < <(printf '%s' "$each")
  if [ ! -f /userdata/thumb/${rom[0]}.png ]; then wget -nv -O /userdata/thumb/${rom[0]}.png https://raw.githubusercontent.com/WizzardSK/gameflix/master/art/consoles/${rom[0]}.png; fi
  ((idx++))
  rom3=$(sed 's/<[^>]*>//g' <<< "${rom[2]}")
  dst="/userdata/roms/${rom[0]}/${rom3}"
  if [[ "${rom[1]}" == archive:* && "${rom[1]}" == *.zip ]]; then
    # Symlink the zips tree to the local downloaded zip (already ensured by Phase 1)
    if local_path=$(local_zip_path "${rom[1]}") && [[ -f "$local_path" ]]; then
      mkdir -p /userdata/zips/${rom[0]}
      ln -sfn "$local_path" "/userdata/zips/${rom[0]}/${rom3}.zip"
      ((zip_count++))
    fi
  elif [[ "${rom[1]}" == archive:* ]]; then
    # archive:<bucket>/<subpath> (no .zip): rclone-mount parent IA item once,
    # then symlink $dst into the mount. Mirrors webflix.sh Phase 5 so the
    # symlinks made there ('/userdata/roms/<plat>/<fold> -> /userdata/mount/
    # <item>/<subpath>') just work without webflix overwriting them.
    aftercolon="${rom[1]#archive:}"; item="${aftercolon%%/*}"; subpath="${aftercolon#$item}"; subpath="${subpath#/}"
    if [[ -z "${ia_dir_mounted[$item]}" ]]; then
      mkdir -p /userdata/mount/"$item"
      if ! grep -q " /userdata/mount/$item " /proc/mounts; then
        echo "[$idx/$total] rclone-mount archive:$item"
        rclone mount "archive:$item" /userdata/mount/"$item" --config=/userdata/system/rclone.conf --http-no-head --daemon --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h --allow-non-empty --vfs-cache-mode minimal --vfs-read-chunk-size 1M
        ((rclone_count++))
      fi
      ia_dir_mounted[$item]=1
    fi
    src="/userdata/mount/$item${subpath:+/$subpath}"
    if [[ -d "$dst" && ! -L "$dst" ]] && [[ -z "$(ls -A "$dst" 2>/dev/null)" ]]; then
      rmdir "$dst" 2>/dev/null
    fi
    if [[ -L "$dst" || ! -e "$dst" ]]; then
      ln -sfn "$src" "$dst"
    fi
  elif [[ "${rom[1]}" != *:* ]]; then
    grep -q " $dst " /proc/mounts && continue
    mkdir -p "$dst"
    echo "[$idx/$total] bind ${rom[1]} -> $dst"
    mount -o bind /userdata/rom/${rom[1]} "$dst"
    ((bind_count++))
  fi
done
status "=== loop done: $zip_count zip-symlinks, $rclone_count direct rclone mounts, $bind_count binds ==="

# Single ratarmount over the symlink tree of all .zip archives, then symlink into roms.
# --recursion-depth 1 keeps ROM zips inside MAME bundles as files; --transform strips
# the redundant <shortname>/ directory inside MAME-SL zips.
grep -q " /userdata/zips-mount " /proc/mounts && fusermount -u -z /userdata/zips-mount 2>/dev/null
# ratarmount in foreground: it eagerly indexes every nested zip, then forks a
# FUSE daemon and exits the parent — when this command returns, the mount-point
# is fully populated. Don't '&' it: the previous attempt registered the
# mount-point only AFTER the fork, so a backgrounded ratarmount left our wait
# loop polling on a path that wouldn't appear in /proc/mounts for 5-30 min.
# negative_timeout dropped to 60 to avoid kernel caching false-negative lookups
# for 24h if anything goes wrong.
expected_dirs=$(find /userdata/zips -mindepth 2 -name "*.zip" 2>/dev/null | wc -l)
status "=== indexing $expected_dirs zips into ratarmount mount (foreground; takes a while) ==="
/userdata/system/ratarmount --recursion-depth 1 -s --transform '^[a-z0-9_]+/' '' \
  -o entry_timeout=86400,attr_timeout=86400,negative_timeout=60 \
  /userdata/zips /userdata/zips-mount
current_dirs=$(find /userdata/zips-mount -mindepth 2 -maxdepth 2 -type d 2>/dev/null | wc -l)
status "=== ratarmount ready ($current_dirs/$expected_dirs zip dirs) ==="

IFS=";"; for each in "${roms[@]}"; do
  read -ra rom < <(printf '%s' "$each")
  [[ "${rom[1]}" != archive:* || "${rom[1]}" != *.zip ]] && continue
  rom3=$(sed 's/<[^>]*>//g' <<< "${rom[2]}")
  src="/userdata/zips-mount/${rom[0]}/${rom3}"
  dst="/userdata/roms/${rom[0]}/${rom3}"
  if [[ -d "$dst" && ! -L "$dst" ]] && [[ -z "$(ls -A "$dst" 2>/dev/null)" ]]; then
    rmdir "$dst" 2>/dev/null
  fi
  if [[ -L "$dst" || ! -e "$dst" ]]; then
    ln -sfn "$src" "$dst"
  fi
done

archives=(wasm4 lowresnx)
for name in "${archives[@]}"; do
  wget -q "https://wizzardsk.github.io/$name.zip" -O "/userdata/system/$name.zip"; rm -rf "/userdata/roms/$name/*"; unzip -oq "/userdata/system/$name.zip" -d "/userdata/roms/$name"
done

wget -nv -O /userdata/system/gamelist.zip https://github.com/WizzardSK/gameflix/raw/main/batocera/gamelist.zip; unzip -q -o /userdata/system/gamelist.zip -d /userdata/roms
cp /usr/share/emulationstation/es_systems.cfg /userdata/system/es_systems.bak
wget -nv -O /usr/share/emulationstation/es_systems.cfg https://github.com/WizzardSK/gameflix/raw/main/batocera/es_systems.cfg > /dev/null 2>&1
cp /usr/share/emulationstation/es_systems.cfg /userdata/system/es_systems.cfg
chvt 1; wget http://127.0.0.1:1234/reloadgames > /dev/null 2>&1
