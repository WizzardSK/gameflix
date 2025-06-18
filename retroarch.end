esac

if [ -n "$ext" ]; then
  umount -l ~/iso
  mount-zip "$1" ~/iso
  rom=$(find ~/iso -type f -name "*.${ext}" | head -n 1)
else
  rom="$1"
fi

if [[ "$core" == *"mame"* ]]; then
  filename="${rom##*/}"
  basename="${filename%.*}"
  ${core} "${rom}" -skip_gameinfo -snapname "${basename}"
  exit
fi

if [[ "$core" == *"libretro"* ]]; then
  retroarch -L ~/.config/retroarch/cores/${core}.so "${rom}"
else
  ${core} "${rom}"
fi

if [ -z "$core" ]; then
  ark "$1"
fi
