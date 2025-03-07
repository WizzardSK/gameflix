# gameflix
![obrázok](https://github.com/user-attachments/assets/c90a7c26-1828-481c-a236-f56d0b19f936)

Demo: https://wizzardsk.github.io/

Project for running retro games directly from public online sources on Linux machines.

I made this project for my own personal needs, to have the same setup on all my machines.

All games are stored on public services Myrient and others. Thumbnails are downloaded from github repositories. 

Why is it better than to have all games on local storage? You may have the access to all your games without the need to have a huge storage. Some PSX, PS2, GameCube or Dreamcast games may be very large and using this script you may run them on a Chromebook with small storage (if it may run those emulators). The disadvantage is that you need fast internet connection and even with that the loading of bigger games may be quite slow.

If you need ARM64 libretro cores, try here: https://github.com/christianhaitian/retroarch-cores

For BIOS, check this page: https://github.com/PIBSAS

## Web version
`rclone` binary is needed on host system (version 1.60+). Also it is needed to have rclone configured for all the remotes. Attached [rclone.conf](/.config/rclone/rclone.conf) should be placed in `~/.config/rclone/` If your version is not up to date, grab it from here: https://rclone.org/downloads/

Run [mount.sh](mount.sh) or `webflix.sh` or `bash <(curl -Ls https://raw.githubusercontent.com/WizzardSK/gameflix/main/webflix.sh)` to mount the library.

The library is mounted into `roms` folder in your home directory. If roms directories do not exist, they are automatically created.

Then use the library with any emulation system like Retroarch. It is up to you how you configure the emulators. I am using my web version on Linux on my arm Chromebook.

Now you may run the roms directly without copying them to local storage, just like Netflix. 

You also need fuse-zip program to use TOSEC libraries. They are stored in zipped files, which are downloaded and mounted like folders. Mount-zip is used to run zipped ISO files for PSP, PS2, PC Engine CD and other.

[mount.sh](mount.sh) mounts the library. 

Then run [gen.sh](gen.sh) to generate or update games collection. The script generates a `gameflix` folder in your home directory which is automatically opened in default browser. Firefox is recommended. The game is launched after clicking on the thumbnail. It is necessary to associate the zip files and other rom files with `retroarch.sh` script, which is also downloaded into home directory. It automatically launches RetroArch with correct core or standalone emulator. You may edit that file according to your needs. Web page contains links to all the platforms supported with all the games available. It is not necessary to run it all the time, because it takes time, about 30 minutes on my Chromebook.

## Usage - Batocera Linux
For Batocera, you need to copy [custom.sh](batocera/share/system/custom.sh) file to your system folder in shared drive. It will launch automatically at system boot. It should also install rclone config file in system folder. Thumbnail folders are mounting too.

AMD64 version also supports zipped libraries for Atari 800, Amstrad CPC, ZX Spectrum and a lot of others.

## Usage - Recalbox (unmaintained)
For Recalbox, you need to copy [custom.sh](recalbox/share/system/custom.sh) file to your system folder in shared drive. It will launch automatically at system boot. It should also install rclone config file in system folder. Thumbnail folders are mounting too.

Raspberry Pi 4 version also supports zipped libraries for Atari 800, Amstrad CPC and ZX Spectrum.

Recalbox version is no longer maintained cause I do not use it anymore and don't have time to maintain it now.
