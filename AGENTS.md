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
  spotify-toggle.sh   Toggles Spotify scratchpad on special workspace "special:magic"
quickshell/
  caelestia/          THE VENDORED SHELL — do not treat as third-party docs; it is the live code
    shell.qml         Shell root/entry point
    modules/          UI: bar, dashboard, launcher, lock, notifications, osd, session, drawers...
    services/         Singletons: Audio, Brightness, Colours, Hypr, Notifs, Players, Wallpapers...
    components/       Reusable styled widgets (StyledRect, StyledText, MaterialIcon...)
    utils/            Icons.qml, Paths.qml, Searcher.qml, scripts/ ...
```

## Critical facts

1. **Hyprland config is Lua** (`hypr/hyprland.lua`, ~490 lines). Uses an `hl.*` API: `hl.bind()`, `hl.config()`, `hl.window_rule()`, `hl.workspace_rule()`, `hl.gesture()`, `hl.dsp.*` (dispatchers as functions taking tables), `hl.exec_cmd()`. When editing keybinds/rules, mimic the existing Lua call style — do NOT paste classic `.conf` syntax.
2. **No Tide Island, no hyprpaper/hypridle config**: the old `hyprland.conf` stub (which sourced `~/.config/tide-island/hyprland-shortcuts.conf`) and the `hypridle/hyprlock/hyprpaper/monitors/workspaces` `.conf` files were all deleted. Everything now lives in `hyprland.lua`; the Caelestia shell handles lock (`SUPER+L`) and wallpapers (`caelestia wallpaper`). If you ever reintroduce Tide Island binds, add them to `hyprland.lua` with `hl.bind(...)`.
3. **Single shell**: the full Caelestia fork, launched via `caelestia shell -d` (autostarted from `hyprland.lua` `hyprland.start` handler). There is no shell-toggling script — the old `dynamicIsland` alternative and both toggle scripts were removed as dead code.
4. **Colours**: Material 3 scheme. `services/Colours.qml` reads scheme state from `${Paths.state}/scheme.json` at runtime; `hypr/scheme/current.lua` mirrors the active palette (dark teal/orange theme) as Lua. Changing theme means updating both consistently.
5. **Licensing matters**: everything under `quickshell/caelestia/` keeps its GPL-3.0 LICENSE (upstream Caelestia). Top-level dotfiles are unrestricted. Keep the vendored tree's license headers intact.
6. **Hardcoded paths**: some scripts/config reference absolute paths (`/home/ayush/...`). Be aware when porting or testing.

## Keybinds cheat-sheet (from hyprland.lua)

- Main mod: `SUPER`. Launcher `SUPER+SUPER_L`(release), dashboard `SUPER+D`, lock `SUPER+L`.
- Dashboard tabs: tap `SUPER+ALT` toggles the dashboard; held as a chord, `SUPER+ALT+1..4` jumps to Dashboard/Media/Performance/Notifications via IPC `drawers setTab <name>` (handler in `modules/Shortcuts.qml`).
- Apps: kitty `SUPER+Q`, code `SUPER+E`, thunar `SUPER+A`, brave `SUPER+W`.
- Spotify scratchpad: `SUPER+S` toggles `special:magic` (launches if not running); `SUPER+SHIFT+S` throws window there. Misc scratchpad: `SUPER+Z` / `SUPER+SHIFT+Z` → `special:misc`.
- Workspaces 1–2 use the **scrolling layout**; others dwindle. 3-finger vertical swipe switches workspaces, horizontal swipes move focus.
- Refresh rate toggle `SUPER+R` (runs `refresh-rate-toggle.sh`); HyprGlass toggle `SUPER+G`; overview plugin bind is commented out at the top of the binds section.
- Auto power-mode refresh rate is handled outside this repo: systemd user unit `power-watcher.service` runs `~/bin/power-watcher.sh`, which calls `~/bin/refresh-rate.sh` on AC state change.

## Conventions

- Comments in configs are explanatory, wiki-linked where relevant — keep that style.
- Shell scripts are bash with `pgrep`/`pkill` process management; keep the scratchpad logic consistent.
- No build system for the dotfiles themselves. The vendored shell has a `CMakeLists.txt` (upstream packaging) but is normally run interpreted by quickshell — don't try to compile it.
- There is no test suite or linter wired up; validate changes by reloading (`hyprctl reload` for Hyprland, restarting the shell for QML).

## Common tasks

- **Add/change a keybind** → edit `hypr/hyprland.lua` using `hl.bind(...)`; check for collisions with existing binds above.
- **Change theme colour** → update `hypr/scheme/current.lua` and regenerate/set the matching Material 3 scheme so `Colours.qml` picks it up.
- **Tweak bar/dashboard/launcher UI** → look in `quickshell/caelestia/modules/<area>/`; shared widgets in `components/`.
