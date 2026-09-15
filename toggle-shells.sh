#!/usr/bin/env bash
# toggle-shell.sh — swap between Caelestia and custom rice

if pgrep -x qs >/dev/null; then
    # Caelestia is active -> kill it, bring up custom rice
    pkill -x qs

    pgrep -x awww-daemon >/dev/null || awww-daemon &
    pgrep -x waybar    >/dev/null || waybar &
    pgrep -x hypridle  >/dev/null || hypridle &   # handles your lock trigger

elif pgrep -x waybar >/dev/null; then
    # Custom rice is active -> tear it down, bring up Caelestia
    pkill -x waybar
    pkill -x awww-daemon
    pkill -x hypridle

    caelestia shell -d &

else
    # Neither running -> just start Caelestia as default
    caelestia shell -d &
fi