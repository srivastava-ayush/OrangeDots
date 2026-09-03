#!/bin/bash

if [ "$(cat /sys/class/power_supply/AC*/online 2>/dev/null | head -n1)" = "1" ]; then
    # AC / Performance
    hyprctl eval 'hl.monitor({ output = "eDP-1", mode = "1920x1080@144", position = "0x0", scale = 1 })'

else
    # Battery / Power saving
    hyprctl eval 'hl.monitor({ output = "eDP-1", mode = "1920x1080@60", position = "0x0", scale = 1 })'
fi
