#!/usr/bin/env bash

MODEL_FILE="/tmp/whisper/model"

model="large-v3"
if [[ -f "$MODEL_FILE" ]]; then
    model=$(cat "$MODEL_FILE")
fi

case "$model" in
    medium)   text="M";  tooltip="Whisper: medium" ;;
    large-v3) text="L";  tooltip="Whisper: large-v3" ;;
    turbo)    text="T";  tooltip="Whisper: turbo" ;;
    *)        text="?";  tooltip="Whisper: $model" ;;
esac

echo "{\"text\": \"${text}\", \"tooltip\": \"${tooltip}\", \"class\": \"${model}\"}"
