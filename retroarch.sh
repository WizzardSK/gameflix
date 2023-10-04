#!/bin/bash
adresar=$(dirname "$1")
adresar="${adresar##*/}"
case "$adresar" in

  "channelf"|"Fairchild - Channel F")                           core="freechaf" ;;
  "vectrex"|"CGE - Vectrex")                                    core="vecx" ;;
  "o2em"|"Magnavox - Odyssey 2")                                core="o2em" ;;
  "videopacplus"|"Philips - Videopac+")                         core="o2em" ;;

  "atari2600"|"Atari - 2600")                                   core="stella" ;;
  "atari5200"|"Atari - 5200")                                   core="a5200" ;;
  "atari7800"|"Atari - 7800")                                   core="prosystem" ;;
  "lynx"|"Atari - Lynx")                                        core="mednafen_lynx" ;;
  "jaguar"|"Atari - Jaguar (J64)")                              core="virtualjaguar" ;;
  "atarist"|"Atari - ST")                                       core="hatari" ;;

  "vic20"|"Commodore - VIC-20")                                 core="vice_xvic" ;;
  "c64"|"Commodore - Commodore 64")                             core="vice_x64sc" ;;
  "amiga1200"|"Commodore - Amiga")                              core="puae" ;;
  "amigacd32"|"Commodore - Amiga CD32")                         core="puae" ;;
  "intellivision"|"Mattel - Intellivision")                     core="freeintv" ;;
  "colecovision"|"Coleco - ColecoVision")                       core="bluemsx" ;;

  "sg1000"|"Sega - SG-1000")                                    core="genesis_plus_gx" ;;
  "mastersystem"|"Sega - Master System - Mark III")             core="genesis_plus_gx" ;;
  "gamegear"|"Sega - Game Gear")                                core="genesis_plus_gx" ;;
  "megadrive"|"Sega - Mega Drive - Genesis")                    core="genesis_plus_gx" ;;
  "sega32x"|"Sega - 32X")                                       core="picodrive" ;;
  "segacd"|"Sega - Mega CD & Sega CD")                          core="picodrive" ;;
  "saturn"|"Sega - Saturn")                                     core="yabause" ;;
  "dreamcast"|"Sega - Dreamcast")                               command="umount ~/iso; mount-zip \"$1\" ~/iso; /usr/bin/retroarch -L ~/.config/retroarch/cores/flycast_libretro.so ~/iso/*.cue" ;;

  "fds"|"Nintendo - Family Computer Disk System (FDS)")         core="nestopia" ;;
  "gb"|"Nintendo - Game Boy")                                   core="sameboy" ;;
  "gbc"|"Nintendo - Game Boy Color")                            core="sameboy" ;;
  "gba"|"Nintendo - Game Boy Advance")                          core="mgba" ;;
  "nds"|"Nintendo - Nintendo DS (Decrypted)")                   core="melonds" ;;
  "nes"|"Nintendo - Nintendo Entertainment System (Headered)")  core="nestopia" ;;
  "snes"|"Nintendo - Super Nintendo Entertainment System")      core="snes9x" ;;
  "n64"|"Nintendo - Nintendo 64 (ByteSwapped)")                 core="mupen64plus_next" ;;
  "n64dd"|"Nintendo - Nintendo 64DD")                           core="parallel_n64" ;;
  "gamecube"|"Nintendo - GameCube - NKit RVZ [zstd-19-128k]")   command="umount ~/iso; mount-zip \"$1\" ~/iso; /usr/local/bin/dolphin-emu -b -e ~/iso/*.rvz" ;;
  "wii"|"Nintendo - Wii - NKit RVZ [zstd-19-128k]")             command="umount ~/iso; mount-zip \"$1\" ~/iso; /usr/local/bin/dolphin-emu -b -e ~/iso/*.rvz" ;;

  "psx"|"Sony - PlayStation")                                   core="pcsx_rearmed" ;;
  "ps2"|"Sony - PlayStation 2")                                 command="umount ~/iso; mount-zip \"$1\" ~/iso; ~/*2.AppImage ~/iso/*.iso" ;;
  "psp"|"Sony - PlayStation Portable")                          command="umount ~/iso; mount-zip \"$1\" ~/iso; /usr/bin/retroarch -L ~/.config/retroarch/cores/ppsspp_libretro.so ~/iso/*.iso" ;;

  "pc98"|"NEC - PC-98 series")                                  core="np2kai" ;;
  "pcengine"|"NEC - PC Engine - TurboGrafx-16")                 core="mednafen_pce_fast" ;;
  "pcenginecd"|"NEC - PC Engine CD & TurboGrafx CD")            command="umount ~/iso; mount-zip \"$1\" ~/iso; /usr/bin/retroarch -L ~/.config/retroarch/cores/mednafen_pce_fast_libretro.so ~/iso/*.cue" ;;
  "supergrafx"|"NEC - PC Engine SuperGrafx")                    core="mednafen_supergrafx" ;;  
  "pcfx"|"NEC - PC-FX & PC-FXGA")                               command="umount ~/iso; mount-zip \"$1\" ~/iso; /usr/bin/retroarch -L ~/.config/retroarch/cores/mednafen_pcfx_libretro.so ~/iso/*.cue" ;;

  "3do"|"Panasonic - 3DO Interactive Multiplayer")              command="umount ~/iso; mount-zip \"$1\" ~/iso; /usr/bin/retroarch -L ~/.config/retroarch/cores/opera_libretro.so ~/iso/*.cue" ;;
  "ngp"|"SNK - NeoGeo Pocket")                                  core="mednafen_ngp" ;;
  "ngpc"|"SNK - NeoGeo Pocket Color")                           core="mednafen_ngp" ;;
  "neogeocd"|"SNK - Neo Geo CD")                                command="umount ~/iso; mount-zip \"$1\" ~/iso; /usr/bin/retroarch -L ~/.config/retroarch/cores/neocd_libretro.so ~/iso/*.cue" ;;

  "atari800")                                                   command="atari800 \"$1\"" ;;
  "amstradcpc")                                                 core="cap32" ;;
  "zx81")                                                       core="81" ;;
  "zxspectrum")                                                 core="fuse" ;;
  "dos")                                                        core="dosbox_pure" ;;
  "msx"|"Microsoft - MSX")                                      core="bluemsx" ;;
  "msx2"|"Microsoft - MSX")                                     core="bluemsx" ;;  
  "xbox"|"Microsoft - Xbox")                                    command="umount ~/iso; mount-zip \"$1\" ~/iso; /usr/bin/xemu ~/iso/*.iso" ;;

esac
/usr/bin/retroarch -L ~/.config/retroarch/cores/${core}_libretro.so "$1"
eval "$command"
