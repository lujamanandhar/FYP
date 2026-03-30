import requests
from typing import List, Dict, Optional
import math


class OpenStreetMapService:
    """Service for fetching gym data from OpenStreetMap Overpass API - 100% FREE"""
    
    # Public Overpass API endpoints (completely free, no API key needed)
    OVERPASS_ENDPOINTS = [
        "https://overpass-api.de/api/interpreter",
        "https://overpass.kumi.systems/api/interpreter",
    ]
    
    def __init__(self):
        self.current_endpoint = 0
    
    def search_nearby_gyms(self, latitude: float, longitude: float, radius: int = 5000) -> List[Dict]:
        """
        Search for gyms near a location using OpenStreetMap Overpass API
        
        Args:
            latitude: Latitude of search center
            longitude: Longitude of search center
            radius: Search radius in meters (default 5000m = 5km)
        
        Returns:
            List of gym data dictionaries
        """
        # Convert radius to bounding box (approximate)
        # 1 degree latitude ≈ 111km
        # 1 degree longitude ≈ 111km * cos(latitude)
        lat_offset = (radius / 1000) / 111.0
        lng_offset = (radius / 1000) / (111.0 * math.cos(math.radians(latitude)))
        
        south = latitude - lat_offset
        west = longitude - lng_offset
        north = latitude + lat_offset
        east = longitude + lng_offset
        
        # Overpass QL query for gyms and fitness centers
        # Tags: leisure=fitness_centre, leisure=sports_centre, sport=fitness
        query = f"""
        [out:json][timeout:25];
        (
          node["leisure"="fitness_centre"]({south},{west},{north},{east});
          way["leisure"="fitness_centre"]({south},{west},{north},{east});
          node["leisure"="sports_centre"]["sport"~"fitness|gym"]({south},{west},{north},{east});
          way["leisure"="sports_centre"]["sport"~"fitness|gym"]({south},{west},{north},{east});
        );
        out center tags;
        """
        
        try:
            endpoint = self.OVERPASS_ENDPOINTS[self.current_endpoint]
            response = requests.post(
                endpoint,
                data={'data': query},
                timeout=30,
                headers={'User-Agent': 'NutriLift-Gym-Finder/1.0'}
            )
            response.raise_for_status()
            data = response.json()
            
            print(f"✅ OpenStreetMap Overpass API: Found {len(data.get('elements', []))} gyms")
            
            gyms = []
            for element in data.get('elements', []):
                gym = self._format_osm_place(element, latitude, longitude)
                if gym:
                    gyms.append(gym)
            
            # Sort by distance from search center
            gyms.sort(key=lambda g: self._calculate_distance(
                latitude, longitude, g['latitude'], g['longitude']
            ))
            
            return gyms[:20]  # Return top 20 closest gyms
            
        except Exception as e:
            print(f"❌ Error fetching from Overpass API: {e}")
            # Try alternate endpoint
            if self.current_endpoint < len(self.OVERPASS_ENDPOINTS) - 1:
                self.current_endpoint += 1
                return self.search_nearby_gyms(latitude, longitude, radius)
            return []
    
    def get_place_details(self, place_id: str) -> Optional[Dict]:
        """
        Get detailed information about a specific place from OSM
        
        Args:
            place_id: OSM element ID (format: "node/123" or "way/456")
        
        Returns:
            Detailed place information
        """
        try:
            # Parse OSM ID format
            if '/' in place_id:
                element_type, element_id = place_id.split('/')
            else:
                # Assume it's a node if no type specified
                element_type = 'node'
                element_id = place_id
            
            query = f"""
            [out:json][timeout:25];
            {element_type}({element_id});
            out center tags;
            """
            
            endpoint = self.OVERPASS_ENDPOINTS[self.current_endpoint]
            response = requests.post(
                endpoint,
                data={'data': query},
                timeout=30,
                headers={'User-Agent': 'NutriLift-Gym-Finder/1.0'}
            )
            response.raise_for_status()
            data = response.json()
            
            elements = data.get('elements', [])
            if elements:
                return self._format_osm_place_details(elements[0])
            
            return None
            
        except Exception as e:
            print(f"Error fetching place details: {e}")
            return None
    
    def _format_osm_place(self, element: Dict, search_lat: float, search_lng: float) -> Optional[Dict]:
        """Format OSM element to match our gym data structure"""
        tags = element.get('tags', {})
        
        # Get coordinates
        if 'lat' in element and 'lon' in element:
            lat = element['lat']
            lon = element['lon']
        elif 'center' in element:
            lat = element['center']['lat']
            lon = element['center']['lon']
        else:
            return None
        
        # Get name
        name = tags.get('name', tags.get('operator', 'Unnamed Gym'))
        
        # Build address from available tags
        address_parts = []
        if 'addr:street' in tags:
            address_parts.append(tags['addr:street'])
        if 'addr:city' in tags:
            address_parts.append(tags['addr:city'])
        elif 'addr:district' in tags:
            address_parts.append(tags['addr:district'])
        
        address = ', '.join(address_parts) if address_parts else 'Address not available'
        
        # Calculate distance
        distance = self._calculate_distance(search_lat, search_lng, lat, lon)
        
        # Create place_id from OSM element
        place_id = f"{element['type']}/{element['id']}"
        
        # Default photo (OSM doesn't provide photos directly)
        photos = ['https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800']
        
        return {
            'place_id': place_id,
            'name': name,
            'address': address,
            'latitude': lat,
            'longitude': lon,
            'rating': 0,  # OSM doesn't have ratings
            'user_ratings_total': 0,
            'is_open': None,  # We could parse opening_hours but it's complex
            'photos': photos,
            'price_level': 0,
            'distance': round(distance, 2),  # Distance in km
        }
    
    def _format_osm_place_details(self, element: Dict) -> Dict:
        """Format detailed OSM place data"""
        tags = element.get('tags', {})
        
        # Get coordinates
        if 'lat' in element and 'lon' in element:
            lat = element['lat']
            lon = element['lon']
        elif 'center' in element:
            lat = element['center']['lat']
            lon = element['center']['lon']
        else:
            lat = 0
            lon = 0
        
        # Get name
        name = tags.get('name', tags.get('operator', 'Unnamed Gym'))
        
        # Build full address
        address_parts = []
        if 'addr:housenumber' in tags:
            address_parts.append(tags['addr:housenumber'])
        if 'addr:street' in tags:
            address_parts.append(tags['addr:street'])
        if 'addr:city' in tags:
            address_parts.append(tags['addr:city'])
        if 'addr:postcode' in tags:
            address_parts.append(tags['addr:postcode'])
        
        address = ', '.join(address_parts) if address_parts else 'Address not available'
        
        # Get contact info
        phone = tags.get('phone', tags.get('contact:phone', ''))
        website = tags.get('website', tags.get('contact:website', ''))
        
        # Parse opening hours if available
        opening_hours = {}
        if 'opening_hours' in tags:
            opening_hours = {
                'raw': tags['opening_hours'],
                'weekday_text': [tags['opening_hours']],  # Simplified
                'open_now': None,
            }
        
        place_id = f"{element['type']}/{element['id']}"
        
        return {
            'place_id': place_id,
            'name': name,
            'address': address,
            'phone': phone,
            'website': website,
            'latitude': lat,
            'longitude': lon,
            'rating': 0,
            'user_ratings_total': 0,
            'price_level': 0,
            'photos': ['https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800'],
            'reviews': [],
            'opening_hours': opening_hours,
        }
    
    def _calculate_distance(self, lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        """Calculate distance between two points using Haversine formula (returns km)"""
        R = 6371  # Earth's radius in kilometers
        
        lat1_rad = math.radians(lat1)
        lat2_rad = math.radians(lat2)
        delta_lat = math.radians(lat2 - lat1)
        delta_lon = math.radians(lon2 - lon1)
        
        a = math.sin(delta_lat/2)**2 + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(delta_lon/2)**2
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
        
        return R * c
