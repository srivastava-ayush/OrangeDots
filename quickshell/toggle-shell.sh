#!/bin/bash

if pgrep -x qs >/dev/null; then
    # Stop Caelestia
    pkill -x qs

    # Start custom shell
    quickshell -c dynamicIsland &
else
    # Stop custom shell
    pkill -f "quickshell.*dynamicIsland"

    # Stop custom-shell-only processes
    pkill -x cava 2>/dev/null
    pkill -x swww-daemon 2>/dev/null
    pkill -x hypridle 2>/dev/null
    pkill -x hyprpaper 2>/dev/null

    # Start Caelestia
    caelestia shell -d
fi