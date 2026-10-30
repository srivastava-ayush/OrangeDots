# OrangeDots source layout

## Start here

| Working on… | Open… |
|---|---|
| A first installation or config links | `install.sh`, `scripts/install.py`, and the root `README.md` |
| Hyprland keybinds, rules, or gestures | `hypr/hyprland.lua` — **Lua**, not `.conf` syntax |
| Scratchpad / shell / refresh helpers | `hypr/scripts/` |
| First-run preferences | `caelestia/*.json` — committed presets, not private live state |
| Taskbar layout / clock / status icons | `quickshell/caelestia/modules/taskbar/` |
| Dashboard tabs / Google agenda / notes | `quickshell/caelestia/modules/dashboard/` |
| Window composition / edge hover / focus / input regions | `quickshell/caelestia/modules/desktop/` |
| Nexus settings pages | `quickshell/caelestia/modules/settings/` |
| Password field / session lock / wake recovery | `quickshell/caelestia/modules/lockscreen/` |
| New-notification banners vs history shade | `quickshell/caelestia/modules/notifications/banners/` vs `notifications/shade/` |
| Shared UI widgets | `quickshell/caelestia/components/` |
| Data, devices, and persistent state | `quickshell/caelestia/services/` |
| C++ / native QML modules | `quickshell/caelestia/plugin/` |
| Configuration/install regression tests | `tests/test_installation.py` |
| Running-shell integration tests | `quickshell/caelestia/tests/integration.py` |

## How the UI is assembled

```text
shell.qml
  ├─ Background
  ├─ Desktop                        one instance per screen
  │    ├─ ExclusiveZones            compositor-reserved screen edges
  │    └─ DesktopWindow             shared window, backgrounds, focus handling
  │         └─ PanelInteractions    pointer/drag/hover coordination
  │              ├─ PanelLayout    dashboard, launcher, banners, OSD, session menu
  │              └─ TaskbarWrapper → TaskbarLayout → components / popouts
  ├─ ScreenCapture → SelectionOverlay
  └─ LockScreen → LockSurface → LockView
```

Each panel has a feature-named wrapper/content pair, such as
`DashboardWrapper.qml` / `DashboardContent.qml` and `LauncherWrapper.qml` /
`LauncherContent.qml`. A wrapper owns loading, visibility, and geometry;
content owns the UI. This avoids searching through unrelated `Wrapper.qml`
and `Content.qml` files.

`TaskbarLayout.qml` deliberately does **not** use the name `Taskbar.qml`:
`services/Taskbar.qml` is the existing settings singleton, and QML type names
must not collide with that imported singleton.

## Rename map

Paths below are relative to `quickshell/caelestia/`.

| Previous source module | Canonical source module |
|---|---|
| `modules/bar/` | `modules/taskbar/` |
| `modules/drawers/` | `modules/desktop/` |
| `modules/nexus/` | `modules/settings/` |
| `modules/lock/` | `modules/lockscreen/` |
| `modules/areapicker/` | `modules/screencapture/` |
| `modules/osd/` | `modules/onscreendisplay/` |
| `modules/session/` | `modules/sessionmenu/` |
| `modules/notifications/` | `modules/notifications/banners/` |
| `modules/notifshade/` | `modules/notifications/shade/` |
| `modules/dashboard/dash/` | `modules/dashboard/overview/` |

Examples of entry-point renames:

- `Bar.qml` → `TaskbarLayout.qml`; `BarWrapper.qml` → `TaskbarWrapper.qml`.
- `Drawers.qml` → `Desktop.qml`; `ContentWindow.qml` → `DesktopWindow.qml`;
  `Interactions.qml` → `PanelInteractions.qml`; `Panels.qml` → `PanelLayout.qml`;
  `Regions.qml` → `InputRegions.qml`; `Exclusions.qml` → `ExclusiveZones.qml`.
