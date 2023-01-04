# gameflix

Project for running games directly from public online sources.

Only for testing purposes.

You must own all the games that you are running using this script.

Rclone binary is needed on host system (version 1.60+).

Also it is needed to have rclone configured for all the remotes.

Attached `rclone.conf` should be placed in `~/.config/rclone/` with Archive S3 keys added from https://archive.org/account/s3.php

If your version is not up to date, grab it from here: https://rclone.org/downloads/

## Usage
Run `mount.sh` or `roms.sh` or `bash <(curl -Ls https://raw.githubusercontent.com/WizzardSK/gameflix/main/roms.sh)` to mount the library.

The library is mounted into 'roms' folder in your home directory.

Then use the library with any emulation system. I am using https://es-de.org/ on Linux on my arm Chromebook.

Run `unmount.sh` or `unroms.sh` or `bash <(curl -Ls https://raw.githubusercontent.com/WizzardSK/gameflix/main/unroms.sh)` to unmount the library.
