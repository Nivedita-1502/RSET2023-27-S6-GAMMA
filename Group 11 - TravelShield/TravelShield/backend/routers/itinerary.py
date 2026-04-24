"""
routers/itinerary.py  –  AI itinerary generator (Groq first, hardcoded fallback).
"""

import json
from datetime import datetime, timedelta

import httpx
from fastapi import APIRouter, HTTPException
from core.config import GROQ_API_KEY, GROQ_MODEL, logger

router = APIRouter(tags=["Itinerary"])

# ── Hardcoded destination data ────────────────────────────────────────────────

KERALA_ITINERARY_DATA = {
    "Munnar": {
        "places": [
            {"name": "Eravikulam National Park",  "time": "2h",      "desc": "Home to Nilgiri Tahr, misty grasslands and stunning valley views.",             "activity": "Wildlife spotting, Photography"},
            {"name": "Kanan Devan Tea Estate",     "time": "1.5h",    "desc": "Sprawling tea plantations with factory tour and tea tasting.",                  "activity": "Tea tasting, Factory tour"},
            {"name": "Mattupetty Dam",             "time": "1.5h",    "desc": "Scenic reservoir surrounded by lush hills, great for boating.",                  "activity": "Boating, Picnic"},
            {"name": "Echo Point",                 "time": "1h",      "desc": "A natural phenomenon where your voice echoes back from hills.",                  "activity": "Echo test, Photography"},
            {"name": "Top Station",                "time": "2h",      "desc": "Highest point in Munnar with panoramic views of Tamil Nadu border.",             "activity": "Trekking, Sunrise viewing"},
            {"name": "Attukal Waterfalls",         "time": "1h",      "desc": "Scenic waterfalls along the Munnar-Kodaikanal road.",                            "activity": "Swimming, Photography"},
            {"name": "Munnar Town Market",         "time": "1h",      "desc": "Local market with spices, tea, cardamom and handicrafts.",                       "activity": "Shopping, Street food"},
            {"name": "Chinnar Wildlife Sanctuary", "time": "3h",      "desc": "Dry deciduous forest with elephants, leopards and giant grizzled squirrels.",    "activity": "Safari, Trekking"},
        ],
        "food": [
            "Puttu and Kadala Curry at Rapsy Restaurant",
            "Kerala Sadhya at Hotel Copper Castle",
            "Cardamom Tea at any tea shop",
            "Beef Fry at local toddy shops",
        ],
        "tips": [
            "Carry a light jacket — temperatures drop at night",
            "Book Eravikulam tickets online in advance",
            "Best visited Sep–Mar for clear skies",
            "Hire a local guide for trekking",
        ],
    },
    "Alleppey": {
        "places": [
            {"name": "Alleppey Houseboat Cruise", "time": "Full day", "desc": "Overnight or day cruise through Kerala's iconic backwater network.",           "activity": "Boating, Fishing, Relaxing"},
            {"name": "Vembanad Lake",             "time": "2h",       "desc": "Largest lake in Kerala, famous for the Nehru Trophy Boat Race.",               "activity": "Sunset cruise, Photography"},
            {"name": "Alleppey Beach",            "time": "1.5h",     "desc": "Serene beach with an old lighthouse and gentle waves.",                        "activity": "Swimming, Beach walk"},
            {"name": "Krishnapuram Palace",       "time": "1.5h",     "desc": "18th century palace museum with murals and antique collections.",               "activity": "Heritage tour, Photography"},
            {"name": "Marari Beach",              "time": "2h",       "desc": "Pristine secluded beach popular among foreign tourists for Ayurveda.",          "activity": "Ayurveda, Beach relaxing"},
            {"name": "Pathiramanal Island",       "time": "2h",       "desc": "Bird sanctuary island accessible by boat with 100+ bird species.",              "activity": "Bird watching, Boat ride"},
        ],
        "food": [
            "Karimeen Pollichathu at Harbour Restaurant",
            "Prawn Curry at Thaff Restaurant",
            "Kerala Fish Curry at any backwater shack",
            "Toddy with spicy fish at local kalahs",
        ],
        "tips": [
            "Book houseboat 2–3 weeks in advance",
            "Negotiate houseboat rates directly",
            "Carry mosquito repellent for evenings",
            "Nov–Feb is best season",
        ],
    },
    "Wayanad": {
        "places": [
            {"name": "Edakkal Caves",            "time": "2.5h", "desc": "Ancient caves with 6000-year-old pictorial writings and carvings.",                 "activity": "Trekking, Archaeological exploration"},
            {"name": "Chembra Peak",             "time": "4h",   "desc": "Highest peak in Wayanad with a heart-shaped lake halfway up.",                     "activity": "Trekking, Camping"},
            {"name": "Banasura Sagar Dam",       "time": "1.5h", "desc": "Largest earthen dam in India surrounded by misty hills.",                          "activity": "Boating, Photography"},
            {"name": "Muthanga Wildlife Sanctuary","time": "3h", "desc": "Part of Nilgiri Biosphere with elephants, tigers and leopards.",                   "activity": "Jeep safari, Wildlife spotting"},
            {"name": "Soochipara Waterfalls",    "time": "2h",   "desc": "Three-tiered waterfall cascading through dense forest.",                           "activity": "Swimming, Trekking"},
            {"name": "Thirunelli Temple",        "time": "1.5h", "desc": "Ancient Vishnu temple in the forest, called the Kashi of the South.",              "activity": "Pilgrimage, Photography"},
        ],
        "food": [
            "Bamboo Biryani at Pepper County",
            "Tribal cuisine at Vythiri Resort",
            "Wayanad coffee and spice tea",
            "Wild mushroom curry at forest lodges",
        ],
        "tips": [
            "Get trekking permits from Forest Dept in advance",
            "Oct–May best season, avoid peak monsoon",
            "Carry leech socks for forest treks",
            "Hire a guide for Chembra Peak",
        ],
    },
    "Kochi": {
        "places": [
            {"name": "Fort Kochi Chinese Fishing Nets", "time": "1h",   "desc": "Iconic cantilevered fishing nets from 14th century Chinese traders.",        "activity": "Photography, Watch fishing"},
            {"name": "Mattancherry Palace",            "time": "1.5h",  "desc": "Portuguese palace with stunning Kerala murals depicting Ramayana.",           "activity": "Heritage tour, Art viewing"},
            {"name": "Jewish Synagogue & Jew Town",    "time": "1h",    "desc": "400-year-old synagogue with Belgian chandeliers and antique spice market.",   "activity": "Heritage visit, Shopping"},
            {"name": "Marine Drive",                   "time": "1h",    "desc": "Waterfront promenade perfect for evening walks and people watching.",          "activity": "Strolling, Sunset viewing"},
            {"name": "Cherai Beach",                   "time": "2h",    "desc": "Clean beach near Kochi known for dolphins and Chinese fishing nets.",          "activity": "Swimming, Dolphin spotting"},
            {"name": "Kerala Folklore Museum",         "time": "1.5h",  "desc": "Museum with 4000+ artefacts spanning 3 floors of Kerala's history.",          "activity": "Cultural tour, Photography"},
        ],
        "food": [
            "Seafood at Fort House Restaurant",
            "Appam and Stew at Dhe Puttu",
            "Kerala breakfast at Idly Kadala shops",
            "Biryani at Kayees Rahmathulla Hotel",
        ],
        "tips": [
            "Take the KSWTD ferry between Fort Kochi and Ernakulam",
            "Walk around Fort Kochi — most attractions are close",
            "Visit during Biennale (Dec–Mar) for art events",
            "Bargain at Jew Town antique shops",
        ],
    },
    "Kovalam": {
        "places": [
            {"name": "Lighthouse Beach",              "time": "2h",  "desc": "Most popular beach with a lighthouse, cafes and water sports.",               "activity": "Swimming, Surfing, Sunbathing"},
            {"name": "Hawa Beach",                    "time": "1.5h","desc": "Calm crescent beach ideal for swimming and relaxing.",                        "activity": "Swimming, Ayurveda massage"},
            {"name": "Samudra Beach",                 "time": "1h",  "desc": "Quiet beach away from crowds, popular with fishermen.",                       "activity": "Peaceful walk, Photography"},
            {"name": "Vizhinjam Rock Cut Cave Temple","time": "1h",  "desc": "8th century rock-cut cave temple with Pallava sculptures.",                   "activity": "Heritage, Photography"},
            {"name": "Poovar Island",                 "time": "3h",  "desc": "Isolated island where river meets sea, accessible only by boat.",              "activity": "Boat ride, Nature walk"},
        ],
        "food": [
            "Lobster at Rockholm Restaurant",
            "Fish and chips at German Bakery",
            "Seafood thali at Suprabhatam",
            "Fresh coconut water on the beach",
        ],
        "tips": [
            "Swim only in flagged areas — currents can be strong",
            "Book Ayurveda treatments in advance",
            "Oct–Mar is ideal season",
            "Haggle with souvenir vendors",
        ],
    },
}

