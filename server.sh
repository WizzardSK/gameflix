#!/bin/bash
rclone mount myrient: ~/myrient --no-checksum --no-modtime --attr-timeout 1000h --dir-cache-time 1000h --poll-interval 1000h --allow-non-empty --daemon --no-check-certificate --allow-other

if [ ! -d "$HOME/share/thumbs/Uzebox" ]; then git clone --depth 1 "https://github.com/WizzardSK/Uzebox.git" "$HOME/share/thumbs/Uzebox" 2>&1 | tee -a "$HOME/git.log"; else
  git config --global --add safe.directory "$HOME/share/thumbs/Uzebox"
  git -C "$HOME/share/thumbs/Uzebox" config pull.rebase false 2>&1 | tee -a "$HOME/git.log"; git -C "$HOME/share/thumbs/Uzebox" pull 2>&1 | tee -a "$HOME/git.log"
fi

if [ ! -d "$HOME/share/thumbs/Vircon32" ]; then git clone --depth 1 "https://github.com/WizzardSK/Vircon32.git" "$HOME/share/thumbs/Vircon32" 2>&1 | tee -a "$HOME/git.log"; else
  git config --global --add safe.directory "$HOME/share/thumbs/Vircon32"
  git -C "$HOME/share/thumbs/Vircon32" config pull.rebase false 2>&1 | tee -a "$HOME/git.log"; git -C "$HOME/share/thumbs/Vircon32" pull 2>&1 | tee -a "$HOME/git.log"
fi

declare -A seen; mkdir -p "$HOME/share/thumbs"
IFS=$'\n' read -d '' -ra roms <<< "$(curl -s https://raw.githubusercontent.com/WizzardSK/gameflix/main/platforms.txt)"
IFS=";"; for each in "${roms[@]}"; do
  echo "${rom3}"; read -ra rom < <(printf '%s' "$each")
  if [[ -z "${seen[${rom[0]}]}" ]]; then
    seen[${rom[0]}]=1; rom2="${rom[2]// /_}"; echo "${rom[2]} thumbs" | tee -a "$HOME/git.log"
    if [ ! -d "$HOME/share/thumbs/${rom[2]}" ]; then git clone --depth 1 "https://github.com/WizzardSK/${rom2}.git" "$HOME/share/thumbs/${rom[2]}" 2>&1 | tee -a "$HOME/git.log"; else
      git config --global --add safe.directory $HOME/share/thumbs/${rom[2]}
      git -C "$HOME/share/thumbs/${rom[2]}" config pull.rebase false 2>&1 | tee -a "$HOME/git.log"
      git -C "$HOME/share/thumbs/${rom[2]}" pull 2>&1 | tee -a "$HOME/git.log"
      sleep 0.5
    fi
  fi  
done
