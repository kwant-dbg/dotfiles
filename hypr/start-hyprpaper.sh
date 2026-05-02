#!/bin/sh

wallpaper="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/wallpaper.jpg"

if [ ! -f "$wallpaper" ]; then
    exit 0
fi

if ! pgrep -x hyprpaper >/dev/null 2>&1; then
    hyprpaper >/tmp/hyprpaper.log 2>&1 &
    sleep 1
fi

hyprctl hyprpaper wallpaper "DP-1,$wallpaper,cover" >/dev/null 2>&1
hyprctl hyprpaper wallpaper "eDP-1,$wallpaper,cover" >/dev/null 2>&1
