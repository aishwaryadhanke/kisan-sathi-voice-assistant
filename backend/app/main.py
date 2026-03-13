# backend/app/main.py

from fastapi import FastAPI, UploadFile, File, HTTPException
from pydantic import BaseModel
from typing import Optional, List, Dict

from .utils_ollama import call_ollama
from .nlu_intent import predict_intent
from .asr_service import transcribe_audio
from .utils_city import extract_city_name
from .utils_commodity import extract_commodity_name
from .weather_service import fetch_weather_for_city
from .nearby_market_service import fetch_nearby_agri_markets
from .market_price_service import fetch_market_prices_for_city_commodity


app = FastAPI(
    title="Farmer Voice Assistant 🌾",
    version="1.3",
    description="Backend for Weather, Nearby Markets, and Mandi Prices with Hindi AI Replies.",
)


# -----------------------------------------------------
# Response model
# -----------------------------------------------------
class VoiceQueryResponse(BaseModel):
    text: str
    intent: str
    score: float
    city: Optional[str] = None
    commodity: Optional[str] = None
    weather: Optional[dict] = None
    nearby_markets: Optional[List[dict]] = None
    market_prices: Optional[dict] = None
    final_reply: Optional[str] = None  # ✅ Final Hindi output


# -----------------------------------------------------
# Build final Hindi reply using Ollama or fallback
# -----------------------------------------------------
def build_final_reply(
    *,
    text: str,
    intent: str,
    city: Optional[str],
    commodity: Optional[str],
    weather_info: Optional[dict],
    nearby_markets: Optional[List[dict]],
    market_prices: Optional[dict],
) -> Optional[str]:
    """
    Generate a short, friendly Hindi reply for farmers.
    Uses Ollama when possible, else fallback text.
    """

    # Small helper: nicer city names in Hindi, where we know them
    def pretty_city_name(raw_city: Optional[str]) -> str:
        if not raw_city:
            return ""
        c = str(raw_city)
        lc = c.lower()

        mapping = {
            "solapur": "सोलापुर",
            "pune": "पुणे",
            "nashik": "नाशिक",
            "nagpur": "नागपूर",
            "mumbai": "मुंबई",
            "kolhapur": "कोल्हापुर",
            "satara": "सातारा",
            "jalgaon": "जलगाव",
            "latur": "लातूर",
            "ahmednagar": "अहमदनगर",
            "thane": "ठाणे",
            "aurangabad": "औरंगाबाद",
            "beed": "बीड",
            "akola": "अकोला",
            "parbhani": "परभणी",
            "wardha": "वर्धा",
            "osmanabad": "उस्मानाबाद",
            "dharashiv": "धाराशिव",
        }

        return mapping.get(lc, c)

    # 🌦️ 1. WEATHER
    if intent == "weather":
        if weather_info:
            city_name = pretty_city_name(weather_info.get("city") or city or "आपके क्षेत्र")
            temp = weather_info.get("temp")
            feels = weather_info.get("feels_like")
            humidity = weather_info.get("humidity")
            desc = weather_info.get("description")

            prompt = f"""
आप एक किसान सहायक हैं और किसान को सरल हिंदी में मौसम बताते हैं।

किसान ने पूछा: "{text}"
शहर: {city_name}
तापमान: {temp}°C
महसूस होता है: {feels}°C
नमी: {humidity}%
मौसम: {desc}

ऊपर दिए गए डेटा के आधार पर किसान को सिर्फ 1–2 छोटे वाक्यों में आज के मौसम की जानकारी दीजिए।
बुलेट पॉइंट या सूची का उपयोग मत कीजिए, केवल साधारण वाक्य लिखिए।
"""
            llm_reply = call_ollama(prompt)
            if llm_reply:
                return llm_reply

            # 🪫 Fallback if Ollama slow / error
            return (
                f"आज {city_name} में तापमान लगभग {temp}°C है, "
                f"मौसम '{desc}' जैसा है और नमी करीब {humidity}% है।"
            )

        # no weather_info (maybe city missing / API failed)
        city_name = pretty_city_name(city) or "आपके क्षेत्र"
        return (
            f"माफ़ कीजिए किसान जी, अभी {city_name} के मौसम की जानकारी नहीं मिल सकी। "
            f"थोड़ी देर बाद दोबारा कोशिश करें।"
        )

    # 🏪 2. NEARBY MARKETS
    if intent == "nearby_market":
        city_name = pretty_city_name(city) or "आपके क्षेत्र"

        # If we actually have markets from the service
        if nearby_markets:
            top = nearby_markets[:3]
            markets_text = "\n".join(
                f"- {m['name']} (लगभग {m['distance_km']:.1f} किमी)"
                for m in top
            )

            prompt = f"""
आप एक किसान सहायक हैं।

किसान ने पूछा: "{text}"
शहर: {city_name}

पास के कृषि बाज़ार:
{markets_text}

ऊपर दिए गए डेटा के आधार पर किसान को सिर्फ 1 या 2 छोटे वाक्यों में बताइए
कि उसके पास कौन-कौन से कृषि मार्केट हैं और वे कितनी दूरी पर हैं।
बुलेट पॉइंट या नई लाइन में सूची न दें, सिर्फ लगातार साधारण वाक्य में जवाब दें।
"""
            llm_reply = call_ollama(prompt)
            if llm_reply:
                return llm_reply

            # 🪫 Fallback with list
            nearest = top[0]
            others = ", ".join(m["name"] for m in top[1:]) if len(top) > 1 else ""
            reply = (
                f"{city_name} के पास '{nearest['name']}' कृषि बाज़ार सबसे नज़दीक है "
                f"(लगभग {nearest['distance_km']:.1f} किमी दूरी पर)।"
            )
            if others:
                reply += f" इसके अलावा {others} जैसे अन्य बाज़ार भी आसपास हैं।"
            return reply

        # ❌ No nearby_markets returned → still give a nice line
        return (
            f"{city_name} के पास के कृषि बाज़ारों की जानकारी अभी प्राप्त नहीं हो सकी, "
            f"कृपया थोड़ी देर बाद फिर से प्रयास करें।"
        )

    # 🌾 3. MANDI PRICE
    if intent == "market_price":
        city_name = pretty_city_name(city) or "आपके क्षेत्र"

        # ✅ We have price data
        if (
            isinstance(market_prices, dict)
            and market_prices.get("status") == "ok"
            and market_prices.get("results")
        ):
            first = market_prices["results"][0]
            commodity_hi = first.get("commodity_hi", commodity or "यह फसल")
            variety_raw = first.get("variety", "---")
            unit = first.get("unit", "क्विंटल")
            min_p = round(first.get("min_price", 0))
            max_p = round(first.get("max_price", 0))
            avg_p = round(first.get("avg_modal_price", 0))

            # Hide ugly '---' variety in the text
            if variety_raw in ("---", "--", "-"):
                variety_for_sentence = ""
                variety_for_bracket = ""
            else:
                variety_for_sentence = f" ({variety_raw})"
                variety_for_bracket = variety_raw

            summary_text = (
                f"{commodity_hi}{variety_for_sentence} का आज {city_name} मंडी में "
                f"न्यूनतम भाव ₹{min_p}, अधिकतम भाव ₹{max_p} "
                f"और औसत लगभग ₹{avg_p} प्रति {unit} है।"
            )

            prompt = f"""
आप एक किसान सहायक हैं जो मंडी भाव को बहुत सरल हिंदी में बताते हैं।

किसान ने पूछा: "{text}"

जानकारी:
{summary_text}

उपरोक्त जानकारी के आधार पर किसान के लिए केवल 1 ही छोटा वाक्य लिखिए,
जिसमें न्यूनतम, अधिकतम और औसत भाव तीनों साफ़-साफ़ बताए गए हों।
कोई अतिरिक्त सलाह या जानकारी न दें, सिर्फ वही एक वाक्य लिखें।
"""
            llm_reply = call_ollama(prompt)
            if llm_reply:
                return llm_reply

            # 🪫 Fallback (fast, no LLM)
            if variety_for_bracket:
                return (
                    f"किसान जी, आज {city_name} मंडी में {commodity_hi} ({variety_for_bracket}) "
                    f"का न्यूनतम भाव ₹{min_p}, अधिकतम ₹{max_p} और औसत लगभग ₹{avg_p} प्रति {unit} है।"
                )
            else:
                return (
                    f"किसान जी, आज {city_name} मंडी में {commodity_hi} "
                    f"का न्यूनतम भाव ₹{min_p}, अधिकतम ₹{max_p} और औसत लगभग ₹{avg_p} प्रति {unit} है।"
                )

        # ❌ No data case (or city/commodity not properly detected)
        prompt = f"""
आप एक किसान सहायक हैं।

किसान ने पूछा: "{text}"
शहर: {city_name or 'अज्ञात'}
फसल: {commodity or 'अज्ञात'}

आज के लिए इस फसल का मंडी भाव हमारे डेटाबेस में उपलब्ध नहीं है
या शहर/फसल को साफ़-साफ़ पहचान नहीं सके।
किसान को बहुत विनम्र और सरल हिंदी में सिर्फ 1–2 छोटे वाक्यों में यह बात समझाइए
और कहिए कि वो शहर और फसल का नाम थोड़ा और साफ़ बोलें।
"""
        llm_reply = call_ollama(prompt)
        if llm_reply:
            return llm_reply

        # 🪫 Fallback
        if city and commodity:
            return f"माफ़ कीजिए किसान जी, आज {city_name} मंडी में {commodity} का भाव उपलब्ध नहीं है।"
        return (
            "माफ़ कीजिए किसान जी, मैं आपके सवाल में शहर या फसल का नाम ठीक से पहचान नहीं सका। "
            "कृपया दोबारा साफ़-साफ़ शहर और फसल का नाम लेकर पूछिए।"
        )

    # 💤 UNKNOWN or anything else
    if intent == "unknown":
        prompt = f"""
आप एक किसान सहायक हैं।

किसान ने कहा: "{text}"

यह सवाल सीधे मौसम, मंडी भाव या पास की मंडी से जुड़ा नहीं दिख रहा।
किसान को विनम्र तरीके से 1–2 छोटे वाक्यों में बताइए कि
आप अभी केवल मौसम, मंडी भाव और पास की मंडी जैसी जानकारी दे सकते हैं।
"""
        llm_reply = call_ollama(prompt)
        if llm_reply:
            return llm_reply

        return (
            "किसान जी, अभी मैं सिर्फ मौसम, मंडी भाव और पास की मंडी की जानकारी दे सकता हूँ। "
            "कृपया इन्हीं से संबंधित सवाल पूछें।"
        )

    # Default: nothing to say
    return None


