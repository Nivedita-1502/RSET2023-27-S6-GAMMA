# Standard reference prices (Kerala context)
STANDARD_PRICES = {
    "taxi_per_km": 30,       # ₹30 per km
    "auto_per_km": 25,       # ₹25 per km
    "bus_ticket": 30,        # ₹30 per ticket
    "museum_entry": 50       # ₹50 per person
}

def detect_overpricing(service, charged_price, quantity):
    """
    Overpricing categories:
    - not overpriced
    - slightly overpriced (₹1–₹10)
    - overpriced (> ₹10)
    """
    if service not in STANDARD_PRICES:
        return "not applicable", None

    expected_price = STANDARD_PRICES[service] * quantity
    difference = charged_price - expected_price

    if difference <= 0:
        status = "not overpriced"
    elif difference <= 10:
        status = "slightly overpriced"
    else:
        status = "overpriced"

    return status, expected_price
