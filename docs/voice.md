---
covers:
  features: [voice]
  paths:
    - home/dot_config/niri/voice.kdl.tmpl
    - home/bin/executable_handy-type.sh
    - home/.chezmoiscripts/run_onchange_before_40-voice.sh.tmpl
    - home/.chezmoiscripts/run_after_44-handy-settings.sh.tmpl
---

# Voice input: Handy

## What it does

Offline dictation on the host: `Mod+Shift+D` toggles recording in
[Handy](https://handy.computer), Whisper transcribes locally, a script types it
into the focused window. Feature `voice` (`home/.chezmoidata.yaml`, scope
`host`): `openblas` (pacman), `handy-bin` (AUR). whisper.cpp uses Vulkan, not CUDA - hence no `cuda` package anywhere
(`run_onchange_before_35-nvidia.sh.tmpl`).

## Files

| Path | Role |
|---|---|
| `home/dot_config/niri/voice.kdl.tmpl` | Startup and the bind. `config.kdl` includes it unconditionally, so the `{{ else }}` branch emits a comment, not nothing. |
| `home/bin/executable_handy-type.sh` | `external_script` paste handler. Always deployed (no `.tmpl`, no gate), 755. |
| `.chezmoiscripts/run_onchange_before_40-voice.sh.tmpl` | Prints the manual model step. |
| `.chezmoiscripts/run_after_44-handy-settings.sh.tmpl` | Patches 13 keys of Handy's own `~/.local/share/com.pais.handy/settings_store.json` every apply; never creates it. |

## How it works

- niri owns the bind and `spawn`s `handy --toggle-transcription` at the running
  instance (`spawn-at-startup "handy" "--start-hidden"`).
- `paste_method=external_script` -> `$HOME/bin/handy-type.sh`: collapses
  `\n`/`\r`/`\t` runs to one space, types 12-character chunks via `wtype -d 1`.
- Script 44 writes the punctuation seed into `custom_words`, Handy's only source
  for whisper's `initial_prompt`. Handy's UI rejects entries with a space
  (`CustomWords.tsx:22-28`), so any multi-word entry is one this script wrote -
  that shape is how old seeds get swept without losing hand-added terms. It also
  clears `voice-postprocess` leftovers, each only while still unchanged, and
  swaps the file atomically (temp file beside `$STORE`, `chmod --reference`,
  `HANDY_STOPPED=1` before `pkill`).

## Constraints

- The seed must be **last** in `custom_words`: Handy joins the list with `", "`,
  and a prompt cut off mid-list punctuates worse than none.
- The seed must match `selected_language`: it pins output language harder than
  the language setting does ([investigation](issues/2026-08-03-dictation-translated-not-transcribed.md)).
  On `auto`, no seed at all - not an empty string. Switching language takes two
  steps: the UI, then `chezmoi apply`. The seed pins only the first 30 s window,
  so long dictations still lose punctuation partway, whatever the model.
- If Handy outlives `pkill -x handy` by 10 s the file is left untouched: Tauri's
  single-instance plugin would reject the relaunch, leaving no Handy at all.
  `cleanup()` relaunches only with `WAYLAND_DISPLAY`/`DISPLAY` set.
- `selected_microphone` is not patched; the audio stack comes from
  [desktop.md](desktop.md).

## Decisions

| Decision | Why | Rejected |
|---|---|---|
| niri owns the hotkey | Tauri's global-shortcut plugin cannot grab keys on wlroots compositors: no `zwp_keyboard_shortcuts_inhibit_manager_v1`. [Handy#949](https://github.com/cjpais/Handy/issues/949) names it and the `--toggle-transcription` workaround; [tauri#3578](https://github.com/tauri-apps/tauri/issues/3578) open | in-app shortcut |
| CLI flag, not signals; `overlay_style: none` | `SIGUSR1` clashes with JavaScriptCore's GC in WebKitGTK ([Handy#1660](https://github.com/cjpais/Handy/issues/1660), 2026-07-11): six `SIGSEGV` dumps 2026-07-29, same frame in `libjavascriptcoregtk-4.1`. `SIGUSR2` crashes on its own ([Handy#512](https://github.com/cjpais/Handy/issues/512)). Fix pending in [#1824](https://github.com/cjpais/Handy/pull/1824) (replaced #1267, unmerged 2026-07-31); not in 0.9.4. An idle webview GCs less often | signals; live overlay |
| Own type script, 12-char chunks, flattened newlines | Built-in paste drops Cyrillic: `wtype`'s virtual keymap loses unique characters #14/#15 on niri/ghostty ([wtype#71](https://github.com/atx/wtype/issues/71): Chromium, #14 only). 88 runs: chunk 12 lost nothing at any delay, chunk 64 lost two every run. `-d 1` is a leftover, not the defence (`-d 0` is rejected). A newline becomes keysym `Linefeed` = byte `0x0A` = `Ctrl+J` = Enter in a terminal (no upstream ticket, searched 2026-07-31) | one `wtype` call |
| Pinned model, seed in-decoder | Whisper fixes punctuated-or-not at the first token of each 30 s window. 39 recordings, 4 conditions (2026-07-30): unseeded, 2 dictations ended with no punctuation at all (worst 507/733 chars), seeded 0 (worst 342/403). large-v3 over turbo is about anglicisms, not punctuation: turbo writes `Chizmoi`/`GEMA`, large-v3 `chezmoi`/`Gemma` (42 vs 34 unique Latin tokens); median 622 vs 272 ms | `voice-postprocess` (`ollama` + `gemma2:9b`); turbo |
| `openblas` listed | 0.9.4 linked `libopenblas.so.0` undeclared ([Handy#1611](https://github.com/cjpais/Handy/issues/1611); upstream fix merged 2026-07-07). **Probably obsolete**: `handy-bin 0.9.4-2` declares it (checked 2026-08-03); kept as a guard | `blas-openblas` |

## Verify

```sh
chezmoi --source . execute-template < home/dot_config/niri/voice.kdl.tmpl
# one binds block: Mod+Shift+D -> spawn "handy" "--toggle-transcription"

jq -r '.settings | [.selected_model, .selected_language, .paste_method,
  .overlay_style, (.custom_words[-1] | test(" "))] | @tsv' \
  ~/.local/share/com.pais.handy/settings_store.json
# whisper-large-v3-Q8_0.gguf  en  external_script  none  true
# Last field true = seed is final; its language must equal selected_language.
```

## Failure modes

| Symptom | Cause | Fix |
|---|---|---|
| Empty dictation, or the wrong room heard | Wrong default source | `wpctl status` -> `Audio/Sources`: `*` is the live default, `Default Configured Devices` can lag |
| Dropped Cyrillic, self-submitting dictation, or nothing typed | Handy fell back to its built-in paste path, which also needs X11 (`DISPLAY :12`) | Check `paste_method`/`external_script_path`, re-apply; `pgrep -a xwayland-satellite` |
| Translation, or no punctuation | Seed language != `selected_language`, seed not last, or `auto` | Pick a concrete language, `chezmoi apply` |
| "pinned model is missing" though a model exists | next-steps matches `whisper-large-v3-Q8_0.gguf` exactly | Settings -> Model, download it (~1.7 GB) |

## See also

- [workarounds.md](workarounds.md) - a row per workaround above.
