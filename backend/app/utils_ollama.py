# backend/app/utils_ollama.py

import requests

# 👇 Ollama server URL (default for Windows)
OLLAMA_URL = "http://127.0.0.1:11434/api/generate"

# 👇 Which model to use (you already have this downloaded)
DEFAULT_MODEL = "llama3.2:3b"
# If your PC is strong and you want better answers, you can change to:
# DEFAULT_MODEL = "llama3:8b"


def call_ollama(prompt: str, model: str = DEFAULT_MODEL, timeout: int = 25) -> str | None:
    """
    Call local Ollama server and return generated text.
    Returns None if there is any error, so backend can use fallback.
    """
    payload = {
        "model": model,
        "prompt": prompt,
        "stream": False,   # important: get single JSON, not streaming chunks
    }

    try:
        resp = requests.post(OLLAMA_URL, json=payload, timeout=timeout)
        resp.raise_for_status()

        data = resp.json()
        text = (data.get("response") or "").strip()

        if not text:
            print("[OLLAMA] Empty response from model")
            return None

        print(f"[OLLAMA OK] model={model}, chars={len(text)}")
        return text

    except requests.exceptions.Timeout:
        print(f"[OLLAMA ERROR] Timeout after {timeout}s while calling {model}")
        return None

    except Exception as e:
        print(f"[OLLAMA ERROR] {e}")
        return None
