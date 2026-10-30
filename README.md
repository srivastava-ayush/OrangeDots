# OrangeDots · Orange OS

Personal Arch Linux + Hyprland dotfiles with **Orange OS**, a customized [Caelestia](https://github.com/caelestia-dots/shell) Quickshell desktop shell. Nexus identifies this fork as **Orange OS — AYUSH_GOAT_V4**.

This is a desktop shell and dotfiles repository, **not an operating-system installer or an Arch ISO**. It includes the shell source, native-module source, assets, and first-install configuration presets. Install the system dependencies separately.

## Contents

- [Features](#features)
- [Before installing](#before-installing)
- [Installation: shell only](#installation-shell-only)
- [Optional: install the bundled Hyprland dotfiles](#optional-install-the-bundled-hyprland-dotfiles)
- [First-run customization](#first-run-customization)
- [Commands and shortcuts](#commands-and-shortcuts)
- [Configuration, backups, and migration](#configuration-backups-and-migration)
- [Updating](#updating)
- [Troubleshooting](#troubleshooting)
- [Development checks](#development-checks)
- [Repository layout](#repository-layout)
- [License](#license)

## Features

- Left-side or top taskbar, launcher, dashboard, lock screen, notifications, media controls, system tray, and Nexus settings.
- Selectable **Unified** (default), **Three notches**, or **Center notch** taskbar, with centered date/time and shell-attached backgrounds in either orientation.
- Notification bell inside the status-icon group, with a hover popout. In Left orientation, the shade is attached to the shell's inner bottom edge. New-notification banners remain separate from notification history.
- Material 3 wallpaper-derived colours, transparency, and a customizable global background tint.
- **VOID** tint preset: pure black at 100% tint strength. Transparency remains a separate setting.
- Dashboard weather, recording controls, utility cards, performance information, and optional phone integration.
- Recording captures at the display or selected region's native resolution with the `ultra` quality preset; `-s 0x0` prevents downscaling. Quality, codec, frame rate, tune, and cursor are configurable in **Services → Screen recorder**.
- Dashboard Calendar tab with notes and optional private Google Calendar iCal integration.
- Optional Lua-based Hyprland dotfiles, scratchpads, gestures, and overview-plugin integration.

See [FEATURES.md](FEATURES.md) for the detailed feature and source inventory. The installation instructions below take precedence over the inherited upstream README for installing **this fork**.

## Before installing

### Supported setup

- **Arch Linux**, a working **Hyprland Wayland session**, and a normal user account with `sudo` access.
- **Quickshell's git version** (`quickshell-git`), not just an older tagged release.
- **Qt 6.9 or newer** for the native modules, with Quickshell and the modules built against compatible Qt versions. The lock-screen frame-callback recovery currently supports **Qt 6.12 only**, with identical build/runtime versions; see [sleep/wake recovery](#lock-screen-rendering-after-sleep).
- Internet access for package installation, the CLI, and CMake's pinned M3Shapes download.

The current development machine uses Hyprland **0.56.2** and `quickshell-git`. Other distributions are not covered by this guide. The bundled Hyprland config uses the **Lua `hl.*` API**; do not paste it into an older classic `hyprland.conf` setup.

### Choose your installation scope

| Option | What changes |
|---|---|
| **Shell only — recommended first** | Installs Orange OS alongside your existing Hyprland configuration. You add autostart and shortcuts yourself. |
| **Full dotfiles** | Also replaces your Hyprland configuration with this repo's personal keybinds, app commands, monitor settings, rules, and gestures. Adapt those before activating it. |

> [!IMPORTANT]
> Keep a working terminal and a way to return to a TTY. Back up existing configuration before replacing it. Test password unlocking before relying on the shell's lock screen. Do not run Quickshell as root.

All shell command blocks below use **Bash**. Open `bash` first if your interactive shell is Fish. The examples use `~/OrangeDots`; adjust `repo` if you clone somewhere else.

## Installation: shell only

### 1. Install Arch packages

Update Arch normally first; avoid partial upgrades:

```bash
sudo pacman -Syu
```

Install the build dependencies and desktop tools:

```bash
sudo pacman -S --needed \
  git base-devel cmake ninja pkgconf \
  qt6-base qt6-declarative qt6-shadertools qt6-svg qt6-wayland \
  libqalculate libpipewire aubio cava lm_sensors \
  networkmanager bluez bluez-utils upower \
  brightnessctl ddcutil fish curl jq libnotify \
  wl-clipboard cliphist playerctl grim slurp swappy matugen \
  ttf-cascadia-code-nerd ttf-jetbrains-mono-nerd noto-fonts-emoji
```

If Hyprland is not installed yet, install it and establish a working session **before** installing the shell:

```bash
sudo pacman -S --needed hyprland xdg-desktop-portal-hyprland
```

Use a working PipeWire setup for audio controls. On a new installation, a typical stack is:

```bash
sudo pacman -S --needed pipewire pipewire-pulse wireplumber
```

Review package conflicts rather than blindly replacing an existing audio setup. After installing the stack, log out and back in, or start its user services:

```bash
systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service
```

### 2. Install the AUR dependencies and fonts

With an existing AUR helper such as `yay`:

```bash
yay -S --needed quickshell-git caelestia-cli libcava material-symbols-rounded-font-git
```

Review AUR build files and dependency prompts. `libcava` is needed by the native audio visualizer; installing the `cava` executable alone does not guarantee its development library is available. CMake accepts either a `libcava` or `cava` pkg-config module.

If you do not have an AUR helper, one way to install `yay` is to build its AUR package as your **normal user**:

```bash
git clone https://aur.archlinux.org/yay.git "$HOME/yay-build"
cd "$HOME/yay-build"
less PKGBUILD
makepkg -si
```

Do not run `makepkg` as root. Alternatively, build the individual dependencies from their AUR packages without a helper. Package availability can change on a rolling-release distribution.

Font requirements:

| Font | Purpose / installation |
|---|---|
| Material Symbols Rounded | Required for shell icons; installed by the AUR font package above. |
| GoogleSansFlex | Bundled in `quickshell/caelestia/assets/google-sans-flex/` and loaded by the shell. |
| CaskaydiaCove NF | Monospace text; supplied by the Cascadia Code Nerd Font package. |
| JetBrainsMono Nerd Font | The customized taskbar logo and other Nerd Font glyphs. |
| Rubik | Clock/workspace font. Obtain it from [Google Fonts](https://fonts.google.com/specimen/Rubik) or an appropriate font package. |

For manually downloaded fonts, put the extracted `.ttf`/`.otf` files in `~/.local/share/fonts/`, then refresh the cache:

```bash
mkdir -p "$HOME/.local/share/fonts"
fc-cache -f
fc-match 'Material Symbols Rounded'
fc-match 'CaskaydiaCove NF'
fc-match 'JetBrainsMono Nerd Font'
fc-match 'Rubik'
```

Check the **returned font family**, not just the exit status: `fc-match` can silently choose a fallback.

### 3. Enable the services you use

If NetworkManager is your chosen network manager, enable it:

```bash
sudo systemctl enable --now NetworkManager.service
```

Do not enable it alongside another service already managing the same interfaces without planning the migration.

For Bluetooth:

```bash
sudo systemctl enable --now bluetooth.service
```

Optional features have additional requirements:

| Feature | Requirements |
|---|---|
| Screen recording | `gpu-screen-recorder`; supported GPU/driver and recording permissions. Install with `sudo pacman -S --needed gpu-screen-recorder` where available. The bundled `cli.json` records at native resolution with the `ultra` quality preset. |
| Power-profile switching | `power-profiles-daemon` and its system service. Do not run competing power managers such as TLP/tuned without checking compatibility. |
| Phone integration | `kdeconnect`, a running `kdeconnectd`, and a paired phone. |
| External-display brightness | Monitor DDC/CI support and the appropriate `ddcutil`/I²C permissions. |
| Network/authentication prompts | A suitable polkit authentication agent in your desktop session. |
| GPU statistics | Working driver tools for your GPU; choose the corresponding GPU configuration in Nexus. |

The shell does not replace these system services. Missing optional tools can make the corresponding feature unavailable without preventing the rest of the shell from working.

### 4. Clone, back up, and link the shell

```bash
git clone https://github.com/srivastava-ayush/OrangeDots.git "$HOME/OrangeDots"

repo="$HOME/OrangeDots"
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
backup="$HOME/.local/share/orangedots-backups/$(date +%Y%m%d-%H%M%S)"

mkdir -p "$backup" "$config_home/quickshell" "$config_home/caelestia"

# Preserve existing CLI/shell preferences, including private local settings.
cp -a "$config_home/caelestia" "$backup/caelestia"

# Move only an existing Caelestia shell entry, not your other Quickshell configs.
if [[ -e "$config_home/quickshell/caelestia" || -L "$config_home/quickshell/caelestia" ]]; then
  mv "$config_home/quickshell/caelestia" "$backup/quickshell-caelestia"
fi

ln -s "$repo/quickshell/caelestia" "$config_home/quickshell/caelestia"

# Seed presets only when the destination does not already exist.
for file in shell.json shell-tokens.json cli.json; do
  if [[ ! -e "$config_home/caelestia/$file" && ! -L "$config_home/caelestia/$file" ]]; then
    cp "$repo/caelestia/$file" "$config_home/caelestia/$file"
  fi
done
```

If the repository is already cloned, skip the `git clone` command and set `repo` to that existing location. The symlink reads the QML directly from the clone, so **keep the repository in place**.

> [!NOTE]
> The display name is Orange OS, but the runtime config name, CLI command, native imports, and data directories remain **`caelestia`** for compatibility. Do not rename those directories to `Orange OS`.

Do **not** install upstream `caelestia-shell`/`caelestia-shell-git` as a substitute for building this fork. An upstream package can supply incompatible native modules or a different shell configuration. Review any already-installed package and its owned files before replacing it.

### 5. Build and install this fork's native modules

The QML itself is interpreted by Quickshell. This step compiles its **native dependencies**, not the entire dotfiles setup.

Check that the required development libraries are discoverable:

```bash
pkg-config --modversion Qt6Core Qt6WaylandClient wayland-client libqalculate libpipewire-0.3 aubio
pkg-config --exists libcava || pkg-config --exists cava
```

Then build from the vendored source:

```bash
repo="$HOME/OrangeDots"

cmake -S "$repo/quickshell/caelestia" \
  -B "$repo/quickshell/caelestia/build" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/usr \
  '-DENABLE_MODULES=extras;plugin;m3shapes' \
  -DVERSION=1.0.0

cmake --build "$repo/quickshell/caelestia/build" --parallel 2
sudo cmake --install "$repo/quickshell/caelestia/build"
```

- `--parallel 2` limits memory use; increase it if your machine has sufficient RAM.
- `VERSION=1.0.0` is a **numeric CMake build version** used because this clone may not have a usable Git version tag. It is separate from the About page's `AYUSH_GOAT_V4` display version.
- `extras;plugin;m3shapes` installs the native helpers and QML modules without installing a second QML shell over the symlinked source.
- M3Shapes is fetched from its pinned Git revision during configuration; network access is required.
- With this prefix, native files are installed under `/usr/lib/caelestia` and `/usr/lib/qt6/qml`. A different library location requires the matching `CAELESTIA_LIB_DIR` at launch; custom QML import locations also need to be discoverable by Qt.
- The core module uses `Qt::WaylandClientPrivate` for lock rendering recovery. Qt's private-API warning is intentional: rebuild after **every Qt upgrade**, and review the workaround before enabling it for a new Qt minor. The runtime version guard is not a substitute for rebuilding an ABI-incompatible library.
- When updating an existing installation, stop the shell **while unlocked** before replacing its native libraries. The [targeted recovery installer](#lock-screen-rendering-after-sleep) handles this for the core module only; it is not a first-install or full-module updater.

### 6. Start the shell and check it

Run these commands **inside your Hyprland session**, as your normal user—not from a root shell, SSH session, or an unrelated TTY:

```bash
quickshell --version
hyprctl monitors
qs -c caelestia -n
```

The final command runs the shell in the foreground and shows loading errors. `-n` avoids starting another instance of the same config. If an instance is already running, inspect its log rather than launching a second one:

```bash
caelestia shell -l
```

Once the foreground launch works, stop that test with `Ctrl+C` **while unlocked**, then launch normally:

```bash
caelestia shell -d
caelestia shell nexus open
```

The supplied preset hides the taskbar until hover. Move your pointer to the **left edge** if you do not immediately see it, or enable Persistent in Nexus.

Check the launcher, audio/network icons, notification bell, dashboard, and Nexus before making the shell your everyday session. Disable another notification daemon/bar's autostart if it conflicts; do not indiscriminately kill unrelated Quickshell instances.

### 7. Set your wallpaper and scheme

The shell includes a fallback wallpaper, but your personal wallpaper collection is not included.

```bash
mkdir -p "$HOME/Pictures/Wallpapers"
# Add your own images to this directory, then select an actual file:
caelestia wallpaper -f "$HOME/Pictures/Wallpapers/your-wallpaper.jpg"
```

Replace the example filename with an existing image. You can also choose a wallpaper in Nexus or run:

```bash
caelestia shell wallpapers pick
caelestia scheme set -n dynamic -m dark
```

The shell reads the generated scheme from `${XDG_STATE_HOME:-$HOME/.local/state}/caelestia/scheme.json`. If you adopt the bundled Hyprland colour palette too, keep `hypr/scheme/current.lua` consistent with the generated scheme; custom shell tint is only a shell overlay and does not rewrite that Lua palette.

### 8. Add autostart and shortcuts to your own config

If keeping your existing **Lua-based** Hyprland config, merge the following into its existing startup handler and keybinds. Do not add duplicate shell autostarts:

```lua
hl.on("hyprland.start", function()
    hl.exec_cmd("caelestia shell -d")
end)

hl.bind("SUPER + X", hl.dsp.exec_cmd("caelestia shell nexus open"))
hl.bind("SUPER + D", hl.dsp.exec_cmd("caelestia shell drawers toggle dashboard"))
hl.bind("SUPER + L", hl.dsp.exec_cmd("caelestia shell lock lock"))
hl.bind("SUPER + SUPER_L", hl.dsp.exec_cmd("caelestia shell drawers toggle launcher"), { release = true })
```

These bindings use this repo's Lua syntax. For a different Hyprland configuration format, use your installed version's supported startup/binding mechanism to run the same commands; do not mix config syntaxes.

Reload your own configuration after editing it:

```bash
hyprctl reload
```

A startup handler runs on the **next session start**; use `caelestia shell -d` to start it in the current session. No shell keybinds are installed automatically by the shell-only steps.

## Optional: install the bundled Hyprland dotfiles

**Skip this section if you want to keep your existing window-manager setup.** The shell-only installation above is sufficient for Orange OS.

### Adapt the configuration first

Review `hypr/hyprland.lua` and the refresh-rate script before linking them:

| Setting | Current assumption | What to change |
|---|---|---|
| Monitor | `1920x1080@144` | A mode and scale supported by your display; inspect `hyprctl monitors`. |
| Refresh-rate script | `eDP-1`, 60/144 Hz, origin `0x0` | Your output name, supported refresh rates, and monitor position. |
| `SUPER+R` | `/home/ayush/OrangeDots/refresh-rate-toggle.sh` | The location of the script in your clone. |
| IDE command | `/home/ayush/.local/bin/zed` | An installed editor command/path, such as `zed` or `code`. |
| App commands | `kitty`, `yazi`, `helium-browser`, Spotify, Obsidian, Blueman, Pavucontrol | Install the apps you use or replace their binds. Some require AUR/third-party packages. |
| Startup apps | `kdeconnectd`, clipboard watchers, `hyprpm reload -n` | Keep only the integrations you actually installed. |
| Plugins | ScrollOverview; guarded Hypr3D/HyprGlass sections | Install compatible plugins or remove the corresponding references. |

The shell's terminal wrapper is bundled at `quickshell/caelestia/assets/wrap_term_launch.sh`. The personal `SUPER+Q` / `SUPER+A` bindings use it to launch the terminal/Yazi.

### Set up the overview plugin if using its binds

The configuration references [ScrollOverview](https://github.com/yayuuu/hyprland-scroll-overview), including `SUPER+Escape`, gestures, and the overview hot corner:

```bash
hyprpm add https://github.com/yayuuu/hyprland-scroll-overview.git
hyprpm update
hyprpm enable scrolloverview
hyprpm reload
```

Hyprland plugins must match your installed Hyprland version. Rebuild/update them after Hyprland upgrades. If not using ScrollOverview, remove/comment its Lua references and disable the overview hot corner in Nexus. Hypr3D and HyprGlass are optional; neither is required for the shell itself.

### Back up and link Hyprland

After adapting the files, back up the existing directory and link the repo:

```bash
repo="$HOME/OrangeDots"
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
backup="$HOME/.local/share/orangedots-backups/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$backup" "$config_home"

if [[ -e "$config_home/hypr" || -L "$config_home/hypr" ]]; then
  mv "$config_home/hypr" "$backup/hypr"
fi

ln -s "$repo/hypr" "$config_home/hypr"
```

Activate the adapted config in a controlled session. It already autostarts `caelestia shell -d`; do not add a second autostart from the shell-only instructions. The main configuration is **`hyprland.lua`**, not classic `.conf` syntax.

The external `~/bin/power-watcher.sh`, `~/bin/refresh-rate.sh`, and `power-watcher.service` from the original machine are **not included**. Automatic AC/battery refresh-rate switching must be recreated separately if wanted.

## First-run customization

Open Nexus with `caelestia shell nexus open`, or `SUPER+X` when using the bundled binds.

| Preference | Nexus location |
|---|---|
| Left / Top orientation, Unified / Three notches / Center notch style, and taskbar persistence | **Panels → Taskbar** |
| Notification bell/shade and hover behavior | **Panels → Taskbar → Notification shade** |
| Status icons and their order | **Panels → Taskbar → Status icons** |
| Global background tint, VOID, presets, hex/RGB, strength, reset | **Wallpaper & style → Shell tint** |
| Wallpaper, transparency, dark/light theme | **Wallpaper & style** |
| Weather visibility, location, units, refresh | **Panels → Dashboard** |
| Utility cards and overview hot corner | **Panels → Dashboard → Utilities** |
| Recorder resolution, quality, codec, frame rate, cursor, reset | **Services → Screen recorder** |
| Dashboard Calendar tab and notes | **Panels → Dashboard → Calendar & notes** |
| Orange OS release label and system details | **About** |

Settings apply live where supported. Tint does not replace the Material accent scheme. To make VOID fully opaque rather than wallpaper-tinted black, disable **Transparency** separately.

**Three notches** keeps enabled logo/workspace entries together at the start, date/time in the center, and enabled tray/status entries at the end. The notches merge into the shell border rather than floating independently. This style always shows date/time and hides the active-window entry; switching back to **Unified** restores your configured entry order and active-window settings. Auto-hide and hover popouts work with either style.

Use **Panels → Taskbar → Center notch size** to set its minimum width in Top orientation or height in Left orientation, in logical pixels. **0 = Auto** fits the clock. The size cannot shrink below its contents or overlap the neighboring notches, and is saved across restarts.

**Center notch** uses the same grouping but draws only the date/time notch. Logo/workspaces and tray/status icons stay visible directly over the wallpaper, without side notches or background pills. Those exposed entries use white silhouettes with a dark shadow for contrast on light, dark, or busy wallpaper; workspace size/opacity still distinguish active, occupied, and empty workspaces. The clock and popouts retain their theme colours. Center notch sizing, auto-hide, and popouts work as in Three notches.

### Optional personal data

- **Profile photo:** copy an image to `~/.face`, or use the dashboard's photo control.
- **Weather:** enter a city or `latitude, longitude` in Nexus. It uses Open-Meteo; no API key is required.
- **Google Calendar:** create `${XDG_CONFIG_HOME:-$HOME/.config}/caelestia/calendar-url` containing your secret iCal URL on one line, then restrict it with `chmod 600`. Obtain the URL from Calendar's **Integrate calendar → Secret address in iCal format**. Treat it as a credential; do not commit it or paste it into issues.
- **Screen locking:** the repo includes password PAM configuration under `assets/pam.d/`. Fingerprint/face unlock require their own system setup. Keep a recovery session available while testing password unlock; do not copy arbitrary PAM files into `/etc/pam.d`.

## Commands and shortcuts

These CLI commands work independently of whether you installed the bundled keybinds:

```bash
caelestia shell -d                       # Start detached
caelestia shell -r                       # Restart this shell
caelestia shell -k                       # Stop this shell
caelestia shell -l                       # Show logs
caelestia shell -s                       # List available IPC commands
caelestia shell nexus open               # Open Nexus
caelestia shell drawers toggle dashboard
caelestia shell drawers toggle launcher
caelestia shell drawers toggle notifShade
caelestia shell drawers setTab calendar   # Google agenda and notes in the dashboard
```

Useful shortcuts in the **bundled** `hyprland.lua`:

| Shortcut | Action |
|---|---|
| `SUPER+X` | Nexus |
| `SUPER+D` | Dashboard |
| `SUPER+SUPER_L` on release | Launcher |
| `SUPER+L` | Lock |
| Tap `SUPER+SHIFT` | Toggle taskbar persistence |
| `SUPER+SHIFT+T` | Cycle taskbar style: Unified → Three notches → Center notch |
| `SUPER+SHIFT+T+O` | Toggle taskbar orientation: Left ↔ Top (hold T, then press O) |
| `SUPER+ALT+1..5` | Media / Dashboard / Performance / Phone / Calendar, subject to enabled tabs |
| `SUPER+Q` / `SUPER+A` | Terminal / Yazi through the bundled wrapper |
| `SUPER+S` | Spotify scratchpad |
| `SUPER+Escape` | ScrollOverview, when installed |

Check the Lua file for the complete, current keybind list.

## Configuration, backups, and migration

The committed JSON files are **first-install presets**, not a continuously synced copy of your Nexus changes. Existing live preferences are intentionally preserved when seeding them.

Default paths below honor `XDG_CONFIG_HOME` / `XDG_STATE_HOME` if set:

| Location | What to preserve |
|---|---|
| `~/.config/caelestia/shell.json` | Main Nexus preferences |
| `~/.config/caelestia/shell-tokens.json` | Font/size/style token overrides |
| `~/.config/caelestia/cli.json` | CLI options, including native-resolution recording |
| `~/.config/caelestia/monitors/<output>/` | Per-monitor overrides; output names must match the new machine |
| `~/.config/caelestia/weather.json` | Weather refresh interval |
| `~/.config/caelestia/calendar-url` | Private calendar URL |
| `~/.local/state/caelestia/taskbar.json` | Left/Top orientation, taskbar style, and center notch size |
| `~/.local/state/caelestia/shell-tint.json` | Custom tint, strength, and enabled state |
| `~/.local/state/caelestia/hot-corner.json` | Overview hot-corner settings |
| `~/.local/state/caelestia/scheme.json` | Generated Material palette |
| `~/.local/state/caelestia/wallpaper/path.txt` | Current wallpaper's absolute path, not the image itself |
| `~/.local/state/caelestia/notifs.json` | Notification history; can contain private text |
| `~/Pictures/Wallpapers`, `~/.face`, recordings | Actual personal media files |

For migration, back up the live `caelestia` config/state directories privately and copy the media separately. Reselect the wallpaper on the new machine instead of assuming an old absolute path still exists. Keep the repo's Lua palette and generated Material palette consistent if using both.

Notes currently use Quickshell `PersistentProperties` for shell reloads; they are **not a documented, portable notes-file backup**. Save important note text elsewhere before reinstalling.

Never commit calendar secrets, notification history, or other private runtime data. To deliberately update this repo's presets, copy your live JSON into `caelestia/` and review the diff first.

## Updating

Back up your live settings and inspect local edits before pulling:

```bash
repo="$HOME/OrangeDots"
git -C "$repo" status --short
git -C "$repo" pull --ff-only
```

If you have conflicting local edits, commit or back them up and resolve the conflict; do not use a hard reset to discard them. Do not reseed live JSON files over your preferences on every update.

QML-only changes usually hot-reload. For a clean restart:

```bash
caelestia shell -r
```

After native-source, Qt, or Quickshell ABI changes, repeat [the native-module build/install step](#5-build-and-install-this-forks-native-modules), then restart. A Qt upgrade may also require rebuilding `quickshell-git`. Update Hyprland plugins separately when Hyprland changes.

## Troubleshooting

| Symptom | What to check |
|---|---|
| `module "Caelestia..." is not installed` or `M3Shapes` missing | Build/install this fork's native modules, not only the QML files. Check the install prefix and Qt import path. |
| CMake cannot infer `VERSION` | Pass `-DVERSION=1.0.0` as shown above; `AYUSH_GOAT_V4` is not a numeric CMake project version. |
| `libcava`, `cava`, Qalculate, PipeWire, Aubio, or sensors missing | Install development libraries; check pkg-config and `lm_sensors`. Re-run CMake configuration after fixing dependencies. |
| Qt symbol/ABI errors after an upgrade | Rebuild Quickshell/native modules against the same Qt installation. Do not mix old packaged modules with this fork. |
| Config named `caelestia` cannot be found | Check the symlink with `readlink -f ~/.config/quickshell/caelestia`. A top-level `quickshell/shell.qml` default config can interfere with named-config discovery; back up/reconcile it instead of deleting blindly. For diagnosis, try `qs -p "$HOME/OrangeDots/quickshell/caelestia" -n`. |
| No taskbar | The preset is hover-to-reveal on the left. Check the left edge, monitor overrides, and Persistent in Nexus. |
| Two bars or notification-server registration errors | Remove duplicate autostarts and disable the competing notification daemon for this session. Restart only the relevant shell. |
| Wi-Fi/Bluetooth/audio controls unavailable | Check NetworkManager, `bluetooth.service`, PipeWire/WirePlumber, and your session's authentication agent. |
| Icons are squares or literal symbol names | Check Material Symbols Rounded and Nerd Font family resolution; refresh the font cache and restart. |
| Wallpaper/scheme errors | Choose an existing wallpaper using the CLI. Restore/regenerate state rather than copying another user's absolute wallpaper path. |
| Login/config parsing errors with the full dotfiles | Confirm Lua-compatible Hyprland, adapt monitor/app paths, and check ScrollOverview references. Return to your backed-up config if necessary. |
| Password feedback is missing after wake until you click the field | A pending Wayland frame callback can strand lock rendering across sleep even while input/authentication work. Check `caelestia shell lock renderRecoveryStatus`, then follow [sleep/wake recovery](#lock-screen-rendering-after-sleep). A restart alone is not a confirmed fix. Do not kill/restart the shell while locked. |
| Recording does not start | Install/check `gpu-screen-recorder`, GPU support, available audio devices, and the CLI's recording command. |
| Recording is downscaled or lower quality | Open **Services → Screen recorder** and choose **Reset to highest quality**, or ensure `~/.config/caelestia/cli.json` has `"record": {"extraArgs": ["-s", "0x0", "-q", "ultra", "-tune", "quality"]}`, then restart the recording. Resolution is always native. |
| Calendar is empty | Check the private iCal URL file and network access. The calendar parser does not expand all recurring-event rules. |
| A pure-black preset still looks translucent | VOID sets tint strength, not opacity. Turn off Transparency for an opaque background. |

For useful diagnostics:

```bash
caelestia shell -l
qs list --all
hyprctl monitors
hyprctl configerrors
```

Before sharing logs, remove credentials, private calendar URLs, notification text, and machine-specific information you do not want public.

### Lock-screen rendering after sleep

`LockRenderRecovery` discards a pending frame callback once after resume, restores Qt's exposure bookkeeping, and requests a frame. Later password edits trigger recovery **only if Qt reports a callback timeout**. It is restricted to Quickshell session-lock windows: it never hides/recreates the surface, changes its protocol role, or unlocks/relocks the session. The password widget and PAM verification are unchanged by this native recovery.

The private Qt layout has been reviewed for **6.12**. `supported:true` requires matching Qt build/runtime versions within that minor; other versions refuse recovery. Rebuild all affected native modules after any Qt upgrade, and review the implementation before supporting a new Qt minor. Do not suppress the private-API compatibility warning.

For an **existing, manually installed** `/usr/lib/qt6/qml/Caelestia` module, run from a terminal in your **unlocked Wayland desktop**, as your normal user:

```bash
repo="$HOME/OrangeDots"
bash "$repo/quickshell/caelestia/scripts/install-lock-render-recovery.sh" --check
bash "$repo/quickshell/caelestia/scripts/install-lock-render-recovery.sh"
caelestia shell lock renderRecoveryStatus
```

The installer requires this checkout's build configured with prefix `/usr`. It rebuilds `caelestia-coreplugin`, stages CMake's install/RPATH changes without root, and backs up only `lib/libcaelestia-core.so`, `libcaelestia-coreplugin.so`, `qmldir`, and `caelestia-core.qmltypes`. Backups are under `${XDG_STATE_HOME:-$HOME/.local/state}/caelestia/native-backups/lock-render-*`. It refuses package-owned target files, prompts for sudo **locally in your terminal**, stops the unlocked shell, installs those four files, restarts, verifies native support, and arms temporary wake tracing. Qt/Hyprland packages and other QML modules are not replaced. `--check` does not build, install, stop the shell, or request privileges.

On installation/verification failure, it attempts rollback only after confirming no named shell remains running. If a relaunched shell has locked, or its state is unavailable, it refuses to stop/overwrite it and prints the backup path for later recovery. Do not manually restore libraries under a running shell.

Successful status includes `"supported":true` and identical `qtBuild`/`qtRuntime` values. `lockWindow:false` is expected for this status query, which does not target a window. `"reason":"native plugin not rebuilt"` means the running process has not loaded the helper yet.

Installation is **not proof that the intermittent wake bug is fixed**. Test repeated real suspend/resume and hibernate/resume cycles, typing before any click, and inspect the opt-in trace described below. Re-arm tracing before each cycle; it disables itself on unlock. Never share your password.

### Undoing the installation

Stop the shell with `caelestia shell -k`, remove its autostart/binds, and restore the configuration entries saved in `~/.local/share/orangedots-backups/`. Remove **only the symlinks you created**, not a whole config directory or the clone they point to. Preserve live state if you want your preferences later.

The manual native-module install is separate from the symlinks. Review `quickshell/caelestia/build/install_manifest.txt` and package ownership before removing any system files; do not recursively delete Qt's QML directory or assume CMake provides an uninstall target.

## Development checks

From the repository root, inside a Wayland session with the native modules installed:

```bash
python3 quickshell/caelestia/tests/taskbar.test.py
```

The integration checks use isolated config/state and a transparent, input-free test surface. They cover taskbar orientation/styles, shell-attached notch geometry, popout sizing/hover, notification shade, Nexus navigation, recorder settings/persistence, lock-input recovery/focus, tint/VOID, persistence, and invalid settings. A focused run is available, for example:

```bash
python3 quickshell/caelestia/tests/taskbar.test.py --mode tint
```

Lock-screen checks require Qt's `QtTest` QML module (part of `qt6-declarative` on Arch). They deliver real Qt key events directly to the native password field in the isolated test application's window—no OS keyboard injection or clicks before typing. They cover masking, Backspace/Ctrl+Backspace, Unicode editing, Enter/button handoff, repeated resume settling, early/duplicate unlock, and disabled animations. Submission routing uses a mock backend; the real backend is checked to reject unsecured submissions. These tests never acquire the session lock or authenticate:

```bash
python3 quickshell/caelestia/tests/taskbar.test.py --mode lock-input
python3 quickshell/caelestia/tests/taskbar.test.py --mode lock-focus
```

To require the newly built native helper before installing it, build `caelestia-coreplugin` and run:

```bash
LOCK_REQUIRE_NATIVE=1 \
  QML_IMPORT_PATH="$PWD/quickshell/caelestia/build/qml" \
  python3 quickshell/caelestia/tests/taskbar.test.py --mode lock-input
QML_IMPORT_PATH="$PWD/quickshell/caelestia/build/qml" \
  python3 quickshell/caelestia/tests/taskbar.test.py --mode lock-focus
```

The native checks require supported, identical Qt build/runtime versions and verify that recovery rejects ordinary layer-shell windows and absent targets. They do **not** acquire a real session-lock surface or reproduce a stalled compositor callback.

After changing the lock screen, also manually check normal lock/unlock, suspend, and hibernate. On resume, type before clicking the password field. Verify visible typing feedback, Backspace/Ctrl+Backspace, incorrect-password feedback, and successful unlock; test each attached display if you use multiple monitors. Automated focus simulation cannot reproduce a GPU/compositor's actual sleep cycle.

For the resume-only typing-feedback issue, temporary opt-in diagnostics compare Qt focus, application state, masked-input presence, frame notifications, and native `framePending`/`callbackTimedOut`/exposure metadata before/after a click. Tracing itself never records password text or password length and does not request focus or repaints. The recovery runs independently of tracing. After replacing a native library, restart **while unlocked**; live QML reloads do not replace a loaded native plugin.

```bash
# Arm before the manual sleep/wake test.
caelestia shell lock traceWake
# After reproducing and unlocking, retrieve the captured metadata.
caelestia shell lock wakeTrace
qs --no-color log -c caelestia -t 150
caelestia shell lock stopWakeTrace
```

Trace records named `render-recovery` include before/after native state; native recovery messages use the `caelestia.lock.render` log category. Re-arm `traceWake` before each new sleep test because unlocking disables it.

Weather helper tests require Node.js:

```bash
node --test quickshell/caelestia/tests/weather.test.cjs
```

These checks do not replace testing your real GPU, audio devices, network permissions, recording, and lock/PAM behavior.

## Repository layout

| Path | Purpose |
|---|---|
| `hypr/hyprland.lua` | Personal Hyprland configuration; Lua syntax |
| `hypr/scheme/current.lua` | Hyprland-side colour palette |
| `hypr/spotify-toggle.sh` | Spotify scratchpad helper |
| `hypr/caelestia-toggle.sh` | Toggle this shell instance |
| `refresh-rate-toggle.sh` | Hardware-specific refresh-rate helper |
| `caelestia/*.json` | First-install shell, token, and CLI presets |
| `quickshell/caelestia/shell.qml` | Orange OS shell entry point |
| `quickshell/caelestia/modules/` | Bar, popouts, dashboard, Nexus, launcher, lock, and other UI |
| `quickshell/caelestia/services/` | Runtime services, including tint, taskbar state, weather, and notifications |
| `quickshell/caelestia/plugin/` | Native QML modules; rebuild when changing native code |
| `quickshell/caelestia/assets/` | Bundled fallback wallpaper, Google Sans Flex font, PAM files, and helper assets |
| `quickshell/caelestia/tests/` | Integration and weather tests |

## License

The vendored shell under `quickshell/caelestia/` is a fork of Caelestia and retains its **GPL-3.0** license and applicable upstream notices. Orange OS branding does not change that license. Top-level personal dotfiles are unrestricted: use and adapt them as you wish.
