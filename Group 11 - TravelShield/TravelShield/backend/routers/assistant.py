from fastapi import APIRouter
from pydantic import BaseModel
from nlp.service import analyze_input, price_check, speech_translate

router = APIRouter(prefix="/assistant", tags=["AI Assistant"])


# ---------- Request Models ----------
class TranslateRequest(BaseModel):
    text: str
    lang: str


class PriceCheckRequest(BaseModel):
    service: str
    charged_price: float
    quantity: int


class SpeechRequest(BaseModel):
    direction: str


# ---------- Routes ----------

@router.post("/translate")
def translate_text(request: TranslateRequest):
    return analyze_input(request.text, request.lang)


@router.post("/price-check")
def check_price(request: PriceCheckRequest):
    return price_check(
        request.service,
        request.charged_price,
        request.quantity
    )


@router.post("/speech-translate")
def speech_translate_api(request: SpeechRequest):
    return speech_translate(request.direction)