#!/bin/bash
# Handy paste_method=external_script handler: per-character typing that
# survives Cyrillic. wtype builds a virtual keymap from the text's unique
# characters in order of first appearance, and the stack (niri/ghostty)
# silently eats keycodes #14 and #15 of that keymap -- verified across
# several dictations: exactly the 14th/15th unique character vanished
# every time, all occurrences. Typing in chunks of 12 keeps every keymap
# under 14 unique symbols, so no character ever lands on a dead keycode.
exec python3 - "$1" <<'PY'
import subprocess, sys
# The cleanup model routinely appends trailing newlines to its output --
# measured on a real dictation, a 58-character transcript came back as 64,
# the extra 6 being trailing whitespace with content otherwise identical.
# Left alone those land as blank lines in the target window. Strip only the
# ends: the cleanup prompt asks for paragraph breaks between topics, and
# those internal newlines are meant to be typed.
text = sys.argv[1].strip()
if not text:
    sys.exit(0)
for i in range(0, len(text), 12):
    subprocess.run(["wtype", "-d", "5", "--", text[i:i+12]])
PY
