#!/usr/bin/env bash

exec >> /tmp/whisper/voice-input.log 2>&1
echo "$(date '+%H:%M:%S.%N') --- $1 called"

WHISPER_DIR="/tmp/whisper"
SOCKET="$WHISPER_DIR/whisper.sock"
LANG_FILE="$WHISPER_DIR/lang"
PID_FILE="$WHISPER_DIR/recording.pid"
METER_PID_FILE="$WHISPER_DIR/meter.pid"
RAW_FILE="$WHISPER_DIR/recording.raw"
WAV_FILE="$WHISPER_DIR/recording.wav"
SAMPLE_RATE=16000
MIN_SAMPLES=8000
TAIL_SILENCE_SEC=0.5

start_recording() {
    if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        kill "$(cat "$PID_FILE")" 2>/dev/null
        rm -f "$PID_FILE"
    fi

    if [[ ! -S "$SOCKET" ]]; then
        notify-send -u critical "Voice Input" "Whisper daemon is not running"
        exit 1
    fi

    rm -f "$RAW_FILE" "$WAV_FILE"
    notify-send -t 1000 "Voice Input" "Recording..."

    setsid rec -q -t raw -r $SAMPLE_RATE -c 1 -b 16 -e signed-integer "$RAW_FILE" &
    echo $! > "$PID_FILE"

    if [[ -f "$METER_PID_FILE" ]]; then
        kill "$(cat "$METER_PID_FILE")" 2>/dev/null
        rm -f "$METER_PID_FILE"
    fi
    foot --app-id voice-meter --title "Voice Meter" -W 14x7 -o pad=2x2 -e ~/bin/voice-meter.sh &
    echo $! > "$METER_PID_FILE"
}

kill_meter() {
    if [[ -f "$METER_PID_FILE" ]]; then
        kill "$(cat "$METER_PID_FILE")" 2>/dev/null
        rm -f "$METER_PID_FILE"
    fi
}

stop_recording() {
    kill_meter

    echo "$(date '+%H:%M:%S.%N') stop: checking PID file"
    if [[ ! -f "$PID_FILE" ]]; then
        echo "$(date '+%H:%M:%S.%N') stop: no PID file, exiting"
        exit 0
    fi

    pid=$(cat "$PID_FILE")
    echo "$(date '+%H:%M:%S.%N') stop: waiting ${TAIL_SILENCE_SEC}s for buffer flush"
    sleep $TAIL_SILENCE_SEC

    echo "$(date '+%H:%M:%S.%N') stop: killing rec pid=$pid"
    kill -INT "$pid" 2>/dev/null
    for i in $(seq 1 20); do
        kill -0 "$pid" 2>/dev/null || break
        sleep 0.05
    done
    rm -f "$PID_FILE"

    if [[ ! -f "$RAW_FILE" ]]; then
        echo "$(date '+%H:%M:%S.%N') stop: no RAW file, exiting"
        exit 0
    fi

    raw_size=$(stat -c%s "$RAW_FILE" 2>/dev/null || echo 0)
    samples=$((raw_size / 2))
    echo "$(date '+%H:%M:%S.%N') stop: raw_size=$raw_size samples=$samples"

    if [[ "$samples" -lt "$MIN_SAMPLES" ]]; then
        echo "$(date '+%H:%M:%S.%N') stop: too short, exiting"
        rm -f "$RAW_FILE"
        exit 0
    fi

    sox -t raw -r $SAMPLE_RATE -c 1 -b 16 -e signed-integer "$RAW_FILE" "$WAV_FILE" pad 0 $TAIL_SILENCE_SEC
    rm -f "$RAW_FILE"

    echo "$(date '+%H:%M:%S.%N') stop: converted to WAV, $(soxi -D "$WAV_FILE" 2>/dev/null)s"

    lang=""
    if [[ -f "$LANG_FILE" ]]; then
        lang=$(cat "$LANG_FILE")
    fi
    echo "$(date '+%H:%M:%S.%N') stop: lang=$lang, sending to whisper"

    notify-send -t 1000 "Voice Input" "Transcribing..."

    response=$(curl --silent --max-time 30 \
        --unix-socket "$SOCKET" \
        -X POST \
        -F "audio=@$WAV_FILE" \
        ${lang:+-F "language=$lang"} \
        http://localhost/transcribe)

    echo "$(date '+%H:%M:%S.%N') stop: response=$response"

    rm -f "$WAV_FILE"

    text=$(echo "$response" | jq -r '.text // empty')
    echo "$(date '+%H:%M:%S.%N') stop: text='$text'"

    if [[ -z "$text" ]]; then
        if echo "$response" | jq -e '.error' >/dev/null 2>&1; then
            error=$(echo "$response" | jq -r '.error')
            notify-send -u critical "Voice Input" "Transcription failed: $error"
            exit 1
        fi
        exit 0
    fi

    printf '%s' "$text" | wl-copy
    wtype -M ctrl -M shift -k v -m shift -m ctrl
    echo "$(date '+%H:%M:%S.%N') stop: wtype done"
}

toggle_recording() {
    if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        stop_recording
    else
        rm -f "$PID_FILE"
        start_recording
    fi
}

case "${1:-}" in
    start)  start_recording ;;
    stop)   stop_recording ;;
    toggle) toggle_recording ;;
    *)
        echo "Usage: voice-input.sh {start|stop|toggle}"
        exit 1
        ;;
esac
