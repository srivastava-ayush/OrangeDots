# 🟠 OrangeDots · Orange OS

Personal **Arch Linux + Hyprland** dotfiles featuring **Orange OS**, a heavily customized riced [Caelestia](https://github.com/caelestia-dots/shell) Quickshell desktop shell.
> [!NOTE]
> This is a **desktop shell and dotfiles repo**, not an OS installer or Arch ISO. It ships the shell source, native-module source, assets, and first-install presets. You install system dependencies yourself.

| | |
|---|---|
| **Platform** | Arch Linux · Hyprland (Wayland) |
| **Shell** | Quickshell (`quickshell-git`) · Qt 6.9+ |
| **Tested on** | Hyprland 0.56.2 |
| **Hyprland config** | Lua `hl.*` API (not classic `hyprland.conf`) |
| **License** | GPL-3.0 (shell) · unrestricted (personal dotfiles) |

---

## 📑 Contents

1. [Quick start](#-quick-start)
2. [Features](#-features)
3. [Requirements](#-requirements)
4. [Installation (shell only)](#-installation-shell-only)
5. [Optional: full Hyprland dotfiles](#-optional-full-hyprland-dotfiles)
6. [First-run customization](#-first-run-customization)
7. [Sidebar and AI panel](#-sidebar-and-ai-panel)
8. [Commands and shortcuts](#-commands-and-shortcuts)
9. [Configuration, backups, migration](#-configuration-backups-and-migration)
10. [Updating](#-updating)
11. [Troubleshooting](#-troubleshooting)
12. [Advanced: lock-screen recovery](#-advanced-lock-screen-recovery-after-sleep)
13. [Uninstall](#-uninstall)
14. [Development](#-development)
15. [Repository layout](#-repository-layout)
16. [License](#-license)

---

## ⚡ Quick start

For a machine that already runs **Hyprland** with packages and AUR dependencies installed (see [Installation](#-installation-shell-only) for those):

```bash
git clone https://github.com/srivastava-ayush/OrangeDots.git ~/OrangeDots
cd ~/OrangeDots

bash install.sh --dry-run     # preview what will change
bash install.sh               # link shell + seed missing presets

cmake -S quickshell/caelestia -B quickshell/caelestia/build -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr \
  '-DENABLE_MODULES=extras;plugin;m3shapes' -DVERSION=1.0.0
cmake --build quickshell/caelestia/build --parallel 2
sudo cmake --install quickshell/caelestia/build

qs -c caelestia -n            # test run (Ctrl+C to stop), then: caelestia shell -d
```

> [!IMPORTANT]
> Keep a working terminal and a way back to a TTY. Back up existing config before replacing it. Test password unlock before relying on the lock screen. **Never run Quickshell as root.**

---

## ✨ Features

| Area | What you get |
|---|---|
| **Taskbar** | Left or top orientation. Styles: **Unified** (default), **Three notches**, **Center notch**. Centered date/time, shell-attached backgrounds. |
| **Notifications** | Bell in the status-icon group with hover popout. In Left orientation the shade attaches to the inner bottom edge. Banners are separate from history. |
| **Theming** | Material 3 wallpaper-derived colours, transparency, global background tint. **VOID** preset = pure black at 100% tint (transparency is a separate setting). |
| **Dashboard** | Weather, recording controls, utility cards, performance info, optional phone integration, Calendar tab with notes and optional private Google Calendar (iCal). |
| **Screen recording** | Native resolution, `ultra` preset, `-s 0x0` (no downscaling). Quality, codec, frame rate, tune, cursor configurable in **Services → Screen recorder**. |
| **Sidebars** | Left and right modular sidebars: AI, Calendar, Clipboard, Focus, Notes. |
| **AI sidebar** | Lazy-loaded; OpenCode, Codex, Claude Code, or local Ollama; per-provider reasoning effort. |
| **Hyprland dotfiles** | Optional Lua config, scratchpads, gestures, overview-plugin integration. |

Also included: launcher, lock screen, media controls, system tray, and the **Nexus** settings overlay.

📖 Detailed inventory: [docs/FEATURES.md](docs/FEATURES.md). These instructions take precedence over the inherited upstream README for **this fork**.

---

## 📋 Requirements

- **Arch Linux** with a working **Hyprland Wayland session**, and a normal user with `sudo`.
- **`quickshell-git`** (not just an older tagged release).
- **Qt 6.9+**, with Quickshell and the native modules built against compatible Qt versions.
  - Lock-screen frame-callback recovery supports **Qt 6.12 only**, with identical build/runtime versions. See [lock-screen recovery](#-advanced-lock-screen-recovery-after-sleep).
- Internet access (packages, CLI, and CMake's pinned M3Shapes download).

Other distributions are not covered. The bundled Hyprland config uses the **Lua API**; don't paste it into a classic `hyprland.conf` setup.

### Choose your scope

| Option | What changes |
|---|---|
| **Shell only** *(recommended first)* | Installs Orange OS next to your existing Hyprland config. You add autostart and keybinds yourself. |
| **Full dotfiles** | Also replaces your Hyprland config with this repo's keybinds, apps, monitor settings, rules, and gestures. Adapt before activating. |

> [!TIP]
> All command blocks use **Bash**. If your interactive shell is Fish, run `bash` first. Examples assume the clone lives at `~/OrangeDots`.

---

## 🛠 Installation (shell only)

### Step 1 · Install Arch packages

Update first and avoid partial upgrades:

```bash
sudo pacman -Syu
```

Build dependencies and desktop tools:

```bash
sudo pacman -S --needed \
  git base-devel cmake ninja pkgconf python \
  qt6-base qt6-declarative qt6-shadertools qt6-svg qt6-wayland \
  libqalculate libpipewire aubio cava lm_sensors \
  networkmanager bluez bluez-utils upower \
  brightnessctl ddcutil fish curl jq libnotify \
  wl-clipboard cliphist playerctl grim slurp swappy matugen \
  ttf-cascadia-code-nerd ttf-jetbrains-mono-nerd noto-fonts-emoji
```

<details>
<summary><b>Hyprland and PipeWire not installed yet?</b></summary>

Get a working Hyprland session **before** installing the shell:

```bash
sudo pacman -S --needed hyprland xdg-desktop-portal-hyprland
```

Typical audio stack for a new install (review conflicts rather than replacing an existing setup):

```bash
sudo pacman -S --needed pipewire pipewire-pulse wireplumber
systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service
```

Or log out and back in after installing.
</details>

### Step 2 · Install AUR dependencies

With an AUR helper such as `yay`:

```bash
yay -S --needed quickshell-git caelestia-cli libcava ttf-material-symbols-variable-git
```

Review the build files and dependency prompts. `libcava` is required by the native audio visualizer; the `cava` executable alone doesn't guarantee its development library. CMake accepts either a `libcava` or `cava` pkg-config module.

### Step 3 · Clone, back up, and link the shell

**Recommended: the installer script.**

```bash
git clone https://github.com/srivastava-ayush/OrangeDots.git "$HOME/OrangeDots"
cd "$HOME/OrangeDots"

bash install.sh --dry-run   # preview
bash install.sh             # apply
```

The installer:
- ✅ preserves existing preferences and private files
- ✅ backs up conflicting shell entries to `${XDG_STATE_HOME:-$HOME/.local/state}/orangedots/backups/`
- ✅ seeds only **missing** JSON presets
- ❌ does **not** install packages, build native modules, or restart your session

Run it from the checkout or by full path. For reviewed full dotfiles use `bash install.sh --full` (preview with `--full --dry-run`).

<details>
<summary><b>Manual installation (equivalent)</b></summary>

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

If the repo is already cloned, skip `git clone` and set `repo` to its location. The symlink reads QML directly from the clone, so **keep the repository in place**.
</details>

> [!NOTE]
> The display name is **Orange OS**, but the runtime config name, CLI command, native imports, and data directories stay **`caelestia`** for compatibility. Don't rename them.

> [!WARNING]
> Don't install upstream `caelestia-shell` / `caelestia-shell-git` as a substitute for building this fork. Upstream can supply incompatible native modules or a different shell config. Review any already-installed package and the files it owns before replacing it.

### Step 4 · Build and install the native modules

QML is interpreted by Quickshell; this step compiles only the **native dependencies**.

Check that dev libraries are discoverable:

```bash
pkg-config --modversion Qt6Core Qt6WaylandClient wayland-client libqalculate libpipewire-0.3 aubio
pkg-config --exists libcava || pkg-config --exists cava
```

Build from the vendored source:

```bash
repo="$HOME/OrangeDots"

cmake -S "$repo/quickshell/caelestia" \
  -B "$repo/quickshell/caelestia/build" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/usr \
  '-DENABLE_MODULES=extras;plugin;m3shapes' \
  -DVERSION=1.0.0

cmake --build "$repo/quickshell/caelestia/build" --parallel 2   # drop --parallel if unsupported
sudo cmake --install "$repo/quickshell/caelestia/build"
```

<details>
<summary><b>What these flags mean</b></summary>

- `--parallel 2` limits memory use; raise it if you have the RAM.
- `VERSION=1.0.0` is a **numeric CMake build version** (this clone may lack a usable Git tag). It is separate from the About page's `AYUSH_GOAT_V4` display version.
- `extras;plugin;m3shapes` installs native helpers and QML modules without installing a second QML shell over the symlinked source.
- M3Shapes is fetched from a pinned Git revision during configuration, so network access is required.
- With this prefix, files go to `/usr/lib/caelestia` and `/usr/lib/qt6/qml`. A different library location needs a matching `CAELESTIA_LIB_DIR` at launch, and custom QML import paths must be discoverable by Qt.
- The core module uses `Qt::WaylandClientPrivate` for lock-rendering recovery. The private-API warning is intentional: **rebuild after every Qt upgrade** and review the workaround before enabling it for a new Qt minor. The runtime version guard doesn't replace a rebuild.
- When updating, stop the shell **while unlocked** before replacing native libraries. The [targeted recovery installer](#-advanced-lock-screen-recovery-after-sleep) handles this for the core module only.
</details>

### Step 5 · Fonts

| Font | Purpose / source |
|---|---|
| Material Symbols Rounded | Shell icons. Installed by the AUR font package above. |
| GoogleSansFlex | Bundled in `quickshell/caelestia/assets/google-sans-flex/`; loaded automatically. |
| CaskaydiaCove NF | Monospace text. From the Cascadia Code Nerd Font package. |
| JetBrainsMono Nerd Font | Taskbar logo and other Nerd Font glyphs. |
| Rubik | Clock/workspace font. Get it from [Google Fonts](https://fonts.google.com/specimen/Rubik) or a font package. |

For manually downloaded fonts, put the `.ttf`/`.otf` files in `~/.local/share/fonts/`, then verify:

```bash
mkdir -p "$HOME/.local/share/fonts"
fc-cache -f
fc-match 'Material Symbols Rounded'
fc-match 'CaskaydiaCove NF'
fc-match 'JetBrainsMono Nerd Font'
fc-match 'Rubik'
```

> [!TIP]
> Check the **returned family name**, not the exit status. `fc-match` can silently pick a fallback.

### Step 6 · Enable services and optional features

```bash
sudo systemctl enable --now NetworkManager.service   # only if it's your network manager
sudo systemctl enable --now bluetooth.service
```

Don't enable NetworkManager alongside another service managing the same interfaces without planning the migration.

Optional features and what they need (missing tools disable only that feature):

| Feature | Requirements |
|---|---|
| **Screen recording** | `gpu-screen-recorder` (`sudo pacman -S --needed gpu-screen-recorder` where available), supported GPU/driver, recording permissions. Bundled `cli.json` records at native resolution, `ultra` preset. |
| **Power profiles** | `power-profiles-daemon` + its system service. Avoid competing managers (TLP/tuned) without checking compatibility. |
| **Phone integration** | `kdeconnect`, running `kdeconnectd`, a paired phone. |
| **External-display brightness** | Monitor DDC/CI support and appropriate `ddcutil` / I²C permissions. |
| **Network/auth prompts** | A polkit authentication agent in your session. |
| **GPU statistics** | Working GPU driver tools; pick the matching GPU config in Nexus. |

### Step 7 · Start the shell and verify

Run these **inside your Hyprland session** as your normal user (not root, SSH, or another TTY):

```bash
quickshell --version
hyprctl monitors
qs -c caelestia -n          # foreground; shows loading errors. -n avoids a second instance
```

If an instance is already running, read its log instead of launching another:

```bash
caelestia shell -l
```

When the foreground launch works, stop it with `Ctrl+C` **while unlocked**, then launch normally:

```bash
caelestia shell -d
caelestia shell nexus open
```

> [!TIP]
> The preset hides the taskbar until hover. Move your pointer to the **left edge**, or enable **Persistent** in Nexus.

Before making it your daily session, check the launcher, audio/network icons, notification bell, dashboard, and Nexus. Disable any conflicting notification daemon or bar autostart, and don't indiscriminately kill unrelated Quickshell instances.

### Step 8 · Wallpaper and colour scheme

A fallback wallpaper is included; your personal collection is not.

```bash
mkdir -p "$HOME/Pictures/Wallpapers"
# add your images, then point at a real file:
caelestia wallpaper -f "$HOME/Pictures/Wallpapers/your-wallpaper.jpg"
```

Or pick in Nexus, or:

```bash
caelestia shell wallpapers pick
caelestia scheme set -n dynamic -m dark
```

The generated scheme lives at `${XDG_STATE_HOME:-$HOME/.local/state}/caelestia/scheme.json`. If you use the bundled Hyprland palette too, keep `hypr/scheme/current.lua` consistent with it. Shell tint is only an overlay and does not rewrite that Lua palette.

### Step 9 · Autostart and shortcuts (your own Hyprland config)

If keeping your existing **Lua-based** Hyprland config, merge this into your startup handler and binds. Avoid duplicate shell autostarts:

```lua
hl.on("hyprland.start", function()
    hl.exec_cmd("caelestia shell -d")
end)

hl.bind("SUPER + X", hl.dsp.exec_cmd("caelestia shell nexus open"))
hl.bind("SUPER + D", hl.dsp.exec_cmd("caelestia shell drawers toggle dashboard"))
hl.bind("SUPER + L", hl.dsp.exec_cmd("caelestia shell lock lock"))
hl.bind("SUPER + SUPER_L", hl.dsp.exec_cmd("caelestia shell drawers toggle launcher"), { release = true })
```

For other Hyprland config formats, use your version's own startup/bind mechanism to run the same commands; don't mix syntaxes.

```bash
hyprctl reload
```

A startup handler only runs on the **next session start**; use `caelestia shell -d` to start now. The shell-only steps install **no** keybinds automatically.

---

## 🧩 Optional: full Hyprland dotfiles

> [!NOTE]
> **Skip this if you want to keep your current window-manager setup.** Shell-only is enough for Orange OS.

### 1 · Adapt the config first

Review `hypr/hyprland.lua` and the refresh-rate script before linking:

| Setting | Current assumption | Change to |
|---|---|---|
| Monitor | `1920x1080@144` | A mode/scale your display supports (`hyprctl monitors`) |
| Refresh-rate script | `eDP-1`, 60/144 Hz, origin `0x0` | Your output name, rates, and position |
| `SUPER+SHIFT+R` | `hypr/scripts/toggle-refresh-rate.sh` | Adapt hardware-specific modes in the helper (no clone path to edit) |
| IDE command | `zed` on `PATH` | Your editor (`zed`, `code`, …) |
| App commands | `kitty`, `yazi`, `helium-browser`, Spotify, Obsidian, Blueman, Pavucontrol | Install them, or replace the binds (some need AUR/third-party packages) |
| Startup apps | `kdeconnectd`, clipboard watchers, `hyprpm reload -n` | Keep only integrations you installed |
| Plugins | ScrollOverview; guarded Hypr3D / HyprGlass | Install compatible plugins or remove the references |

The terminal wrapper lives at `quickshell/caelestia/assets/wrap_term_launch.sh`; `SUPER+Q` / `SUPER+A` use it for the terminal and Yazi.

### 2 · Set up the overview plugin (if using its binds)

The config references [ScrollOverview](https://github.com/yayuuu/hyprland-scroll-overview) (`SUPER+Escape`, gestures, overview hot corner):

```bash
hyprpm add https://github.com/yayuuu/hyprland-scroll-overview.git
hyprpm update
hyprpm enable scrolloverview
hyprpm reload
```

Plugins must match your installed Hyprland version, so rebuild/update them after each Hyprland upgrade. Not using ScrollOverview? Remove its Lua references and disable the overview hot corner in Nexus. Hypr3D and HyprGlass are optional.

### 3 · Back up and link

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

Or use `bash install.sh --full`. Activate in a controlled session. The config **already autostarts** `caelestia shell -d`; don't add a second autostart from the shell-only steps. The main file is **`hyprland.lua`**, not classic `.conf` syntax.

> [!WARNING]
> `~/bin/power-watcher.sh`, `~/bin/refresh-rate.sh`, and `power-watcher.service` from the original machine are **not included**. Automatic AC/battery refresh-rate switching must be recreated separately.

---

## 🎛 First-run customization

Open **Nexus** with `caelestia shell nexus open` (or `SUPER+X` with the bundled binds). Every entry point opens the same animated **in-shell overlay**; there is no standalone floating window. Dismiss with `Esc` or the close button.

| I want to change… | Go to |
|---|---|
| Orientation (Left/Top), style (Unified / Three notches / Center notch), persistence | **Panels → Taskbar** |
| Notification bell/shade and hover behavior | **Panels → Taskbar → Notification shade** |
| Status icons and order | **Panels → Taskbar → Status icons** |
| Center notch size | **Panels → Taskbar → Center notch size** |
| Tint, VOID, presets, hex/RGB, strength, reset | **Wallpaper & style → Shell tint** |
| Wallpaper, transparency, dark/light | **Wallpaper & style** |
| Weather visibility, location, units, refresh | **Panels → Dashboard** |
| Utility cards, overview hot corner | **Panels → Dashboard → Utilities** |
| Calendar tab and notes | **Panels → Dashboard → Calendar & notes** |
| Recorder resolution, quality, codec, fps, cursor, reset | **Services → Screen recorder** |
| Sidebars and modules | **Panels → Sidebar** |
| Orange OS release label, system details | **About** |

Settings apply live where supported. Tint doesn't replace the Material accent scheme. For a fully opaque VOID, disable **Transparency** separately.

### Taskbar styles

| Style | Behavior |
|---|---|
| **Unified** *(default)* | Single taskbar; your configured entry order and active-window settings. |
| **Three notches** | Logo/workspaces at start, date/time centered, tray/status at end. Notches merge into the shell border. Always shows date/time; hides the active-window entry. Switching back to Unified restores your order and settings. |
| **Center notch** | Only the date/time notch is drawn. Logo/workspaces and tray/status sit directly on the wallpaper as white silhouettes with a dark shadow for contrast; workspace size/opacity still distinguish active/occupied/empty. Clock and popouts keep theme colours. |

**Center notch size:** minimum width (Top) or height (Left) in logical pixels. `0` = Auto (fits the clock). It can't shrink below its contents or overlap neighboring notches, and persists across restarts. Auto-hide and hover popouts work in every style.

### Optional personal data

| Item | How |
|---|---|
| **Profile photo** | Copy an image to `~/.face`, or use the dashboard's photo control. |
| **Weather** | Enter a city or `latitude, longitude` in Nexus. Uses Open-Meteo; no API key. |
| **Google Calendar** | Paste your **Secret address in iCal format** (Calendar → *Integrate calendar*) into **Nexus → Panels → Sidebar → Modules → Calendar & notes**. Stored privately at `${XDG_CONFIG_HOME:-$HOME/.config}/caelestia/calendar-url`; existing manual files still work. **Treat it as a credential.** Never commit it or paste it into issues. |
| **Screen locking** | Password PAM config is in `assets/pam.d/`. Fingerprint/face need their own system setup. Keep a recovery session while testing, and never copy arbitrary PAM files into `/etc/pam.d`. |

---

## 🗂 Sidebar and AI panel

Configure under **Nexus → Panels → Sidebar**.

### Layout and behavior

- **Left** and **Right** sidebars each have their own enable switch, width, height, and default module.
- Open either by **dragging inward from its screen edge**; both can be open at once.
- **Modules** assigns each module to **Left / Right / Off**. Existing assignments stay on the right after upgrade; an empty left sidebar shows a configuration prompt.
- Hover a tab to switch (short crossfade/glide); clicking also works.
- **Modules → Module labels** renames tabs/headers (blank restores the default).
- Top-attached sidebars share the taskbar's liquid shell background; panels overlay windows without resizing them.

**Toggle shortcuts:** `Super+I` (right sidebar, bundled binds) · `caelestia shell drawers toggle ai` · `... rightSidebar` · `... leftSidebar`. The old right-edge power-menu gesture is replaced; power buttons and other session-menu entry points remain.

<details>
<summary><b>Memory and unloading behavior</b></summary>

- Only the visible module view and a briefly outgoing crossfade view are loaded; closing a sidebar unloads module views after the slide finishes.
- Shared notes/drafts and focus timers stay alive. AI keeps bounded conversation state and any in-flight reply but releases the chat UI.
- Clipboard's in-memory display cache expires 3 s after its last view closes (after any pending operation), without deleting history or pins. Image previews avoid Qt's shared decoded-image cache.
- Qt may retain allocator/render caches, so releasing views doesn't guarantee an immediate drop in process RSS.
</details>

### Modules

| Module | What it does | Storage |
|---|---|---|
| **Calendar** | Google Calendar (iCal) + notes. Settings button opens **Calendar & notes** directly. Masked **Secret iCal URL** field with Save/Replace and confirmed Remove; the URL is never prefilled or displayed. Passed to helper/curl via stdin, not arguments. | `calendar-url` (`0600`), not ordinary settings JSON |
| **Clipboard** | Same `cliphist` + `wl-copy` backend as `caelestia clipboard`. Search recent text/images, preview, copy, paste, pin snippets, delete items. Clearing asks to confirm: **History** keeps pins, **Everything** removes them. Shows the latest 200 items and previews up to 24 recent images. | Pins: `$XDG_STATE_HOME/caelestia/clipboard-sidebar` (fallback `~/.local/state`), private permissions. Previews: private XDG cache. |
| **Focus** | Work / short-break / long-break durations, task field, start/pause/reset/skip, long break every 4 work intervals. Optional auto-start and focus-only DND (pre-enabled DND is left alone). Optional countdown before the tray. Runs while the sidebar is closed; uses wall-clock deadlines across sleep. | `$XDG_STATE_HOME/caelestia/focus-timer.json` |
| **Notes** | Quick capture for plain-text notes (including links) and checkable todos. Search/filter, edit, copy, delete with confirmation. **Delete all notes/todos** clears only the current category and keeps your draft. `Ctrl+Enter` saves. Old Link entries become ordinary notes. Doesn't touch the calendar scratchpad. | `$XDG_STATE_HOME/caelestia/sidebar-notes.json` |
| **AI** | See below. | `ai-panel.json`, `sidebar-panel.json` |

> [!WARNING]
> Pins hold the full copied data as plaintext. Don't pin passwords or other secrets.

**Direct paste** needs `wtype` and compositor support; otherwise copy and press `Ctrl+V`. Clipboard history collection must already be running, as with `caelestia clipboard`.

### AI sidebar

**Prerequisites:** a recent Node.js with built-in `fetch`. For OpenCode, also OpenCode V2 and the pinned client dependencies (run from the repo for a linked install, or from the installed shell's `utils/opencode` path for a copied install; no native rebuild needed):

```bash
npm ci --prefix quickshell/caelestia/utils/opencode --ignore-scripts --no-audit --no-fund
```

| Backend | Requirements | Behavior |
|---|---|---|
| **OpenCode** | OpenCode V2 + dependencies above | Dedicated sidebar sessions. Tools auto-approve by default (configurable in Nexus); turn off **Auto-approve tools** to require approval. Auto-approval allows commands and file edits but doesn't alter global/project rules or bypass provider restrictions. |
| **Codex** | Installed, signed-in `codex` CLI | Native app-server, read-only sandbox, explicit approvals. |
| **Claude Code** | Installed, signed-in `claude` CLI | Print-mode streaming, tools and MCP disabled. Update the CLI if it lacks required flags; the adapter never bypasses safety flags. |
| **Ollama** | Running loopback HTTP server + an installed model selected in Nexus | Local chat without tools; HTTP restricted to loopback. `keep_alive: 0` unloads the model after each reply (less memory, slower next message). No models are downloaded automatically. |

**Reasoning effort** is saved per provider and applies on the next message. "Provider default" omits an override (OpenCode uses its model variant). Available levels depend on the model and CLI; OpenCode accepts a custom variant name, and Ollama offers thinking on/off plus model-specific low/medium/high. Unsupported values may be rejected, and higher effort can raise latency and cost.

<details>
<summary><b>Lifecycle, history, and privacy details</b></summary>

- The QML UI unloads on close; streaming updates are batched at 50 ms; history is bounded to 40 rows of up to 60,000 characters each.
- Idle adapters stop when the panel closes; an active reply finishes in the background. Provider switches wait for the active reply. The shared OpenCode service is never stopped by the panel.
- **New chat** interrupts the current response, clears the sidebar, and starts fresh. It does **not** delete the provider's saved transcript.
- **NUKE** (top navigation) additionally forgets all providers' cached messages and resume IDs for that screen, clears the draft, stops the adapter, and closes/unloads the UI. Provider-native history and shared services are untouched. It allows garbage collection; it is **not** secure memory zeroing.
- **Config:** `$XDG_CONFIG_HOME/caelestia/ai-panel.json` (fallback `~/.config/caelestia`; legacy enabled/geometry keys kept). Module assignments, per-side defaults, left-side geometry, and custom labels live in `sidebar-panel.json` in the same directory. Session IDs/directories live under `$XDG_STATE_HOME/caelestia`.
- Shell files store **no API keys or chat text**; provider tools keep their own credentials and transcripts.
- After a shell restart: OpenCode reloads its transcript, Codex/Claude resume native session IDs (old text isn't reloaded into the sidebar), Ollama starts with no prior context. Switching modules preserves AI history and drafts; disabling the AI module unloads its backend.
</details>

---

## ⌨️ Commands and shortcuts

### CLI (works with or without the bundled keybinds)

```bash
caelestia shell -d                       # start detached
caelestia shell -r                       # restart
caelestia shell -k                       # stop
caelestia shell -l                       # show logs
caelestia shell -s                       # list IPC commands
caelestia shell nexus open               # open Nexus
caelestia shell drawers toggle dashboard
caelestia shell drawers toggle launcher
caelestia shell drawers toggle notifShade
caelestia shell drawers toggle utilitySidebar   # Calendar on its assigned sidebar
```

### Bundled `hyprland.lua` shortcuts

| Shortcut | Action |
|---|---|
| `SUPER+X` | Nexus |
| `SUPER+D` | Dashboard |
| `SUPER+SUPER_L` (on release) | Launcher |
| `SUPER+L` | Lock |
| `SUPER+I` | Right sidebar |
| Tap `SUPER+SHIFT` | Toggle taskbar persistence |
| `SUPER+SHIFT+T` | Cycle taskbar style: Unified → Three notches → Center notch |
| `SUPER+SHIFT+T+O` | Toggle orientation Left ↔ Top (hold `T`, then press `O`) |
| `SUPER+ALT+1..4` | Media / Dashboard / Performance / Phone (subject to enabled tabs) |
| `SUPER+Q` / `SUPER+A` | Terminal / Yazi via the bundled wrapper |
| `SUPER+S` | Spotify scratchpad |
| `SUPER+SHIFT+R` | Toggle refresh rate |
| `SUPER+Escape` | ScrollOverview (when installed) |

See `hypr/hyprland.lua` for the complete, current list.

---

## 💾 Configuration, backups, and migration

The committed JSON files are **first-install presets**, not a synced copy of your Nexus changes. Seeding never overwrites live preferences. Paths honor `XDG_CONFIG_HOME` / `XDG_STATE_HOME`.

| Location | Contains |
|---|---|
| `~/.config/caelestia/shell.json` | Main Nexus preferences |
| `~/.config/caelestia/shell-tokens.json` | Font/size/style token overrides |
| `~/.config/caelestia/cli.json` | CLI options (incl. native-resolution recording) |
| `~/.config/caelestia/monitors/<output>/` | Per-monitor overrides (output names must match the new machine) |
| `~/.config/caelestia/weather.json` | Weather refresh interval |
| `~/.config/caelestia/calendar-url` | 🔒 Private calendar URL |
| `~/.local/state/caelestia/taskbar.json` | Orientation, style, center notch size |
| `~/.local/state/caelestia/shell-tint.json` | Custom tint, strength, enabled state |
| `~/.local/state/caelestia/hot-corner.json` | Overview hot-corner settings |
| `~/.local/state/caelestia/scheme.json` | Generated Material palette |
| `~/.local/state/caelestia/wallpaper/path.txt` | Current wallpaper's absolute path (not the image) |
| `~/.local/state/caelestia/notifs.json` | 🔒 Notification history (may contain private text) |
| `~/Pictures/Wallpapers`, `~/.face`, recordings | Your personal media |

**Migrating:** back up the live `caelestia` config/state directories privately and copy media separately. Reselect the wallpaper on the new machine rather than relying on an old absolute path. Keep the repo's Lua palette and generated Material palette consistent if using both.

> [!WARNING]
> Notes use Quickshell `PersistentProperties` for shell reloads and are **not** a documented, portable notes-file backup. Save important note text elsewhere before reinstalling.

> [!CAUTION]
> Never commit calendar secrets, notification history, or other private runtime data. To deliberately update this repo's presets, copy your live JSON into `caelestia/` and review the diff first.

---

## 🔄 Updating

```bash
repo="$HOME/OrangeDots"
git -C "$repo" status --short
git -C "$repo" pull --ff-only
```

- Back up live settings and inspect local edits first.
- With conflicting local edits, commit or back them up and resolve; **don't hard-reset**.
- Don't reseed live JSON over your preferences on every update.
- QML-only changes usually hot-reload. For a clean restart: `caelestia shell -r`
- After native-source, Qt, or Quickshell ABI changes, repeat [Step 4](#step-4--build-and-install-the-native-modules), then restart. A Qt upgrade may also require rebuilding `quickshell-git`.
- Update Hyprland plugins separately when Hyprland changes.

---

## 🩺 Troubleshooting

### Diagnostics first

```bash
caelestia shell -l
qs list --all
hyprctl monitors
hyprctl configerrors
```

Before sharing logs, strip credentials, private calendar URLs, notification text, and machine-specific info.

### Symptom guide

| Symptom | What to check |
|---|---|
| `module "Caelestia..." is not installed` / `M3Shapes` missing | Build/install this fork's native modules, not just the QML. Check install prefix and Qt import path. |
| CMake can't infer `VERSION` | Pass `-DVERSION=1.0.0`. `AYUSH_GOAT_V4` isn't a numeric CMake version. |
| `libcava`, `cava`, Qalculate, PipeWire, Aubio, or sensors missing | Install dev libraries; check pkg-config and `lm_sensors`; re-run CMake configure. |
| Qt symbol/ABI errors after upgrade | Rebuild Quickshell and native modules against the same Qt. Don't mix old packaged modules with this fork. |
| Config `caelestia` not found | `readlink -f ~/.config/quickshell/caelestia`. A top-level `quickshell/shell.qml` default config can interfere with discovery; back up and reconcile rather than deleting. Diagnose with `qs -p "$HOME/OrangeDots/quickshell/caelestia" -n`. |
| No taskbar | Preset is hover-to-reveal on the left. Check the left edge, monitor overrides, and **Persistent** in Nexus. |
| Two bars / notification-server registration errors | Remove duplicate autostarts; disable the competing notification daemon; restart only the relevant shell. |
| Wi-Fi / Bluetooth / audio controls missing | Check NetworkManager, `bluetooth.service`, PipeWire/WirePlumber, and your auth agent. |
| Icons are squares or literal names | Check Material Symbols Rounded and Nerd Font resolution; refresh font cache; restart. |
| Wallpaper/scheme errors | Choose an existing wallpaper via CLI. Regenerate state; don't copy another user's absolute path. |
| Login/config parse errors with full dotfiles | Confirm Lua-compatible Hyprland, adapt monitor/app paths, check ScrollOverview references. Return to your backup if needed. |
| Password feedback missing after wake until you click | A pending Wayland frame callback can strand lock rendering across sleep. Run `caelestia shell lock renderRecoveryStatus`, then see [lock-screen recovery](#-advanced-lock-screen-recovery-after-sleep). A restart alone isn't a confirmed fix. **Don't kill/restart the shell while locked.** |
| Recording doesn't start | Check `gpu-screen-recorder`, GPU support, audio devices, and the CLI recording command. |
| Recording is downscaled / low quality | **Services → Screen recorder → Reset to highest quality**, or ensure `~/.config/caelestia/cli.json` has `"record": {"extraArgs": ["-s", "0x0", "-q", "ultra", "-tune", "quality"]}`, then restart recording. |
| Calendar is empty | Check the private iCal URL file and network. The parser doesn't expand all recurring-event rules. |
| Pure-black preset still looks translucent | VOID sets tint strength, not opacity. Turn off **Transparency**. |

---

## 🔒 Advanced: lock-screen recovery after sleep

<details>
<summary><b>Expand for the native recovery workflow</b></summary>

### How it works

`LockRenderRecovery` discards a pending frame callback once after resume, restores Qt's exposure bookkeeping, and requests a frame. Later password edits trigger recovery **only if Qt reports a callback timeout**.

- Restricted to Quickshell session-lock windows.
- Never hides/recreates the surface, changes its protocol role, or unlocks/relocks.
- Password widget and PAM verification are unchanged.
- Private Qt layout reviewed for **6.12**. `supported:true` requires matching Qt build/runtime versions within that minor; other versions refuse recovery.
- Rebuild all affected native modules after any Qt upgrade, review the implementation before supporting a new minor, and don't suppress the private-API warning.

### Install the fix (existing manual install)

Run from a terminal in your **unlocked Wayland desktop** as your normal user:

```bash
repo="$HOME/OrangeDots"
bash "$repo/quickshell/caelestia/scripts/install-lock-render-recovery.sh" --check
bash "$repo/quickshell/caelestia/scripts/install-lock-render-recovery.sh"
caelestia shell lock renderRecoveryStatus
```

What the installer does:
- Requires this checkout's build configured with prefix `/usr`.
- Rebuilds `caelestia-coreplugin`, stages CMake install/RPATH changes without root.
- Backs up only `lib/libcaelestia-core.so`, `libcaelestia-coreplugin.so`, `qmldir`, `caelestia-core.qmltypes` to `${XDG_STATE_HOME:-$HOME/.local/state}/caelestia/native-backups/lock-render-*`.
- Refuses package-owned target files; prompts for sudo **locally**.
- Stops the unlocked shell, installs those four files, restarts, verifies native support, and arms temporary wake tracing.
- `--check` builds nothing, installs nothing, stops nothing, requests no privileges.
- Qt/Hyprland packages and other QML modules aren't replaced.

**On failure** it attempts rollback only after confirming no named shell remains running. If a relaunched shell has locked, or its state is unavailable, it refuses to stop/overwrite and prints the backup path. Never restore libraries manually under a running shell.

### Reading the status

- ✅ `"supported":true` with identical `qtBuild` / `qtRuntime`.
- `lockWindow:false` is expected (this query doesn't target a window).
- `"reason":"native plugin not rebuilt"` means the running process hasn't loaded the helper yet.

> [!IMPORTANT]
> Installation is **not proof the intermittent wake bug is fixed**. Test repeated real suspend/resume and hibernate/resume cycles, type before clicking, and inspect the trace. Re-arm tracing before each cycle (it disables itself on unlock). Never share your password.
</details>

---

## 🧹 Uninstall

1. Stop the shell: `caelestia shell -k`
2. Remove its autostart and binds.
3. Restore saved config entries from `~/.local/share/orangedots-backups/` (manual install) or `${XDG_STATE_HOME:-$HOME/.local/state}/orangedots/backups/` (installer).
4. Remove **only the symlinks you created**, not a whole config directory or the clone they point to.
5. Keep live state if you want your preferences later.

The native-module install is separate from the symlinks. Review `quickshell/caelestia/build/install_manifest.txt` and package ownership before removing system files. Don't recursively delete Qt's QML directory, and don't assume CMake provides an uninstall target.

---

## 🧪 Development

### Layout and install checks (safe: no real config touched)

```bash
python3 scripts/check-layout.py
python3 -m unittest discover -s tests -v
```

These validate an exported checkout at another path (including spaces), fresh/full installs, backups, existing preferences, legacy symlinks, and the CMake staged shell install. See [docs/STRUCTURE.md](docs/STRUCTURE.md) for the module map, compatibility boundary, and installed-tree checks.

### Integration tests

Run from the repo root, inside a Wayland session with native modules installed. They use isolated config/state and a transparent, input-free test surface.

```bash
python3 quickshell/caelestia/tests/integration.py                 # everything
python3 quickshell/caelestia/tests/integration.py --mode tint     # focused run
```

Coverage: taskbar orientation/styles, shell-attached notch geometry, popout sizing/hover, notification shade, Nexus navigation, recorder settings/persistence, lock-input recovery/focus, tint/VOID, persistence, invalid settings.

<details>
<summary><b>Lock-screen tests and wake tracing</b></summary>

Lock tests need Qt's `QtTest` QML module (in `qt6-declarative` on Arch). They deliver real Qt key events to the native password field in the isolated test window (no OS keyboard injection, no clicks before typing). They cover masking, Backspace/Ctrl+Backspace, Unicode editing, Enter/button handoff, repeated resume settling, early/duplicate unlock, and disabled animations. Submission routing uses a mock backend, and the real backend is checked to reject unsecured submissions. They never acquire the session lock or authenticate.

```bash
python3 quickshell/caelestia/tests/integration.py --mode lock-input
python3 quickshell/caelestia/tests/integration.py --mode lock-focus
```

To require the newly built native helper before installing it:

```bash
LOCK_REQUIRE_NATIVE=1 \
  QML_IMPORT_PATH="$PWD/quickshell/caelestia/build/qml" \
  python3 quickshell/caelestia/tests/integration.py --mode lock-input
QML_IMPORT_PATH="$PWD/quickshell/caelestia/build/qml" \
  python3 quickshell/caelestia/tests/integration.py --mode lock-focus
```

Native checks need supported, identical Qt build/runtime versions and verify recovery rejects ordinary layer-shell windows and absent targets. They do **not** acquire a real session-lock surface or reproduce a stalled compositor callback.

**Manual checks after changing the lock screen:** normal lock/unlock, suspend, and hibernate. On resume, type **before** clicking. Verify typing feedback, Backspace/Ctrl+Backspace, wrong-password feedback, and successful unlock on every attached display. Automated focus simulation can't reproduce a real GPU/compositor sleep cycle.

**Wake tracing** (opt-in) compares Qt focus, app state, masked-input presence, frame notifications, and native `framePending` / `callbackTimedOut` / exposure metadata before and after a click. It never records password text or length and never requests focus or repaints. Recovery runs independently of tracing. After replacing a native library, restart **while unlocked**, since live QML reloads don't replace a loaded native plugin.

```bash
caelestia shell lock traceWake          # arm before the manual sleep/wake test
caelestia shell lock wakeTrace          # after reproducing and unlocking
qs --no-color log -c caelestia -t 150
caelestia shell lock stopWakeTrace
```

`render-recovery` trace records include before/after native state; native messages use the `caelestia.lock.render` log category. Re-arm `traceWake` before each new sleep test.
</details>

### Weather helper tests (require Node.js)

```bash
node --test quickshell/caelestia/tests/weather.test.cjs
```

> [!NOTE]
> These checks don't replace testing your real GPU, audio devices, network permissions, recording, and lock/PAM behavior.

---

## 📁 Repository layout

| Path | Purpose |
|---|---|
| `install.sh`, `scripts/install.py` | Safe shell/full-dotfiles linking and preset seeding |
| `caelestia/*.json` | First-install shell, token, and CLI presets |
| `hypr/hyprland.lua` | Personal Hyprland config (Lua) |
| `hypr/scheme/current.lua` | Hyprland-side colour palette |
| `hypr/scripts/` | Shell toggle, Spotify scratchpad, hardware-specific refresh modes |
| `refresh-rate-toggle.sh` | Compatibility launcher for the moved refresh helper |
| `quickshell/caelestia/shell.qml` | Orange OS shell entry point |
| `quickshell/caelestia/modules/` | UI modules: taskbar, desktop, dashboard, settings, launcher, lockscreen, notifications |
| `quickshell/caelestia/services/` | Runtime services: tint, taskbar state, weather, notifications |
| `quickshell/caelestia/plugin/` | Native QML modules (rebuild when native code changes) |
| `quickshell/caelestia/assets/` | Fallback wallpaper, Google Sans Flex, PAM files, helper assets |
| `quickshell/caelestia/tests/` | Integration and weather tests |
| `scripts/check-layout.py`, `tests/test_installation.py` | Import/layout contract and isolated install checks |
| `docs/FEATURES.md`, `docs/STRUCTURE.md` | Feature inventory, module map, rename map, compatibility rules |

---

## 📄 License

The vendored shell under `quickshell/caelestia/` is a fork of Caelestia and keeps its **GPL-3.0** license and upstream notices. Orange OS branding doesn't change that. Top-level personal dotfiles are unrestricted: use and adapt them as you wish.