# -----------------------------------------------------
# Root + Ping
# -----------------------------------------------------
@app.get("/")
async def root():
    return {
        "status": "ok",
        "service": "Farmer Voice Assistant",
        "message": "Backend running ✅",
    }


@app.get("/ping")
async def ping():
    return {"status": "ok", "message": "pong"}


# -----------------------------------------------------
# Voice query endpoint
# -----------------------------------------------------
@app.post("/voice-query", response_model=VoiceQueryResponse)
async def voice_query_endpoint(audio: UploadFile = File(...)):
    """
    🎤 Voice Input Pipeline:
    1️⃣ ASR → Text
    2️⃣ NLU → Intent
    3️⃣ Extract city + commodity
    4️⃣ Fetch Data (Weather / Market / Mandi)
    5️⃣ Generate Hindi reply
    """
    audio_bytes = await audio.read()
    if not audio_bytes:
        raise HTTPException(status_code=400, detail="Empty audio file")

    text = transcribe_audio(audio_bytes)
    if not text or not text.strip():
        raise HTTPException(status_code=500, detail="ASR returned empty text")

    intent, score = predict_intent(text)

    # 🔍 Fuzzy city + commodity (from your updated utils)
    city = extract_city_name(text)
    commodity = extract_commodity_name(text)

    print(f"[VOICE] Text: {text}")
    print(f"[VOICE] City: {city}, Commodity: {commodity}, Intent: {intent}")

    weather_info = None
    nearby_markets = None
    market_prices = None

    try:
        if intent == "weather" and city:
            weather_info = fetch_weather_for_city(city)
        elif intent == "nearby_market" and city:
            nearby_markets = fetch_nearby_agri_markets(city)
        elif intent == "market_price" and city and commodity:
            market_prices = fetch_market_prices_for_city_commodity(city, commodity)
    except Exception as e:
        print(f"[ERROR] {e}")

    final_reply = build_final_reply(
        text=text,
        intent=intent,
        city=city,
        commodity=commodity,
        weather_info=weather_info,
        nearby_markets=nearby_markets,
        market_prices=market_prices,
    )

    return VoiceQueryResponse(
        text=text,
        intent=intent,
        score=score,
        city=city,
        commodity=commodity,
        weather=weather_info,
        nearby_markets=nearby_markets,
        market_prices=market_prices,
        final_reply=final_reply,
    )


