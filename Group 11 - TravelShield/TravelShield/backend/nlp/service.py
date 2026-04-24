from nlp.translation import translate_text
from nlp.price_check import detect_overpricing
from nlp.speech_to_text import speech_to_text


def analyze_input(text, output_language="en"):
    """
    TEXT TRANSLATION SERVICE
    Malayalam ↔ English
    """
    return {"translated_text": translate_text(text, output_language)}


def price_check(service, charged_price, quantity):
    """
    PRICE OVERCHARGE CHECK SERVICE
    Returns expected price + status + alert (True/False)
    """
    price_status, expected = detect_overpricing(service, charged_price, quantity)
    alert = price_status != "not overpriced"

    return {
        "expected_price": expected,
        "price_status": price_status,
        "alert": alert
    }


def speech_translate(direction_choice):
    """
    SPEECH → TEXT → TRANSLATE (Google Speech Recognition)

    direction_choice:
    1 = Malayalam → English
    2 = English → Malayalam
    """

    # Malayalam → English
    if direction_choice == "1":
        speech_text = speech_to_text("ml")
        if speech_text is None:
            return {"speech_text": None, "translated_text": None}

        translated = translate_text(speech_text, "en")
        return {"speech_text": speech_text, "translated_text": translated}

    # English → Malayalam
    elif direction_choice == "2":
        speech_text = speech_to_text("en")
        if speech_text is None:
            return {"speech_text": None, "translated_text": None}

        translated = translate_text(speech_text, "ml")
        return {"speech_text": speech_text, "translated_text": translated}

    else:
        return {"speech_text": None, "translated_text": None}
