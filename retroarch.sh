#!/bin/bash
arg="$1"
[[ "$arg" == play://* ]] && arg="${arg#play://}"
arg=$(printf '%b' "${arg//%/\\x}")
[[ -e "$arg" ]] || arg="$HOME/share/roms$arg"
set -- "$arg" "${@:2}"
head "$1"
adresar=$(dirname "$1")
adresar2="${adresar##*/}"
case "$adresar/" in
