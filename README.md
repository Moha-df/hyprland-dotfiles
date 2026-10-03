# Hyprland + Quickshell "island" setup

My Hyprland config and a custom Quickshell bar (a floating pill that grows into a clock, calendar,
wallpaper picker, app/file launcher, clipboard history, per-app mixer, notifications and a control center).

```
.config/hypr/               Hyprland config, scripts
.config/quickshell/island/  the bar (QML)
```

## Install (Arch)

```sh
sudo pacman -S --needed hyprland quickshell jq fd grim slurp wf-recorder wl-clipboard libpulse \
    gammastep nemo imagemagick curl playerctl python ttf-0xproto-nerd ttf-opensans
yay -S awww mpvpaper          # wallpaper daemon / live wallpapers
./install.sh                  # copies the config into ~/.config (backs up what is already there)
```

Optional: `ydotool` (only for testing), `pavucontrol`, `nm-connection-editor`.

The Quickshell config is started from `hyprland.conf`:

```
exec-once = qs -p ~/.config/quickshell/island
```

## Keybinds

| Keys | Action |
| --- | --- |
| Super+R / Super+A | app + file launcher (Ctrl+2 = files) |
| Super+W | wallpaper picker |
| Super+N | control center |
| Super+T | clock / calendar |
| Super+X | mixer (volume per app) |
| Super+Shift+V | clipboard history |
| Super+B | show / hide the bar (hidden by default) |

IPC: `qs -p ~/.config/quickshell/island ipc show`

## Discord widget (optional)

The voice controls use Discord's local RPC. Create an application at
<https://discord.com/developers/applications>, add `http://localhost` as an OAuth2 redirect, add your account
as an App Tester, then:

```sh
cd ~/.config/quickshell/island/scripts
cp discord_rpc.json.example discord_rpc.json   # and fill in client_id / client_secret
```

`discord_rpc.json` is git-ignored, never commit it.

## Notes

- Monitor names (`DP-3`, `HDMI-A-1`) and the wallpaper folder (`~/Pictures/wallpapers`) are specific to my machine:
  edit `hyprland.conf` and the Appearance panel / `settings.json`.
- Big wallpapers (gif / mp4 / webm) are not in the repo.
