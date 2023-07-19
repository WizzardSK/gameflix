# gameflix

Project for running retro games directly from public online sources on Linux machines.

I made this project for my own personal needs, to have the same setup on all my machines.

All games are stored on public services Internet Archive and Myrient. Thumbnails are used from https://thumbnails.libretro.com/ configured to use with ES-DE frontend. 

Why is it better than to have all games on local storage? You may have the access to all your games without the need to have a huge storage. Some PSX, PS2, GameCube or Dreamcast games may be very large and using this script you may run them on a Chromebook with small storage (if it may run those emulators). The disadvantage is that you need fast internet connection and even with that the loading of bigger games may be quite slow.

For BIOS, check this page: https://github.com/Luciano2018

| Platform     | Location | Type      | Thumbs |
| ------------ | -------- | --------- | ------ |
| Atari 2600   | myrient  | No-Intro  | [libretro](http://thumbnails.libretro.com/Atari%20-%202600/Named_Snaps)
| Atari 5200   | myrient  | No-Intro  | [libretro](http://thumbnails.libretro.com/Atari%20-%205200/Named_Snaps)
| Atari 7800   | myrient  | No-Intro  | [libretro](http://thumbnails.libretro.com/Atari%20-%207800/Named_Snaps)
| Atari Lynx   | myrient  | No-Intro  | [libretro](http://thumbnails.libretro.com/Atari%20-%20Lynx/Named_Snaps)
| Atari Jaguar | myrient  | No-Intro  | [libretro](http://thumbnails.libretro.com/Atari%20-%20Jaguar/Named_Snaps)
| Atari ST     | myrient  | No-Intro  | [libretro](http://thumbnails.libretro.com/Atari%20-%20ST/Named_Snaps)
| Atari 8-bit  | myrient  | TOSEC zip | [libretro](http://thumbnails.libretro.com/Atari%20-%208-bit/Named_Snaps)
| Amstrad CPC  | myrient  | TOSEC zip | [libretro](http://thumbnails.libretro.com/Amstrad%20-%20CPC/Named_Snaps)
| ZX Spectrum  | myrient  | TOSEC zip | [libretro](http://thumbnails.libretro.com/Sinclair%20-%20ZX%20Spectrum/Named_Snaps)
| Commodore 64 | myrient  | No-Intro  |
| Amiga        | myrient  | No-Intro  |
| Intellivision| myrient  | No-Intro  |
| Colecovision | myrient  | No-Intro  |
| NES          | myrient  | No-Intro  |
| SNES         | myrient  | No-Intro  |
| Nintendo 64  | myrient  | No-Intro  |
| GameCube     | myrient  | Redump    |
| Wii          | myrient  | Redump    |
| SG-1000      | myrient  | No-Intro  |
| Master System| myrient  | No-Intro  |
| Game Gear    | myrient  | No-Intro  |
| Mega Drive   | myrient  | No-Intro  |
| Sega 32X     | myrient  | No-Intro  |
| Sega CD      | myrient  | Redump    |
| Saturn       | myrient  | Redump    |
| Dreamcast    | myrient  | Redump    |
| PlayStation  | myrient  | Redump    |
| PlayStation 2| myrient  | Redump    |
| PlayStation 3| myrient  | Redump    |
| PC Engine    | myrient  | No-Intro  |
| PC Engine CD | myrient  | Redump    |
| DOS          | archive  | eXoDOS    |

## Usage - EmulationStation DE
`rclone` binary is needed on host system (version 1.60+). Also it is needed to have rclone configured for all the remotes. Attached [rclone.conf](/.config/rclone/rclone.conf) should be placed in `~/.config/rclone/` with Archive S3 keys added from https://archive.org/account/s3.php If your version is not up to date, grab it from here: https://rclone.org/downloads/

[es_systems.xml](.emulationstation/custom_systems/es_systems.xml) is used to configure roms directories for your emulators and alternative emulators for ES-DE frontend. It is updated automatically from this repository when running mount script.

Run [mount.sh](mount.sh) or `emulationstation.sh` or `bash <(curl -Ls https://raw.githubusercontent.com/WizzardSK/gameflix/main/emulationstation.sh)` to mount the library.

The library is mounted into `roms` folder in your home directory. If roms directories do not exist, they are automatically created.

Then use the library with any emulation system like Retroarch. It is up to you how you configure the emulators. I am using https://es-de.org/ on Linux on my arm Chromebook, what is basically EmulationStation Desktop Edition suitable for desktop computers, including arm.

Now you may run the roms directly without copying them to local storage, just like Netflix. 

You also need `mount-zip` program to use Amstrad CPC, ZX Spectrum and Atari 800 games. They are stored in zipped libraries on remote place so the program needs to mount it like folder. It is also used to run zipped ISO files for PSP, PS2, PC Engine CD.

## Usage - Batocera Linux
For Batocera, you need to copy [custom.sh](batocera/share/system/custom.sh) file to your system folder in shared drive. It will launch automatically at system boot. It should also install rclone config file in ./config/rclone folder in system folder. Thumbnail folders are mounting too.

To show the game thumbnails, it is necessary to enable "Search for local art" option in Advanced Settings - Developer Options. Also, I also recommend enabling preloading options in the same menu, it greatly improves the performance when opening the system for the first time.

AMD64 version also supports zipped libraries for Atari 800, Amstrad CPC and ZX Spectrum.

## Usage - Recalbox
For Recalbox, you need to copy [custom.sh](recalbox/share/system/custom.sh) file to your system folder in shared drive. It will launch automatically at system boot. It should also install rclone config file in ./config/rclone folder in system folder. Thumbnail folders are mounting too.

Raspberry Pi 4 version also supports zipped libraries for Atari 800, Amstrad CPC and ZX Spectrum.
