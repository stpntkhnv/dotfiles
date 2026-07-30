#!/bin/bash
# Handy paste_method=external_script handler: per-character typing that
# survives Cyrillic. wtype builds a virtual keymap from the text's unique
# characters in order of first appearance, and the stack (niri/ghostty)
# silently eats keycodes #14 and #15 of that keymap -- verified across
# several dictations: exactly the 14th/15th unique character vanished
# every time, all occurrences. Typing in chunks of 12 keeps every keymap
# under 14 unique symbols, so no character ever lands on a dead keycode.
#
# The chunking is the whole defence; the inter-key delay is not. Measured
# over 88 runs into a focused window, comparing byte for byte: at chunk 12
# nothing was ever dropped at 5 ms, 3, 2, 1, or with the flag left off, on
# short and long text, idle and with every core spinning -- while chunk 64
# lost exactly two characters in every run despite the same 5 ms. The delay
# started at 10 ms back when it was the only defence and outlived its
# reason. 1 ms is what is left of it: the floor is about 4.5 ms per
# character no matter what, and each further millisecond of -d costs about
# 0.4 s on a 400-character dictation. It stays non-zero because every one
# of those runs typed into ghostty, and Handy types into whatever window
# has focus. (-d 0 is not the way to say zero: wtype 0.4 rejects it with
# "Invalid sleep time". Zero is the flag left off.)
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
    subprocess.run(["wtype", "-d", "1", "--", text[i:i+12]])
PY
