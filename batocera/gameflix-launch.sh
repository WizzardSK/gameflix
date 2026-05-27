#!/bin/bash
# Wrapper around Batocera's emulatorlauncher that knows how to expand a zipped
# ROM into a real ROM path. Called from es_systems.cfg <command> entries for
# every CD-based system, instead of the old hard-coded
#   "mount-zip %ROM% /iso; emulatorlauncher -rom /iso/*.cue"
# which broke whenever the zip's inner file wasn't a .cue (NonRedump PSX
# ships .iso, Dreamcast TOSEC ships .gdi, etc).
#
# Args: passed straight through to emulatorlauncher except %ROM%. If %ROM%
# ends in .zip we mount-zip it under /userdata/iso and pick the first match
# from a priority extension list.
args=("$@")
rom=""
rom_idx=-1
for ((i=0;i<${#args[@]};i++)); do
  if [[ "${args[$i]}" == "-rom" ]]; then
    rom_idx=$((i+1))
    rom="${args[$rom_idx]}"
    break
  fi
done

if [[ "$rom" == *.zip ]]; then
  umount /userdata/iso 2>/dev/null
  rm -rf /userdata/iso
  mkdir -p /userdata/iso
  /userdata/system/mount-zip "$rom" /userdata/iso
  # First-match priority list for inner disc descriptors. .cue points at .bin
  # tracks so it wins over the bare .bin / .iso for Redump-style sets; .gdi is
  # canonical for Dreamcast; .iso wins for NonRedump / single-track sets.
  inner=""
  for ext in cue gdi iso chd rvz gcm 3ds cci pbp cso m3u nrg toc img mdf ccd dol elf; do
    cand=$(ls /userdata/iso/*."$ext" 2>/dev/null | head -1)
    if [[ -n "$cand" ]]; then inner="$cand"; break; fi
  done
  if [[ -n "$inner" ]]; then
    args[$rom_idx]="$inner"
  else
    echo "gameflix-launch: no playable file found inside $rom after mount-zip into /userdata/iso" >&2
    ls -la /userdata/iso >&2
    exit 1
  fi
fi

exec emulatorlauncher "${args[@]}"
