#!/bin/sh
# Copies .config/hypr and .config/quickshell into ~/.config, keeping a timestamped backup of existing ones.
set -e
here=$(cd "$(dirname "$0")" && pwd)
stamp=$(date +%Y%m%d-%H%M%S)
for d in hypr quickshell; do
  dest="$HOME/.config/$d"
  if [ -e "$dest" ]; then
    mv "$dest" "$dest.bak-$stamp"
    echo "backed up $dest -> $dest.bak-$stamp"
  fi
  cp -a "$here/.config/$d" "$dest"
  echo "installed $dest"
done
mkdir -p "$HOME/.local/state/quickshell-island"   # settings, clipboard history and launcher history live here
echo "Now create ~/.config/quickshell/island/scripts/discord_rpc.json if you want the Discord widget (see README)."
