"""
routers/chatbot.py  –  TravelShield AI chatbot powered by Groq.
"""

import httpx
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from core.config import GROQ_API_KEY, GROQ_MODEL

router = APIRouter(tags=["Chatbot"])

# ── System prompt ─────────────────────────────────────────────────────────────

CHATBOT_SYSTEM_PROMPT = """
You are TravelShield AI, a friendly and expert Kerala Tourism Assistant.
Your role is to help tourists visiting Kerala, India with:
1. Travel Safety – safety tips, emergency guidance, weather alerts
2. Food Recommendations – suggest restaurants, local cuisine near a location
3. Accommodation Suggestions – hotels, homestays, budget stays, resorts
4. Tourist Place Guidance – best time, entry fees, nearby attractions
5. Travel Planning Tips – what to carry, cultural etiquette, transportation
6. Emotional Support – calm anxious or lost tourists
7. Location-Based Suggestions – tailor response to user location

RULES:
- Only answer questions related to Kerala tourism
- Be warm, empathetic, and supportive
- For emergencies, mention Kerala Tourism Helpline: 1800-425-4747
- Keep responses concise, helpful, and friendly
- Use cultural warmth ("Namaskaram!", "God's Own Country", etc.)
"""


# ── Schemas ───────────────────────────────────────────────────────────────────

class ChatRequest(BaseModel):
    message:  str       = Field(..., min_length=1, max_length=2000)
    location: str | None = Field(None, max_length=200)


class ChatResponse(BaseModel):
    reply: str


# ── Helper ────────────────────────────────────────────────────────────────────

def _build_user_message(message: str, location: str | None) -> str:
    if location and location.strip():
        return f"[User's current location: {location.strip()}]\n\n{message}"
    return message


# ── Route ─────────────────────────────────────────────────────────────────────

@router.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    if not GROQ_API_KEY:
        raise HTTPException(status_code=503, detail="GROQ_API_KEY is not configured.")

    user_content = _build_user_message(request.message, request.location)
    headers = {
        "Authorization": f"Bearer {GROQ_API_KEY}",
        "Content-Type":  "application/json",
    }
    payload = {
        "model": GROQ_MODEL,
        "messages": [
            {"role": "system", "content": CHATBOT_SYSTEM_PROMPT},
            {"role": "user",   "content": user_content},
        ],
        "max_tokens":  1024,
        "temperature": 0.7,
    }

    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                "https://api.groq.com/openai/v1/chat/completions",
                json=payload, headers=headers,
            )
        if response.status_code != 200:
            raise HTTPException(status_code=503, detail=f"Groq API error {response.status_code}")
        data = response.json()
        return ChatResponse(reply=data["choices"][0]["message"]["content"].strip())
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(status_code=500, detail="An unexpected error occurred.")