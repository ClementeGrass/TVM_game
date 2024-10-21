#!/bin/sh
echo -ne '\033c\033]0;multiplayer_example\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/papaCaliente2.x86_64" "$@"