DEFAULT_ITINERARY_DATA = {
    "places": [
        {"name": "Local Heritage Site", "time": "2h",   "desc": "Explore the historical and cultural heritage of this destination.",         "activity": "Sightseeing, Photography"},
        {"name": "Nature Park / Garden","time": "1.5h",  "desc": "Beautiful natural surroundings perfect for a morning walk.",                "activity": "Walking, Bird watching"},
        {"name": "Local Market",        "time": "1h",    "desc": "Vibrant local market with spices, handicrafts and street food.",             "activity": "Shopping, Street food"},
        {"name": "Waterfront / Lake",   "time": "1.5h",  "desc": "Scenic waterfront area ideal for relaxing and photography.",                "activity": "Boating, Photography"},
        {"name": "Temple / Religious Site","time": "1h", "desc": "Significant religious site with traditional Kerala architecture.",           "activity": "Spiritual visit, Architecture"},
        {"name": "Beach / Hilltop",     "time": "2h",    "desc": "Perfect spot to catch the golden sunset over Kerala.",                      "activity": "Sunset viewing, Relaxing"},
    ],
    "food": [
        "Try local Kerala Sadhya (traditional feast)",
        "Fresh coconut water",
        "Appam with Stew",
        "Seafood specialties",
    ],
    "tips": [
        "Carry cash as many local shops don't accept cards",
        "Respect local customs at religious sites",
        "Stay hydrated in Kerala's tropical climate",
        "Use KSRTC buses for budget travel",
    ],
}


