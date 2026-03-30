import 'package:dio/dio.dart';
import 'dio_client.dart';

class GymPlace {
  final String placeId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double rating;
  final int userRatingsTotal;
  final bool? isOpen;
  final List<String> photos;
  final int priceLevel;
  final double? distance; // Distance in km from search center

  GymPlace({
    required this.placeId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.userRatingsTotal,
    this.isOpen,
    required this.photos,
    required this.priceLevel,
    this.distance,
  });

  factory GymPlace.fromJson(Map<String, dynamic> json) {
    return GymPlace(
      placeId: json['place_id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      rating: (json['rating'] ?? 0).toDouble(),
      userRatingsTotal: json['user_ratings_total'] ?? 0,
      isOpen: json['is_open'],
      photos: List<String>.from(json['photos'] ?? []),
      priceLevel: json['price_level'] ?? 0,
      distance: json['distance'] != null ? (json['distance'] as num).toDouble() : null,
    );
  }

  String get priceDisplay {
    if (priceLevel == 0) return 'Free';
    return '\$' * priceLevel;
  }

  double distanceFrom(double lat, double lng) {
    // Simple distance calculation (Haversine formula simplified)
    const double earthRadius = 6371; // km
    final dLat = _toRadians(latitude - lat);
    final dLng = _toRadians(longitude - lng);
    final a = (dLat / 2).abs() * (dLat / 2).abs() +
        (dLng / 2).abs() * (dLng / 2).abs() * 
        (latitude * lat).abs();
    final c = 2 * (a.abs());
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * 3.14159265359 / 180;
  }
}

class GymDetails extends GymPlace {
  final String? phone;
  final String? website;
  final List<GymReview> reviews;
  final Map<String, dynamic>? openingHours;
  final bool isFavorite;

  GymDetails({
    required super.placeId,
    required super.name,
    required super.address,
    required super.latitude,
    required super.longitude,
    required super.rating,
    required super.userRatingsTotal,
    super.isOpen,
    required super.photos,
    required super.priceLevel,
    this.phone,
    this.website,
    required this.reviews,
    this.openingHours,
    required this.isFavorite,
  });

  factory GymDetails.fromJson(Map<String, dynamic> json) {
    return GymDetails(
      placeId: json['place_id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      rating: (json['rating'] ?? 0).toDouble(),
      userRatingsTotal: json['user_ratings_total'] ?? 0,
      isOpen: json['opening_hours']?['open_now'],
      photos: List<String>.from(json['photos'] ?? []),
      priceLevel: json['price_level'] ?? 0,
      phone: json['phone'],
      website: json['website'],
      reviews: (json['reviews'] as List?)
              ?.map((r) => GymReview.fromJson(r))
              .toList() ??
          [],
      openingHours: json['opening_hours'],
      isFavorite: json['is_favorite'] ?? false,
    );
  }

  List<String> get weekdayHours {
    return List<String>.from(openingHours?['weekday_text'] ?? []);
  }
}

class GymReview {
  final String authorName;
  final double rating;
  final String text;
  final String time;

  GymReview({
    required this.authorName,
    required this.rating,
    required this.text,
    required this.time,
  });

  factory GymReview.fromJson(Map<String, dynamic> json) {
    return GymReview(
      authorName: json['author_name'] ?? 'Anonymous',
      rating: (json['rating'] ?? 0).toDouble(),
      text: json['text'] ?? '',
      time: json['time'] ?? '',
    );
  }
}

class GymService {
  final _dioClient = DioClient();

  Future<List<GymPlace>> searchNearbyGyms({
    required double latitude,
    required double longitude,
    int radius = 5000,
  }) async {
    try {
      print('GymService: Searching gyms at lat=$latitude, lng=$longitude, radius=$radius');
      final dio = _dioClient.dio;
      final response = await dio.get('/gyms/nearby/', queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
      });
      
      print('GymService: Response status: ${response.statusCode}');
      print('GymService: Response data: ${response.data}');
      
      final List<dynamic> gyms = response.data['gyms'] ?? [];
      print('GymService: Parsed ${gyms.length} gyms');
      return gyms.map((json) => GymPlace.fromJson(json)).toList();
    } catch (e) {
      print('GymService: Error - $e');
      rethrow;
    }
  }

  Future<GymDetails> getGymDetails(String placeId) async {
    final dio = _dioClient.dio;
    final response = await dio.get('/gyms/details/$placeId/');
    return GymDetails.fromJson(response.data);
  }

  Future<List<GymDetails>> compareGyms(List<String> placeIds) async {
    final dio = _dioClient.dio;
    final response = await dio.post('/gyms/compare/', data: {
      'place_ids': placeIds,
    });
    
    final List<dynamic> gyms = response.data['gyms'] ?? [];
    return gyms.map((json) => GymDetails.fromJson(json)).toList();
  }

  Future<void> addToFavorites(String placeId, String name, String address) async {
    final dio = _dioClient.dio;
    await dio.post('/gyms/favorites/', data: {
      'place_id': placeId,
      'name': name,
      'address': address,
    });
  }

  Future<void> removeFromFavorites(String placeId) async {
    final dio = _dioClient.dio;
    await dio.delete('/gyms/favorites/$placeId/');
  }

  Future<List<Map<String, dynamic>>> getFavorites() async {
    final dio = _dioClient.dio;
    final response = await dio.get('/gyms/favorites/');
    return List<Map<String, dynamic>>.from(response.data);
  }
}
