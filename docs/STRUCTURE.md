# OrangeDots source layout

## Start here

| Working on… | Open… |
|---|---|
| A first installation or config links | `install.sh`, `scripts/install.py`, and the root `README.md` |
| Hyprland entry point / module load order | `hypr/hyprland.lua` — **Lua**, not `.conf` syntax |
| Apps and helper paths | `hypr/modules/settings.lua` |
| Alt+Tab overlay / MRU selection / keyboard handling | `quickshell/caelestia/modules/switcher/` |
| Keybinds / input and gestures / window rules | `hypr/modules/keybindings.lua`, `input.lua`, `rules.lua` |
| Appearance / animations / workspace layouts | `hypr/modules/appearance.lua`, `animations.lua`, `layouts.lua` |
| Monitor / startup / environment / plugins | `hypr/modules/monitors.lua`, `autostart.lua`, `environment.lua`, `plugins.lua` |
| Scratchpad / shell / refresh helpers | `hypr/scripts/` |
| First-run preferences | `caelestia/*.json` — committed presets, not private live state |
| Taskbar layout / clock / status icons | `quickshell/caelestia/modules/taskbar/` |
| Dashboard: Media / Dashboard / Performance / Phone | `quickshell/caelestia/modules/dashboard/` |
| Left/right sidebar containers / replaceable modules | `quickshell/caelestia/modules/sidebar/` |
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

Nexus always uses `taskbar/popouts/PopoutWrapper.qml`'s existing expansion/morph
overlay. The compatibility-named `settings/SettingsWindows.qml` routes Super+X,
IPC and module settings buttons to that per-screen host rather than constructing
a FloatingWindow. Helpers navigate the existing view to the requested page/stack;
Escape or the close button animates out and unloads it. `SettingsPages` discards
stale asynchronous page loads during rapid navigation.

`TaskbarLayout.qml` deliberately does **not** use the name `Taskbar.qml`:
`services/Taskbar.qml` is the existing settings singleton, and QML type names
must not collide with that imported singleton.

### Modular left/right sidebars

`modules/sidebar/SidebarWrapper.qml` is instantiated for each side and owns the
mirrored edge slides, sizing and hover-switching module tabs. Module changes use
a short crossfade/glide and only the selected module accepts input.
Non-AI module loaders are active only while the sidebar is visible and that
module's reveal/fade progress is nonzero. AI keeps a small state-owner instance
for conversation continuity, with a separate lazy chat-view loader. Shared
services hold notes, scratchpad drafts and running timers independently of views.
`ClipboardHistory` reference-counts live views and evicts its display cache after
three idle seconds; actions such as paste finish even if their initiating view
has already unloaded. Clipboard previews disable the shared decoded-image cache.
Its background is drawn by `DesktopWindow.qml` in the same `BlobGroup` as
the taskbar/dashboard, extended to the top shell edge so there is no detached gap.
The wrapper is top-aligned, including when a custom panel height is configured.
`services/SidebarStyle.qml` defines shared padding, gaps, card insets/rounding and
header sizing; `SidebarHeader.qml` renders the common icon/title/action header.
User-defined module labels are saved in `SidebarConfig.moduleLabels` and applied
to tabs, headers, the default-module picker and the Panels sidebar summary.

`SidebarModules.qml` registers the replaceable module components:

- `modules/sidebar/modules/ai/AiModule.qml` owns its `AiChatState` backend and lazily loads
  `AiChatContent.qml` when selected. Switching tabs retains the conversation,
  draft and in-flight reply; disabling the AI module unloads its backend.
- `modules/sidebar/modules/calendar/CalendarModule.qml` hosts `CalendarContent.qml`,
  the Google Calendar feed and shared scratchpad. Calendar is sidebar-only.
- `modules/sidebar/modules/clipboard/ClipboardModule.qml` uses `ClipboardHistory`
  and `utils/scripts/sidebar-clipboard.py` to access Caelestia's cliphist backend,
  with local pins, previews and confirmed clearing. No shell interpolation is used.
- `modules/sidebar/modules/focus/FocusModule.qml` uses the shared `FocusTimer`
  service; timers and optional taskbar countdowns outlive the visible module.
- `modules/sidebar/modules/notes/NotesModule.qml` uses `QuickNotes` for persistent
  plain-text notes (including links), todos and unfinished drafts. It is independent
  of the calendar's session-local scratchpad.

The dashboard contains only Media, Dashboard (`Overview.qml`), Performance and
Phone. Supporting recorder/quick-control cards live in `dashboard/overview/cards/`;
the obsolete `dashboard/utilities/` tree and Utilities settings page were removed.
Overview card and hot-corner settings live directly on the Dashboard Nexus page.
Calendar settings live under Sidebar → Modules → Calendar & notes.
The masked feed field uses `utils/scripts/calendar-url.py` to atomically save a
private `0600` calendar-url file. Existing secret URLs are not displayed or put
in normal preference JSON. `GoogleCalendar.qml` reads the file with FileView,
passes curl's URL through stdin, and invalidates stale fetches on replacement
or removal so the old feed cannot repopulate the agenda.

**Nexus → Panels → Sidebar** contains separate **Left sidebar** / **Right sidebar**
size/enable/default pages and a centralized **Modules** page for Left/Right/Off
assignments, labels and AI settings. Each module has one sidebar owner.
`services/SidebarConfig.qml` persists module choices in `sidebar-panel.json`.
Its right-side `layout` facade deliberately uses the existing `AiConfig` enabled/geometry
fields in `ai-panel.json`, so existing preferences and JSON keys remain valid.
`ScreenState.ai`, the `panels.ai` alias, `drawers toggle ai`, and Super+I remain
compatible; the composition layer also exposes `panels.sidebar` / `panels.rightSidebar`
and `panels.leftSidebar`. The left open state is `ScreenState.leftSidebar` and its
IPC name is `leftSidebar`; `rightSidebar` is an alias for the original `ai` IPC.
Left-side geometry, assignments and defaults live alongside existing settings
in `sidebar-panel.json`; upgrades preserve existing right-side assignments.

To add another module, create `modules/sidebar/modules/<id>/<Name>Module.qml`
with `screenState`, `selected`, and `closeRequested`; register its component in
`SidebarModules.qml`, add its ID/name in `SidebarConfig.modules`, and expose its
default choice in `settings/pages/panels/SidebarSidePanel.qml`. Central assignment
and label controls in `SidebarModulesPanel.qml` are generated from the registry. The generic
loader and tab strip require no changes.

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
| `modules/ai/` | `modules/sidebar/modules/ai/` (container: `modules/sidebar/SidebarWrapper.qml`) |

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
