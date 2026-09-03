#!/bin/bash

AC="/sys/class/power_supply/AC/online"

last=""

while true; do
    current="$(cat "$AC")"

    if [ "$current" != "$last" ]; then
        ~/OrangeDots/refresh_rate.sh
        last="$current"
    fi

    sleep 2
done