# ── Groq AI generator ─────────────────────────────────────────────────────────

async def _generate_itinerary_groq(
    destination, start_date, end_date, num_days, purpose, travelers_count
):
    prompt = f"""You are a Kerala travel expert. Generate a detailed {num_days}-day travel itinerary for {destination}, Kerala, India.

Trip details:
- Destination: {destination}
- Start date: {start_date}
- End date: {end_date}
- Duration: {num_days} days
- Purpose: {purpose}
- Travelers: {travelers_count} person(s)

IMPORTANT: Respond with ONLY a valid JSON object. No explanation, no markdown, no code blocks. Just raw JSON.

The JSON must follow this exact structure:
{{
  "destination": "{destination}",
  "start_date": "{start_date}",
  "end_date": "{end_date}",
  "number_of_days": {num_days},
  "travelers_count": {travelers_count},
  "days": [
    {{
      "day_number": 1,
      "date": "DD Mon YYYY",
      "title": "Day title",
      "morning": [
        {{"time_slot": "9:00 AM",  "place_name": "Place name", "description": "2 sentence description", "duration": "2h",   "activity": "Main activity"}},
        {{"time_slot": "10:30 AM", "place_name": "Another place", "description": "2 sentence description", "duration": "1.5h", "activity": "Main activity"}}
      ],
      "afternoon": [
        {{"time_slot": "12:00 PM", "place_name": "Place name", "description": "2 sentence description", "duration": "2h",   "activity": "Main activity"}},
        {{"time_slot": "2:30 PM",  "place_name": "Another place", "description": "2 sentence description", "duration": "1.5h", "activity": "Main activity"}}
      ],
      "evening": [
        {{"time_slot": "5:00 PM",  "place_name": "Place name", "description": "2 sentence description", "duration": "1.5h", "activity": "Main activity"}}
      ],
      "total_hours": "8-9 hours",
      "day_tip": "One practical tip for this day"
    }}
  ],
  "food_suggestions": ["Specific dish at specific restaurant name"],
  "general_tips":     ["Practical travel tip"],
  "hotel_suggestions": [
    {{"name": "Hotel name", "category": "budget/mid-range/luxury", "area": "Area in {destination}", "price_range": "INR per night range", "highlight": "One key feature"}}
  ],
  "budget_estimate": {{
    "accommodation_per_night":      "INR range",
    "food_per_day_per_person":      "INR range",
    "transport_per_day":            "INR range",
    "activities_per_day":           "INR range",
    "total_estimated":              "INR total for {travelers_count} person(s) for {num_days} days"
  }},
  "local_transport": [
    {{"type": "Transport type", "use_for": "When to use it", "cost": "Approximate cost", "tip": "Practical tip"}}
  ],
  "best_season": "Best months to visit"
}}

Rules:
- Include 2 places for morning, 2 for afternoon, 1 for evening each day
- Every day must have UNIQUE places — never repeat across days
- For {num_days} days you need {num_days * 5} unique place visits
- Include hidden gems and lesser-known local spots, not just famous ones
- Food suggestions must name specific dishes at specific restaurants
- Budget must be realistic for Kerala in 2025
- Tailor activities to the purpose: {purpose}"""

    headers = {
        "Authorization": f"Bearer {GROQ_API_KEY}",
        "Content-Type":  "application/json",
    }
    payload = {
        "model":       GROQ_MODEL,
        "messages":    [{"role": "user", "content": prompt}],
        "temperature": 0.7,
        "max_tokens":  6000,
    }

    async with httpx.AsyncClient(timeout=60.0) as client:
        response = await client.post(
            "https://api.groq.com/openai/v1/chat/completions",
            json=payload, headers=headers,
        )

    if response.status_code != 200:
        raise Exception(f"Groq returned {response.status_code}")

    content = response.json()["choices"][0]["message"]["content"].strip()

    # Strip accidental markdown wrapping
    if content.startswith("```"):
        content = content.split("```")[1]
        if content.startswith("json"):
            content = content[4:]
    content = content.strip()

    result = json.loads(content)
    result.setdefault("hotel_suggestions", [])
    result.setdefault("budget_estimate", {})
    result.setdefault("local_transport", [])
    result.setdefault("best_season", "October to March")
    return result


