# Wallpaper switcher

The dedicated `SUPER+TAB` wallpaper strip. It is intentionally separate from
the launcher's wallpaper browser (`caelestia shell wallpapers pick`,
`SUPER+SHIFT+W`), which keeps its search, category and preview behaviour.

`WallpaperSwitcher.qml` is a `Scope` that chooses the active screen, closes the
launcher/dashboard/session/emoji surfaces, and registers the
`wallpaperswitcher` IPC target. `WallpaperSwitcherState.qml` remembers the
selected path so model refreshes cannot reorder the strip; the wallpaper model
itself stays owned by the `Wallpapers` service.

`WallpaperSwitcherWindow.qml` renders a transparent full-screen overlay with a
centred horizontal `PathView`. Opening and closing are a plain vertical slide
from above the screen: the card keeps its final height and widens from 60% to
100% on the way in, then runs the same motion backwards on close. The whole
layer never slides or squeezes; only the card moves, with the background dim
fading in independently. The strip is draggable with the mouse and responds to
the scroll wheel, exactly like the launcher's wallpaper list. Preview changes
the live wallpaper and, for dynamic schemes, the Material colours immediately.

A search box sits in the centre of the header and takes focus as soon as the
strip opens, so `SUPER+TAB` followed by typing filters the wallpapers straight
away. Space-separated terms are matched against the relative path, and the
highlight jumps to (and previews) the first remaining card.

Each wallpaper tile is drawn as a parallelogram. Unselected tiles are compact
in width with more rounded corners; moving the selection with the keyboard,
wheel or a drag animates the tile into a full-sized parallelogram with a
primary outline, while the previous card collapses back to the compact form.
Toggling the strip slides every tile in from its own side, one neighbour after
another in a wave that starts at the highlight, and reverses the wave on close;
the fade and scale stay synchronised so the strip still reads as one piece.
Preview changes the live wallpaper and, for dynamic schemes, the Material
colours immediately.

## Controls

- **SUPER+TAB:** toggle the strip and focus the search box.
- **Type:** filter wallpapers by name; the first match previews immediately.
- **Left / Right** (with an empty search) or **Tab / Shift+Tab**, or the scroll
  wheel: browse wallpapers.
- **Drag the strip** with the mouse: browse wallpapers.
- **Enter / Space** or **click a card:** apply the highlighted wallpaper.
- **Escape / click outside:** close and revert the preview.

The card with the small `check` badge is the wallpaper currently applied; the
brighter card with the primary-colour ring is the preview under the cursor.

IPC, useful for debugging:

```sh
caelestia shell wallpaperswitcher toggle
caelestia shell wallpaperswitcher open
caelestia shell wallpaperswitcher close
caelestia shell wallpaperswitcher next
caelestia shell wallpaperswitcher previous
caelestia shell wallpaperswitcher select 3
caelestia shell wallpaperswitcher isOpen
caelestia shell wallpaperswitcher status
```

Run the isolated layout/state/keyboard test inside Wayland:

```sh
python3 quickshell/caelestia/tests/integration.py --mode wallpaper-switcher
```

The fixture never focuses real windows, grabs the keyboard, applies a real
wallpaper, or connects to Hyprland.
