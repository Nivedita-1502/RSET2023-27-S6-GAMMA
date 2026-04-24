"""
routers/alerts.py  –  District-level travel alerts via GNews + Groq summarisation.
"""

import httpx
from datetime import datetime, timedelta, timezone
from typing import List, Optional

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel
from core.config import GNEWS_API_KEY, GROQ_API_KEY, GROQ_MODEL, logger

router = APIRouter(tags=["Travel Alerts"])

# ── Keyword lists ─────────────────────────────────────────────────────────────

TOURISM_KEYWORDS = [
    "rain","rainfall","heavy rain","flood","flooding","landslide","landslips",
    "cyclone","storm","cloudburst","inundation","red alert","orange alert",
    "yellow alert","high tide","rough sea","tsunami","earthquake","waterlogging",
    "road closed","road block","highway blocked","traffic block","traffic jam",
    "ghat road","nh blocked","transport strike","bus strike","hartal","bandh",
    "train cancelled","flight cancelled","airport closed","ferry suspended",
    "festival","procession","crowd","rush","yatra","pilgrimage","onam","vishu",
    "thrissur pooram","sabarimala","tourist alert","travel advisory",
    "travel warning","wildlife","elephant","tiger","leopard","wild animal",
    "snake bite","bee attack","disease outbreak","dengue","leptospirosis",
    "cholera","food poisoning","health alert","epidemic",
    "tourist","tourism","traveller","visitor","beach closed","trekking ban",
    "forest closed","entry banned","rescue operation","missing tourist","accident",
]

EXCLUDE_KEYWORDS = [
    "stock market","share price","sensex","nifty","ipl","cricket score",
    "match result","bollywood","celebrity wedding","film release",
    "election result","political rally","lok sabha","assembly poll",
]

HIGH_SEVERITY = [
    "red alert","flood","flooding","landslide","landslip","cyclone","tsunami",
    "earthquake","disease outbreak","emergency","evacuation","road closed",
    "nh blocked","transport strike","hartal","bandh","rescue operation",
    "missing tourist","fatal","death","killed",
]

MEDIUM_SEVERITY = [
    "heavy rain","orange alert","yellow alert","waterlogging","traffic block",
    "traffic jam","crowd","rush","flight cancelled","train cancelled",
    "ferry suspended","wildlife","elephant","health alert","dengue",
    "high tide","rough sea","ghat road","accident",
]


# ── Schemas ───────────────────────────────────────────────────────────────────

class NewsArticle(BaseModel):
    title:        str
    url:          str
    source:       str
    published_at: str
    description:  Optional[str] = None


class DistrictAlertResponse(BaseModel):
    district:       str
    alert_level:    str
    alert_summary:  str
    news_articles:  List[NewsArticle]
    total_fetched:  int
    total_filtered: int
    fetched_at:     str


# ── Helpers ───────────────────────────────────────────────────────────────────

def _filter_tourism_news(articles):
    kept = []
    for article in articles:
        text = f"{article['title']} {article['description']}".lower()
        if any(kw in text for kw in TOURISM_KEYWORDS):
            kept.append(article)
        elif not any(kw in text for kw in EXCLUDE_KEYWORDS):
            kept.append(article)
    return kept


def _calculate_alert_level(articles):
    combined = " ".join(
        f"{a.get('title','')} {a.get('description','')}".lower()
        for a in articles
    )
    high_hits   = sum(1 for kw in HIGH_SEVERITY   if kw in combined)
    medium_hits = sum(1 for kw in MEDIUM_SEVERITY if kw in combined)
    if high_hits >= 2:   return "HIGH"
    if high_hits >= 1:   return "MEDIUM"
    if medium_hits >= 2: return "MEDIUM"
    if medium_hits >= 1: return "LOW"
    return "LOW"


async def _fetch_gnews(district: str):
    if not GNEWS_API_KEY:
        raise ValueError("GNEWS_API_KEY is not set.")
    from_date = (datetime.now(timezone.utc) - timedelta(days=7)).strftime("%Y-%m-%dT%H:%M:%SZ")
    params = {
        "q":       f'"{district}" Kerala',
        "lang":    "en",
        "country": "in",
        "from":    from_date,
        "max":     10,
        "sortby":  "publishedAt",
        "apikey":  GNEWS_API_KEY,
    }
    async with httpx.AsyncClient(timeout=20.0) as client:
        response = await client.get("https://gnews.io/api/v4/search", params=params)
        if response.status_code == 403:
            raise PermissionError("GNews API key invalid or quota exceeded.")
        if response.status_code != 200:
            raise ConnectionError(f"GNews API returned {response.status_code}")
        articles = response.json().get("articles", [])
        return [
            {
                "title":        (a.get("title")                       or "").strip(),
                "description":  (a.get("description")                 or "").strip(),
                "url":          (a.get("url")                         or "").strip(),
                "source":       (a.get("source", {}).get("name")      or "Unknown").strip(),
                "published_at": (a.get("publishedAt")                 or "").strip(),
            }
            for a in articles
        ]


