#!/usr/bin/env bash
# Toggle the Spotify scratchpad (special:magic).
# Launches Spotify if it isn't already running.

# Pull any Spotify windows that left the scratchpad back into it, then toggle.
# NOTE: on a Lua config root, `hyprctl dispatch` only takes a single
# expression, so use `hyprctl eval` for multi-statement chunks.
hyprctl eval '
for _, w in ipairs(hl.get_windows()) do
    if w.class == "Spotify" and w.workspace and w.workspace.name ~= "special:magic" then
        hl.dispatch(hl.dsp.window.move({ workspace = "special:magic", window = w, follow = false }))
    end
end
hl.dispatch(hl.dsp.workspace.toggle_special("magic"))
' >/dev/null

# Not running? Launch it — the window rule drops it straight into the scratchpad.
if ! pgrep -x spotify >/dev/null; then
    setsid spotify-launcher >/dev/null 2>&1 </dev/null &
fi