# ── Hardcoded fallback ────────────────────────────────────────────────────────

def _generate_itinerary_fallback(
    destination, start_date, end_date, num_days,
    purpose, travelers_count, start_dt
):
    dest_key = None
    for key in KERALA_ITINERARY_DATA:
        if key.lower() in destination.lower() or destination.lower() in key.lower():
            dest_key = key
            break

    dest_data = KERALA_ITINERARY_DATA.get(dest_key, DEFAULT_ITINERARY_DATA)
    places       = dest_data["places"]
    total_places = len(places)

    time_slots_morning   = ["9:00 AM",  "10:30 AM"]
    time_slots_afternoon = ["12:00 PM", "2:30 PM"]
    time_slots_evening   = ["5:00 PM"]
    day_titles = [
        "Arrival & Exploration", "Deep Dive & Discovery",
        "Nature & Adventure",    "Culture & Heritage",
        "Leisure & Local Life",  "Hidden Gems", "Farewell Day",
    ]
    tips_pool = [
        "Start early to beat the crowds",
        "Keep evenings free for local market exploration",
        "Try the local street food near the main market",
        "Hire a local auto for short distances",
        "Carry a water bottle — stay hydrated",
        "Golden hour photography is stunning here",
    ]

    days = []
    place_index = 0

    for day_num in range(1, num_days + 1):
        current_date = start_dt + timedelta(days=day_num - 1)
        date_str     = current_date.strftime("%d %b %Y")
        morning, afternoon, evening = [], [], []

        for slot_list, time_list, count in [
            (morning,   time_slots_morning,   2),
            (afternoon, time_slots_afternoon, 2),
            (evening,   time_slots_evening,   1),
        ]:
            for i in range(count):
                p = places[place_index % total_places]
                place_index += 1
                slot_list.append({
                    "time_slot":   time_list[i],
                    "place_name":  p["name"],
                    "description": p["desc"],
                    "duration":    p["time"],
                    "activity":    p["activity"],
                })

        days.append({
            "day_number":  day_num,
            "date":        date_str,
            "title":       day_titles[(day_num - 1) % len(day_titles)],
            "morning":     morning,
            "afternoon":   afternoon,
            "evening":     evening,
            "total_hours": "8–9 hours",
            "day_tip":     tips_pool[(day_num - 1) % len(tips_pool)],
        })

    return {
        "destination":     destination,
        "start_date":      start_date,
        "end_date":        end_date,
        "number_of_days":  num_days,
        "travelers_count": travelers_count,
        "days":            days,
        "food_suggestions":dest_data["food"],
        "general_tips":    dest_data["tips"],
        "hotel_suggestions": [],
        "budget_estimate":   {},
        "local_transport":   [],
        "best_season":       "October to March",
    }


# ── Route ─────────────────────────────────────────────────────────────────────

@router.post("/itinerary/generate")
async def generate_itinerary(data: dict):
    try:
        start = datetime.strptime(data["start_date"], "%Y-%m-%d")
        end   = datetime.strptime(data["end_date"],   "%Y-%m-%d")
    except (ValueError, KeyError):
        raise HTTPException(status_code=400, detail="Invalid date format. Use YYYY-MM-DD")

    num_days        = (end - start).days + 1
    destination     = data.get("destination", "Kerala")
    purpose         = data.get("purpose", "leisure")
    travelers_count = data.get("travelers_count", 1)

    # Try Groq AI first
    if GROQ_API_KEY:
        try:
            result = await _generate_itinerary_groq(
                destination=destination,
                start_date=data["start_date"],
                end_date=data["end_date"],
                num_days=num_days,
                purpose=purpose,
                travelers_count=travelers_count,
            )
            if result:
                return result
        except Exception as e:
            logger.warning(f"Groq itinerary failed, using fallback: {e}")

    # Fallback to hardcoded data
    return _generate_itinerary_fallback(
        destination=destination,
        start_date=data["start_date"],
        end_date=data["end_date"],
        num_days=num_days,
        purpose=purpose,
        travelers_count=travelers_count,
        start_dt=start,
    )