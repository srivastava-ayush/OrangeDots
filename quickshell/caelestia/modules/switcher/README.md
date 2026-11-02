# Window switcher

The shell's `WindowSwitcher` scope registers compositor global shortcuts and a
`switcher` IPC target. `SwitcherState.qml` owns an address-based, frozen MRU
snapshot; `SwitcherWindow.qml` renders it on the monitor focused at invocation.

## Controls

- **Alt+Tab:** open / next window.
- **Alt+Shift+Tab:** open / previous window.
- **Release either Alt:** select the highlighted window.
- **Escape / click outside:** cancel without changing the focused window.
- **Left / Right:** move the highlight while open.
- **Enter / click a card:** select the window.

Bindings live in `hypr/modules/keybindings.lua`. Selection is across workspaces,
including mapped scratchpad windows. Unmapped/hidden windows are excluded.
The first version uses application icons and titles, not live thumbnails.

The current window is first, followed by compositor focus history. Opening or
cycling does not focus windows. New windows appear on the next invocation;
closed windows are pruned immediately without reordering the survivors. The
keyboard layer unmaps before the final focus request so Hyprland cannot restore
the old focus over the selected window. Locking cancels and blocks the switcher.

IPC, useful for debugging:

```sh
caelestia shell switcher next
caelestia shell switcher previous
caelestia shell switcher accept
caelestia shell switcher cancel
caelestia shell switcher status
```

Run isolated layout/state/native-key-event tests inside Wayland:

```sh
python3 quickshell/caelestia/tests/integration.py --mode switcher
```

The fixture uses a transparent background surface, no input region or keyboard
grab, no Hyprland connection, and isolated settings. It never focuses real apps.
