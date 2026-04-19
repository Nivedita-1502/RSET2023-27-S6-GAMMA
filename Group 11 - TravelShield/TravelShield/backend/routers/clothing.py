"""
routers/clothing.py  –  Weather-based clothing suggestions via OpenWeatherMap.
"""

import requests
from fastapi import APIRouter
from core.config import OPENWEATHER_API_KEY

router = APIRouter(tags=["Clothing Suggestions"])


@router.get("/clothing_suggestion/{city}")
def clothing_suggestion(city: str):
    try:
        url = (
            f"https://api.openweathermap.org/data/2.5/weather"
            f"?q={city}&appid={OPENWEATHER_API_KEY}&units=metric"
        )
        response = requests.get(url).json()

        if "main" not in response:
            return {"status": "error", "message": response.get("message", "Weather API error")}

        temp    = response["main"]["temp"]
        weather = response["weather"][0]["main"]

        suggestions = []
        if temp < 18:
            suggestions += ["Warm jacket", "Sweater", "Full pants"]
        elif temp < 25:
            suggestions += ["Light jacket", "Jeans", "Sneakers"]
        else:
            suggestions += ["T-shirt", "Shorts", "Cap"]

        if weather.lower() == "rain":
            suggestions += ["Raincoat", "Umbrella"]

        return {
            "status":      "success",
            "city":        city,
            "temperature": temp,
            "weather":     weather,
            "suggestions": suggestions,
        }
    except Exception as e:
        return {"status": "error", "message": str(e)}