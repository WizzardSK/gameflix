#!/bin/bash
wget -nv https://github.com/WizzardSK/gameflix/raw/refs/heads/main/gameflix.zip
mkdir -p ~/gameflix
unzip -o gameflix.zip -d ~/gameflix/
rm gameflix.zip
