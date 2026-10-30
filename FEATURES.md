# OrangeShell — Features, Modules, and Components

OrangeShell is the custom [Caelestia](https://github.com/caelestia-dots/shell) fork vendored in **`quickshell/caelestia/`**. It is the live desktop shell for OrangeDots, running on **Quickshell, Qt 6, Wayland, and Hyprland**.

This is an inventory of the source in this checkout, including the custom dashboard, Game mode and weather cards, notification shade, Calendar/notes tab, phone integration, and Nexus settings. It documents implemented capabilities, not a promise that every optional feature is enabled or that every external dependency is installed. Unfinished and disconnected UI is identified separately.

## Contents

- [Shell architecture](#shell-architecture)
- [Feature catalog](#feature-catalog)
- [Shortcuts and IPC](#shortcuts-and-ipc)
- [UI module inventory](#ui-module-inventory)
- [Shared QML components](#shared-qml-components)
- [QML services](#qml-services)
- [Native QML modules](#native-qml-modules)
- [Utilities and supporting resources](#utilities-and-supporting-resources)
- [Configuration and persistent state](#configuration-and-persistent-state)
- [Dependencies and integration boundaries](#dependencies-and-integration-boundaries)
- [Unfinished, legacy, and disconnected pieces](#unfinished-legacy-and-disconnected-pieces)

## Shell architecture

The entry point is [`quickshell/caelestia/shell.qml`](quickshell/caelestia/shell.qml). Source watching is enabled, so QML changes can reload the shell automatically.

```text
shell.qml
├── GSFLoader             Bundled Google Sans Flex font
├── ServiceLoader         Eager initialization of essential singletons
├── Background            Per-screen wallpaper, visualiser, and desktop clock
├── Drawers               Per-screen shell window, bar, and sliding panels
│   ├── Bar               Left-side taskbar and its popouts
│   ├── Dashboard         Top panel: Media / Dashboard / Performance / Phone
│   ├── Launcher          Bottom application and action launcher
│   ├── Notifications     Top-right popup notifications
│   ├── NotifShade        Top-right grouped notification shade
│   ├── Sidebar           Bottom-right agenda and notes
│   ├── Osd               Right-side volume, microphone, and brightness sliders
│   └── Session           Right-side session/power menu
├── AreaPicker            Screenshot-selection overlays
├── Lock                  Wayland session lock and authentication
├── ConfigToasts          Configuration diagnostics
├── Shortcuts             Global-shortcut and IPC entry points
├── BatteryMonitor        Battery warnings and critical-level hibernation
└── IdleMonitors          Dimming, locking, sleep, and brightness restoration
```

Additional UI is opened on demand: **Nexus** is the settings interface, and **WindowInfo** is the expanded window inspector. QML singletons in `services/` provide shared state; C++ modules in `plugin/src/Caelestia/` supply native services, rendering, configuration, and models.

## Feature catalog

### Desktop layout and interaction

- A left-side vertical taskbar surrounded by a configurable, rounded desktop border.
- Sliding panels attached to the top, bottom, and right edges rather than separate applications for every utility.
- Material 3 colours, translucent surfaces, shadows, animated state changes, and deformable/blob-style panel backgrounds.
- Configurable hover activation and drag thresholds for supported panels; launcher, dashboard, shade, and session visibility can also be controlled through IPC.
- Click-away and Escape dismissal where supported, with keyboard focus handling that avoids stealing input for incidental corner hovers.
- Fullscreen-aware hiding, input regions, border transitions, and notification/toast policies, including special-workspace handling.
- A configurable **top-left overview hot corner** with activation size and delay. It calls the external Hyprland ScrollOverview plugin; it is not a built-in overview renderer.
- Per-screen panel state, monitor filtering, and per-monitor configuration/token overrides.

### Taskbar and popouts

- Configurable taskbar entries: logo/launcher button, workspaces, spacers, active window, clock, system tray, and status icons.
- Persistent visibility or edge-hover/drag reveal; persistence can be toggled at runtime.
- Workspace indicators with active highlighting/trails, occupied backgrounds, optional application icons, special workspaces, and per-monitor workspace display.
- Scroll over workspaces to change workspace; optional top-half volume scrolling and bottom-half brightness scrolling.
- Compact or expanded system tray, optional icon recolouring/backgrounds, hidden-icon filtering, and nested tray menus.
- Optional active-window title display, compact/inverted styling, a summary popout, and an expanded window inspector.
- Status indicators for speaker audio, microphone, keyboard layout, Caps/Num Lock, networking, Bluetooth, and battery, subject to configuration.
- Audio popout with output controls/device selection and access to Nexus audio settings.
- Wi-Fi/Ethernet popouts, wireless password entry, Bluetooth device information, and keyboard-layout information.
- Battery percentage and time estimates; power-profile selection for Power Saver, Balanced, and Performance when the system supports it, with degradation warnings.
- A clock popout containing a navigable month calendar, today highlighting, scroll-to-change-month, and return-to-today actions.
- Popouts can expand into a larger Nexus view or the window inspector where supported.

### Dashboard

The current tab order is **Media → Dashboard → Performance → Phone → Calendar**. Media, Dashboard, Performance, and Calendar can be hidden in configuration; Phone is currently always included. Tabs support buttons, horizontal swipes, and named IPC selection.

#### Dashboard tab

- User card with a selectable profile picture from `~/.face`, clock, date, and uptime.
- Arch package-update count using `checkupdates`, refreshed every 30 minutes while the user card is loaded. Clicking the update row opens `kitty -e sudo pacman -Syu`.
- Logout, suspend, hibernate, reboot, and shutdown buttons.
- A shared row of three utility cards:

  | Card | Behaviour |
  |---|---|
  | **Caffeine** | Toggles the Wayland idle inhibitor and shows when it was enabled. Its visibility follows `utilities.cards.keepAwake`. |
  | **Blackout** | Turns the display off and inhibits the lid switch so audio/network activity can continue with the lid closed. Shell idle actions pause while active; disabling it restores the display and releases the inhibitor. |
  | **Game mode** | Disables Hyprland animations, shadows, blur, gaps, and rounding, sets a one-pixel border, and enables tearing. Disabling it reloads Hyprland's configured settings. This is a compositor-effects mode, not Feral GameMode or a CPU-governor switch. |

- Screen-recorder card with full-screen/region and with/without-audio choices, pause/resume, stop, elapsed time, and recording history. Its visibility follows `utilities.cards.recorder`.
- Recording history can expand/collapse, play a recording, and reveal it in the configured file manager. A delete button is present, but its confirmation/deletion flow is not currently wired up.
- Weather sits **beside the screen recorder** in the row below the utility toggles. The recorder uses a compact two-row header at narrower widths, giving the weather more room without widening the dashboard. Each card can be hidden independently, and the remaining card fills the row.

#### Media tab — OrangePod

- MPRIS integration with multiple players, a preferred default player, player-name aliases, and manual player selection.
- An iPod-style click wheel: shuffle, previous/next, play/pause, centre playback button, circular scrubbing, and an outer track-progress ring, subject to the player's supported controls.
- Rotating album art, track title, artist/album information, position/duration display, seek slider, and loop controls.
- Mouse-wheel volume adjustment with a temporary volume HUD.
- An audio-reactive visualiser strip. These bars are visualisation, not an audio equalizer.
- Synced lyrics with current-line tracking, scrolling, and click-to-seek; loading/empty states and backend/candidate/offset information.
- Native lyrics backends: **Auto, Local, LRCLIB, and NetEase**; the preferred backend is configurable through Nexus.
- Now-playing toasts, including handling for players that populate title and artist metadata at different times, and a YouTube artwork fallback when possible.

#### Performance tab

- Independently configurable CPU, GPU, memory, storage, network, and battery widgets.
- CPU/GPU names, usage gauges, and temperatures. GPU support depends on the selected Auto/NVIDIA/Generic/None backend and the hardware.
- Memory usage and storage capacity/usage displays.
- Network upload/download rates, transfer totals since tracking began, and a recent-history sparkline. The network service aggregates non-loopback interfaces.
- An animated battery-tank display with charge percentage, charging state, and remaining-time estimate on systems with a laptop battery.
- Configurable resource polling, lazy widget loading, and reference-counted native service activation.
- A clear empty state when no applicable performance widgets are enabled.

#### Phone tab

- KDE Connect paired-device discovery, device selection, reachable/offline status, and battery reporting.
- Refresh/scan and a shortcut to the external KDE Connect pairing/management application.
- Quick actions for ringing, pinging, clipboard sending, phone lock/unlock, and browsing shared phone folders. Availability depends on the phone's KDE Connect plugins and permissions.
- Send a selected file or share a link/text message.
- Open the external KDE Connect SMS application.
- Action-result and error feedback, with periodic refresh while the phone panel is loaded.
- Shared-folder browsing uses KDE Connect's SFTP D-Bus interface and opens the result in Thunar; pairing and SMS are delegated to KDE Connect, not reimplemented inside the shell.

### Weather

- An Open-Meteo weather card with current temperature/conditions, day/night icons, feels-like temperature, humidity, and wind speed.
- A wide, compact layout places current conditions and the forecast side by side to keep the recorder/weather row's height down.
- A three-day outlook with weather icons, daily high/low temperatures, and rain probabilities, plus last-update status and provider attribution.
- No API key or automatic location tracking. Set a city name or exact `latitude, longitude` in **Nexus → Panels → Dashboard → Weather**; the card's settings button opens that dashboard settings page directly.
- Weather visibility, Celsius/Fahrenheit (with km/h/mph), a 5–180 minute refresh interval, resolved-location information, and manual refresh are configurable in Nexus.
- City names resolve to the provider's first matching location; check the resolved name and use coordinates when a city name is ambiguous.
- Network requests are made only while a weather card or its dashboard settings page is loaded and a location is configured. Recent forecasts are reused when reopening the dashboard; city coordinates are reused for subsequent refreshes.
- Requests have timeouts and stale-response cancellation. Failed refreshes keep the last successful forecast with an update-failed indicator; changing/clearing the location removes the old location's data.
- The existing native `dashboard.showWeather`, `services.weatherLocation`, and `services.useFahrenheit` settings are reused. Refresh frequency is stored separately in `weather.json`, so the feature requires no native plugin rebuild.

### Notifications and toasts

- An integrated desktop notification server supporting actions, body markup, hyperlinks, images, urgency, expiry, and persistent notification data.
- Animated top-right popup notifications and a separate **Android-style notification shade**.
- Shade activation by top-right hover/vertical drag or IPC, with a scrollable, height-capped panel.
- Grouping by application, collapsed/expanded groups, swipe-to-clear interactions, notification actions, a notification count, and animated clear-all.
- Do Not Disturb controls in the shade and through IPC; fullscreen popup policies are configurable separately.
- Notification history saved to `notifs.json` and restored on startup.
- Info, success, warning, and error toasts with configurable limits and fullscreen policy.
- Optional event toasts for configuration loading, charging changes, Game mode, DND, input/output device changes, keyboard-lock/layout changes, VPN changes, and now-playing events.
- Configuration parse/save failures and unknown options are surfaced as diagnostic toasts.

### Calendar and notes dashboard tab

- A dashboard tab opened through its tab button, `SUPER+ALT+5`, or `caelestia shell drawers setTab calendar`. The former bottom-right hover/drag trigger has been removed.
- A seven-day Google Calendar agenda read from a private iCalendar URL, without an OAuth login flow.
- All-day and timed events, day grouping, current-event highlighting, manual refresh, scheduled refresh, and empty/error states.
- A multiline notes scratchpad with wrapping, text selection, scrolling, and keyboard focus that keeps the panel open while editing.
- Independent agenda and notes visibility and a screen-relative height cap, configured under **Nexus → Panels → Dashboard → Calendar & notes**. Existing `sidebar.enabled`, `sidebar.showAgenda`, and `sidebar.showNotes` settings are reused, so no native plugin rebuild is needed.
- Notes are held in a shared singleton so tab switching and closing/reopening the dashboard do not lose the draft. They survive Quickshell reloads through `PersistentProperties`; they are **not** a durable notes-file or cloud-sync feature.
- Calendar parsing does not expand recurring-event `RRULE`s, and `TZID`-qualified times are treated as local wall time. It is a read-only agenda, not a calendar editor.

### Application and action launcher

- Installed desktop-application search, launch-frequency ranking backed by SQLite, favourite apps, hidden apps, and terminal-application launching.
- Configurable fuzzy search independently for apps, actions, schemes, Material 3 variants, and wallpapers.
- Arrow-key navigation and optional Vim-style/Ctrl+J/K/N/P and Tab navigation.
- A configurable action prefix, **`>` by default**, with these built-in actions:

  | Action | Capability |
  |---|---|
  | `>calc …` | Asynchronous Qalculate expressions, copy result to clipboard, or open interactive `qalc` in a terminal. |
  | `>scheme …` | Search and switch colour schemes. |
  | `>variant …` | Search and switch Material 3 scheme variants. |
  | `>wallpaper …` | Browse/search wallpaper thumbnails with live wallpaper and dynamic-colour previews. |
  | Random, Light, Dark | Random wallpaper and light/dark theme actions. |
  | Lock, Sleep, Settings | Lock, suspend-then-hibernate, or open Nexus. |
  | Shutdown, Reboot, Logout | Dangerous actions, hidden unless explicitly enabled. |

- User-configurable actions with names, descriptions, icons, commands, enable flags, and dangerous-action flags.
- Special application-search filters, using the configurable **`@` default prefix**: `@i` desktop ID, `@c` category, `@d` description, `@e` executable, `@w` startup class, `@g` generic name, `@k` keywords, and `@t` terminal apps. Use a space before the search term, for example `@c development`.

### Nexus settings

Nexus can be opened as a floating window or expanded from supported taskbar popouts. It has category navigation and nested subpages. Implemented settings modify the live configuration; the native backend watches the JSON files and automatically saves changes.

| Page / area | Implemented controls |
|---|---|
| **Wallpaper & style** | Wallpaper enablement, local/category browsing, image-file selection, random wallpaper, transparency, and light/dark theme. The dedicated Colours subpage is unfinished. |
| **Network** | Wi-Fi radio control, available/saved network lists, filters for saved/secured/2.4 GHz/5 GHz networks, password entry, hidden/open/personal-security network creation, connect/disconnect/forget, autoconnect, connection information, and IPv4/DNS configuration. |
| **Ethernet subpages** | Interface/connection information, connect/disconnect, IPv4 method, manual address/gateway, DNS, and apply controls. |
| **VPN** | Add/edit/delete/select providers, connect/disconnect, interface/status information, statistics/ping, built-in command templates for WireGuard/WARP/Tailscale/NetBird, and custom connect/disconnect commands. External providers must be installed/configured. |
| **Connected devices** | Bluetooth adapter control, discovery/pairing, saved devices, connect/disconnect/forget, discoverable/pairable settings, trust/block/wake permissions, and device battery/address information. |
| **Audio** | Default output/input device selection, volume/mute, and individual application-stream volumes/mutes. |
| **Power & sleep** | Idle dim/lock/sleep stages, dim brightness, timeouts, suspend/hibernate/suspend-then-hibernate action, lock-before-sleep, audio/charging inhibition, and critical-battery threshold. Systemd sleep/lid settings are displayed read-only. |
| **Panels** | Dashboard tabs/widgets and weather visibility/location/units/refresh, taskbar behaviour/components, launcher behaviour/search, Calendar/notes tab, notification shade, and utility-card settings. Some inherited utility switches have no corresponding live quick-toggle grid. |
| **Taskbar subpages** | Workspace rendering, active-window presentation, tray styling/compactness, status-icon selection, clock, hover popouts, and scroll actions. |
| **Apps** | Default application commands, application library, favourites, hidden apps, and desktop-entry details. Regex-based favourite/hidden rules are identified rather than silently overwritten. |
| **Services** | Media/resource/network polling, lyrics backend, preferred player, volume/brightness increments, volume limit, visualiser bar count, smart wallpaper-derived schemes, and GPU backend. |
| **Notifications** | Popup/fullscreen/expiry/expansion behaviour, timing/group limits, toast settings, and event-toast switches. |
| **Language & region** | System-locale information, Celsius/Fahrenheit, and 12/24-hour time. This is not currently a UI-language picker. |
| **About** | System/hardware/software information, shell/Qt version information, and credits/plugin information. |
| **Updates / Plugins** | Navigation entries exist, but both pages are placeholders, not working package/plugin managers. |

### Wallpapers, theming, and desktop background

- Wallpaper rendering and transitions are handled by OrangeShell, not hyprpaper.
- Recursive wallpaper discovery, directory-based categories, search, random selection, cached image loading, and a bundled fallback wallpaper.
- Wallpaper selection from Nexus, the launcher, IPC, or the external `caelestia wallpaper` command.
- Preview wallpaper/theme colours before applying them; optional smart scheme selection based on the wallpaper.
- Material 3 palette loading from runtime `scheme.json`, light/dark modes, transparent palette layers, wallpaper-luminance-aware surfaces, and Hyprland blur-rule updates.
- Configurable design tokens for typography, icon fonts, component dimensions, rounding, spacing, padding, transparency, and animation curves/durations.
- A bundled Google Sans Flex variable font, Material Symbols icons, and Nerd Font usage in selected UI.
- Optional desktop clock with scale, nine screen positions, colour inversion, shadow, and background/blur options.
- Optional desktop audio visualiser with spacing/rounding/blur controls and auto-hide when tiled windows occupy the workspace.

### Lock screen and authentication

- A compositor-backed Wayland session lock, with a lock surface for each screen.
- Profile/clock/password UI, keyboard-lock state feedback, authentication messages, and animated lock/unlock transitions.
- Wallpaper or captured-desktop background, blur, and dimming.
- PAM password authentication; optional fingerprint authentication through fprintd and face authentication through Howdy, with availability detection, retry limits, and configurable wake behaviour.
- Sleep/resume integration that settles lock geometry without replaying an entrance animation during suspend/resume.
- IPC/global-shortcut lock control and automatic locking through idle or system sleep events.
- The current lock content is centre-only; the additional media/notification source components are not placed in that layout.

### Screenshots and recording

- Per-screen screenshot overlays with pointer-based window highlighting or a freely dragged selection rectangle.
- Live capture or freeze-before-select modes, with Escape cancellation.
- Capture to the external Swappy editor or directly to the clipboard through `wl-copy`; clipboard captures also produce a desktop notification.
- Screen recording through `caelestia record` and `gpu-screen-recorder`, exposed by the dashboard recorder card and external keybinds.
- Custom shared file dialogs for profile images, wallpapers, and phone-file sharing, with directory navigation, filtered selection, and accept/cancel handling.

### Power, idle, and hardware controls

- Speaker and microphone volume/mute state, default-device selection, application-stream controls, output cycling, and device-change toasts through PipeWire.
- An on-screen display with interactive volume, optional microphone, and optional per-screen brightness sliders; it reacts to changes and supports wheel adjustment.
- Brightness via `brightnessctl`, DDC/CI via `ddcutil`, and optional Apple Studio Display support via `asdbctl`; monitor selection supports active output, name, ID, model, or serial.
- Idle dimming and brightness restoration, with animated transitions and respect for manual brightness adjustments made while dimmed.
- Configurable idle locking/sleep, audio-playback and charging exemptions, and Wayland idle inhibition through Caffeine.
- Blackout pauses the shell's idle actions in addition to inhibiting the lid switch; it is distinct from Caffeine and normal idle dimming.
- Battery threshold warnings, charging-change notifications, and a five-second delayed hibernation request at the configured critical level.
- Session menu for logout, shutdown, hibernate, and reboot, with configurable commands/icons, keyboard navigation, and a configurable animated image. Suspend is also available from the dashboard and idle controls.
- Native systemd/logind session integration, including suspend-then-hibernate and sleep/resume signals.

### Window inspection and Hyprland integration

- Active-window preview and metadata inspection in an expanded popout.
- Window actions to move to a workspace, switch between tiled/floating, pin/unpin floating windows, and kill the selected window.
- Workspace and special-workspace discovery/cycling, focused-monitor tracking, dynamic configuration updates, and keyboard-device/layout/lock-state tracking.
- Hyprland IPC helpers account for the Lua-based configuration API used by this setup while retaining compatibility paths for classic Hyprland dispatch syntax.

## Shortcuts and IPC

### OrangeDots keybinds

Bindings are defined in [`hypr/hyprland.lua`](hypr/hyprland.lua), not inside a classic `.conf` file. The following shell-related bindings are present in the current file; they are separate from the shell's registered global-shortcut names.

| Binding | Action |
|---|---|
| `SUPER+SUPER_L` on release | Toggle launcher. |
| `SUPER+D` on release | Toggle dashboard. |
| Tap `SUPER+ALT` | Toggle dashboard. |
| `SUPER+ALT+1..5` | Select Media / Dashboard / Performance / Phone / Calendar by name. Disabled dashboard tabs are omitted from the visible strip. |
| `SUPER+P` | Open Performance. |
| Tap `SUPER+SHIFT` | Toggle taskbar persistence. |
| `SUPER+L` | Lock session. |
| `SUPER+X` | Open Nexus. |
| `SUPER+TAB` | Open the launcher's wallpaper picker. |
| `SUPER+CapsLock` | External Caelestia region-screenshot command. |
| `SUPER+ALT+CapsLock` | External Caelestia region-recording command with sound. |

The top-left hot corner and `SUPER+Escape` use the separately installed ScrollOverview plugin. Clipboard, emoji, Spotify scratchpads, refresh-rate switching, and Hyprland window-management bindings belong to the surrounding dotfiles/CLI integration rather than additional OrangeShell UI modules.

### IPC targets

Use **`caelestia shell <target> <function> [arguments…]`**. `caelestia shell -s` lists the targets available in the running instance; lazily loaded services may only register their handlers after loading.

| Target | Functions implemented in QML |
|---|---|
| `drawers` | `list()`, `toggle(drawer)`, `isOpen(drawer)`, `toggleBarPersistent()`, `setTab(tab)`; tab names are `media`, `dashboard`, `performance`, `phone`, `calendar`. |
| `nexus` | `open()`. |
| `wallpapers` | `pick()` — open the launcher's wallpaper browser. |
| `wallpaper` | `get()`, `set(path)`, `list()` — current selection and discovered files. |
| `lock` | `lock()`, `unlock()`, `isLocked()`. |
| `picker` | `open()`, `openFreeze()`, `openClip()`, `openFreezeClip()`. |
| `mpris` | `list()`, `getActive(prop)`, `play()`, `pause()`, `playPause()`, `previous()`, `next()`, `stop()`. |
| `notifs` | `clear()`, `isDndEnabled()`, `toggleDnd()`, `enableDnd()`, `disableDnd()`. |
| `gameMode` | `isEnabled()`, `toggle()`, `enable()`, `disable()`. |
| `idleInhibitor` | `isEnabled()`, `toggle()`, `enable()`, `disable()`. |
| `blackout` | `toggle()`, `disable()`. |
| `brightness` | `get()`, `getFor(query)`, `set(value)`, `setFor(query, value)`; absolute/relative percentage and fractional formats are accepted. |
| `hypr` | `refreshDevices()`, `cycleSpecialWorkspace(direction)`, `listSpecialWorkspaces()`. |
| `audio` | `cycleOutput()`. |
| `kdeconnect` | `status()`, `refresh()`, `ping()`, `browse()`. |
| `toaster` | `info(title, message, icon)`, `success(…)`, `warn(…)`, `error(…)`. |

Examples:

```bash
caelestia shell drawers toggle notifShade
caelestia shell drawers setTab calendar
caelestia shell drawers setTab phone
caelestia shell gameMode toggle
caelestia shell idleInhibitor toggle
caelestia shell brightness setFor active '+10%'
caelestia shell mpris getActive trackTitle
caelestia shell nexus open
```

The shared `ScreenState` exposes these drawer names: `bar`, `osd`, `session`, `launcher`, `dashboard`, and `notifShade`. The legacy `drawers toggle utilitySidebar` and `isOpen utilitySidebar` commands remain aliases for the dashboard's Calendar tab. Opening a disabled panel does not override its configuration; fullscreen guards also apply to several drawer actions.

Registered global-shortcut names include `nexus`, `showall`, `dashboard`, `session`, `launcher`, `launcherInterrupt`, `lock`, `unlock`, `screenshot`, `screenshotFreeze`, `screenshotClip`, `screenshotFreezeClip`, `clearNotifs`, `mediaToggle`, `mediaPrev`, `mediaNext`, `mediaStop`, `brightnessUp`, `brightnessDown`, and `refreshDevices`.

## UI module inventory

All paths below are relative to **`quickshell/caelestia/`**. Every QML file under `modules/` is listed; directory rows group related implementation pieces, not separate independently running shells.

| Directory | QML files | Responsibility |
|---|---|---|
| `modules/` | `BatteryMonitor.qml`, `ConfigToasts.qml`, `GSFLoader.qml`, `IdleMonitors.qml`, `ServiceLoader.qml`, `Shortcuts.qml` | Startup, monitoring, font loading, diagnostics, shortcuts, and IPC. |
| `modules/areapicker/` | `AreaPicker.qml`, `Picker.qml` | Screenshot lifecycle, per-screen overlays, and selection/capture UI. |
| `modules/background/` | `Background.qml`, `DesktopClock.qml`, `Visualiser.qml`, `Wallpaper.qml` | Background windows, clock, audio visualiser, and wallpaper rendering. |
| `modules/bar/` | `Bar.qml`, `BarWrapper.qml` | Taskbar entry layout, visibility, and interaction wrapper. |
| `modules/bar/components/` | `ActiveWindow.qml`, `Clock.qml`, `OsIcon.qml`, `Power.qml`, `StatusIcons.qml`, `Tray.qml`, `TrayItem.qml` | Taskbar widgets; `Power.qml` is retained but not selected by the current bar delegate. |
| `modules/bar/components/status/` | `BatteryStatus.qml`, `BluetoothStatus.qml`, `LockStatus.qml` | Hardware/keyboard status indicators. |
| `modules/bar/components/workspaces/` | `SpecialWorkspaces.qml`, `Workspace.qml`, `Workspaces.qml` | Normal/special workspace indicators and window icons. |
| `modules/bar/popouts/` | `ActiveWindow.qml`, `AudioPopout.qml`, `Battery.qml`, `Bluetooth.qml`, `CalendarPopout.qml`, `ClipWrapper.qml`, `Content.qml`, `LockStatus.qml`, `Network.qml`, `PopoutState.qml`, `TrayMenu.qml`, `WirelessPassword.qml`, `Wrapper.qml` | Popout content, clipping, state, password entry, menus, and detached views. |
| `modules/bar/popouts/kblayout/` | `KbLayout.qml`, `KbLayoutModel.qml` | Keyboard-layout display/model. |
| `modules/dashboard/` | `Calendar.qml`, `Content.qml`, `Dash.qml`, `Media.qml`, `Performance.qml`, `Phone.qml`, `Tabs.qml`, `Wrapper.qml` | Dashboard panel, tab composition, and the five main panes. |
| `modules/dashboard/dash/` | `User.qml`, `WeatherCard.qml` | Profile, updates, uptime, clock, power actions, and the recorder-adjacent weather card. |
| `modules/dashboard/media/` | `ClickWheel.qml`, `Details.qml`, `EqBars.qml`, `LyricList.qml`, `LyricsAndSelector.qml`, `LyricsInfo.qml` | OrangePod controls, metadata, visualiser, synced lyrics, and player selection. |
| `modules/dashboard/performance/` | `BatteryTank.qml`, `HeroCard.qml`, `MemoryCard.qml`, `NetworkCard.qml`, `StorageCard.qml` | Performance and battery cards. |
| `modules/dashboard/utilities/` | `Props.qml` | Retained utility-panel state helper; the current Dash owns its recorder state directly. |
| `modules/dashboard/utilities/cards/` | `BlackoutCard.qml`, `GameModeCard.qml`, `IdleInhibit.qml`, `Record.qml`, `RecordingList.qml` | Caffeine/Blackout/Game mode, recording controls, and recording history. |
| `modules/drawers/` | `ContentWindow.qml`, `Drawers.qml`, `Exclusions.qml`, `Interactions.qml`, `Panels.qml`, `Regions.qml` | Per-screen window composition, reserved space, focus, input regions, border rendering, and edge/corner gestures. |
| `modules/launcher/` | `AppList.qml`, `Content.qml`, `ContentList.qml`, `WallpaperList.qml`, `Wrapper.qml` | Search input, result lists, wallpaper browser, and launcher panel. |
| `modules/launcher/items/` | `ActionItem.qml`, `AppItem.qml`, `CalcItem.qml`, `SchemeItem.qml`, `VariantItem.qml`, `WallpaperItem.qml` | Launcher result delegates. |
| `modules/launcher/services/` | `Actions.qml`, `Apps.qml`, `M3Variants.qml`, `Schemes.qml` | Launcher-specific search providers and action/app launching. |
| `modules/lock/` | `Center.qml`, `Content.qml`, `Lock.qml`, `LockSurface.qml`, `Media.qml`, `NotifGroup.qml`, `Pam.qml` | Session-lock lifecycle, authentication, surfaces, centre UI, and retained media/notification pieces. |
| `modules/lock/center/` | `Clock.qml`, `InputField.qml`, `PasswordInput.qml`, `ProfilePic.qml`, `StateMessage.qml` | Lock-screen clock, profile, animated credential input, and state feedback. |
| `modules/nexus/` | `NavPane.qml`, `Nexus.qml`, `NexusState.qml`, `PageCompRegistry.qml`, `PageRegistry.qml`, `Pages.qml`, `WindowFactory.qml` | Settings window, navigation, page routing, and shared view state. |
| `modules/nexus/common/` | `AnimatedLogo.qml`, `AudioDeviceList.qml`, `BlobPopup.qml`, `ConnectedRect.qml`, `DialogRowButton.qml`, `DialogSelectButton.qml`, `EthernetSection.qml`, `InfoRow.qml`, `ItemList.qml`, `ListEditor.qml`, `NavRow.qml`, `NetworkList.qml`, `PageBase.qml`, `PopupRow.qml`, `RowButton.qml`, `SectionHeader.qml`, `SelectRow.qml`, `SliderRow.qml`, `StackPage.qml`, `StepperRow.qml`, `TextFieldRow.qml`, `ToggleRow.qml`, `WallItem.qml` | Nexus-local reusable rows, lists, page containers, popups, device/network widgets, and wallpaper tiles. |
| `modules/nexus/navpane/` | `NavLocations.qml` | Settings navigation locations. |
| `modules/nexus/pages/` | `AboutPage.qml`, `AppsPage.qml`, `AudioPage.qml`, `BluetoothPage.qml`, `LanguageAndRegion.qml`, `NetworkPage.qml`, `PanelsPage.qml`, `PowerAndSleepPage.qml`, `ServicesPage.qml`, `WallpaperAndStyle.qml` | Main implemented settings pages. |
| `modules/nexus/pages/apps/` | `AllApps.qml`, `AppInfo.qml` | Application browsing and per-app settings. |
| `modules/nexus/pages/audio/` | `AppVolumes.qml` | Application-stream volume/mute controls. |
| `modules/nexus/pages/bluetooth/` | `BluetoothPairing.qml`, `BtDeviceInfo.qml` | Pairing and device-specific controls. |
| `modules/nexus/pages/network/` | `AddNetworkPage.qml`, `AddVpnPage.qml`, `AllNetworksPage.qml`, `EthernetDetailPage.qml`, `NetworkDetailPage.qml`, `SavedNetworksPage.qml` | Network creation/filtering, saved profiles, IPv4 details, and VPN-provider editing. |
| `modules/nexus/pages/panels/` | `CalendarNotesPanel.qml`, `DashboardPanel.qml`, `LauncherPanel.qml`, `NotificationShadePanel.qml`, `TaskbarPanel.qml`, `UtilitiesPanel.qml` | Shell-panel configuration. |
| `modules/nexus/pages/panels/taskbar/` | `BarActiveWindow.qml`, `BarClock.qml`, `BarStatusIcons.qml`, `BarTray.qml`, `BarWorkspaces.qml` | Taskbar component settings. |
| `modules/nexus/pages/services/` | `NotificationsPage.qml` | Notification and toast configuration. |
| `modules/nexus/pages/wallandstyle/` | `ColourSelect.qml`, `WallpaperCategory.qml`, `WallpaperSelect.qml` | Wallpaper browsing and the unfinished colour-selection page. |
| `modules/notifications/` | `Content.qml`, `Notification.qml`, `Wrapper.qml` | Transient notification popup stack. |
| `modules/notifshade/` | `Notif.qml`, `NotifActionList.qml`, `NotifDockList.qml`, `NotifGroup.qml`, `NotifGroupList.qml`, `Props.qml`, `Shade.qml`, `Wrapper.qml` | Notification shade, grouped/docked lists, actions, and expansion state. |
| `modules/osd/` | `Content.qml`, `Wrapper.qml` | Volume/microphone/brightness OSD and change-driven visibility. |
| `modules/session/` | `Content.qml`, `Wrapper.qml` | Session buttons, animated image, keyboard navigation, and panel visibility. |
| `modules/windowinfo/` | `Buttons.qml`, `Details.qml`, `Preview.qml`, `WindowInfo.qml` | Expanded window preview, metadata, workspace moves, and window actions. |

## Shared QML components

These are the shell-wide reusable components under **`quickshell/caelestia/components/`**. Nexus-local components are listed separately in the module inventory above.

| Relative path | Purpose |
|---|---|
| `AnchorAnim.qml` | Shared anchor-transition animation. |
| `Anim.qml` | Token-driven numeric animation presets. |
| `AnimLoader.qml` | Loader with animated lifecycle/visibility support. |
| `CAnim.qml` | Shared colour-transition animation. |
| `MaterialIcon.qml` | Styled Material Symbols icon with variable-font styling. |
| `ScreenState.qml` | Per-screen persistent drawer and dashboard state. |
| `StateLayer.qml` | Hover/press/focus interaction layer used by controls. |
| `StyledClippingRect.qml` | Rounded, clipping surface. |
| `StyledRect.qml` | Basic rectangle with animated colour changes. |
| `StyledText.qml` | Shared typography, colours, and text transitions. |
| `containers/StyledFlickable.qml` | Styled scrollable content container. |
| `containers/StyledListView.qml` | Styled list-view foundation. |
| `containers/StyledWindow.qml` | Shared shell-window setup with screen-aware configuration/tokens. |
| `containers/VerticalFadeFlickable.qml` | Flickable with vertical edge fading. |
| `containers/VerticalFadeListView.qml` | List view with vertical edge fading. |
| `controls/ButtonBase.qml` | Base styling/interaction for buttons. |
| `controls/CircularIndicator.qml` | Circular loading/indeterminate indicator. |
| `controls/CircularProgress.qml` | Circular determinate progress display. |
| `controls/CustomMouseArea.qml` | Shared mouse/wheel interaction wrapper. |
| `controls/FilledSlider.qml` | Filled, icon-bearing slider used by the OSD. |
| `controls/IconButton.qml` | Icon-only button with multiple visual styles. |
| `controls/IconTextButton.qml` | Combined icon-and-label button. |
| `controls/LoadingIndicator.qml` | Animated loading indicator. |
| `controls/Menu.qml` | Styled popup/menu container. |
| `controls/MenuItem.qml` | Shared menu-entry data/control. |
| `controls/SearchBar.qml` | Launcher/search input control. |
| `controls/SplitButton.qml` | Main-action button paired with a selection menu. |
| `controls/StyledProgressBar.qml` | Styled linear progress display. |
| `controls/StyledRadioButton.qml` | Radio-choice control. |
| `controls/StyledScrollBar.qml` | Scrollbar bound to scrollable content. |
| `controls/StyledSlider.qml` | General-purpose styled slider. |
| `controls/StyledSpinBox.qml` | Numeric stepper/spin box. |
| `controls/StyledSwitch.qml` | Animated on/off switch used by dashboard/settings toggles. |
| `controls/StyledTextField.qml` | General-purpose styled text input. |
| `controls/TextButton.qml` | Text-labelled button. |
| `controls/TextFieldBase.qml` | Shared foundation for text-input controls. |
| `effects/ColouredIcon.qml` | Recoloured icon rendering. |
| `effects/Colouriser.qml` | Colourisation effect for source content. |
| `effects/Elevation.qml` | Material-style elevation/shadow effect. |
| `effects/Mask.qml` | Shared masking effect. |
| `filedialog/CurrentItem.qml` | File-dialog selection/current-item presentation. |
| `filedialog/DialogButtons.qml` | File-dialog accept/cancel controls and validation. |
| `filedialog/FileDialog.qml` | Lazily opened floating file-picker window. |
| `filedialog/FolderContents.qml` | Directory/file listing and selection. |
| `filedialog/HeaderBar.qml` | File-dialog path/navigation header. |
| `filedialog/Sidebar.qml` | File-dialog location navigation. |
| `filedialog/Sizes.qml` | File-dialog sizing helper. |
| `images/CachingIconImage.qml` | Cached icon-image wrapper. |
| `images/CachingImage.qml` | Cached image loading/rendering. |
| `images/FadeImage.qml` | Image wrapper with fading transitions. |
| `misc/CustomShortcut.qml` | Shared global-shortcut registration wrapper. |
| `misc/Ref.qml` | Reference/lifetime helper for shared objects. |
| `widgets/CoverArt.qml` | Themed, shaped media artwork. |
| `widgets/ExtraIndicator.qml` | Indicator for additional content outside a visible list area. |

## QML services

All paths are relative to **`quickshell/caelestia/`**. Most of these are singletons; `NotifData.qml` is a per-notification data object rather than an independent daemon.

| File | Responsibility |
|---|---|
| `services/Audio.qml` | PipeWire outputs/inputs/streams, volume/mute, preferred devices, output cycling, device-change toasts, Cava, and beat tracking. |
| `services/Blackout.qml` | Display DPMS control, systemd lid-switch inhibition, failure cleanup, and Blackout IPC. |
| `services/Brightness.qml` | Per-monitor brightness, backlight/DDC/Apple display backends, monitor queries, shortcuts, and IPC. |
| `services/Colours.qml` | Runtime Material 3 palettes, preview colours, light/dark mode, transparency/luminance helpers, and Hyprland blur rules. |
| `services/GameMode.qml` | Compositor performance options, restoration/reapplication on reload, state, toasts, and IPC. |
| `services/GoogleCalendar.qml` | Private iCalendar URL loading, fetching/parsing, seven-day agenda, refresh, and error state. |
| `services/CalendarNotes.qml` | Shared, reload-persistent scratchpad for the dashboard Calendar tab; survives lazy tab loading and dashboard close/open cycles. |
| `services/HotCorner.qml` | Overview hot-corner enablement, size/delay, and JSON state persistence. |
| `services/Hypr.qml` | Hyprland monitors/workspaces/windows, Lua-aware dispatch, dynamic options, devices, and special-workspace IPC. |
| `services/IdleInhibitor.qml` | Wayland idle inhibition, enabled-since timestamp, reload-persistent state, and IPC. |
| `services/KdeConnect.qml` | Device/plugin/reachability/battery queries, CLI actions, SFTP browsing, refresh lifecycle, and IPC. |
| `services/NetworkUsage.qml` | `/proc/net/dev` rates/totals, recent-history buffers, formatting, and demand-driven polling. |
| `services/Nmcli.qml` | NetworkManager CLI orchestration, scanning/profiles, Wi-Fi/Ethernet state, passwords, autoconnect, connection details, and IPv4 editing. |
| `services/NotifData.qml` | Notification state/actions/images, timestamps, popup lifetime, closure, and history representation. |
| `services/Notifs.qml` | Desktop notification server, popup/DND policy, notification collections/history, and IPC. |
| `services/Players.qml` | MPRIS collection/active player, aliases, artwork fallback, now-playing toasts, media shortcuts, and IPC. |
| `services/Recorder.qml` | `gpu-screen-recorder` detection and Caelestia start/stop/pause requests, with reload-persistent recording state. |
| `services/Screens.qml` | Screen filtering/exclusion used by per-screen shell UI. |
| `services/ShellState.qml` | Per-screen `ScreenState` registry, active-screen lookup, and references to live UI components. |
| `services/Time.qml` | Shared clock/date values and time-formatting helpers. |
| `services/VPN.qml` | Provider configuration/migration, connection lifecycle/status, authentication/status parsing, traffic statistics, ping, and toasts. |
| `services/Weather.qml` | Demand-driven Open-Meteo geocoding/forecasts, request cancellation/timeouts, last-forecast state, local unit conversion, and refresh-interval persistence. |
| `services/Wallpapers.qml` | Recursive wallpaper model/search/categories, selection/previews, dynamic-colour preview, runtime path watching, and IPC. |

## Native QML modules

The QML shell is interpreted, but imports under **`Caelestia.*`** require this fork's native plugin. Source lives in **`quickshell/caelestia/plugin/src/Caelestia/`**. Some listed types are data objects or internal helpers rather than user-creatable widgets.

| Import / source directory | Exposed types and capabilities |
|---|---|
| `Caelestia` / root | `AppDb`, `AppEntry` — application usage database; `CUtils` — version, item capture, file operations, and object lookup; `ImageAnalyser` — dominant colour/luminance; `Qalculator` — expression evaluation; `Requests` — HTTP requests; `Toast`, `Toaster` — toast objects and delivery. |
| `Caelestia.Blobs` / `Blobs/` | `BlobGroup`, `BlobRect`, `BlobInvertedRect` — joined/deformable rounded surfaces and desktop-border rendering. |
| `Caelestia.Components` / `Components/` | `ButtonRow` — button layout; `LazyListView` — asynchronous/viewport-aware list lifecycle; `WavyLine` — wave/progress rendering. |
| `Caelestia.Config` / `Config/` | `GlobalConfig`, attached `Config`, `TokenConfig`, attached `Tokens`, `MonitorConfigManager` — defaults, live JSON configuration, per-monitor inheritance, design tokens, and automatic save/reload. Supporting C++ config classes define each panel/service's schema. |
| `Caelestia.Images` / `Images/` | `IUtils` and the native caching image-provider backend. |
| `Caelestia.Internal` / `Internal/` | `CircularBuffer`, `SparklineItem`, `VisualiserBars` — history/graphs/visualisers; `CircularIndicatorManager`, `LinearIndicatorManager`, `LinearIndicatorSegment` — progress animation; `HyprExtras`, `HyprDevices`, `HyprKeyboard` — Hyprland IPC/options/devices. |
| `Caelestia.Models` / `Models/` | `FileSystemModel`, `FileSystemEntry` — filesystem discovery, filtering, sorting, recursive wallpaper discovery, and file-picker/recording models. |
| `Caelestia.Services` / `Services/` | `Cpu`, `Gpu`, `Memory`, `Storage`, `DiskInfo`, `UsageFmt` — system usage and formatting; `Lyrics`, `LyricsBackend` — lyric fetching/synchronisation; `CavaProvider`, `BeatTracker` — audio analysis; `ServiceRef` — service lifetime tracking; `SessionManager` — logind/session power operations. |

The UI also imports **`M3Shapes`** for Material shapes. It is a fetched native dependency, not another shell module authored under `modules/`.

## Utilities and supporting resources

| Path under `quickshell/caelestia/` | Purpose |
|---|---|
| `utils/Icons.qml` | Application/system icon lookup and volume, network, Bluetooth, and related icon selection. |
| `utils/Images.qml` | Supported image-extension/filter helpers. |
| `utils/NetworkConnection.qml` | Shared Wi-Fi connection flow and password-dialog coordination. |
| `utils/Paths.qml` | XDG/home/config/state/cache/media paths, environment overrides, and path conversion/shortening. |
| `utils/Searcher.qml` | Reusable query/scoring infrastructure for search providers. |
| `utils/Strings.qml` | Shared string/regex matching helpers. |
| `utils/SysInfo.qml` | OS, kernel, hostname, firmware, hardware identity, and uptime. |
| `utils/scripts/fzf.js`, `utils/scripts/fuzzysort.js` | JavaScript search/scoring implementations. |
| `utils/scripts/weather.js` | Weather-response validation, coordinates/API URLs, WMO condition descriptions/icons, and temperature/wind conversion. |
| `assets/` | Bundled images/fonts, PAM profiles, terminal-launch wrapper, and other runtime resources. |
| `scripts/qml-lint-conventions.py` | Repository QML convention-checking helper. |
| `tests/weather.test.cjs` | Weather parsing/units/condition tests; run with `node --test quickshell/caelestia/tests/weather.test.cjs` from the repo root. |
| `plugin/` | Native Qt/QML implementation, rendering resources, and build definitions. |
| `extras/` | Auxiliary version/build support. |
| `CMakeLists.txt`, `nix/`, `flake.nix`, `flake.lock` | Native-module build/installation and Nix packaging support. |

Generated `build/` content is not a second feature/module implementation and is excluded from the inventories.

## Configuration and persistent state

Runtime directories respect the relevant XDG environment variables. Paths shown with `~/.config`, `~/.local/state`, and `~/.cache` are the defaults.

| Location | Role |
|---|---|
| `caelestia/shell.json`, `caelestia/shell-tokens.json` in this repo | First-install presets; not an automatic mirror of later Nexus edits. |
| `~/.config/caelestia/shell.json` | Live shell behaviour, panels, services, default apps, and paths. |
| `~/.config/caelestia/shell-tokens.json` | Live typography, dimensions, spacing, rounding, transparency, and animation tokens. |
| `~/.config/caelestia/weather.json` | Weather refresh frequency (`refreshMinutes`, default 30); location/units/visibility remain in `shell.json`. |
| `~/.config/caelestia/monitors/<output>/shell.json` | Per-monitor shell configuration overlay. |
| `~/.config/caelestia/monitors/<output>/shell-tokens.json` | Per-monitor token overlay. |
| `~/.config/caelestia/calendar-url` | Private Google Calendar iCal URL; supply locally and do not commit it. |
| `~/.local/state/caelestia/scheme.json` | Runtime colour scheme consumed by `Colours.qml`. |
| `hypr/scheme/current.lua` in this repo | Hyprland-side palette; keep it consistent with the runtime shell scheme. |
| `~/.local/state/caelestia/wallpaper/path.txt` | Current wallpaper's absolute path. |
| `~/.local/state/caelestia/notifs.json` | Notification history. |
| `~/.local/state/caelestia/apps.sqlite` | Launcher usage-frequency database. |
| `~/.local/state/caelestia/hot-corner.json` | Overview hot-corner settings. |
| `~/.cache/caelestia/imagecache/` | Cached images, including notification images under `notifs/`. |
| `~/.face` | Dashboard/lock profile image. |
| `~/Pictures/Wallpapers` by default | User wallpaper library; configurable through shell paths or `CAELESTIA_WALLPAPERS_DIR`. |
| `~/Videos/Recordings` by default | Recording history directory; override with `CAELESTIA_RECORDINGS_DIR`. |
| Quickshell `PersistentProperties` | Reload continuity for panel state, selected player, Caffeine/Game mode/recording state, notes, and other transient UI state; not equivalent to writing a durable backup. |

The native configuration backend debounces writes, reloads external JSON edits, reports unknown options, and refuses to overwrite a configuration whose last load failed until that error is resolved.

## Dependencies and integration boundaries

See the repository [setup instructions](README.md#recreate-the-setup-arch-linux) for installation and native-module build steps. The main feature-specific integrations are:

| Integration | Used for |
|---|---|
| Quickshell, Qt 6, Hyprland/Wayland | Shell windows, compositor state, session locking, screen capture, shortcuts, and IPC. |
| This fork's native Caelestia modules and M3Shapes | Native services, configuration, rendering, and Material shapes. |
| Caelestia CLI | Shell management, wallpaper/scheme commands, screenshot/recording entry points, and selected launcher actions. |
| PipeWire, libcava, aubio | Audio device/stream controls, visualisation, and beat analysis. |
| NetworkManager / `nmcli` | Wi-Fi/Ethernet profiles and connection configuration. |
| Bluetooth services exposed through Quickshell | Device status, discovery, pairing, and controls. |
| UPower / power-profiles service | Battery information and power-profile selection. |
| systemd/logind / `systemd-inhibit` | Session power operations, sleep events, and Blackout lid inhibition. |
| `brightnessctl`, `ddcutil`, optional `asdbctl` | Backlight, external-monitor, and Apple display brightness. |
| `curl` and a private iCal feed | Google Calendar agenda retrieval. |
| Open-Meteo geocoding and forecast APIs | Weather data over HTTPS through Qt; no API key, separate weather CLI, or IP-based geolocation required. |
| KDE Connect CLI/apps, `gdbus`, Thunar | Phone status/actions, SFTP browsing, file/text sharing, and external SMS/pairing UI. |
| `checkupdates` from pacman-contrib, Kitty, pacman | Arch update count and the dashboard's update action. |
| `gpu-screen-recorder`, Swappy, `wl-copy`, `notify-send` | Recording, screenshot editing, clipboard capture, and capture notifications. |
| libqalculate / `qalc`, Fish for the interactive launcher action | Calculator evaluation and optional terminal calculator. |
| lm_sensors and supported GPU backends | Hardware usage/temperature reporting. |
| PAM, optional fprintd/Howdy | Password, fingerprint, and face authentication. |
| Hyprland ScrollOverview plugin | Overview hot corner and overview keybind; not bundled in the shell. |

External integrations need their own installation, permissions, hardware support, and sometimes authentication. OrangeShell is not a replacement window manager, VPN daemon, package manager, KDE Connect daemon, or system-wide sleep/lid configuration tool.

## Unfinished, legacy, and disconnected pieces

- **Nexus Colours, Updates, and Plugins:** placeholder/under-construction pages. Theme switching through existing controls/launcher/CLI is implemented; those pages are not full colour/package/plugin editors.
- **Nexus Display page:** only a commented-out registry idea; no implemented display-settings page is registered.
- **Inherited utilities settings:** settings/schema still describe a separate utilities panel and configurable quick-toggle grid for Wi-Fi/Bluetooth/microphone/settings/Game mode/DND/VPN. The current drawer tree does not instantiate that old grid. Caffeine/Blackout/Game mode and recording are composed directly in `Dash.qml`; the Game mode and Blackout cards are unconditional there.
- **Taskbar `Power.qml`:** source and a preset `power` entry remain, but `Bar.qml` has no matching `power` delegate. Use the implemented dashboard/session power controls rather than assuming that entry renders.
- **Lock-screen `Media.qml` / `NotifGroup.qml`:** retained source components, not displayed by the current centre-only `lock/Content.qml`.
- **Dashboard utility `Props.qml`:** retained helper; the current dashboard owns recorder expansion/deletion state itself.
- **Recording deletion:** the history delete button sets `recordingConfirmDelete`, but the current dashboard has no confirmation/deletion handler consuming that state. It is not a completed delete feature.
- **Notification tab:** notifications are a separate shade, not a dashboard tab. `drawers setTab` currently accepts only `media`, `dashboard`, `performance`, and `phone`.
- **Notes/calendar limits:** notes are reload-persistent rather than durable storage; the agenda is read-only and does not expand recurring-event rules.
- **Surrounding dotfiles:** refresh-rate helpers, Spotify scratchpads, clipboard/emoji commands, HyprGlass, Hypr3D, and ScrollOverview are integrations outside the shell UI module inventory. There is no Tide Island or alternative-shell implementation in this tree, and no bundled hyprpaper/hypridle configuration.

The vendored OrangeShell tree retains its upstream [GPL-3.0 license](quickshell/caelestia/LICENSE).
