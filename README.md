# gameflix
Discord: https://discord.gg/aJsVfUr6CA

Project for running retro games directly from public online sources on Linux machines.

I made this project for my own personal needs, to have the same setup on all my machines.

All games are stored on public services Myrient and The Eye. Thumbnails are used from https://thumbnails.libretro.com/ configured to use with some frontend. 

Why is it better than to have all games on local storage? You may have the access to all your games without the need to have a huge storage. Some PSX, PS2, GameCube or Dreamcast games may be very large and using this script you may run them on a Chromebook with small storage (if it may run those emulators). The disadvantage is that you need fast internet connection and even with that the loading of bigger games may be quite slow.

If you need ARM64 libretro cores, try here: https://github.com/christianhaitian/retroarch-cores

For BIOS, check this page: https://github.com/Luciano2018

## Web version
`rclone` binary is needed on host system (version 1.60+). Also it is needed to have rclone configured for all the remotes. Attached [rclone.conf](/.config/rclone/rclone.conf) should be placed in `~/.config/rclone/` If your version is not up to date, grab it from here: https://rclone.org/downloads/

Run [mount.sh](mount.sh) or `webflix.sh` or `bash <(curl -Ls https://raw.githubusercontent.com/WizzardSK/gameflix/main/webflix.sh)` to mount the library.

The library is mounted into `roms` folder in your home directory. If roms directories do not exist, they are automatically created.

Then use the library with any emulation system like Retroarch. It is up to you how you configure the emulators. I am using my web version on Linux on my arm Chromebook.

Now you may run the roms directly without copying them to local storage, just like Netflix. 

You also need [mount-zip](https://github.com/google/mount-zip) program to use Amstrad CPC, ZX Spectrum and Atari 800 games. They are stored in zipped libraries on remote place so the program needs to mount it like folder. It is also used to run zipped ISO files for PSP, PS2, PC Engine CD.

[mount.sh](mount.sh) script generates a `gameflix.html` web page in your home directory which is automatically opened in default browser. Firefox is recommended. Web page contains links to all the platforms supported with all the games available. The game is launched after clicking on the thumbnail. It is necessary to associate the zip files and other rom files with `retroarch.sh` script, which is also downloaded into home directory. It automatically launches RetroArch with correct core or standalone emulator. You may edit that file according to your needs.

Then run [gen.sh](gen.sh) to generate or update games collection. It is not necessary to run it all the time, because it takes time, about 30 minutes on my Chromebook.

## Usage - Batocera Linux
For Batocera, you need to copy [custom.sh](batocera/share/system/custom.sh) file to your system folder in shared drive. It will launch automatically at system boot. It should also install rclone config file in ./config/rclone folder in system folder. Thumbnail folders are mounting too.

To show the game thumbnails, it is necessary to enable "Search for local art" option in Advanced Settings - Developer Options. Also, I also recommend enabling preloading options in the same menu, it greatly improves the performance when opening the system for the first time.

AMD64 version also supports zipped libraries for Atari 800, Amstrad CPC and ZX Spectrum.

## Usage - Recalbox
For Recalbox, you need to copy [custom.sh](recalbox/share/system/custom.sh) file to your system folder in shared drive. It will launch automatically at system boot. It should also install rclone config file in ./config/rclone folder in system folder. Thumbnail folders are mounting too.

Raspberry Pi 4 version also supports zipped libraries for Atari 800, Amstrad CPC and ZX Spectrum.
