#!/bin/bash
# usage: rec.sh <file> <geometry|-> <audio device|->
mkdir -p "$(dirname "$1")"
args=(-r 60 -f "$1")
if [ "$2" != "-" ]; then
  args+=(-g "$2")
else
  # without -o wf-recorder asks which output to use on stdin and hangs with 2 monitors
  args+=(-o "$(hyprctl monitors -j | jq -r '[.[]|select(.focused)][0].name // .[0].name')")
fi
[ "$3" != "-" ] && args+=("--audio=$3")
exec wf-recorder "${args[@]}"
