#!/usr/bin/env bash

LANG_FILE="/tmp/whisper/lang"

lang="en"
if [[ -f "$LANG_FILE" ]]; then
    lang=$(cat "$LANG_FILE")
fi

case "$lang" in
    en) text="EN"; tooltip="English"; class="en" ;;
    ru) text="RU"; tooltip="Russian"; class="ru" ;;
    pl) text="PL"; tooltip="Polish";  class="pl" ;;
    *)  text="??"; tooltip="Unknown"; class="unknown" ;;
esac

echo "{\"text\": \"${text}\", \"tooltip\": \"Voice: ${tooltip}\", \"class\": \"${class}\"}"
