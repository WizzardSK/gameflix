#!/bin/bash
sleep 5
now=1980
while (( $now < 2020 )); do
    sleep 1
    now=$(date '+%Y')
done

if [ $1 == "start" ]
then 
	curl -s -L https://raw.githubusercontent.com/WizzardSK/gameflix/main/batocera.sh | bash
fi
