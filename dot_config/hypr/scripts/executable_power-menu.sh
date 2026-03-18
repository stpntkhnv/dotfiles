#!/bin/bash

options="󰌾 Lock\n󰍃 Logout\n󰜉 Reboot\n󰐥 Shutdown"

selected=$(echo -e "$options" | wofi --dmenu --prompt "Power" --width 200 --height 200)

case "$selected" in
    "󰌾 Lock") hyprlock ;;
    "󰍃 Logout") hyprctl dispatch exit ;;
    "󰜉 Reboot") systemctl reboot ;;
    "󰐥 Shutdown") systemctl poweroff ;;
esac
