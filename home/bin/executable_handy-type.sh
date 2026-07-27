#!/bin/bash
# Handy paste_method=external_script handler: types the transcript
# per-character, like paste_method=direct, but with an inter-key delay.
# Handy's own direct mode runs bare `wtype --` with no delay, and that
# event burst drops Cyrillic letters (each non-ASCII char also rides a
# keymap swap). 10 ms per key is invisible to the eye but survives it.
exec wtype -d 10 -- "$1"
