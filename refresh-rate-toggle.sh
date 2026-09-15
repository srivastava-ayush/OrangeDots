#!/bin/bash

if hyprctl monitors | grep -q '^\s*1920x1080@60'; then
    # 60 Hz → 144 Hz
    hyprctl eval 'hl.monitor({ output = "eDP-1", mode = "1920x1080@144", position = "0x0", scale = 1 })'
    notify-send "Refresh Rate" "144 Hz"
else
    # 144 Hz → 60 Hz
    hyprctl eval 'hl.monitor({ output = "eDP-1", mode = "1920x1080@60", position = "0x0", scale = 1 })'
    notify-send "Refresh Rate" "60 Hz"
fi