- `Nexus.qml` → `SettingsView.qml`; `NexusState.qml` → `SettingsState.qml`;
  `WindowFactory.qml` → `SettingsWindows.qml`; `Pages.qml` → `SettingsPages.qml`;
  `NavPane.qml` → `SettingsNavigation.qml`; `PageCompRegistry.qml` → `PageComponents.qml`.
- Dashboard `Dash.qml` → `Overview.qml`, with explicit `DashboardContent`,
  `DashboardTabs`, and `DashboardWrapper` types.
- Notification `Notif*` types now use `Notification*` names; `Props.qml` in the
  shade is `ShadeState.qml`.
- `tests/taskbar.qml` → `tests/integration.qml`; `tests/taskbar.test.py` is a
  compatibility launcher for `tests/integration.py`.

At the repository level, Hyprland helpers live in `hypr/scripts/` as
`toggle-shell.sh`, `toggle-spotify.sh`, and `toggle-refresh-rate.sh`. The old
root `refresh-rate-toggle.sh` remains a compatibility launcher.

## Compatibility boundary — do not rename these casually

The source folder names above are developer-facing. The following remain
unchanged so existing installs, CLI packages, and native plugins keep working:

- `quickshell/caelestia/` and the installed Quickshell config name `caelestia`.
- `~/.config/caelestia`, XDG state/data/cache directories, JSON keys, and preset
  file names. For example, the taskbar's config key is still `bar`, not `taskbar`.
- Native `Caelestia`, `Caelestia.Config`, `Caelestia.Services`, etc. QML imports;
  native build targets, package names, and `/usr/lib/caelestia`.
- IPC targets such as `drawers`, `nexus`, `lock`, and `picker`, existing shortcut
  names, object names used by tests/automation, and persistent state identities.
- The Nexus display name and GPL-3.0 licensing of the vendored shell.

No old UI-module symlinks are needed: source imports and component types use the
canonical locations. CMake still installs the complete `modules/` tree
recursively. Native source/build directories were not moved.

## Reproduce an installation

After installing the documented dependencies and native modules:

```bash
bash install.sh --dry-run       # inspect the shell-only plan
bash install.sh                 # link the shell and seed missing presets
bash install.sh --full          # additionally link reviewed Hyprland dotfiles
```

The installer works from any current directory and clone location, preserves
existing preferences and private calendar files, backs up conflicting config
entries, and does not restart or stop a desktop session. It supports the old
whole-`quickshell` symlink layout as well as a named-config symlink. When an old
parent symlink points into another checkout, it backs up that symlink and
preserves other configs through individual links; it never moves the old
checkout's source files. Backups
default to `$XDG_STATE_HOME/orangedots/backups/` (or
`~/.local/state/orangedots/backups/`). `--config-home` and `--backup-dir` allow
explicit staging locations.

A fresh installation reproduces **committed source and presets**. It does not
copy secrets, notification history, transient notes, personal wallpapers,
machine-specific monitor capabilities, or independently installed system
packages. Keep those separate. Commit/push the renamed and new files before
cloning the updated layout on another machine.

## Validate future refactors

```bash
python3 scripts/check-layout.py
python3 -m unittest discover -s tests -v
python3 quickshell/caelestia/tests/integration.py
```

The first two checks need no real config installation or sudo. Installation
tests export the working source to a path containing spaces, use isolated homes,
check backups/idempotency/private-data preservation, and exercise CMake's actual
shell-only install into a staging directory. With Wayland/native modules
available, the staged QML also runs through the layout integration test.

To test an already staged/installed QML tree:

```bash
python3 scripts/check-layout.py --shell-root /path/to/quickshell/caelestia
python3 quickshell/caelestia/tests/integration.py \
  --shell-root /path/to/quickshell/caelestia --mode layout
```

When adding a module, use lowercase QML-import-safe directory names and
feature-specific PascalCase component names. Update all `qs.modules.*` and
relative imports, keep configuration/IPC names stable, and run these checks.
