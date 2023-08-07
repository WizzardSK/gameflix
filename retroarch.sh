#!/bin/bash
adresar=$(dirname "$1")
adresar="${adresar##*/}"
case "$adresar" in

  "atari2600")     core="stella" ;;
  "atari5200")     core="a5200" ;;
  "atari7800")     core="prosystem" ;;
  "lynx")          core="mednafen_lynx" ;;
  "jaguar")        core="virtualjaguar" ;;
  "atarist")       core="hatari" ;;
  "atari800")      core="atari800" ;;

  "c64")           core="vice_x64sc" ;;
  "amiga1200")     core="puae" ;;
  "intellivision") core="freeintv" ;;
  "colecovision")  core="bluemsx" ;;

  "sg1000")        core="genesis_plus_gx" ;;
  "mastersystem")  core="genesis_plus_gx" ;;
  "gamegear")      core="genesis_plus_gx" ;;
  "megadrive")     core="genesis_plus_gx" ;;
  "sega32x")       core="picodrive" ;;
  "segacd")        core="picodrive" ;;
  "saturn")        core="yabause" ;;
  "dreamcast")     command="umount ~/iso; mount-zip \"$1\" ~/iso; /usr/bin/retroarch -L ~/.config/retroarch/cores/flycast_libretro.so ~/iso/*.cue" ;;

  "gbc")           core="sameboy" ;;
  "gba")           core="mgba" ;;
  "nes")           core="nestopia" ;;
  "snes")          core="snes9x" ;;
  "n64")           core="mupen64plus_next" ;;
  "gamecube")      command="umount ~/iso; mount-zip \"$1\" ~/iso; /usr/local/bin/dolphin-emu -b -e ~/iso/*.rvz" ;;
  "wii")           command="umount ~/iso; mount-zip \"$1\" ~/iso; /usr/local/bin/dolphin-emu -b -e ~/iso/*.rvz" ;;

  "psx")           core="pcsx_rearmed" ;;
  "ps2")           command="umount ~/iso; mount-zip \"$1\" ~/iso; ~/*2.AppImage ~/iso/*.iso" ;;
  "psp")           command="umount ~/iso; mount-zip \"$1\" ~/iso; /usr/bin/retroarch -L ~/.config/retroarch/cores/ppsspp_libretro.so ~/iso/*.iso" ;;

  "pcengine")      core="mednafen_pce_fast" ;;
  "pcenginecd")    command="umount ~/iso; mount-zip \"$1\" ~/iso; /usr/bin/retroarch -L ~/.config/retroarch/cores/mednafen_pce_fast_libretro.so ~/iso/*.cue" ;;
  "3do")           command="umount ~/iso; mount-zip \"$1\" ~/iso; /usr/bin/retroarch -L ~/.config/retroarch/cores/opera_libretro.so ~/iso/*.cue" ;;
  "dos")           core="dosbox_pure" ;;

  "amstradcpc")    core="cap32" ;;
  "zxspectrum")    core="fuse" ;;

esac
/usr/bin/retroarch -L ~/.config/retroarch/cores/${core}_libretro.so "$1"
flatpak run org.libretro.RetroArch -L ~/.config/retroarch/cores/${core}_libretro.so "$1"
eval "$command"
