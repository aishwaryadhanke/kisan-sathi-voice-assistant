from sentence_transformers import SentenceTransformer, util
from typing import Tuple
import numpy as np

from app.utils_city import normalize_city_names  # 👈 handles city normalization


print("Loading NLU model, please wait...")
model = SentenceTransformer("sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2")
print("NLU model loaded ✅")


# 🔹 Out-of-scope keywords
SPECIAL_UNKNOWN_KEYWORDS = [ 
    "gana", "gaana", "song", "music",
    "joke", "hasao", "game", "khelte",
    "play song", "play music", "movie", "film"
]

# 🔹 Hint keywords
WEATHER_HINT_KEYWORDS = [
    "मौसम", "हवामान", "बारिश", "बरसात",
    "तापमान", "ठंड", "थंड", "गरमी",
    "mausam", "barish", "dhup", "temperature"
]

MARKET_HINT_KEYWORDS = [
    "भाव", "दाम", "रेट", "किंमत",
    "bhav", "daam", "rate", "kimat"
]

# 🔹 Nearby market hint keywords
NEARBY_MARKET_HINT_KEYWORDS = [
    "मंडी", "mandi",
    "मार्केट", "market",
    "बाज़ार", "बाजार", "bazar",
    "पास", "aas paas", "आस पास",
    "nazdik", "nearby", "near"
]

# Extra groups to help post-fix the intent
NEARBY_WORDS_ONLY = [
    "पास", "पास की", "आसपास", "आस पास",
    "nazdik", "nearby", "near"
]
MANDI_WORDS_ONLY = [
    "मंडी", "mandi", "बाजार", "बाज़ार", "market", "मार्केट"
]

# ==========================
# 2. Intent examples
# ==========================
INTENT_EXAMPLES = {
    "weather": [
        "aaj mausam kaisa hai",
        "barish hogi kya",
        "aaj ka temperature kya hai",
        "kal barish aayegi kya",
        "मौसम कैसा है",
        "सोलापुर का हवामान कैसा है",
        "पुणे का मौसम कैसा है"
    ],

    "market_price": [
        "pyaaz ka bhav kya hai",
        "mandi ka rate kya hai",
        "aaj ka bhav batao",
        "crop ka daam kya hai",
        "गेहूं का भाव क्या है",
        "सोलापुर में टमाटर के क्या भाव हैं",
        "नाशिक में प्याज के क्या दाम हैं"
    ],

    "government_scheme": [
        "pm kisan yojana kya hai",
        "tractor pe subsidy milti hai kya",
        "सरकारी योजना बताओ",
        "किसान योजना क्या है"
    ],

    "nearby_market": [
        "nazdiki mandi batao",
        "nearest market kaha hai",
        "पास की मंडी दिखाओ",
        "सोलापुर के पास की मंडी दिखाओ",
        "लातूर के पास की मंडी बताओ",
        "पास में कौन सी मंडी है",
        "नजदीक की मंडी बताओ",
        "यहाँ के आसपास की मंडी"
    ]
}

FALLBACK_INTENT = "unknown"


# ==========================
# 3. Pre-compute embeddings
# ==========================
def build_intent_embeddings():
    intent_embeddings = {}
    for intent, examples in INTENT_EXAMPLES.items():
        # Normalize city names before embedding
        normalized_examples = [normalize_city_names(ex) for ex in examples]
        embeddings = model.encode(normalized_examples, convert_to_tensor=True)
        intent_embeddings[intent] = embeddings
    return intent_embeddings


INTENT_EMBEDDINGS = build_intent_embeddings()
print("Intent embeddings ready ✅")


# ==========================
# 4. Predict intent
# ==========================
def predict_intent(query: str, base_threshold: float = 0.8) -> Tuple[str, float]:
    """
    Returns (intent, score)
    - Relaxes threshold for weather / market_price / nearby_market.
    - Normalizes city names before embeddings.
    - Adds a hard rule so price queries with 'भाव/दाम/रेट...' become market_price.
    """
    if not query or not query.strip():
        return FALLBACK_INTENT, 0.0

    text = query.strip()
    normalized_text = normalize_city_names(text)
    lower_norm = normalized_text.lower()

    # 1️⃣ Ignore clearly unrelated stuff
    if any(keyword in lower_norm for keyword in SPECIAL_UNKNOWN_KEYWORDS):
        return FALLBACK_INTENT, 1.0

    # 2️⃣ Dynamic thresholds
    threshold = base_threshold
    if any(k in text for k in WEATHER_HINT_KEYWORDS):
        threshold = 0.5
    elif any(k in text for k in MARKET_HINT_KEYWORDS):
        threshold = 0.5
    elif any(k in text for k in NEARBY_MARKET_HINT_KEYWORDS):
        threshold = 0.45  # 👈 loosen threshold for nearby queries

    # 3️⃣ Similarity on normalized text
    query_embedding = model.encode(normalized_text, convert_to_tensor=True)

    best_intent = FALLBACK_INTENT
    best_score = 0.0

    for intent, embeddings in INTENT_EMBEDDINGS.items():
        cosine_scores = util.cos_sim(query_embedding, embeddings)[0]
        max_score = float(cosine_scores.max().item())
        if max_score > best_score:
            best_score = max_score
            best_intent = intent

    # 4️⃣ If below threshold, mark unknown
    if best_score < threshold:
        return FALLBACK_INTENT, best_score

    # 5️⃣ HARD RULE: price keywords => market_price (unless it's clearly "nearby mandi")
    has_price_word = any(w in lower_norm for w in MARKET_HINT_KEYWORDS)
    has_nearby_pattern = any(w in lower_norm for w in NEARBY_WORDS_ONLY) and any(
        w in lower_norm for w in MANDI_WORDS_ONLY
    )

    # Example: "सोलापुर में चना का भाव बताओ" → price word present, no "पास / मंडी" combo
    if has_price_word and not has_nearby_pattern:
        best_intent = "market_price"

    return best_intent, best_score


# ==========================
# 5. CLI Test
# ==========================
if __name__ == "__main__":
    print("\n👨‍🌾 Farmer NLU Test (type 'exit' to quit')\n")
    while True:
        user_query = input("Query: ")
        if user_query.lower().strip() in ["exit", "quit"]:
            print("Goodbye 👋")
            break

        intent, score = predict_intent(user_query)
        print(f"➡ Intent: {intent} (score={score:.3f})\n")
