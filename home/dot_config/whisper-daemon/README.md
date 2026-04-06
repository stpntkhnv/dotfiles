# Voice-to-Text Pipeline

## Architecture

The pipeline consists of three layers: **audio recording** -> **transcription** -> **text insertion**. Controlled by a single **F9** key in toggle mode (press to start recording, press again to stop and transcribe). **Shift+F9** cancels without transcribing.

## Components

### 1. Whisper Daemon — `~/.config/whisper-daemon/whisper-daemon.py`

FastAPI server on `faster-whisper`. Runs as a systemd user service, listens on Unix socket `/tmp/whisper/whisper.sock`.

- **Model**: read from `/tmp/whisper/model` at startup (fallback to env `WHISPER_MODEL`, default `large-v3`)
- **GPU**: CUDA, float16
- **Endpoints**: `POST /transcribe` (accepts WAV, returns JSON with text), `GET /health`
- **VAD**: built-in voice activity detection with 500ms silence threshold, 400ms speech padding
- **Vocabulary hints**: reads `~/.config/whisper-daemon/vocab.txt` and passes as `initial_prompt` to bias toward specific terms

**Systemd unit**: `~/.config/systemd/user/whisper-daemon.service` — autostart, restart on failure, `LD_LIBRARY_PATH` setup for CUDA/cuDNN.

### 2. Voice Input — `~/bin/voice-input.sh`

Main script, manages the entire process. Modes: `start`, `stop`, `cancel`, `toggle`.

**toggle** (called by F9):
- If PID file `/tmp/whisper/recording.pid` is alive -> calls `stop`
- Otherwise -> calls `start`

**start**:
- Launches `rec` (SoX) in background via `setsid`: raw PCM, 16kHz, 16-bit, mono -> `/tmp/whisper/recording.raw`
- Writes `recording` to meter state file
- Plays start sound effect
- Launches voice-meter window (foot terminal with equalizer)
- Saves PIDs of both processes

**stop**:
- Plays stop sound, writes `processing` to meter state (meter shows bouncing progress bar)
- Waits 0.8s (`TAIL_SILENCE_SEC`) for `rec` buffer flush
- Sends `SIGINT` to `rec` process, waits for termination
- Converts raw -> WAV via `sox` with 0.8s silence padding at the end
- Sends WAV to daemon via `curl --unix-socket`
- Parses JSON response via `jq`
- Copies text to clipboard (`wl-copy`) and pastes (`wtype Ctrl+Shift+V`)
- Writes `done` to meter state (meter shows green checkmark for 2s)
- Plays done sound effect

**cancel** (called by Shift+F9):
- Kills recording, discards audio, closes meter
- Plays cancel sound, no transcription

**Sound effects**: generated inline via `sox play` with synth — distinct sounds for start, stop, done, cancel, error.

**Log**: `/tmp/whisper/voice-input.log`

### 3. Voice Meter — `~/bin/voice-meter.sh`

Visual recording indicator — scrolling waveform equalizer in a floating foot terminal.

Three states driven by `/tmp/whisper/meter.state`:

**recording**:
- Runs continuous `parec` stream (PipeWire/PulseAudio, 16kHz, mono, `--latency-msec=50`)
- Every ~0.05s reads a 1600-byte chunk from the stream
- Computes peak amplitude via `sox stat`
- Maintains history of 14 most recent values
- Renders via `awk`: 14 columns x 6 rows height, unicode blocks `▁▂▃▄▅▆▇█`
- Color by height: green (0-60%) -> yellow (60-80%) -> red (80-100%)
- Status bar: `●REC` (red) on the left, `EN·L` (dim) on the right — shows current language and model
- Thin separator line between equalizer and status bar

**processing**:
- Bouncing light bar animation (Knight Rider style), cyan color
- Status bar: `◎···` with language/model tag

**done**:
- Green checkmark ASCII art
- Status bar: `✓ OK`
- Auto-exits after 2 seconds

**Window**: `foot --app-id voice-meter -W 14x8 -o pad=6x4`, Hyprland windowrule makes it floating, pinned, no animation, thin border (`#45475a`), no focus.

### 4. Vocabulary File — `~/.config/whisper-daemon/vocab.txt`

Plain text, one word/phrase per line. Lines starting with `#` are comments. Read on every transcription request (no daemon restart needed). Biases Whisper toward specific spellings of technical terms, names, etc.

## Helper Scripts

| Script | Purpose |
|---|---|
| `~/bin/whisper-lang-switch.sh` | Cycle language: en -> ru -> pl. Writes to `/tmp/whisper/lang`, updates Waybar (signal 8) |
| `~/bin/whisper-lang-status.sh` | JSON output of current language for Waybar |
| `~/bin/whisper-model-switch.sh` | Cycle model: medium -> large-v3 -> turbo. Writes to `/tmp/whisper/model`, restarts daemon, updates Waybar (signal 9) |
| `~/bin/whisper-model-status.sh` | JSON output of current model for Waybar |

## Waybar Integration

Four custom modules in `~/.config/waybar/config`:

| Module | Group | Display | Update |
|---|---|---|---|
| `custom/gpu` | hardware | `󰢮 3.8G` — used VRAM | interval 5s |
| `custom/memory` | hardware | `󰍛 5G` — used RAM | interval 5s |
| `custom/whisper-model` | system | `󰗊 L` — current model (M/L/T) | signal 9, click to switch |
| `custom/voice-lang` | system | `EN`/`RU`/`PL` — transcription language | signal 8, click to switch |

GPU and RAM show only used amount; full info (total, percentage, top processes) is in the tooltip.

Styles in `~/.config/waybar/style.css`: GPU — teal, whisper-model — sky.

## Hyprland Keybindings

```
bind = , F9, exec, ~/bin/voice-input.sh toggle
bind = SHIFT, F9, exec, ~/bin/voice-input.sh cancel
```

Window rule for voice-meter:
```
windowrule = match:class ^(voice-meter)$, float on, pin on, move monitor_w-240 monitor_h-250, no_anim on, border_size 2, border_color rgb(45475a), no_focus on
```

## Runtime Files — `/tmp/whisper/`

| File | Purpose |
|---|---|
| `whisper.sock` | Daemon Unix socket |
| `lang` | Current language (en/ru/pl) |
| `model` | Current model (medium/large-v3/turbo) |
| `recording.pid` | PID of rec process |
| `meter.pid` | PID of foot meter process |
| `meter.state` | Meter UI state (recording/processing/done) |
| `recording.raw` | Raw audio file (temporary) |
| `recording.wav` | Converted WAV (temporary) |
| `voice-input.log` | Operation log |

## Configuration Management

All files are managed via **chezmoi**, sources in `~/.local/share/chezmoi/home/`. Apply: `chezmoi apply --force`.

## TODO

- [ ] **Kando + AGS config panel** — build a visual settings menu using Kando and AGS for model selection (medium/large-v3/turbo), language switching (en/ru/pl), and other pipeline settings, replacing the current Waybar click-to-cycle approach
- [ ] **Standalone CLI package** — extract the pipeline into a self-contained, configurable CLI tool (possibly a Rust binary) that can be installed independently of the dotfiles repo, with proper config file, argument parsing, and plugin-friendly architecture
