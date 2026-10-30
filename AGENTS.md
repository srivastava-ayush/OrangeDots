# AGENTS.md

Guidance for AI agents working in this repository.

## What this is

Personal **Hyprland dotfiles** ("OrangeDots") plus a **vendored Quickshell shell** — a fork of [Caelestia](https://github.com/caelestia-dots/shell) living directly in this repo under `quickshell/caelestia/` (referred to as "OrangeShell"). Fully self-contained: one clone gets everything.

Target platform: Arch Linux + Hyprland (Wayland). Configs are symlinked into `~/.config`:

```bash
ln -s "$PWD/hypr"      ~/.config/hypr
ln -s "$PWD/quickshell" ~/.config/quickshell
```

## Repo map

```
hypr/
  hyprland.lua        Main Hyprland config — LUA-based, not .conf syntax
  scheme/current.lua  Active Material 3 colour palette (Lua table of hex colours)
  scripts/            toggle-shell.sh, toggle-spotify.sh, toggle-refresh-rate.sh
quickshell/
  caelestia/          THE VENDORED SHELL — do not treat as third-party docs; it is the live code
    shell.qml         Shell root/entry point
    modules/          UI: taskbar, desktop, dashboard, settings, launcher, lockscreen,
                      notifications/{banners,shade}, onscreendisplay, sessionmenu,
                      screencapture, background, windowinfo
    services/         Singletons: Audio, Brightness, Colours, Hypr, Notifs, Players, Wallpapers...
    components/       Reusable styled widgets (StyledRect, StyledText, MaterialIcon...)
    utils/            Icons.qml, Paths.qml, Searcher.qml, scripts/ ...
scripts/              Safe config installer and source/install layout checker
tests/                Isolated config-linking / fresh-export / CMake install tests
docs/STRUCTURE.md     Source map, rename map, and runtime compatibility boundary
```

## Critical facts

1. **Hyprland config is Lua** (`hypr/hyprland.lua`, ~490 lines). Uses an `hl.*` API: `hl.bind()`, `hl.config()`, `hl.window_rule()`, `hl.workspace_rule()`, `hl.gesture()`, `hl.dsp.*` (dispatchers as functions taking tables), `hl.exec_cmd()`. When editing keybinds/rules, mimic the existing Lua call style — do NOT paste classic `.conf` syntax.
2. **No Tide Island, no hyprpaper/hypridle config**: the old `hyprland.conf` stub (which sourced `~/.config/tide-island/hyprland-shortcuts.conf`) and the `hypridle/hyprlock/hyprpaper/monitors/workspaces` `.conf` files were all deleted. Everything now lives in `hyprland.lua`; the Caelestia shell handles lock (`SUPER+L`) and wallpapers (`caelestia wallpaper`). If you ever reintroduce Tide Island binds, add them to `hyprland.lua` with `hl.bind(...)`.
3. **Single shell**: the full Caelestia fork, launched via `caelestia shell -d` (autostarted from `hyprland.lua` `hyprland.start` handler). `hypr/scripts/toggle-shell.sh` toggles only this named shell; there is no alternate Dynamic Island shell.
4. **Colours**: Material 3 scheme. `services/Colours.qml` reads scheme state from `${Paths.state}/scheme.json` at runtime; `hypr/scheme/current.lua` mirrors the active palette (dark teal/orange theme) as Lua. Changing theme means updating both consistently.
5. **Licensing matters**: everything under `quickshell/caelestia/` keeps its GPL-3.0 LICENSE (upstream Caelestia). Top-level dotfiles are unrestricted. Keep the vendored tree's license headers intact.
6. **Portability and runtime names**: helpers resolve through `$XDG_CONFIG_HOME/hypr/scripts` (fallback `~/.config`). Keep `quickshell/caelestia`, native `Caelestia.*` imports, config/state names, JSON keys, IPC targets, and persistent identities stable. Source module folders were renamed for DX; see `docs/STRUCTURE.md`. Hardware modes/app choices still need review on another machine.

## Keybinds cheat-sheet (from hyprland.lua)

- Main mod: `SUPER`. Launcher `SUPER+SUPER_L`(release), dashboard `SUPER+D`, lock `SUPER+L`.
- Dashboard tabs: tap `SUPER+ALT` toggles the dashboard; `SUPER+ALT+1..5` selects Media/Dashboard/Performance/Phone/Calendar by name via IPC `drawers setTab <name>` (handler in `modules/Shortcuts.qml`).
- Apps: kitty `SUPER+Q`, Zed `SUPER+E`, Yazi `SUPER+A`, Helium `SUPER+W` (see Lua for current choices).
- Spotify scratchpad: `SUPER+S` toggles `special:magic` (launches if not running); `SUPER+SHIFT+S` throws window there. Misc scratchpad: `SUPER+Z` / `SUPER+SHIFT+Z` → `special:misc`.
- Workspaces 1–2 use the **scrolling layout**; others dwindle. 3-finger vertical swipe switches workspaces, horizontal swipes move focus.
- Refresh rate toggle `SUPER+SHIFT+R` runs `hypr/scripts/toggle-refresh-rate.sh`; review its output name/modes for another display.
- Auto power-mode refresh rate is handled outside this repo: systemd user unit `power-watcher.service` runs `~/bin/power-watcher.sh`, which calls `~/bin/refresh-rate.sh` on AC state change.

## Conventions

- Comments in configs are explanatory, wiki-linked where relevant — keep that style.
- Shell scripts are bash with `pgrep`/`pkill` process management; keep the scratchpad logic consistent.
- QML is interpreted; do not compile the dotfiles/UI. Native C++ QML modules under `plugin/` do require the documented CMake build, especially after Qt upgrades.
- Check source imports with `python3 scripts/check-layout.py`; config/install replication with `python3 -m unittest discover -s tests -v`; QML behavior with `python3 quickshell/caelestia/tests/integration.py` inside Wayland. Install tests use isolated homes and staged CMake output, never the real config.

## Common tasks

- **Add/change a keybind** → edit `hypr/hyprland.lua` using `hl.bind(...)`; check for collisions with existing binds above.
- **Change theme colour** → update `hypr/scheme/current.lua` and regenerate/set the matching Material 3 scheme so `Colours.qml` picks it up.
- **Tweak taskbar/dashboard/launcher UI** → look in `quickshell/caelestia/modules/<area>/`; shared widgets in `components/`. Use feature-specific `*Content.qml` / `*Wrapper.qml` names, not ambiguous bare `Content.qml` / `Wrapper.qml`.
