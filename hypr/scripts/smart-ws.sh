#!/bin/bash

FOCUSED_MONITOR=$(hyprctl monitors | awk '/Monitor /{mon=$2} /focused: yes/{print mon}')
echo "Focused monitor: $FOCUSED_MONITOR"
KEY=$1
if [[ "$FOCUSED_MONITOR" == "HDMI-A-1" ]]; then
  TARGET_WS=$KEY
else
  TARGET_WS=$((KEY + 5))
fi

hyprctl dispatch workspace "$TARGET_WS"

