#!/bin/bash
params="--no-checksum --no-modtime --attr-timeout 100h --dir-cache-time 100h --poll-interval 100h --vfs-cache-mode full --allow-non-empty --daemon"

sleep 30

./rclone mount "myrient:No-Intro/Atari - 2600" /userdata/roms/atari2600/online $params
./rclone mount "myrient:No-Intro/Atari - 5200" /userdata/roms/atari5200/online $params
./rclone mount "myrient:No-Intro/Atari - 7800" /userdata/roms/atari7800/online $params
./rclone mount "myrient:No-Intro/Atari - Jaguar (J64)" /userdata/roms/jaguar/online $params

curl http://127.0.0.1:1234/reloadgames
