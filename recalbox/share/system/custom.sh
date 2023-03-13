#!/bin/bash

now=1980
while (( $now < 2020 )); do
    sleep 1
    now=$(date '+%Y')
done

curl -L -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/recalbox.sh | su -c bash
