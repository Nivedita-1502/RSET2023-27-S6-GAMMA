import requests
import re

def is_malayalam(text):
    """
    Detects if text contains Malayalam characters
    """
    return bool(re.search(r'[\u0D00-\u0D7F]', text))


def translate_text(text, output_language):
    """
    Malayalam <-> English translation using MyMemory API
    """
    try:
        # Detect source language
        if is_malayalam(text):
            source_lang = "ml"
        else:
            source_lang = "en"

        # If source and target are same, return text
        if source_lang == output_language:
            return text

        url = "https://api.mymemory.translated.net/get"
        params = {
            "q": text,
            "langpair": f"{source_lang}|{output_language}"
        }

        response = requests.get(url, params=params, timeout=5)
        data = response.json()

        return data["responseData"]["translatedText"]

    except Exception:
        return text
