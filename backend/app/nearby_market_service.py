# app/nearby_market_service.py

import requests
from typing import Dict, List, Optional
from geopy.geocoders import Nominatim
from geopy.distance import geodesic
from app.utils_city import extract_city_name


def geocode_city(city_query: str) -> Optional[Dict]:
    """
    Geocode a city (Hindi or English) → lat/lon using Nominatim.
    We first extract a normalized city name from the query.
    """
    city = extract_city_name(city_query)
    if not city:
        return None

    geolocator = Nominatim(user_agent="kisan_sathi_nearby_market")
    location = geolocator.geocode(city + ", India")
    if location:
        return {"lat": location.latitude, "lon": location.longitude}
    return None


def fetch_nearby_agri_markets(city_query: str, limit: int = 3, radius_km: int = 40) -> List[Dict]:
    """
    Fetch nearby agricultural markets (mandis) via OpenStreetMap (Overpass API).

    - city_query: full user text or just city name (e.g. "सोलापुर के पास की मंडी दिखाओ")
    - radius_km: search radius around city center
    - limit: number of closest markets to return
    """
    coords = geocode_city(city_query)
    if not coords:
        raise ValueError(f"Could not detect or geocode city from: {city_query}")

    lat, lon = coords["lat"], coords["lon"]
    radius_m = radius_km * 1000

    # Overpass query:
    # - marketplace = general markets
    # - shop=agricultural = agri input shops
    # - market=agriculture = custom tag if present
    # - also any marketplace whose name contains Mandi/APMC (sometimes used)
    query = f"""
    [out:json];
    (
      node["amenity"="marketplace"](around:{radius_m},{lat},{lon});
      way["amenity"="marketplace"](around:{radius_m},{lat},{lon});
      node["shop"="agricultural"](around:{radius_m},{lat},{lon});
      node["market"="agriculture"](around:{radius_m},{lat},{lon});
      node["amenity"="marketplace"]["name"~"Mandi|मंडी|APMC"](around:{radius_m},{lat},{lon});
    );
    out center;
    """

    response = requests.post("https://overpass-api.de/api/interpreter", data=query, timeout=30)
    response.raise_for_status()
    data = response.json()

    results: List[Dict] = []
    for element in data.get("elements", []):
        tags = element.get("tags", {})
        name = tags.get("name", "Unnamed Market")

        # Get coordinates (node has lat/lon, way/relation has 'center')
        lat2 = element.get("lat") or element.get("center", {}).get("lat")
        lon2 = element.get("lon") or element.get("center", {}).get("lon")
        if lat2 is None or lon2 is None:
            continue

        dist_km = round(geodesic((lat, lon), (lat2, lon2)).km, 2)

        results.append(
            {
                "name": name,
                "lat": lat2,
                "lon": lon2,
                "distance_km": dist_km,
            }
        )

    # Sort by distance and keep top N
    results.sort(key=lambda x: x["distance_km"])
    return results[:limit]
