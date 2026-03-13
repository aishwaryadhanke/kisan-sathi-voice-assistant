# app/weather_service.py

import requests
from typing import Dict, Any
from app.utils_city import extract_city_name

# ✅ Use your API key
OPENWEATHER_API_KEY = ""


def fetch_weather_for_city(city_query: str) -> Dict[str, Any]:
    """
    Fetch current weather using OpenWeather API.
    Uses extract_city_name() to find real city name before API call.
    """

    city = extract_city_name(city_query)
    if not city:
        raise ValueError(f"Could not detect a valid city in: {city_query}")

    query = f"{city.capitalize()},IN"

    params = {
        "q": query,
        "appid": OPENWEATHER_API_KEY,
        "units": "metric",
        "lang": "hi",
    }

    try:
        resp = requests.get("https://api.openweathermap.org/data/2.5/weather", params=params, timeout=10)
        data = resp.json()

        if resp.status_code != 200:
            raise RuntimeError(f"OpenWeather API error: {resp.status_code} - {data}")

        main = data.get("main", {})
        weather = data.get("weather", [{}])[0]

        return {
            "city": data.get("name", city),
            "country": data.get("sys", {}).get("country", "IN"),
            "temp": round(main.get("temp", 0), 1),
            "feels_like": round(main.get("feels_like", 0), 1),
            "humidity": main.get("humidity"),
            "description": weather.get("description", "N/A"),
        }

    except Exception as e:
        raise RuntimeError(f"Weather fetch failed: {e}")
