#!/bin/bash
# Get monitor resolution and gaps from config
read -r W H <<< $(/usr/bin/hyprctl monitors -j | python3 -c "import json,sys; m=json.load(sys.stdin)[0]; print(m['width'], m['height'])")
GAPS=10

/usr/bin/hyprctl eval "
hl.dispatch(hl.dsp.window.move({x=$GAPS, y=$GAPS}))
hl.dispatch(hl.dsp.window.resize({x=$((W - GAPS*2)), y=$((H - GAPS*2))}))
" --quiet
