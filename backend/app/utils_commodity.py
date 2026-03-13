# app/utils_commodity.py
from typing import Optional

# Canonical commodity names in Hindi
# (keys MUST match the `commodity_hi` strings in your mandi JSON)
COMMODITY_KEYWORDS = {
    "गेहूँ": [  # wheat
        "गेहूँ", "गेहूं", "गेहु", "gehun", "gehu", "wheat",
        "गहू", "गहु",
    ],
    "चावल": [  # rice
        "चावल", "धान", "rice", "तांदूळ", "तांदुळ",
    ],
    "मक्का": [
        "मक्का", "मक्खा", "मकई", "corn", "मका",
    ],
    "बाजरा": [
        "बाजरा", "बाजरी", "bajra",
    ],
    "ज्वार": [
        "ज्वार", "ज्वारी", "jowar",
    ],
    "सोयाबीन": [
        "सोयाबीन", "सोयाबिन", "soybean", "soyabean", "soya bean",
    ],
    "चना": [
        "चना", "हरभरा", "chana", "gram",
    ],
    "अरहर": [
        "अरहर", "तूर", "तुअर", "तुर", "तूर दाल", "tur", "toor",
    ],
    "उड़द": [
        "उड़द", "उडीद", "urad",
    ],
    "मूंग": [
        "मूंग", "मूग", "moong",
    ],
    "आलू": [
        "आलू", "बटाटा", "potato",
    ],
    "टमाटर": [
        "टमाटर", "टमेटर", "टोमॅटो", "tomato",
    ],
    "प्याज": [   # 👈 canonical onion spelling (match JSON)
        "प्याज", "प्याज़", "कांदा", "onion", "pyaz",
    ],
    "हरी मिर्च": [
        "हरी मिर्च", "मिरची (हिरवी)", "green chilli", "green chili",
    ],
    "लहसुन": [
        "लहसुन", "लसूण", "garlic",
    ],
    "धनिया": [
        "धनिया", "कोथिंबिर", "coriander",
    ],
}


def extract_commodity_name(text: str) -> Optional[str]:
    """
    Simple rule-based matcher.
    Returns canonical Hindi commodity name (like 'गेहूँ', 'प्याज', etc.)
    or None if nothing matched.
    """
    if not text:
        return None

    t = text.lower()

    for canonical_hi, keywords in COMMODITY_KEYWORDS.items():
        for kw in keywords:
            if kw.lower() in t:
                return canonical_hi

    return None