async def _groq_news_summary(district: str, articles: list) -> str:
    if not GROQ_API_KEY:
        raise ValueError("GROQ_API_KEY is not set.")
    lines = []
    for i, a in enumerate(articles[:8], 1):
        desc = a.get("description", "").strip()
        lines.append(
            f"{i}. [{a.get('source','?')} | {a.get('published_at','')[:10]}] {a.get('title','')}"
            + (f"\n   {desc}" if desc else "")
        )
    prompt = f"""You are a travel safety assistant for Kerala tourism.
Write a SHORT, ACCURATE travel safety alert for tourists in {district} district RIGHT NOW.
- Start with "⚠ Travel Alert – {district} District" if concerns exist.
- Start with "✅ {district} District – Safe for Travel" if all clear.
- 3–4 sentences max. Factual and direct.

NEWS:
{chr(10).join(lines)}

Write the alert:"""

    headers = {
        "Authorization": f"Bearer {GROQ_API_KEY}",
        "Content-Type":  "application/json",
    }
    payload = {
        "model":       GROQ_MODEL,
        "messages":    [{"role": "user", "content": prompt}],
        "temperature": 0.3,
        "max_tokens":  300,
    }
    async with httpx.AsyncClient(timeout=30.0) as client:
        response = await client.post(
            "https://api.groq.com/openai/v1/chat/completions",
            json=payload, headers=headers,
        )
        if response.status_code != 200:
            raise ConnectionError(f"Groq returned {response.status_code}")
        return response.json()["choices"][0]["message"]["content"].strip()


# ── Routes ────────────────────────────────────────────────────────────────────

@router.get("/districts")
def list_districts():
    return {
        "districts": [
            # 14 Official Districts
            "Thiruvananthapuram", "Kollam", "Pathanamthitta", "Alappuzha",
            "Kottayam", "Idukki", "Ernakulam", "Thrissur", "Palakkad",
            "Malappuram", "Kozhikode", "Wayanad", "Kannur", "Kasaragod",
            # Popular Tourist Destinations
            "Munnar", "Alleppey", "Kochi", "Kovalam", "Varkala",
            "Thekkady", "Kumarakom", "Bekal", "Athirappilly", "Marari Beach",
            "Ponmudi", "Vagamon", "Nelliampathi", "Poovar", "Guruvayur",
            "Sabarimala", "Silent Valley", "Peermade", "Thattekkad",
        ]
    }


@router.get("/district-news", response_model=DistrictAlertResponse)
async def get_district_news(district: str = Query(..., example="Idukki")):
    logger.info(f"District news request: {district}")
    try:
        raw_articles = await _fetch_gnews(district)
    except ValueError:
        return DistrictAlertResponse(
            district=district, alert_level="NONE",
            alert_summary=(
                f"⚠️ Demo Mode – Add GNEWS_API_KEY to enable real alerts. "
                f"{district} appears generally safe."
            ),
            news_articles=[], total_fetched=0, total_filtered=0,
            fetched_at=datetime.now(timezone.utc).isoformat(),
        )
    except Exception as e:
        raise HTTPException(status_code=502, detail=str(e))

    tourism_articles = _filter_tourism_news(raw_articles)
    alert_level      = _calculate_alert_level(tourism_articles)

    try:
        summary = (
            await _groq_news_summary(district, tourism_articles)
            if tourism_articles
            else f"✅ No major travel alerts in {district} district. Conditions appear safe for tourism."
        )
    except Exception:
        summary = f"✅ {district} – Alerts unavailable. Please check local conditions."

    return DistrictAlertResponse(
        district=district,
        alert_level=alert_level,
        alert_summary=summary,
        news_articles=[
            NewsArticle(
                title=a["title"], url=a["url"], source=a["source"],
                published_at=a["published_at"], description=a.get("description"),
            )
            for a in tourism_articles
        ],
        total_fetched=len(raw_articles),
        total_filtered=len(tourism_articles),
        fetched_at=datetime.now(timezone.utc).isoformat(),
    )