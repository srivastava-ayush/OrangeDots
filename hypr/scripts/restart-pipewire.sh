
#!/usr/bin/env bash

if systemctl --user restart pipewire pipewire-pulse wireplumber; then
    notify-send "Audio" "PipeWire & WirePlumber restarted"
else
    notify-send -u critical "Audio" "Failed to restart audio services"
fi
