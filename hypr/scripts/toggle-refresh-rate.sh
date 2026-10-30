#!/usr/bin/env bash
# Hardware-specific preset: adapt the output name and modes for another laptop.
set -euo pipefail

if hyprctl monitors | grep -q '^\s*1920x1080@60'; then
    hyprctl eval 'hl.monitor({ output = "eDP-1", mode = "1920x1080@144", position = "0x0", scale = 1 })'
    notify-send "Refresh Rate" "144 Hz"
else
    hyprctl eval 'hl.monitor({ output = "eDP-1", mode = "1920x1080@60", position = "0x0", scale = 1 })'
    notify-send "Refresh Rate" "60 Hz"
fi
