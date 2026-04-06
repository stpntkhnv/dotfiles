#!/usr/bin/env bash

MODEL_FILE="/tmp/whisper/model"
MODELS=(medium large-v3 turbo)

current="large-v3"
if [[ -f "$MODEL_FILE" ]]; then
    current=$(cat "$MODEL_FILE")
fi

for i in "${!MODELS[@]}"; do
    if [[ "${MODELS[$i]}" == "$current" ]]; then
        next_idx=$(( (i + 1) % ${#MODELS[@]} ))
        next="${MODELS[$next_idx]}"
        echo "$next" > "$MODEL_FILE"
        notify-send -t 2000 "Whisper" "Switching model to $next, restarting daemon..."
        systemctl --user restart whisper-daemon
        pkill -RTMIN+9 waybar 2>/dev/null
        exit 0
    fi
done

echo "large-v3" > "$MODEL_FILE"
notify-send -t 2000 "Whisper" "Switching model to large-v3, restarting daemon..."
systemctl --user restart whisper-daemon
pkill -RTMIN+9 waybar 2>/dev/null
