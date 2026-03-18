#!/bin/bash

CURSOR_POS=$(hyprctl cursorpos)
X=$(echo $CURSOR_POS | cut -d',' -f1 | tr -d ' ')
Y=$(echo $CURSOR_POS | cut -d',' -f2 | tr -d ' ')

WINDOW_AT_CURSOR=$(hyprctl clients -j | jq -r ".[] | select(.at[0] <= $X and .at[0] + .size[0] >= $X and .at[1] <= $Y and .at[1] + .size[1] >= $Y) | .address" | head -1)

if [ -z "$WINDOW_AT_CURSOR" ]; then
    nwg-drawer
fi
