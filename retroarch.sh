#!/bin/bash
arg="$1"
[[ "$arg" == play://* ]] && arg="${arg#play://}"
arg=$(printf '%b' "${arg//%/\\x}")
[[ -e "$arg" ]] || arg="$HOME/share/roms$arg"
set -- "$arg" "${@:2}"
head "$1" > /dev/null 2>&1  # wakes a mounted archive; the bytes are not wanted
adresar=$(dirname "$1")
adresar2="${adresar##*/}"
case "$adresar/" in
