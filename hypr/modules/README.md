# Hyprland Lua modules

`../hyprland.lua` loads these in an explicit order. All existing configuration
values, shortcuts, rules, and plugin settings are retained.

| File | Edit here for |
| --- | --- |
| `settings.lua` | Preferred applications and portable helper paths |
| `monitors.lua` | Display output, mode, position, and scale |
| `autostart.lua` | Commands run when Hyprland starts |
| `environment.lua` | Environment variables |
| `appearance.lua` | Gaps, borders, opacity, blur, and shadows |
| `animations.lua` | Animation curves and speeds |
| `layouts.lua` | Layout options and per-workspace layouts |
| `misc.lua` | Wallpaper/logo defaults |
| `input.lua` | Keyboard, mouse, touchpad, gestures, and devices |
| `keybindings.lua` | Shortcuts, submaps, and Spotify scratchpad rule |
| `rules.lua` | Other window rules |
| `plugins.lua` | Hypr3D, scrolloverview, and HyprGlass |

Feature modules return a function accepting the shared settings table, rather
than relying on new globals. The loader clears only its own `package.loaded`
entries before requiring modules, so edits are picked up on config reload.
Hyprland supplies the configuration directory in Lua's module search path.

The Spotify rule stays beside its scratchpad keybindings to preserve registration
order. Plugin configuration retains its existing global `plugin` assignment.
