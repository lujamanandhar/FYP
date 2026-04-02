import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/gym_service.dart';
import 'gym_details_screen.dart';

class GymMapView extends StatefulWidget {
  final List<GymPlace> gyms;
  final Position? currentPosition;
  final Function(double lat, double lng, int radius)? onAreaChanged;

  const GymMapView({
    Key? key,
    required this.gyms,
    this.currentPosition,
    this.onAreaChanged,
  }) : super(key: key);

  @override
  State<GymMapView> createState() => _GymMapViewState();
}

class _GymMapViewState extends State<GymMapView> {
  late final MapController _mapController;
  GymPlace? _selectedGym;
  List<GymPlace> _displayedGyms = [];
  bool _isSearching = false;
  bool _isLoadingGyms = false;
  final TextEditingController _searchController = TextEditingController();
  final GymService _gymService = GymService();
  LatLng? _mapCenter;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _displayedGyms = widget.gyms;
    _mapCenter = widget.currentPosition != null
        ? LatLng(widget.currentPosition!.latitude, widget.currentPosition!.longitude)
        : const LatLng(27.7172, 85.3240);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty && mounted) {
        final loc = locations.first;
        final newCenter = LatLng(loc.latitude, loc.longitude);
        _mapController.move(newCenter, 14);
        setState(() {
          _mapCenter = newCenter;
          _isSearching = false;
        });
        // Fetch gyms at new location
        await _fetchGymsAt(loc.latitude, loc.longitude);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location not found: $query')),
        );
      }
    }
  }

  Future<void> _fetchGymsAt(double lat, double lng) async {
    setState(() => _isLoadingGyms = true);
    try {
      final gyms = await _gymService.searchNearbyGyms(
        latitude: lat,
        longitude: lng,
        radius: 5000,
      );
      if (mounted) {
        setState(() {
          _displayedGyms = gyms;
          _isLoadingGyms = false;
        });
        widget.onAreaChanged?.call(lat, lng, 5000);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingGyms = false);
    }
  }

  void _onMapMoveEnd(MapCamera camera, bool hasGesture) {
    if (hasGesture) {
      setState(() => _mapCenter = camera.center);
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = _mapCenter ?? const LatLng(27.7172, 85.3240);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gym Map'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 2,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search location (e.g. Thamel, Kathmandu)',
                prefixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Icon(Icons.search, color: Color(0xFFE53935)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: _searchLocation,
              onChanged: (v) => setState(() {}),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 14,
              onMapEvent: (event) {
                if (event is MapEventMoveEnd) {
                  _onMapMoveEnd(event.camera, event.source != MapEventSource.mapController);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.nutrilift',
                maxZoom: 19,
                errorTileCallback: (tile, error, stackTrace) {
                  debugPrint('Map tile error: $error');
                },
              ),
              MarkerLayer(
                markers: [
                  // User location
                  if (widget.currentPosition != null)
                    Marker(
                      point: LatLng(
                        widget.currentPosition!.latitude,
                        widget.currentPosition!.longitude,
                      ),
                      width: 44,
                      height: 44,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blue, width: 2),
                        ),
                        child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 28),
                      ),
                    ),
                  // Gym markers
                  ..._displayedGyms.map((gym) => Marker(
                        point: LatLng(gym.latitude, gym.longitude),
                        width: 44,
                        height: 44,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedGym = gym),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _selectedGym?.placeId == gym.placeId
                                  ? const Color(0xFFE53935)
                                  : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFE53935), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.fitness_center,
                              color: _selectedGym?.placeId == gym.placeId
                                  ? Colors.white
                                  : const Color(0xFFE53935),
                              size: 22,
                            ),
                          ),
                        ),
                      )),
                ],
              ),
            ],
          ),

          // Loading overlay
          if (_isLoadingGyms)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 8),
                      Text('Finding gyms...', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),

          // "Search this area" button — appears after map is moved
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedOpacity(
                opacity: _isLoadingGyms ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_mapCenter != null) {
                      _fetchGymsAt(_mapCenter!.latitude, _mapCenter!.longitude);
                    }
                  },
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Search this area', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFE53935),
                    elevation: 4,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
            ),
          ),

          // Gym count badge
          Positioned(
            top: 56,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${_displayedGyms.length} gyms',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // My location FAB
          Positioned(
            bottom: _selectedGym != null ? 200 : 24,
            right: 16,
            child: FloatingActionButton.small(
              onPressed: () {
                if (widget.currentPosition != null) {
                  final pos = LatLng(
                    widget.currentPosition!.latitude,
                    widget.currentPosition!.longitude,
                  );
                  _mapController.move(pos, 14);
                  setState(() => _mapCenter = pos);
                }
              },
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue,
              child: const Icon(Icons.my_location),
            ),
          ),

          // Selected Gym Card
          if (_selectedGym != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedGym!.name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => setState(() => _selectedGym = null),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star, size: 12, color: Colors.white),
                                const SizedBox(width: 3),
                                Text(
                                  _selectedGym!.rating.toStringAsFixed(1),
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_selectedGym!.isOpen != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _selectedGym!.isOpen! ? Colors.green : Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _selectedGym!.isOpen! ? 'Open' : 'Closed',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(_selectedGym!.address, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GymDetailsScreen(placeId: _selectedGym!.placeId),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('View Details'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
