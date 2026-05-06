import requests
import math
import os
from typing import List, Dict, Optional


class FoursquareService:
    """
    Gym data from Foursquare Places API v3.
    Provides real ratings, reviews, phone numbers, hours, and photos.
    Map tiles still come from OSM — this is purely business data.
    """

    BASE_URL = "https://api.foursquare.com/v3"
    # Foursquare category IDs for gyms/fitness
    GYM_CATEGORIES = "73301,73302,73303,73304"  # Gym, Fitness Center, Yoga, Pilates

    def __init__(self):
        self.api_key = os.environ.get("FOURSQUARE_API_KEY", "")
        self.headers = {
            "Authorization": self.api_key,
            "Accept": "application/json",
        }

    def search_nearby_gyms(self, latitude: float, longitude: float, radius: int = 5000) -> List[Dict]:
        """Search for gyms near a location. Returns list of gym dicts."""
        try:
            response = requests.get(
                f"{self.BASE_URL}/places/search",
                headers=self.headers,
                params={
                    "ll": f"{latitude},{longitude}",
                    "radius": min(radius, 100000),
                    "categories": self.GYM_CATEGORIES,
                    "limit": 20,
                    "fields": "fsq_id,name,location,geocodes,rating,stats,hours,tel,website,photos,distance",
                },
                timeout=15,
            )
            response.raise_for_status()
            data = response.json()

            gyms = []
            for place in data.get("results", []):
                gym = self._format_place(place)
                if gym:
                    gyms.append(gym)

            # Sort by distance
            gyms.sort(key=lambda g: g.get("distance") or 9999)
            print(f"✅ Foursquare: Found {len(gyms)} gyms near {latitude},{longitude}")
            return gyms

        except requests.exceptions.RequestException as e:
            print(f"❌ Foursquare search error: {e}")
            raise Exception(f"Foursquare API error: {e}")

    def get_place_details(self, fsq_id: str) -> Optional[Dict]:
        """Get detailed info for a specific place by Foursquare ID."""
        try:
            response = requests.get(
                f"{self.BASE_URL}/places/{fsq_id}",
                headers=self.headers,
                params={
                    "fields": "fsq_id,name,location,geocodes,rating,stats,hours,tel,website,photos,tips,price,description",
                },
                timeout=15,
            )
            response.raise_for_status()
            place = response.json()
            return self._format_place_details(place)

        except requests.exceptions.RequestException as e:
            print(f"❌ Foursquare details error for {fsq_id}: {e}")
            return None

    def _format_place(self, place: Dict) -> Optional[Dict]:
        """Format a Foursquare place result to our standard gym dict."""
        geocodes = place.get("geocodes", {}).get("main", {})
        lat = geocodes.get("latitude")
        lng = geocodes.get("longitude")
        if not lat or not lng:
            return None

        location = place.get("location", {})
        address_parts = []
        if location.get("address"):
            address_parts.append(location["address"])
        if location.get("locality"):
            address_parts.append(location["locality"])
        elif location.get("region"):
            address_parts.append(location["region"])
        address = ", ".join(address_parts) if address_parts else "Address not available"

        # Rating is 0-10 in Foursquare, convert to 0-5
        raw_rating = place.get("rating", 0) or 0
        rating = round(raw_rating / 2, 1)

        stats = place.get("stats", {})
        total_ratings = stats.get("total_ratings", 0) or 0

        # Photos
        photos = []
        for photo in place.get("photos", [])[:3]:
            prefix = photo.get("prefix", "")
            suffix = photo.get("suffix", "")
            if prefix and suffix:
                photos.append(f"{prefix}800x600{suffix}")

        if not photos:
            photos = [self._fallback_photo(place.get("fsq_id", ""))]

        # Hours / open now
        hours = place.get("hours", {})
        is_open = hours.get("open_now")

        return {
            "place_id": place.get("fsq_id", ""),
            "name": place.get("name", "Unknown Gym"),
            "address": address,
            "latitude": lat,
            "longitude": lng,
            "rating": rating,
            "user_ratings_total": total_ratings,
            "is_open": is_open,
            "photos": photos,
            "price_level": place.get("price", 0) or 0,
            "distance": round((place.get("distance") or 0) / 1000, 2),  # metres → km
        }

    def _format_place_details(self, place: Dict) -> Dict:
        """Format detailed Foursquare place data."""
        geocodes = place.get("geocodes", {}).get("main", {})
        lat = geocodes.get("latitude", 0)
        lng = geocodes.get("longitude", 0)

        location = place.get("location", {})
        address_parts = []
        if location.get("address"):
            address_parts.append(location["address"])
        if location.get("locality"):
            address_parts.append(location["locality"])
        if location.get("region"):
            address_parts.append(location["region"])
        if location.get("postcode"):
            address_parts.append(location["postcode"])
        address = ", ".join(address_parts) if address_parts else "Address not available"

        raw_rating = place.get("rating", 0) or 0
        rating = round(raw_rating / 2, 1)

        stats = place.get("stats", {})
        total_ratings = stats.get("total_ratings", 0) or 0

        # Photos
        photos = []
        for photo in place.get("photos", [])[:5]:
            prefix = photo.get("prefix", "")
            suffix = photo.get("suffix", "")
            if prefix and suffix:
                photos.append(f"{prefix}800x600{suffix}")
        if not photos:
            photos = [self._fallback_photo(place.get("fsq_id", ""))]

        # Hours
        hours_data = place.get("hours", {})
        is_open = hours_data.get("open_now")
        weekday_text = hours_data.get("display", [])
        if isinstance(weekday_text, str):
            weekday_text = [weekday_text]
        opening_hours = {
            "open_now": is_open,
            "weekday_text": weekday_text,
        } if hours_data else {}

        # Tips (reviews)
        reviews = []
        for tip in place.get("tips", [])[:5]:
            reviews.append({
                "author_name": tip.get("author", {}).get("name", "Anonymous") if isinstance(tip.get("author"), dict) else "Anonymous",
                "rating": rating,  # Foursquare tips don't have per-tip ratings
                "text": tip.get("text", ""),
                "time": tip.get("created_at", ""),
            })

        return {
            "place_id": place.get("fsq_id", ""),
            "name": place.get("name", "Unknown Gym"),
            "address": address,
            "phone": place.get("tel", ""),
            "website": place.get("website", ""),
            "latitude": lat,
            "longitude": lng,
            "rating": rating,
            "user_ratings_total": total_ratings,
            "price_level": place.get("price", 0) or 0,
            "photos": photos,
            "reviews": reviews,
            "opening_hours": opening_hours,
            "description": place.get("description", ""),
        }

    def _fallback_photo(self, fsq_id: str) -> str:
        """Fallback gym photo from Unsplash when no Foursquare photo available."""
        photos = [
            "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800",
            "https://images.unsplash.com/photo-1540497077202-7c8a3999166f?w=800",
            "https://images.unsplash.com/photo-1571902943202-507ec2618e8f?w=800",
            "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800",
            "https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=800",
        ]
        return photos[abs(hash(fsq_id)) % len(photos)]

    @staticmethod
    def _calculate_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        R = 6371
        lat1_r, lat2_r = math.radians(lat1), math.radians(lat2)
        d_lat = math.radians(lat2 - lat1)
        d_lon = math.radians(lon2 - lon1)
        a = math.sin(d_lat / 2) ** 2 + math.cos(lat1_r) * math.cos(lat2_r) * math.sin(d_lon / 2) ** 2
        return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
