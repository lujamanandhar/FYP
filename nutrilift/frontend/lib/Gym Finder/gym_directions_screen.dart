import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/gym_service.dart';

class GymDirectionsScreen extends StatefulWidget {
  final double gymLat;
  final double gymLng;
  final String gymName;

  const GymDirectionsScreen({
    Key? key,
    required this.gymLat,
    required this.gymLng,
    required this.gymName,
  }) : super(key: key);

  @override
  State<GymDirectionsScreen> createState() => _GymDirectionsScreenState();
}

class _GymDirectionsScreenState extends State<GymDirectionsScreen> {
  final MapController _mapController = MapController();
  LatLng? _userLocation;
  List<LatLng> _routePoints = [];
  bool _loading = true;
  String? _error;
  String _distance = '';
  String _duration = '';

  @override
  void initState() {
    super.initState();
    _loadDirections();
  }

  Future<void> _loadDirections() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Get user location
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      Position? pos;
      if (perm != LocationPermission.denied && perm != LocationPermission.deniedForever) {
        try {
          pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          ).timeout(const Duration(seconds: 8));
        } catch (_) {}
      }

      // Fallback to Kathmandu
      pos ??= Position(
        latitude: 27.7172, longitude: 85.3240,
        timestamp: DateTime.now(), accuracy: 0, altitude: 0,
        altitudeAccuracy: 0, heading: 0, headingAccuracy: 0,
        speed: 0, speedAccuracy: 0,
      );

      final userLatLng = LatLng(pos.latitude, pos.longitude);
      final gymLatLng = LatLng(widget.gymLat, widget.gymLng);

      // Fetch route from OSRM (free, no API key)
      final url = 'https://router.project-osrm.org/route/v1/driving/'
          '${pos.longitude},${pos.latitude};'
          '${widget.gymLng},${widget.gymLat}'
          '?overview=full&geometries=geojson';

      final response = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));

      List<LatLng> routePoints = [userLatLng, gymLatLng];
      String distance = '';
      String duration = '';

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final route = routes[0];
          final coords = route['geometry']['coordinates'] as List;
          routePoints = coords
              .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
              .toList();

          final distM = (route['distance'] as num).toDouble();
          final durS = (route['duration'] as num).toDouble();
          distance = distM < 1000
              ? '${distM.toStringAsFixed(0)} m'
              : '${(distM / 1000).toStringAsFixed(1)} km';
          final mins = (durS / 60).round();
          duration = mins < 60 ? '$mins min' : '${mins ~/ 60}h ${mins % 60}min';
        }
      }

      if (mounted) {
        setState(() {
          _userLocation = userLatLng;
          _routePoints = routePoints;
          _distance = distance;
          _duration = duration;
          _loading = false;
        });

        // Fit map to show full route
        if (routePoints.length > 1) {
          final bounds = LatLngBounds.fromPoints(routePoints);
          _mapController.fitCamera(
            CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)),
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final gymLatLng = LatLng(widget.gymLat, widget.gymLng);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.gymName, overflow: TextOverflow.ellipsis),
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: gymLatLng,
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.nutrilift',
              ),
              // Route polyline
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: const Color(0xFFE53935),
                      strokeWidth: 4,
                    ),
                  ],
                ),
              // Markers
              MarkerLayer(
                markers: [
                  // Gym marker
                  Marker(
                    point: gymLatLng,
                    width: 48,
                    height: 48,
                    child: const Icon(
                      Icons.fitness_center,
                      color: Color(0xFFE53935),
                      size: 36,
                    ),
                  ),
                  // User location marker
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 48,
                      height: 48,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(Icons.person, color: Colors.white, size: 20),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Loading overlay
          if (_loading)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFFE53935)),
                    SizedBox(height: 12),
                    Text('Getting directions...'),
                  ],
                ),
              ),
            ),

          // Error
          if (_error != null)
            Positioned(
              top: 16, left: 16, right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Text('Could not load route. Showing gym location only.',
                    style: TextStyle(color: Colors.orange.shade800)),
              ),
            ),

          // Route info card at bottom
          if (!_loading && (_distance.isNotEmpty || _duration.isNotEmpty))
            Positioned(
              bottom: 16, left: 16, right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10)],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.directions_car, color: Color(0xFFE53935), size: 28),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(widget.gymName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text('$_distance  •  $_duration',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _loadDirections,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Refresh', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
