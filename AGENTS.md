1# AGENTS.md

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
  hyprland.conf       Stub entry config; only sources generated binds (see below)
  scheme/current.lua  Active Material 3 colour palette (Lua table of hex colours)
  spotify-toggle.sh   Toggles Spotify scratchpad on special workspace "special:magic"
  maximize-window.sh  Window maximize helper
quickshell/
  toggle-shell.sh     Switches between Caelestia shell (`qs`) and dynamicIsland shell
  caelestia/          THE VENDORED SHELL — do not treat as third-party docs; it is the live code
    shell.qml         Shell root/entry point
    modules/          UI: bar, dashboard, launcher, lock, notifications, osd, session, drawers...
    services/         Singletons: Audio, Brightness, Colours, Hypr, Notifs, Players, Wallpapers...
    components/       Reusable styled widgets (StyledRect, StyledText, MaterialIcon...)
    utils/            Icons.qml, Paths.qml, Searcher.qml, scripts/ ...
```

## Critical facts

1. **Hyprland config is Lua** (`hypr/hyprland.lua`, ~480 lines). Uses an `hl.*` API: `hl.bind()`, `hl.config()`, `hl.window_rule()`, `hl.workspace_rule()`, `hl.gesture()`, `hl.dsp.*` (dispatchers as functions taking tables), `hl.exec_cmd()`. When editing keybinds/rules, mimic the existing Lua call style — do NOT paste classic `.conf` syntax.
2. **`hyprland.conf` sources external generated binds** at `/home/ayush/.config/tide-island/hyprland-shortcuts.conf` (managed by "Tide Island Config App", not in this repo). Those binds call Quickshell IPC (`quickshell ipc ... call tide ...`). Missing file = broken source, but the rest still loads.
3. **Two shells coexist**: the full Caelestia fork (launched via `caelestia shell -d`) and a minimal `dynamicIsland` shell (`quickshell -c dynamicIsland`). `quickshell/toggle-shell.sh` swaps them by killing/pinning processes (`qs` vs `quickshell.*dynamicIsland`) and restarting swww/hypridle/hyprpaper.
4. **Colours**: Material 3 scheme. `services/Colours.qml` reads scheme state from `${Paths.state}/scheme.json` at runtime; `hypr/scheme/current.lua` mirrors the active palette (dark teal/orange theme) as Lua. Changing theme means updating both consistently.
5. **Licensing matters**: everything under `quickshell/caelestia/` keeps its GPL-3.0 LICENSE (upstream Caelestia). Top-level dotfiles are unrestricted. Keep the vendored tree's license headers intact.
6. **Hardcoded paths**: some scripts/config reference absolute paths (`/home/ayush/...`). Be aware when porting or testing.

## Keybinds cheat-sheet (from hyprland.lua)

- Main mod: `SUPER`. Launcher `SUPER+SUPER_L`(release), dashboard `SUPER+D`, lock `SUPER+L`.
- Dashboard tabs: tap `SUPER+ALT` toggles the dashboard; held as a chord, `SUPER+ALT+1..4` jumps to Dashboard/Media/Performance/Notifications via IPC `drawers setTab <name>` (handler in `modules/Shortcuts.qml`).
- Apps: kitty `SUPER+Q`, code `SUPER+E`, thunar `SUPER+A`, brave `SUPER+W`.
- Spotify scratchpad: `SUPER+S` toggles `special:magic` (launches if not running); `SUPER+SHIFT+S` throws window there. Misc scratchpad: `SUPER+Z` / `SUPER+SHIFT+Z` → `special:misc`.
- Workspaces 1–2 use the **scrolling layout**; others dwindle. 3-finger vertical swipe switches workspaces, horizontal swipes move focus.
- Shell kill switch `SUPER+Delete`; overview plugin bind `SUPER+Escape`; Tide Island binds are the `SUPER+ALT+*` block at the bottom (generated section — keep the begin/end markers intact).

## Conventions

- Comments in configs are explanatory, wiki-linked where relevant — keep that style.
- Shell scripts are bash with `pgrep`/`pkill` process management; keep the scratchpad/daemon restart logic consistent.
- No build system for the dotfiles themselves. The vendored shell has a `CMakeLists.txt` (upstream packaging) but is normally run interpreted by quickshell — don't try to compile it.
- There is no test suite or linter wired up; validate changes by reloading (`hyprctl reload` for Hyprland, restarting the shell for QML).

## Common tasks

- **Add/change a keybind** → edit `hypr/hyprland.lua` using `hl.bind(...)`; check for collisions with existing binds above.
- **Change theme colour** → update `hypr/scheme/current.lua` and regenerate/set the matching Material 3 scheme so `Colours.qml` picks it up.
- **Tweak bar/dashboard/launcher UI** → look in `quickshell/caelestia/modules/<area>/`; shared widgets in `components/`.
- **Toggle shells** → `./quickshell/toggle-shell.sh`.
