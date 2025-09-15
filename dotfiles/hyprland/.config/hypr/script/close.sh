#!/bin/sh

CLASS=$(hyprctl -j activewindow | jq -r '.class')

if [ "$CLASS" = "keymapp" ] || [ "$CLASS" = "flameshot" ] || [ "$CLASS" = "org.pulseaudio.pavucontrol" ]; then
    hyprctl dispatch closewindow activewindow
fi
