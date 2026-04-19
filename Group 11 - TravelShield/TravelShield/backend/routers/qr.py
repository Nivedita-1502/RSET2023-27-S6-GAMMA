"""
routers/qr.py  –  QR code safety checks (text + image upload).
"""

import os
import uuid
import pickle
import pandas as pd
import cv2

from fastapi import APIRouter, File, UploadFile
from core.config import UPLOAD_FOLDER

router = APIRouter(tags=["QR Detection"])

# ── Load model once at import time ────────────────────────────────────────────
try:
    qr_model = pickle.load(open("models/qr_model.pkl", "rb"))
except Exception:
    qr_model = None


# ── Helpers ───────────────────────────────────────────────────────────────────

def _extract_features(text: str) -> dict:
    return {
        "length":        len(text),
        "has_http":      int("http"     in text.lower()),
        "has_https":     int("https"    in text.lower()),
        "has_upi":       int("upi://"   in text.lower()),
        "has_short_url": int("bit.ly"   in text.lower() or "tinyurl" in text.lower()),
        "special_chars": sum(not c.isalnum() for c in text),
    }


def _classify(text: str) -> dict:
    if qr_model is None:
        return {"status": "error", "message": "QR model not loaded"}
    features = _extract_features(text)
    df = pd.DataFrame([features])
    prediction = qr_model.predict(df)[0]
    result = "malicious" if prediction == 1 else "safe"
    return {"status": "success", "result": result, "text": text}


# ── Routes ────────────────────────────────────────────────────────────────────

@router.post("/check_qr")
def check_qr(data: dict):
    try:
        text = data.get("text", "")
        return _classify(text)
    except Exception as e:
        return {"status": "error", "message": str(e)}


@router.post("/detect_qr_image")
async def detect_qr_image(file: UploadFile = File(...)):
    try:
        contents = await file.read()
        filename = str(uuid.uuid4()) + "_" + file.filename
        path = os.path.join(UPLOAD_FOLDER, filename)
        with open(path, "wb") as f:
            f.write(contents)

        img = cv2.imread(path)
        detector = cv2.QRCodeDetector()
        qr_text, _, _ = detector.detectAndDecode(img)

        if not qr_text:
            return {"status": "error", "message": "No QR code found"}
        return _classify(qr_text)
    except Exception as e:
        return {"status": "error", "message": str(e)}