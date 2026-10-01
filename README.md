# OrangeDots

Personal Hyprland dotfiles with a custom Quickshell shell (fork of [Caelestia](https://github.com/caelestia-dots/shell)), themed orange/dark.

Fully self-contained - one `git clone` gets you everything, shell included.

<!-- TODO: add screenshots here -->
<!-- ![desktop](.assets/screenshot.png) -->

## Components

| Path | What it is |
|---|---|
| `hypr/hyprland.lua` | Main Hyprland config (Lua-based) |
| `hypr/scheme/current.lua` | Active Material 3 colour scheme |
| `hypr/spotify-toggle.sh` | Spotify scratchpad toggle |
| `quickshell/caelestia/` | Custom Quickshell shell (vendored OrangeShell fork) |

## Features

- Quickshell-powered bar, dashboard, launcher, lock screen and notification system (Caelestia base)
- Lua-driven Hyprland configuration
- Material 3 colour schemes

## Dependencies

Arch package names:

```
hyprland quickshell-git cava kitty thunar
```

Note: no `hyprpaper`/`hypridle`/`swww` needed — wallpapers and the lock screen are handled by the Caelestia shell.

Plus the [Caelestia shell requirements](https://github.com/caelestia-dots/shell#dependencies):

```
caelestia-cli fish material-symbols-rounded-font-git ttf-google-sans-git
```

## Install

```bash
git clone https://github.com/srivastava-ayush/OrangeDots.git
cd OrangeDots

# copy or link configs into ~/.config
mkdir -p ~/.config
ln -s "$PWD/hypr"      ~/.config/hypr
ln -s "$PWD/quickshell" ~/.config/quickshell
```

Then start Hyprland - `caelestia shell -d` launches automatically.

## Notes

- Everything is configured in `hypr/hyprland.lua` (Lua, not `.conf` syntax)
- The shell under `quickshell/caelestia/` is GPL-3.0 licensed (see its `LICENSE`); my modifications are in-repo

## License

My dotfiles: do whatever you want. The vendored shell keeps its original GPL-3.0 license.
