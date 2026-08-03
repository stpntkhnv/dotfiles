# English dictation comes out as a Russian translation

Found and fixed 2026-08-03.

**Symptom** Handy input language `English`; English speech types out as fluent
Russian matching the meaning - a translation, not a bad transcript.
Intermittent.

**Root cause** The `initial_prompt` seed `44-handy-settings` wrote into
`custom_words` was hardcoded Russian, and the seed sets output language more
strongly than `selected_language`. From `handy.log` + `history.db` (log
UTC, db local): at 18:03:30, `language=Some("en")`, task `Transcribe`,
`translate_to_english` off and `initial_prompt=true` still gave Russian for
English speech (732) - "wrong language" is out. At 18:05:18 the only change
was model `canary-180m-flash`, which drops the seed: same voice, English
(735). `language=None` runs at 18:01-18:02 show the model sometimes beating
the seed. Mic and post-processing ruled out.

**Fix** `44-handy-settings` now reads `selected_language` from
`settings_store.json` and seeds in that language; on `auto`, none. See
[voice.md](../voice.md). Black-box evidence only - no standalone whisper.cpp
here; samples `handy-1785773009.wav` (732), `handy-1785773116.wav` (735).

**Recheck** `grep -aE "transcribe-cpp run" .../handy/logs/handy.log`:
`initial_prompt=true` only when seed and language match.
