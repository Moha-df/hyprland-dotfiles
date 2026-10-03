#!/bin/bash
STATE_FILE="/tmp/keyboard_layout_state"

# init si fichier existe pas
if [ ! -f "$STATE_FILE" ]; then
  echo "US" >"$STATE_FILE"
fi

current=$(cat "$STATE_FILE" 2>/dev/null)

if [ "$current" == "US" ]; then
  echo "FR" >"$STATE_FILE"
  paplay /usr/share/sounds/bip.mp3 & # son FR
else
  echo "US" >"$STATE_FILE"
  paplay /usr/share/sounds/bip1.mp3 & # son US
fi

# envoie le signal à Waybar pour refresh instantané
pkill -RTMIN+8 waybar
