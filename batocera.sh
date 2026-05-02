#!/bin/bash
# Tee all output to a log file so the user can review after boot (chvt 1 hides TTY3)
mkdir -p /userdata/system/logs
exec > >(tee -a /userdata/system/logs/gameflix.log) 2>&1
echo "=== gameflix batocera.sh started at $(date) ==="
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

declare -A ia_zip_mounted
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

zip_count=0; zip_local=0; zip_remote=0; ia_count=0; bind_count=0; rclone_count=0
total=${#roms[@]}; idx=0
echo "=== mounting/linking $total platform entries ==="
IFS=";"; for each in "${roms[@]}"; do
  read -ra rom < <(printf '%s' "$each")
  if [ ! -f /userdata/thumb/${rom[0]}.png ]; then wget -nv -O /userdata/thumb/${rom[0]}.png https://raw.githubusercontent.com/WizzardSK/gameflix/master/art/consoles/${rom[0]}.png; fi
  ((idx++))
  rom3=$(sed 's/<[^>]*>//g' <<< "${rom[2]}")
  dst="/userdata/roms/${rom[0]}/${rom3}"
  if [[ "${rom[1]}" == archive:* && "${rom[1]}" == *.zip ]]; then
    # Prefer locally-downloaded zip in /userdata/zip/<bucket>/; fall back to live IA mount.
    mkdir -p /userdata/zips/${rom[0]}
    src_zip=""
    if local_path=$(local_zip_path "${rom[1]}") && [[ -f "$local_path" ]]; then
      src_zip="$local_path"
      ((zip_local++))
    else
      aftercolon="${rom[1]#archive:}"; item="${aftercolon%%/*}"; subpath="${aftercolon#$item/}"
      if [[ -z "${ia_zip_mounted[$item]}" ]]; then
        mkdir -p /userdata/mount/"$item"
        if ! grep -q " /userdata/mount/$item " /proc/mounts; then
          echo "[$idx/$total] rclone-mount archive:$item (local zip missing)"
          rclone mount "archive:$item" /userdata/mount/"$item" --config=/userdata/system/rclone.conf --http-no-head --daemon --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h --allow-non-empty --vfs-cache-mode minimal --vfs-read-chunk-size 1M
          ((ia_count++))
        fi
        ia_zip_mounted[$item]=1
      fi
      src_zip="/userdata/mount/$item/$subpath"
      ((zip_remote++))
    fi
    ln -sfn "$src_zip" "/userdata/zips/${rom[0]}/${rom3}.zip"
    ((zip_count++))
  elif grep -q ":" <<< "${rom[1]}" && [[ "${rom[1]}" != *.zip ]]; then
    grep -q " $dst " /proc/mounts && continue
    [[ -L "$dst" ]] && continue
    mkdir -p "$dst"
    echo "[$idx/$total] rclone-mount ${rom[1]} -> $dst"
    rclone mount "${rom[1]}" "$dst" --config=/userdata/system/rclone.conf --http-no-head --daemon --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h --allow-non-empty --vfs-cache-mode minimal --vfs-read-chunk-size 1M
    ((rclone_count++))
  elif [[ "${rom[1]}" != *:* ]]; then
    grep -q " $dst " /proc/mounts && continue
    mkdir -p "$dst"
    echo "[$idx/$total] bind ${rom[1]} -> $dst"
    mount -o bind /userdata/rom/${rom[1]} "$dst"
    ((bind_count++))
  fi
done
echo "=== loop done: $zip_count zip-symlinks ($zip_local local, $zip_remote via IA mount), $ia_count IA mounts, $rclone_count direct mounts, $bind_count binds ==="

# Single ratarmount over the symlink tree of all .zip archives, then symlink into roms.
# --recursion-depth 1 keeps ROM zips inside MAME bundles as files; --transform strips
# the redundant <shortname>/ directory inside MAME-SL zips.
grep -q " /userdata/zips-mount " /proc/mounts && fusermount -u -z /userdata/zips-mount 2>/dev/null
/userdata/system/ratarmount --recursion-depth 1 -s --lazy --transform '^[a-z0-9_]+/' '' \
  -o entry_timeout=86400,attr_timeout=86400,negative_timeout=86400 \
  /userdata/zips /userdata/zips-mount &
# Wait briefly for FUSE mountpoint to come up, but don't block on full indexing —
# --lazy defers central-directory reads of each zip until first access
for i in $(seq 1 20); do grep -q " /userdata/zips-mount " /proc/mounts && break; sleep 1; done

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
