# app/market_price_service.py

import json
from pathlib import Path
from typing import Dict, Any, List

from .utils_city import city_to_district_names

# -------------------------------------------
# 1. Find & load JSON data
# -------------------------------------------

BASE_DIR = Path(__file__).resolve().parent

# We will try these possible locations:
CANDIDATE_PATHS = [
    BASE_DIR / "data" / "mandi_demo.json",      # app/data/mandi_prices.json
    BASE_DIR / "mandi_demo.json",               # app/mandi_prices.json
    BASE_DIR.parent / "mandi_demo.json",        # backend/mandi_prices.json
]

MANDI_ROWS: List[Dict[str, Any]] = []


def _load_data_once() -> None:
    """
    Try to load mandi_prices.json from known paths.
    Fill global MANDI_ROWS.
    """
    global MANDI_ROWS

    # If already loaded, don't load again
    if MANDI_ROWS:
        return

    for path in CANDIDATE_PATHS:
        try:
            if path.exists():
                print(f"[MANDI] Trying to load JSON from: {path}")
                with open(path, "r", encoding="utf-8") as f:
                    data = json.load(f)

                if isinstance(data, list) and len(data) > 0:
                    MANDI_ROWS = data
                    print(f"[MANDI] Loaded {len(MANDI_ROWS)} rows from {path}")
                    return
                else:
                    print(f"[MANDI WARNING] File {path} is empty or not a list.")
        except Exception as e:
            print(f"[MANDI ERROR] Failed to load from {path}: {e}")

    # If we come here, nothing worked
    print("[MANDI WARNING] Could not load mandi_prices.json from any known path.")
    MANDI_ROWS = []


# Load once at import
_load_data_once()


def _normalize_hi(text: str) -> str:
    """
    Simple Hindi normalization:
    - remove nukta '़'
    - remove spaces
    - lower-case

    Example: 'प्याज़', 'प्याज' -> 'प्याज'
    """
    if not text:
        return ""
    return text.replace("़", "").replace(" ", "").strip().lower()


# -------------------------------------------
# 2. Main lookup function
# -------------------------------------------
def fetch_market_prices_for_city_commodity(
    city_slug: str,
    commodity_hi: str
) -> Dict[str, Any]:
    """
    city_slug: 'solapur', 'pune', ...
    commodity_hi: canonical Hindi (e.g. 'टमाटर', 'प्याज़')

    Returns one best matching row:
      { "status": "ok", "results": [ row ] }

    or:
      { "status": "not_found", "results": [] }
      { "status": "empty", "results": [] }
    """

    # Try (re)loading if needed
    if not MANDI_ROWS:
        print("[MANDI DEBUG] MANDI_ROWS empty, trying to reload JSON...")
        _load_data_once()

    if not city_slug or not commodity_hi:
        print("[MANDI DEBUG] Missing city or commodity.")
        return {"status": "empty", "results": []}

    if not MANDI_ROWS:
        print("[MANDI DEBUG] Still no rows loaded in MANDI_ROWS after reload.")
        return {"status": "empty", "results": []}

    city_slug_lower = city_slug.lower().strip()
    target_comm = _normalize_hi(commodity_hi)

    # All possible district spellings for this city
    districts = city_to_district_names(city_slug_lower)
    districts_lower = [d.lower() for d in districts]

    print(
        f"[MANDI DEBUG] Looking for city='{city_slug_lower}', "
        f"districts={districts_lower}, commodity='{target_comm}'"
    )

    matches: List[Dict[str, Any]] = []

    for row in MANDI_ROWS:
        try:
            row_city = str(row.get("city_key", "")).strip().lower()
            row_district = str(row.get("district", "")).strip().lower()
            row_comm = _normalize_hi(str(row.get("commodity_hi", "")))

            # City or district must match
            if row_city != city_slug_lower and row_district not in districts_lower:
                continue

            # Commodity must match
            if row_comm != target_comm:
                continue

            matches.append(row)
        except Exception as e:
            print(f"[MANDI DEBUG] Row error: {e}")
            continue

    print(f"[MANDI DEBUG] Found {len(matches)} matches.")

    if not matches:
        return {"status": "not_found", "results": []}

    # Choose “best” row (highest avg price)
    matches.sort(key=lambda r: float(r.get("avg_modal_price") or 0), reverse=True)
    best = matches[0]

    print(f"[MANDI DEBUG] Best row: {best}")

    return {
        "status": "ok",
        "results": [best],
    }
