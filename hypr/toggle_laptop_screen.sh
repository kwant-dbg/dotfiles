#!/usr/bin/env bash

if hyprctl monitors -j | grep -q '"name": "eDP-1"'; then
    hyprctl keyword monitor eDP-1,disable
    notify-send -t 2000 "Hyprland" "Laptop screen disabled"
else
    hyprctl reload
    notify-send -t 2000 "Hyprland" "Laptop screen enabled"
fi
