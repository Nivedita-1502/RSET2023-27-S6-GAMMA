"""
routers/currency.py  -  Fake / real currency note detection via CNN.
"""

import os
import uuid
import numpy as np
from PIL import Image

from fastapi import APIRouter, File, UploadFile
from core.config import UPLOAD_FOLDER

router = APIRouter(tags=["Currency Detection"])

# ── Load model once at import time ────────────────────────────────────────────
try:
    import tensorflow as tf
    currency_model = tf.keras.models.load_model("models/currency_cnn_model.h5")
except Exception:
    currency_model = None


# ── Route ─────────────────────────────────────────────────────────────────────

@router.post("/detect_currency")
async def detect_currency(file: UploadFile = File(...)):
    try:
        if currency_model is None:
            return {"status": "error", "message": "Currency model not loaded"}

        contents = await file.read()
        filename = str(uuid.uuid4()) + "_" + file.filename
        path = os.path.join(UPLOAD_FOLDER, filename)
        with open(path, "wb") as f:
            f.write(contents)

        img = Image.open(path).convert("RGB")
        img = img.resize((224, 224))
        img = np.array(img) / 255.0
        img = np.expand_dims(img, axis=0)

        prediction  = currency_model.predict(img)[0][0]
        real_prob   = float(prediction)
        fake_prob   = 1 - real_prob
        label       = "Real Note" if real_prob > fake_prob else "Fake Note"

        return {
            "status":           "success",
            "prediction":       label,
            "real_probability": round(real_prob * 100, 2),
            "fake_probability": round(fake_prob * 100, 2),
        }
    except Exception as e:
        return {"status": "error", "message": str(e)}