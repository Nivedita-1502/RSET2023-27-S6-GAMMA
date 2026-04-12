"""
main.py  -  Kerala Travel Backend entry point.

Project structure
─────────────────
main.py                   ← you are here (start the server from here)
core/
    config.py             ← API keys, logging, shared constants
    database.py           ← SQLite connection + table initialisation
routers/
    auth.py               ← POST /signup  POST /login  GET /profile/{email}
    qr.py                 ← POST /check_qr  POST /detect_qr_image
    currency.py           ← POST /detect_currency
    clothing.py           ← GET  /clothing_suggestion/{city}
    chatbot.py            ← POST /chat
    alerts.py             ← GET  /districts  GET /district-news
    trips.py              ← CRUD /trips  /trips/{trip_id}
    itinerary.py          ← POST /itinerary/generate
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from core.database import init_db

# ── Feature routers ───────────────────────────────────────────────────────────
from routers import auth, qr, currency, clothing, chatbot, alerts, trips, itinerary
from routers import assistant
from routers import sos
from routers import otp

# ── App ───────────────────────────────────────────────────────────────────────

app = FastAPI(
    title="Kerala Travel Backend",
    description="TravelShield AI – safety, chatbot, alerts, trip planning for Kerala tourism.",
    version="2.0.0",
)


app.include_router(otp.router)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Startup ───────────────────────────────────────────────────────────────────

@app.on_event("startup")
def on_startup():
    """Initialise database tables on first run."""
    init_db()

# ── Health / home ─────────────────────────────────────────────────────────────

@app.get("/", tags=["Health"])
def home():
    return {"message": "Kerala Travel Backend Running"}

@app.get("/health", tags=["Health"])
def health():
    return {"status": "ok", "service": "Kerala Travel Backend"}

# ── Mount routers ─────────────────────────────────────────────────────────────
#   No prefix — all routes keep their original paths, zero conflicts.

app.include_router(auth.router)
app.include_router(qr.router)
app.include_router(currency.router)
app.include_router(clothing.router)
app.include_router(chatbot.router)
app.include_router(alerts.router)
app.include_router(trips.router)
app.include_router(itinerary.router)
app.include_router(assistant.router)
app.include_router(sos.router)  