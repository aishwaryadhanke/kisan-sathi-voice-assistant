# backend/app/asr_service.py

from typing import Optional
import io
import numpy as np
import torch
import soundfile as sf
from scipy.signal import resample_poly
from transformers import AutoModelForCTC, Wav2Vec2Processor
from pathlib import Path

# --------- MODEL LOADING (auto-detect path) ---------
DEVICE = "cuda" if torch.cuda.is_available() else "cpu"

# Dynamically find your model folder (works anywhere)
PROJECT_ROOT = Path(__file__).resolve().parents[2]   # farmer_voice_assitant2/
MODEL_ID = PROJECT_ROOT / "model" / "asr"

print(f"Loading IndicWav2Vec ASR model from {MODEL_ID}, please wait...")
asr_model = AutoModelForCTC.from_pretrained(str(MODEL_ID)).to(DEVICE)
asr_processor = Wav2Vec2Processor.from_pretrained(str(MODEL_ID))
print("IndicWav2Vec ASR model loaded ✅")


# --------- AUDIO PROCESSING ---------
def _load_and_resample(audio_bytes: bytes, target_rate: int = 16000) -> torch.Tensor:
    """
    Load audio from bytes using soundfile, convert to mono, and resample to target_rate Hz.
    Returns a 1D torch.Tensor.
    """
    audio_file = io.BytesIO(audio_bytes)
    data, sample_rate = sf.read(audio_file)

    # Ensure mono
    if data.ndim == 2:
        data = data.mean(axis=1)

    data = data.astype(np.float32)

    if sample_rate != target_rate:
        data = resample_poly(data, target_rate, sample_rate).astype(np.float32)

    return torch.from_numpy(data)


# --------- TRANSCRIPTION FUNCTION ---------
def transcribe_audio(audio_bytes: bytes) -> Optional[str]:
    """
    Perform ASR using local IndicWav2Vec model.
    Takes raw audio bytes (WAV/MP3 readable by soundfile) and returns transcription.
    """
    if not audio_bytes:
        return None

    try:
        # Step 1️⃣ - Load & Resample
        waveform = _load_and_resample(audio_bytes, target_rate=16000)

        # Step 2️⃣ - Prepare model input
        inputs = asr_processor(
            waveform.numpy(),
            sampling_rate=16000,
            return_tensors="pt",
            padding=True,
        )

        # Step 3️⃣ - Run model
        with torch.no_grad():
            logits = asr_model(inputs.input_values.to(DEVICE)).logits.cpu()

        # Step 4️⃣ - Decode output
        predicted_ids = torch.argmax(logits, dim=-1)
        text = asr_processor.batch_decode(predicted_ids)[0]

        return text.strip()

    except Exception as e:
        print(f"[ASR ERROR] {e}")
        return None
