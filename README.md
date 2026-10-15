# OrangeDots

Personal Arch Linux/Hyprland dotfiles with a vendored Quickshell shell (fork of [Caelestia](https://github.com/caelestia-dots/shell)). The clone includes the shell source and first-install settings; system packages, native QML modules, wallpapers, secrets, and some runtime state must be installed or restored separately.

<!-- TODO: add screenshots here -->
<!-- ![desktop](.assets/screenshot.png) -->

## Components

| Path | What it is |
|---|---|
| `hypr/hyprland.lua` | Main Hyprland config (Lua-based) |
| `hypr/scheme/current.lua` | Active Material 3 colour scheme |
| `hypr/spotify-toggle.sh` | Spotify scratchpad toggle |
| `caelestia/` | First-install `shell.json` and `shell-tokens.json` presets |
| `quickshell/caelestia/` | Custom Quickshell shell (vendored OrangeShell fork) |

## Features

- Quickshell-powered bar, dashboard, launcher, lock screen and notification system (Caelestia base)
- Lua-driven Hyprland configuration
- Material 3 colour schemes

## Recreate the setup (Arch Linux)

### 1. Install the system dependencies

Install `hyprland`, `quickshell-git`, `caelestia-cli`, and the dependencies in the [vendored shell's manual-install list](quickshell/caelestia/README.md#manual-installation). For its native modules you also need `base-devel`, `cmake`, `ninja`, `pkgconf`, `qt6-base`, `qt6-declarative`, `qt6-shadertools`, `libqalculate`, `pipewire`, `aubio`, `cava`/`libcava`, and `lm_sensors`. The M3Shapes module is fetched by CMake during the build, so network access is needed.

For the configured shortcuts and autostart, install the apps you use from `hypr/hyprland.lua`: `kitty`, `thunar`, `code`, `helium-browser`, `spotify-launcher`, `spotify`, `gnome-keyring`, `kdeconnect`, `wl-clipboard`, `cliphist`, `playerctl`, `brightnessctl`, `blueman`, `pavucontrol`, `networkmanager` (`nmtui`), and `libnotify` (`notify-send`). Some are AUR or third-party packages; adapt app commands in the Lua config if yours differ. The shell also uses the Caelestia fonts (`material-symbols-rounded-font-git`, `ttf-google-sans-git`, and the fonts listed in its README). Wallpapers and locking are handled by the shell; there is no hyprpaper/hypridle setup here.

The config uses the [ScrollOverview](https://github.com/yayuuu/hyprland-scroll-overview) Hyprland plugin for its overview binds and gesture. Install it for your Hyprland version:

```bash
hyprpm add https://github.com/yayuuu/hyprland-scroll-overview.git
hyprpm update
hyprpm enable scrolloverview
```

The Lua autostart runs `hyprpm reload -n` when Hyprland starts. If installing the plugin in an existing session, run `hyprpm reload` then. Hypr3D and HyprGlass have optional guarded configuration in `hypr/hyprland.lua`; install those separately if you use their effects. Rebuild Hyprland plugins after Hyprland upgrades.

### 2. Clone and link the configs

```bash
git clone https://github.com/srivastava-ayush/OrangeDots.git
cd OrangeDots

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
mkdir -p "$config_home"
ln -s "$PWD/hypr" "$config_home/hypr"
ln -s "$PWD/quickshell" "$config_home/quickshell"

# Only seed files that do not already exist; later Nexus edits stay local.
mkdir -p "$config_home/caelestia"
cp -n caelestia/shell.json caelestia/shell-tokens.json "$config_home/caelestia/"
```

Move any existing `hypr` or `quickshell` config out of the way before creating the links. Keep the clone in place; the links point into it. The Lua config is `hypr/hyprland.lua`, not classic `.conf` syntax.

### 3. Build the vendored native shell modules

The shell's QML is read directly from the linked repo, but `Caelestia` and `M3Shapes` imports require native modules. Build **this fork**, not an upstream shell package. This repo has no Git version tag, so pass an explicit CMake version:

```bash
cd quickshell/caelestia
cmake -S . -B build -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/usr \
  '-DENABLE_MODULES=extras;plugin;m3shapes' \
  -DVERSION=1.0.0
cmake --build build
sudo cmake --install build
```

This installs native files under `/usr/lib/caelestia` and `/usr/lib/qt6/qml`, without installing a second copy of the QML config. Repeat the build/install after changing `quickshell/caelestia/plugin/` or upgrading Qt. If you use a different install prefix, set `CAELESTIA_LIB_DIR` to the corresponding Caelestia library directory.

### 4. Restore your personal data and machine-specific settings

The committed `caelestia/shell*.json` files are **presets**, not a continuously synced copy of Nexus changes. On the old machine, back up the current `$HOME/.config/caelestia/shell.json` and `shell-tokens.json` (and any `monitors/<output>/` overrides) outside this repo if you want the latest values. Use `$XDG_CONFIG_HOME/caelestia` instead if set. Copy them over the seeded files on the new machine before starting the shell. To update the committed presets intentionally, copy the two live JSON files into `caelestia/` and review the diff.

Also restore or recreate these separately:

- **Wallpaper files:** copy your images to the new machine (the default wallpaper directory is `~/Pictures/Wallpapers`). Select the desired image with `caelestia wallpaper -f /path/to/image`; the current selection is stored in `~/.local/state/caelestia/wallpaper/path.txt`, which contains an absolute path. The wallpaper image is not in this repo.
- **Colour scheme:** `hypr/scheme/current.lua` is tracked, but OrangeShell reads `~/.local/state/caelestia/scheme.json`. Recreate the scheme using Caelestia's scheme/wallpaper commands, or restore a backed-up `scheme.json` if you need the same palette immediately. The two palettes should match. Use `$XDG_STATE_HOME/caelestia` instead of `~/.local/state/caelestia` if set.
- **Google Calendar:** put your private iCal URL on a single line in `~/.config/caelestia/calendar-url` (or `$XDG_CONFIG_HOME/caelestia/calendar-url`) on the new machine. It is not committed. The calendar/notes panel otherwise shows an empty agenda.
- **Notes:** the calendar/notes panel uses Quickshell `PersistentProperties` for shell reloads, not a repo-backed notes file; save any text you need elsewhere before reinstalling.
- **Other local services:** the optional `~/bin/power-watcher.sh`, `~/bin/refresh-rate.sh`, and `power-watcher.service` are not in the repo. Recreate those separately if you want automatic AC/battery refresh-rate changes.

### 5. Adapt the hardware paths and start

See [Machine-specific values](#machine-specific-values) below. In particular, edit the refresh-rate keybind and the `eDP-1`/144 Hz monitor assumptions for your display. Then start Hyprland. Its `hyprland.start` handler launches `caelestia shell -d`; to restart an already-running shell after edits, use `caelestia shell -r`. You can open Nexus with `SUPER+X`.

## Machine-specific values

| Location | Current value | Change on another machine |
|---|---|---|
| `hypr/hyprland.lua` (`SUPER+R`) | `/home/ayush/OrangeDots/refresh-rate-toggle.sh` | The script **is included** at the repo root. Only this absolute path needs changing if the clone is under a different user or directory. This is the **only executable `/home/ayush` path in the tracked configuration**. |
| `hypr/hyprland.lua` monitor rule | `1920x1080@144` | Use a mode supported by the new display. |
| `refresh-rate-toggle.sh` | `eDP-1`, `1920x1080@60`, `1920x1080@144`, position `0x0` | Set the monitor name, modes, and position for your hardware. |
| `hypr/hyprland.lua` app commands | `code`, `helium-browser`, `spotify-launcher`, etc. | Install these or change the commands. |
| `hypr/hyprland.lua` HyprGlass state | `/tmp/hyprglass-state` | Temporary toggle state, not a home-directory path or persistent backup. |

The live (untracked) wallpaper selection currently points to `/home/ayush/Pictures/Wallpapers/blades-out.png`; reselect a copied image on the new machine instead of copying that absolute path unchanged. Config paths such as `~/.config/hypr/spotify-toggle.sh` follow the symlinked home directory and are **not** hardcoded to `ayush`.

## Notes

- The shell under `quickshell/caelestia/` retains its GPL-3.0 license; top-level dotfiles are unrestricted.

## License

My dotfiles: do whatever you want. The vendored shell keeps its original GPL-3.0 license.
