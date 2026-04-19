"""
routers/sos.py  -  SOS location handling with improved reverse geocoding.
Returns clean, human-readable address with road, area, city and district.
"""

from fastapi import APIRouter
import requests

router = APIRouter(tags=["SOS"])


# ── Reverse geocode: returns clean structured address ─────────────────────────

def get_place_details(lat: float, lon: float) -> dict:
    """
    Reverse geocode coordinates using Nominatim.
    Returns a clean human-readable name + structured address breakdown.
    zoom=16 gives neighbourhood/area level — more recognizable than zoom=18
    """
    url = "https://nominatim.openstreetmap.org/reverse"
    params = {
        "lat":            lat,
        "lon":            lon,
        "zoom":           16,       # 16 = neighbourhood level (more readable)
        "addressdetails": 1,        # return full address breakdown
        "format":         "json",
        "accept-language": "en",    # always return English names
    }
    headers = {"User-Agent": "TravelShield-SOS-App"}

    try:
        response = requests.get(url, params=params, headers=headers, timeout=8)
        data     = response.json()
        addr     = data.get("address", {})

        # ── Build a clean short name ──────────────────────────────────────────
        # Priority: road/suburb → city/town/village → district → state
        short_name = (
            addr.get("road")         or
            addr.get("suburb")       or
            addr.get("neighbourhood") or
            addr.get("village")      or
            addr.get("town")         or
            addr.get("city")         or
            addr.get("county")       or
            data.get("name")         or
            f"{lat:.5f}, {lon:.5f}"
        )

        # ── Build a readable full address ─────────────────────────────────────
        parts = [
            addr.get("road"),
            addr.get("suburb") or addr.get("neighbourhood"),
            addr.get("village") or addr.get("town") or addr.get("city"),
            addr.get("state_district") or addr.get("county"),
            addr.get("state"),
            addr.get("postcode"),
        ]
        full_address = ", ".join(p for p in parts if p)

        return {
            "short_name":   short_name,
            "full_address": full_address or data.get("display_name", ""),
            "road":         addr.get("road", ""),
            "area":         addr.get("suburb") or addr.get("neighbourhood") or "",
            "city":         addr.get("city") or addr.get("town") or addr.get("village") or "",
            "district":     addr.get("state_district") or addr.get("county") or "",
            "state":        addr.get("state", ""),
            "postcode":     addr.get("postcode", ""),
            "country":      addr.get("country", ""),
        }

    except Exception:
        # Fallback: return raw coordinates if geocoding fails
        return {
            "short_name":   f"{lat:.5f}, {lon:.5f}",
            "full_address": f"{lat:.6f}, {lon:.6f}",
            "road": "", "area": "", "city": "",
            "district": "", "state": "", "postcode": "", "country": "",
        }


# ── SOS endpoint ──────────────────────────────────────────────────────────────

@router.post("/send_location")
def receive_location(data: dict):
    lat = float(data["latitude"])
    lon = float(data["longitude"])
    acc = data.get("accuracy", None)   # optional accuracy in meters

    place   = get_place_details(lat, lon)
    maps_link = f"https://www.google.com/maps?q={lat},{lon}"

    # Log to console
    print(f"🚨 SOS | {place['short_name']} | {place['full_address']} | {maps_link}")
    if acc:
        print(f"   Accuracy: ±{acc}m")

    return {
        "status":       "SOS received",
        "place":        place["short_name"],       # short readable name
        "full_address": place["full_address"],     # full address string
        "address":      place,                     # structured breakdown
        "maps":         maps_link,
        "coordinates": {
            "latitude":  lat,
            "longitude": lon,
            "accuracy":  acc,
        }
    }