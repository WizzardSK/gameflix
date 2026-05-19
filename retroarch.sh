#!/bin/bash
# Strip play:// URL scheme + URL-decode. New gameflix HTML emits a relative
# path like /atari2600/NoIntro/foo.zip which we resolve under ~/share/roms;
# old HTML with the full absolute path is detected via existence and used
# as-is.
arg="$1"
[[ "$arg" == play://* ]] && arg="${arg#play://}"
arg=$(printf '%b' "${arg//%/\\x}")
[[ -e "$arg" ]] || arg="$HOME/share/roms$arg"
set -- "$arg" "${@:2}"
head "$1"
adresar=$(dirname "$1")
adresar2="${adresar##*/}"
case "$adresar/" in
