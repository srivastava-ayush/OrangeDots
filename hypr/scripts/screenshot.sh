#!/usr/bin/env bash
# Save the focused screen immediately, rather than requiring a notification action.
set -euo pipefail
umask 077

directory="$HOME/Pictures/Screenshots"
mkdir -p "$directory"
monitor=$(hyprctl -j monitors | python3 -c 'import json, sys; print(next(m["name"] for m in json.load(sys.stdin) if m.get("focused")))')
# A unique suffix prevents overwriting captures taken within the same second.
destination=$(mktemp "$directory/Screenshot-$(date +%Y-%m-%d_%H-%M-%S)-XXXXXX.png")
if ! grim -o "$monitor" "$destination"; then
    rm -f -- "$destination"
    notify-send -a "Screenshot" "Screenshot failed" "Could not capture the focused screen."
    exit 1
fi

if ! wl-copy --type image/png < "$destination"; then
    notify-send -a "Screenshot" "Screenshot saved" "Saved to $destination, but clipboard copy failed."
    exit 1
fi
notify-send -a "Screenshot" -i "$destination" "Screenshot saved and copied" "Saved to $destination"
