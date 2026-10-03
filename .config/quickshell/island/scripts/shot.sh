#!/bin/sh
# usage: shot.sh display|window|area  -> prints saved path
dir="$HOME/Pictures/Screenshots"; mkdir -p "$dir"
f="$dir/shot_$(date +%Y-%m-%d_%H-%M-%S).png"
case "$1" in
  display) mon=$(hyprctl monitors -j | jq -r '.[]|select(.focused)|.name'); grim -o "$mon" "$f" ;;
  area) g=$(slurp) || exit 1; grim -g "$g" "$f" ;;
  window) g=$(hyprctl clients -j | jq -r '.[]|select(.mapped and (.hidden|not))|"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' | slurp -r) || exit 1; grim -g "$g" "$f" ;;
  *) exit 1 ;;
esac
wl-copy < "$f"
echo "$f"
