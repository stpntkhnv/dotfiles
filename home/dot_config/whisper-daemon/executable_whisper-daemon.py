#!/usr/bin/env python3

import asyncio
import os
import signal
import sys
import tempfile
from pathlib import Path

import uvicorn
from fastapi import FastAPI, File, Form, UploadFile
from fastapi.responses import JSONResponse

WHISPER_DIR = Path("/tmp/whisper")
SOCKET_PATH = WHISPER_DIR / "whisper.sock"
LANG_FILE = WHISPER_DIR / "lang"
MODEL_SIZE = os.environ.get("WHISPER_MODEL", "medium")
DEVICE = os.environ.get("WHISPER_DEVICE", "cuda")
COMPUTE_TYPE = os.environ.get("WHISPER_COMPUTE_TYPE", "float16")

app = FastAPI()
model = None


def load_model():
    global model
    from faster_whisper import WhisperModel

    print(f"Loading model '{MODEL_SIZE}' on {DEVICE} with {COMPUTE_TYPE}...")
    model = WhisperModel(MODEL_SIZE, device=DEVICE, compute_type=COMPUTE_TYPE)
    print("Model loaded.")


def get_default_language() -> str | None:
    try:
        lang = LANG_FILE.read_text().strip()
        return lang if lang else None
    except FileNotFoundError:
        return None


@app.post("/transcribe")
async def transcribe(
    audio: UploadFile = File(...),
    language: str | None = Form(None),
):
    if model is None:
        return JSONResponse(status_code=503, content={"error": "model not loaded"})

    lang = language or get_default_language()

    with tempfile.NamedTemporaryFile(suffix=".wav", delete=True) as tmp:
        content = await audio.read()
        tmp.write(content)
        tmp.flush()

        segments, info = model.transcribe(
            tmp.name,
            language=lang,
            beam_size=5,
            vad_filter=True,
            vad_parameters=dict(min_silence_duration_ms=500),
        )

        text = " ".join(seg.text.strip() for seg in segments)

    return {
        "text": text,
        "language": info.language,
        "language_probability": round(info.language_probability, 3),
    }


@app.get("/health")
async def health():
    return {"status": "ok", "model": MODEL_SIZE, "device": DEVICE}


def setup_socket():
    WHISPER_DIR.mkdir(parents=True, exist_ok=True)
    if SOCKET_PATH.exists():
        SOCKET_PATH.unlink()
    if not LANG_FILE.exists():
        LANG_FILE.write_text("en")


def main():
    setup_socket()
    load_model()

    config = uvicorn.Config(
        app,
        uds=str(SOCKET_PATH),
        log_level="info",
        timeout_keep_alive=30,
    )
    server = uvicorn.Server(config)

    def handle_signal(sig, frame):
        print(f"Received signal {sig}, shutting down...")
        sys.exit(0)

    signal.signal(signal.SIGTERM, handle_signal)
    signal.signal(signal.SIGINT, handle_signal)

    os.chmod(str(SOCKET_PATH.parent), 0o755)
    server.run()


if __name__ == "__main__":
    main()