# -----------------------------------------------------
# Text query endpoint (for Swagger testing)
# -----------------------------------------------------
@app.post("/voice-query-text", response_model=VoiceQueryResponse)
async def voice_query_text_endpoint(payload: Dict[str, str]):
    """
    💬 Text Input: same logic as voice version, for manual testing.
    """
    text = payload.get("text", "").strip()
    if not text:
        raise HTTPException(status_code=400, detail="Text is required")

    intent, score = predict_intent(text)

    city = extract_city_name(text)
    commodity = extract_commodity_name(text)

    print(f"[TEXT] Text: {text}")
    print(f"[TEXT] City: {city}, Commodity: {commodity}, Intent: {intent}")

    weather_info = None
    nearby_markets = None
    market_prices = None

    try:
        if intent == "weather" and city:
            weather_info = fetch_weather_for_city(city)
        elif intent == "nearby_market" and city:
            nearby_markets = fetch_nearby_agri_markets(city)
        elif intent == "market_price" and city and commodity:
            market_prices = fetch_market_prices_for_city_commodity(city, commodity)
    except Exception as e:
        print(f"[ERROR] {e}")

    final_reply = build_final_reply(
        text=text,
        intent=intent,
        city=city,
        commodity=commodity,
        weather_info=weather_info,
        nearby_markets=nearby_markets,
        market_prices=market_prices,
    )

    return VoiceQueryResponse(
        text=text,
        intent=intent,
        score=score,
        city=city,
        commodity=commodity,
        weather=weather_info,
        nearby_markets=nearby_markets,
        market_prices=market_prices,
        final_reply=final_reply,
    )
