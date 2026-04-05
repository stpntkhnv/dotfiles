#!/usr/bin/env bash

LANG_FILE="/tmp/whisper/lang"
LANGUAGES=(en ru pl)

current="en"
if [[ -f "$LANG_FILE" ]]; then
    current=$(cat "$LANG_FILE")
fi

for i in "${!LANGUAGES[@]}"; do
    if [[ "${LANGUAGES[$i]}" == "$current" ]]; then
        next_idx=$(( (i + 1) % ${#LANGUAGES[@]} ))
        echo "${LANGUAGES[$next_idx]}" > "$LANG_FILE"
        pkill -RTMIN+8 waybar 2>/dev/null
        exit 0
    fi
done

echo "en" > "$LANG_FILE"
pkill -RTMIN+8 waybar 2>/dev/null
