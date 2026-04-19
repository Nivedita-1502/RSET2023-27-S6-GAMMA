# backend/app/services/chatbot_service.py

import requests
import json

OLLAMA_URL = "http://localhost:11434/api/generate"

def chatbot_stream(prompt):
    payload = {
        "model": "phi3:mini",
        "prompt": prompt,
        "stream": True
    }

    response = requests.post(
        OLLAMA_URL,
        json=payload,
        stream=True
    )

    for line in response.iter_lines():
        if line:
            data = json.loads(line.decode("utf-8"))

            # ✅ Stop when Ollama signals completion
            if data.get("done"):
                break

            yield data.get("response", "")
