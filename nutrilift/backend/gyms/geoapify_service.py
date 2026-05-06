import os
import math
import requests
from typing import List, Dict, Optional

# Load .env manually if needed (for when Django hasn't loaded it yet)
try:
    from django.conf import settings as django_settings
    _API_KEY = getattr(django_settings, 'GEOAPIFY_API_KEY', '') or os.environ.get("GEOAPIFY_API_KEY", "")
except Exception:
    _API_KEY = os.environ.get("GEOAPIFY_API_KEY", "")


class GeoapifyService:
    """
    Gym data from Geoapify Places API.
    Free tier: 3,000 requests/day, no credit card required.
    Returns: name, address, phone, website, opening_hours, lat/lng, distance.
    """

    BASE_URL = "https://api.geoapify.com/v2/places"
    DETAILS_URL = "https://api.geoapify.com/v2/place-details"

    # Geoapify category for gyms and fitness
    GYM_CATEGORIES = "sport.fitness"

    def __init__(self):
        self.api_key = (
            os.environ.get("GEOAPIFY_API_KEY")
            or _API_KEY
            or "9697d303f4fb470f86ebfeba138f0bdd"
        )

    def search_nearby_gyms(self, latitude: float, longitude: float, radius: int = 5000) -> List[Dict]:
        """Search for gyms near a location. Returns list of gym dicts."""
        try:
            response = requests.get(
                self.BASE_URL,
                params={
                    "categories": self.GYM_CATEGORIES,
                    "filter": f"circle:{longitude},{latitude},{radius}",
                    "limit": 20,
                    "apiKey": self.api_key,
                },
                timeout=15,
            )
            response.raise_for_status()
            data = response.json()

            gyms = []
            for feature in data.get("features", []):
                gym = self._format_feature(feature, latitude, longitude)
                if gym:
                    gyms.append(gym)

            # Sort by distance
            gyms.sort(key=lambda g: g.get("distance") or 9999)
            print(f"✅ Geoapify: Found {len(gyms)} gyms near {latitude},{longitude}")
            return gyms

        except requests.exceptions.RequestException as e:
            print(f"❌ Geoapify search error: {e}")
            raise Exception(f"Geoapify API error: {e}")

    def get_place_details(self, place_id: str) -> Optional[Dict]:
        """Get detailed info for a specific place by Geoapify place_id."""
        try:
            response = requests.get(
                self.DETAILS_URL,
                params={
                    "id": place_id,
                    "apiKey": self.api_key,
                },
                timeout=15,
            )
            response.raise_for_status()
            data = response.json()

            features = data.get("features", [])
            if not features:
                return None

            return self._format_feature_details(features[0])

        except requests.exceptions.RequestException as e:
            print(f"❌ Geoapify details error for {place_id}: {e}")
            return None

    def _format_feature(self, feature: Dict, search_lat: float, search_lng: float) -> Optional[Dict]:
        """Format a Geoapify feature to our standard gym dict."""
        props = feature.get("properties", {})
        geometry = feature.get("geometry", {})

        # Get coordinates
        coords = geometry.get("coordinates", [])
        if len(coords) < 2:
            return None
        lng, lat = coords[0], coords[1]

        name = props.get("name")
        if not name:
            return None

        # Build address
        address = props.get("formatted") or props.get("address_line1") or "Address not available"

        # Phone — check multiple locations in the response
        raw = props.get("datasource", {}).get("raw", {})
        phone = (
            props.get("contact", {}).get("phone")
            or raw.get("phone")
            or raw.get("contact:phone")
            or ""
        )

        # Website
        website = (
            props.get("website")
            or props.get("contact", {}).get("website")
            or raw.get("website")
            or raw.get("contact:website")
            or ""
        )

        # Opening hours
        opening_hours_raw = (
            props.get("opening_hours")
            or raw.get("opening_hours")
            or ""
        )

        # Distance
        distance_m = props.get("distance") or self._calculate_distance(search_lat, search_lng, lat, lng) * 1000
        distance_km = round(distance_m / 1000, 2)

        # Place ID for details lookup
        place_id = props.get("place_id") or props.get("id") or f"{lat},{lng}"

        return {
            "place_id": place_id,
            "name": name,
            "address": address,
            "latitude": lat,
            "longitude": lng,
            "phone": phone,
            "website": website,
            "opening_hours_raw": opening_hours_raw,
            "rating": 0,           # Geoapify doesn't provide ratings
            "user_ratings_total": 0,
            "is_open": self._is_open_now(opening_hours_raw),
            "photos": [self._fallback_photo(place_id)],
            "price_level": 0,
            "distance": distance_km,
        }

    def _format_feature_details(self, feature: Dict) -> Dict:
        """Format detailed Geoapify feature data."""
        props = feature.get("properties", {})
        geometry = feature.get("geometry", {})

        coords = geometry.get("coordinates", [])
        lat = coords[1] if len(coords) >= 2 else 0
        lng = coords[0] if len(coords) >= 2 else 0

        raw = props.get("datasource", {}).get("raw", {})

        name = props.get("name") or "Unknown Gym"
        address = props.get("formatted") or "Address not available"

        phone = (
            props.get("contact", {}).get("phone")
            or raw.get("phone")
            or raw.get("contact:phone")
            or ""
        )
        website = (
            props.get("website")
            or props.get("contact", {}).get("website")
            or raw.get("website")
            or raw.get("contact:website")
            or ""
        )

        opening_hours_raw = props.get("opening_hours") or raw.get("opening_hours") or ""

        # Parse opening hours into weekday text list
        weekday_text = self._parse_opening_hours(opening_hours_raw)

        place_id = props.get("place_id") or props.get("id") or f"{lat},{lng}"

        return {
            "place_id": place_id,
            "name": name,
            "address": address,
            "phone": phone,
            "website": website,
            "latitude": lat,
            "longitude": lng,
            "rating": 0,
            "user_ratings_total": 0,
            "price_level": 0,
            "photos": [self._fallback_photo(place_id)],
            "reviews": [],
            "opening_hours": {
                "open_now": self._is_open_now(opening_hours_raw),
                "weekday_text": weekday_text,
                "raw": opening_hours_raw,
            },
            "description": raw.get("description") or "",
        }

    def _is_open_now(self, opening_hours_raw: str) -> Optional[bool]:
        """Simple check if currently open based on raw opening hours string."""
        if not opening_hours_raw:
            return None
        # If it says 24/7 or Mo-Su with broad hours, likely open
        if "24/7" in opening_hours_raw:
            return True
        # For more complex parsing we'd need a library — return None (unknown) for now
        return None

    def _parse_opening_hours(self, raw: str) -> List[str]:
        """Convert raw OSM opening_hours string to a readable list."""
        if not raw:
            return []
        # Return as-is for now — the raw string is already human-readable
        # e.g. "Mo-Su 08:00-20:00" or "Mo-Fr 06:00-22:00; Sa-Su 08:00-20:00"
        return [raw]

    def _fallback_photo(self, place_id: str) -> str:
        """Fallback gym photo from Unsplash."""
        photos = [
            "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800",
            "https://images.unsplash.com/photo-1540497077202-7c8a3999166f?w=800",
            "https://images.unsplash.com/photo-1571902943202-507ec2618e8f?w=800",
            "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800",
            "https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=800",
        ]
        return photos[abs(hash(place_id)) % len(photos)]

    @staticmethod
    def _calculate_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        """Haversine distance in km."""
        R = 6371
        lat1_r, lat2_r = math.radians(lat1), math.radians(lat2)
        d_lat = math.radians(lat2 - lat1)
        d_lon = math.radians(lon2 - lon1)
        a = math.sin(d_lat / 2) ** 2 + math.cos(lat1_r) * math.cos(lat2_r) * math.sin(d_lon / 2) ** 2
        return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
