# gameflix

Project for running games directly from public online sources on Linux machines.

Only for testing purposes. I made this project mostly for my own personal needs, to have the same setup on all my machines.

You must own all the games that you are running using this script.

`rclone` binary is needed on host system (version 1.60+).

Also it is needed to have rclone configured for all the remotes.

Attached `rclone.conf` should be placed in `~/.config/rclone/` with Archive S3 keys added from https://archive.org/account/s3.php

If your version is not up to date, grab it from here: https://rclone.org/downloads/

All games are stored on public services like Internet Archive and Myrient. Thumbnails are used from https://thumbnails.libretro.com/ configured to use with ES-DE frontend.

`es_systems.xml` is used to configure roms directories for your emulators and alternative emulators for ES-DE frontend.

Why is it better than to have all games on local storage? You may have the access to all your games without the need to have a huge storage. Some PSX, PS2, GameCube or Dreamcast games may be very large and using this script you may run them on a Chromebook with small storage (if it may run those emulators). The disadvantage is that you need fast internet connection and even with that the loading of bigger games may be quite slow.

## Usage
Run `mount.sh` or `roms.sh` or `bash <(curl -Ls https://raw.githubusercontent.com/WizzardSK/gameflix/main/roms.sh)` to mount the library.

The library is mounted into `roms` folder in your home directory. If roms directories do not exist, they are automatically created.

Then use the library with any emulation system like Retroarch. It is up to you how you configure the emulators. I am using https://es-de.org/ on Linux on my arm Chromebook, what is basically EmulationStation Desktop Edition suitable for desktop computers, including arm.

Now you may run the roms directly without copying them to local storage, just like Netflix. Again, you should not play the game if you do not own it, you may just try it.

Run `unmount.sh` or `unroms.sh` or `bash <(curl -Ls https://raw.githubusercontent.com/WizzardSK/gameflix/main/unroms.sh)` to unmount the library or it is unmounted after restart.
