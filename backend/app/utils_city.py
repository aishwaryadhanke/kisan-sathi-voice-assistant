import re
from typing import List, Optional

# 🔹 List of known city names (Roman, normalized “slugs”)
KNOWN_CITIES = [
    "solapur", "pune", "nashik", "latur", "mumbai", "nagpur",
    "satara", "ahmednagar", "kolhapur", "thane", "jalgaon", "aurangabad",
    "beed", "akola", "parbhani", "wardha", "osmanabad", "dharashiv",
    # common ASR spellings (we will normalise them to real slugs)
    "nasik", "sulapur", "sholapur", "bombay",
]

# 🔹 Mapping for Devanagari → Roman city slug
CITY_MAP = {
    "सोलापुर": "solapur",
    "पुणे": "pune",
    "नाशिक": "nashik",
    "नासिक": "nashik",          # 👈 new variant
    "लातूर": "latur",
    "मुंबई": "mumbai",
    "नागपूर": "nagpur",
    "सातारा": "satara",
    "अहमदनगर": "ahmednagar",
    "कोल्हापुर": "kolhapur",
    "ठाणे": "thane",
    "जलगाव": "jalgaon",
    "औरंगाबाद": "aurangabad",
    "बीड": "beed",
    "अकोला": "akola",
    "परभणी": "parbhani",
    "वर्धा": "wardha",
    "उस्मानाबाद": "osmanabad",
    "धाराशिव": "dharashiv",
}

# 🔹 Roman aliases → canonical slug
ROMAN_CITY_ALIASES = {
    "sulapur": "solapur",
    "sholapur": "solapur",
    "nasik": "nashik",
    "bombay": "mumbai",
}

# 🔹 City-slug → possible district names as used in Agmarknet
DISTRICT_MAP = {
    "nashik": ["Nashik", "Nasik"],
    "pune": ["Pune"],
    "solapur": ["Solapur", "Sholapur"],
    "latur": ["Latur"],
    "mumbai": ["Mumbai", "Mumbai(Suburban)", "Bombay"],
    "nagpur": ["Nagpur"],
    "satara": ["Satara"],
    "ahmednagar": ["Ahmednagar", "Ahmadnagar"],
    "kolhapur": ["Kolhapur"],
    "thane": ["Thane"],
    "jalgaon": ["Jalgaon"],
    "aurangabad": ["Aurangabad"],
    "beed": ["Beed", "Bid"],
    "akola": ["Akola"],
    "parbhani": ["Parbhani"],
    "wardha": ["Wardha"],
    "osmanabad": ["Osmanabad"],
    "dharashiv": ["Osmanabad", "Dharashiv"],  # old vs new name
}


def normalize_city_names(text: str) -> str:
    """
    Replace known city names (Hindi/English) with placeholder 'CITY'
    for NLU similarity, so any city behaves similarly.
    """
    if not text:
        return text

    text_norm = text.lower()

    # Roman city names + aliases
    for city in KNOWN_CITIES:
        text_norm = re.sub(rf"\b{city}\b", "CITY", text_norm, flags=re.IGNORECASE)

    # Devanagari city names
    for dev_city in CITY_MAP.keys():
        text_norm = text_norm.replace(dev_city, "CITY")

    return text_norm


def extract_city_name(text: str) -> Optional[str]:
    """
    Extract actual city name from text (Roman or Devanagari).
    Returns normalized slug, e.g. "nashik", "solapur".
    """
    if not text:
        return None

    text_lower = text.lower()

    # Roman aliases first (sulapur, nasik, bombay...)
    for alias, canonical in ROMAN_CITY_ALIASES.items():
        if alias in text_lower:
            return canonical

    # Exact Roman slugs
    for city in KNOWN_CITIES:
        if city in text_lower:
            # If it's one of the special alias spellings, map via ROMAN_CITY_ALIASES
            if city in ROMAN_CITY_ALIASES:
                return ROMAN_CITY_ALIASES[city]
            return city

    # Devanagari names
    for dev_city, eng_city in CITY_MAP.items():
        if dev_city in text:
            return eng_city

    return None


def city_to_district_names(city_slug: str) -> List[str]:
    """
    Given a normalized city slug (e.g. 'nashik'),
    return a list of district names as they appear in Agmarknet.
    """
    if not city_slug:
        return []

    city_slug = city_slug.lower().strip()
    if city_slug in DISTRICT_MAP:
        return DISTRICT_MAP[city_slug]

    return [city_slug.title()]
