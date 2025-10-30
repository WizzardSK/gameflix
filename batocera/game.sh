#!/bin/bash
if [ -d "$2" ]; then exit 0; fi
if [[ "$1" =~ ^(lowresnx|pico8|steam|tic80|voxatron|wasm4)$ ]]; then exit 0; fi
SYSTEM="$1"; GAMENAME="$2"

declare -A PLATFORM_MAP=(
[supervision]="Watara_-_Supervision" [neogeo]="SNK_-_Neo_Geo" [xegs]="Atari_-_XEGS" [videopacplus]="Philips_-_Videopac" [switch]="Nintendo_-_Nintendo_Switch" [vectrex]="GCE_-_Vectrex" [intellivision]="Mattel_-_Intellivision" [o2em]="Magnavox_-_Odyssey2" [channelf]="Fairchild_-_Channel_F" [scv]="Epoch_-_Super_Cassette_Vision" [gamepock]="Epoch_-_Game_Pocket_Computer" [colecovision]="Coleco_-_ColecoVision" [wswan]="Bandai_-_WonderSwan" [wswanc]="Bandai_-_WonderSwan_Color" [uzebox]="Uzebox" [vircon32]="Vircon32" [atari2600]="Atari_-_2600" [atari5200]="Atari_-_5200" [atari7800]="Atari_-_7800" [jaguar]="Atari_-_Jaguar" [jaguarcd]="Atari_-_Jaguar" [lynx]="Atari_-_Lynx" [atarist]="Atari_-_ST" [atari800]="Atari_-_8-bit" [archimedes]="Acorn_-_Archimedes" [apple2]="Apple_-_II" [apple2gs]="Apple_-_IIGS" [macintosh]="Apple_-_Macintosh" [laser310]="VTech_-_Laser_310" [socrates]="VTech_-_Socrates" [ti99]="Texas_Instruments_-_TI-99" [thomson]="Thomson_-_MOTO" [nes]="Nintendo_-_Nintendo_Entertainment_System" [fds]="Nintendo_-_Family_Computer_Disk_System" [snes]="Nintendo_-_Super_Nintendo_Entertainment_System" [snes-msu1]="Nintendo_-_Super_Nintendo_Entertainment_System" [satellaview]="Nintendo_-_Satellaview" [sufami]="Nintendo_-_Sufami_Turbo" [n64]="Nintendo_-_Nintendo_64" [gamecube]="Nintendo_-_GameCube" [wii]="Nintendo_-_Wii" [pokemini]="Nintendo_-_Pokemon_Mini" [virtualboy]="Nintendo_-_Virtual_Boy" [gb]="Nintendo_-_Game_Boy" [gbc]="Nintendo_-_Game_Boy_Color" [gba]="Nintendo_-_Game_Boy_Advance" [nds]="Nintendo_-_Nintendo_DS" [3ds]="Nintendo_-_Nintendo_3DS" [wiiu]="Nintendo_-_Wii_U" [sg1000]="Sega_-_SG-1000" [mastersystem]="Sega_-_Master_System_-_Mark_III" [megadrive]="Sega_-_Mega_Drive_-_Genesis" [msu-md]="Sega_-_Mega_Drive_-_Genesis" [pico]="Sega_-_PICO" [sega32x]="Sega_-_32X" [megacd]="Sega_-_Mega-CD_-_Sega_CD" [saturn]="Sega_-_Saturn" [dreamcast]="Sega_-_Dreamcast" [gamegear]="Sega_-_Game_Gear" [psx]="Sony_-_PlayStation" [ps2]="Sony_-_PlayStation_2" [psp]="Sony_-_PlayStation_Portable" [pcengine]="NEC_-_PC_Engine_-_TurboGrafx_16" [pcenginecd]="NEC_-_PC_Engine_CD_-_TurboGrafx-CD" [supergrafx]="NEC_-_PC_Engine_SuperGrafx" [pcfx]="NEC_-_PC-FX" [cdi]="Philips_-_CD-i" [3do]="The_3DO_Company_-_3DO" [dos]="DOS" [msx1]="Microsoft_-_MSX" [msx2]="Microsoft_-_MSX2" [msx2+]="Microsoft_-_MSX2" [msxturbor]="Microsoft_-_MSX2" [pet]="Commodore_-_PET" [cplus4]="Commodore_-_Plus-4" [c20]="Commodore_-_VIC-20" [c64]="Commodore_-_64" [c128]="Commodore_-_128" [amiga500]="Commodore_-_Amiga" [amiga1200]="Commodore_-_Amiga" [amigacd32]="Commodore_-_CD32" [amigacdtv]="Commodore_-_CDTV" [pc88]="NEC_-_PC-8001_-_PC-8801" [pc98]="NEC_-_PC-98" [x1]="Sharp_-_X1" [x68000]="Sharp_-_X68000" [mame]="MAME" [fbneo]="MAME" [model2]="MAME" [model3]="MAME" [neogeocd]="SNK_-_Neo_Geo_CD" [ngp]="SNK_-_Neo_Geo_Pocket" [ngpc]="SNK_-_Neo_Geo_Pocket_Color" [arduboy]="Arduboy_Inc_-_Arduboy" [megaduck]="Welback_-_Mega_Duck" [gamate]="Bitcorp_-_Gamate" [gmaster]="Hartung_-_Game_Master" [gamecom]="Tiger_-_Game.com" [gp32]="GamePark_-_GP32" [amstradcpc]="Amstrad_-_CPC" [gx4000]="Amstrad_-_GX4000" [zx81]="Sinclair_-_ZX_81" [zxspectrum]="Sinclair_-_ZX_Spectrum" [spectravideo]="Spectravideo_-_SVI-318_-_SVI-328" [samcoupe]="MGT_-_Sam_Coupe" [oricatmos]="Tangerine_-_Oric_Atmos" [camplynx]="Camputers_-_Lynx" [astrocde]="Bally_-_Astrocade" [apfm1000]="APF_-_MP-1000" [advision]="Entex_-_Adventure_Vision" [crvision]="VTech_-_CreatiVision" [vsmile]="VTech_-_V.Smile" [arcadia]="Emerson_-_Arcadia_2001" [pv1000]="Casio_-_PV-1000" [supracan]="Funtech_-_Super_Acan" [vc4000]="Interton_-_VC_4000" [multivision]="Othello_-_Multivision" [adam]="Coleco_-_Adam" [coco]="Tandy_-_TRS-80_Color_Computer" [vis]="Tandy_-_Video_Information_System" [atom]="Acorn_-_Atom" [bbc]="Acorn_-_BBC" [electron]="Acorn_-_Electron" [archimedes]="Acorn_-_Archimedes" [fm7]="Fujitsu_-_Micro_7" [fmtowns]="Fujitsu_-_FM_Towns" [tutor]="Tomy_-_Tutor" )

PLATFORM_KEY=$(echo "$SYSTEM" | tr '[:upper:]' '[:lower:]' | tr -d ' -')
REPO_NAME="${PLATFORM_MAP[$PLATFORM_KEY]}"
[ -z "$REPO_NAME" ] && REPO_NAME="$SYSTEM"

DIR_NAME="${REPO_NAME//_/ }"
DIR="$HOME/../thumbs/$DIR_NAME/Named_Snaps"
mkdir -p "$DIR"

BASENAME=$(basename "$GAMENAME")
BASENAME="${BASENAME%.*}"

if [[ "$BASENAME" == *")"* ]]; then FILENAME="${BASENAME%%)*})"; else FILENAME="$BASENAME"; fi

FULLPATH="$DIR/$FILENAME.png"
if [ -f "$FULLPATH" ]; then exit 0; fi

ENCODED_NAME="${FILENAME// /%20}"
ENCODED_NAME="${ENCODED_NAME//#/%23}"

URL="https://raw.githubusercontent.com/WizzardSK/$REPO_NAME/refs/heads/master/Named_Snaps/$ENCODED_NAME.png"
curl -s -L -f "$URL" -o "$FULLPATH"
