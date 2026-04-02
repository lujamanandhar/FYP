import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'gym_details_screen.dart';
import 'gym_map_view.dart';
import 'area_selector_map.dart';
import '../widgets/nutrilift_header.dart';
import '../widgets/streak_overview_widget.dart';
import '../services/streak_service.dart';
import '../services/dashboard_refresh_service.dart';
import '../services/gym_service.dart';
import 'dart:async';

class GymComparisonScreen extends StatefulWidget {
  @override
  State<GymComparisonScreen> createState() => _GymComparisonScreenState();
}

class _GymComparisonScreenState extends State<GymComparisonScreen> {
  final TextEditingController _searchController = TextEditingController();
  final GymService _gymService = GymService();
  String _selectedFilter = 'All';
  int _currentStreak = 0;
  AllStreaks _allStreaks = const AllStreaks();
  StreamSubscription<void>? _refreshSubscription;
  List<GymPlace> _gyms = [];
  bool _isLoading = false;
  Position? _currentPosition;
  List<String> _selectedForComparison = [];
  double _searchRadius = 5000; // Default 5km
  String? _searchAreaName;

  @override
  void initState() {
    super.initState();
    debugPrint('=== GymComparisonScreen: initState called ===');
    _loadStreak();
    _getCurrentLocation();
    _refreshSubscription = DashboardRefreshService().refreshStream.listen((_) {
      if (mounted) _loadStreak();
    });
  }

  @override
  void dispose() {
    _refreshSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStreak() async {
    try {
      final streaks = await StreakService().fetchAllStreaks();
      if (mounted) {
        setState(() {
          _allStreaks = streaks;
          _currentStreak = streaks.workout.currentStreak;
        });
      }
    } catch (e) {
      debugPrint('Error loading streak: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    
    try {
      if (kIsWeb) {
        // For web, use default location (Kathmandu, Nepal)
        setState(() {
          _currentPosition = Position(
            latitude: 27.7172,
            longitude: 85.3240,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
        });
        debugPrint('Using default location for web: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
      } else {
        // Mobile platform - use geolocator
        await _getMobileLocation();
      }
      
      if (_currentPosition != null) {
        debugPrint('Searching gyms at: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
        await _searchGyms();
      } else {
        debugPrint('No position available');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  // Kathmandu, Nepal — default location
  static const double _defaultLat = 27.7172;
  static const double _defaultLng = 85.3240;

  Position _kathmanduPosition() => Position(
        latitude: _defaultLat,
        longitude: _defaultLng,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );

  Future<void> _getMobileLocation() async {
    // Check permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      // Fall back to Kathmandu
      setState(() => _currentPosition = _kathmanduPosition());
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10));

      // Validate — if lat/lng is 0,0 or clearly wrong, use Kathmandu
      if (position.latitude.abs() < 0.1 && position.longitude.abs() < 0.1) {
        setState(() => _currentPosition = _kathmanduPosition());
      } else {
        setState(() => _currentPosition = position);
      }
    } catch (_) {
      // Timeout or error — fall back to Kathmandu
      setState(() => _currentPosition = _kathmanduPosition());
    }
  }

  Future<void> _searchGyms({double? latitude, double? longitude, int? radius}) async {
    final lat = latitude ?? _currentPosition?.latitude;
    final lng = longitude ?? _currentPosition?.longitude;
    final searchRadius = radius ?? _searchRadius.toInt();
    
    if (lat == null || lng == null) {
      debugPrint('Cannot search: no location available');
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      debugPrint('Calling gym service with lat: $lat, lng: $lng, radius: $searchRadius');
      final gyms = await _gymService.searchNearbyGyms(
        latitude: lat,
        longitude: lng,
        radius: searchRadius,
      );
      
      debugPrint('Received ${gyms.length} gyms from API');
      
      setState(() {
        _gyms = gyms;
        _isLoading = false;
        if (latitude != null && longitude != null) {
          _currentPosition = Position(
            latitude: latitude,
            longitude: longitude,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
          _searchRadius = searchRadius.toDouble();
        }
      });
    } catch (e) {
      debugPrint('Error searching gyms: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading gyms: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _toggleComparison(String placeId) {
    setState(() {
      if (_selectedForComparison.contains(placeId)) {
        _selectedForComparison.remove(placeId);
      } else {
        if (_selectedForComparison.length < 3) {
          _selectedForComparison.add(placeId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum 3 gyms can be compared')),
          );
        }
      }
    });
  }

  Future<void> _showComparison() async {
    if (_selectedForComparison.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least 2 gyms to compare')),
      );
      return;
    }

    try {
      final gyms = await _gymService.compareGyms(_selectedForComparison);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GymComparisonResultScreen(gyms: gyms),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error comparing gyms: $e')),
        );
      }
    }
  }

  Future<void> _openMap() async {
    // Open area selector — user taps to set center + adjusts radius
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => AreaSelectorMap(
          currentPosition: _currentPosition,
        ),
      ),
    );

    if (result != null) {
      final latitude = result['latitude'] as double;
      final longitude = result['longitude'] as double;
      final radius = result['radius'] as int;

      setState(() {
        _searchAreaName = 'Selected Area (${(radius / 1000).toStringAsFixed(1)} km)';
      });

      await _searchGyms(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
      );
    }
  }

  List<GymPlace> get filteredGyms {
    List<GymPlace> filtered = _gyms;
    
    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((gym) =>
          gym.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          gym.address.toLowerCase().contains(_searchController.text.toLowerCase())).toList();
    }
    
    // Apply sorting
    if (_currentPosition != null) {
      switch (_selectedFilter) {
        case 'Near Me':
          filtered.sort((a, b) {
            final distA = a.distanceFrom(_currentPosition!.latitude, _currentPosition!.longitude);
            final distB = b.distanceFrom(_currentPosition!.latitude, _currentPosition!.longitude);
            return distA.compareTo(distB);
          });
          break;
        case 'Top Rated':
          filtered.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'Most Reviewed':
          filtered.sort((a, b) => b.userRatingsTotal.compareTo(a.userRatingsTotal));
          break;
      }
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🏋️ GymComparisonScreen: build() - isLoading=$_isLoading, gyms=${_gyms.length}, position=${_currentPosition?.latitude}');
    return NutriLiftScaffold(
      streakCount: _currentStreak,
      onStreakTap: () => showStreakOverview(context, _allStreaks),
      body: RefreshIndicator(
        onRefresh: _searchGyms,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar with Location Button
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search gyms...',
                          prefixIcon: Icon(Icons.search, color: Colors.red[700]),
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
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.red[700]!, width: 2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.location_on, color: Colors.white),
                        onPressed: _openMap,
                        tooltip: 'Select Search Area',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Loading indicator at top
                if (_isLoading && _gyms.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Finding gyms near you...',
                            style: TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Selected Area Display
                if (_searchAreaName != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE53935)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFFE53935), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Searching in: $_searchAreaName',
                            style: const TextStyle(
                              color: Color(0xFFE53935),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          color: const Color(0xFFE53935),
                          onPressed: () {
                            setState(() => _searchAreaName = null);
                            _getCurrentLocation();
                          },
                          tooltip: 'Reset to current location',
                        ),
                      ],
                    ),
                  ),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Near Me', 'Top Rated', 'Most Reviewed']
                        .map((filter) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(filter, style: const TextStyle(fontWeight: FontWeight.w500)),
                                selected: _selectedFilter == filter,
                                selectedColor: Colors.red[700],
                                labelStyle: TextStyle(
                                  color: _selectedFilter == filter ? Colors.white : Colors.black,
                                ),
                                onSelected: (selected) {
                                  setState(() => _selectedFilter = filter);
                                },
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Comparison Bar
                if (_selectedForComparison.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_selectedForComparison.length} gym(s) selected',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _selectedForComparison.clear()),
                          child: const Text('Clear', style: TextStyle(color: Colors.white)),
                        ),
                        ElevatedButton(
                          onPressed: _showComparison,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFFE53935),
                          ),
                          child: const Text('Compare'),
                        ),
                      ],
                    ),
                  ),
                if (_selectedForComparison.isNotEmpty) const SizedBox(height: 16),

                // Results Count
                if (!_isLoading)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${filteredGyms.length} gyms found',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      TextButton.icon(
                        onPressed: _getCurrentLocation,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Refresh'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFE53935),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),

                // Gym List
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredGyms.isEmpty
                        ? Center(
                            child: Column(
                              children: [
                                const SizedBox(height: 40),
                                Icon(Icons.fitness_center, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'No gyms found nearby',
                                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: _getCurrentLocation,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredGyms.length,
                            itemBuilder: (context, index) {
                              final gym = filteredGyms[index];
                              return _buildGymCard(gym);
                            },
                          ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGymCard(GymPlace gym) {
    final isSelected = _selectedForComparison.contains(gym.placeId);
    // Use distance from API if available (OSM provides it), otherwise calculate
    final distance = gym.distance ?? (_currentPosition != null
        ? gym.distanceFrom(_currentPosition!.latitude, _currentPosition!.longitude)
        : 0.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? const BorderSide(color: Color(0xFFE53935), width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GymDetailsScreen(placeId: gym.placeId),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Gym Image
            if (gym.photos.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  gym.photos.first,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150,
                    color: Colors.grey[300],
                    child: const Icon(Icons.fitness_center, size: 48),
                  ),
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          gym.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Checkbox(
                        value: isSelected,
                        onChanged: (value) => _toggleComparison(gym.placeId),
                        activeColor: const Color(0xFFE53935),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red[700],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, size: 16, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              gym.rating.toStringAsFixed(1),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${gym.userRatingsTotal} reviews)',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const Spacer(),
                      if (gym.isOpen != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: gym.isOpen! ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            gym.isOpen! ? 'Open' : 'Closed',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 18, color: Colors.red[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          gym.address,
                          style: TextStyle(color: Colors.grey[700], fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.directions_walk, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        '${distance.toStringAsFixed(1)} km away',
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                      const SizedBox(width: 16),
                      if (gym.priceLevel > 0)
                        Text(
                          gym.priceDisplay,
                          style: TextStyle(color: Colors.green[700], fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openDirections(gym),
                          icon: Icon(Icons.directions, size: 16, color: Colors.red[700]),
                          label: Text('Directions', style: TextStyle(color: Colors.red[700])),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.red[700]!),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GymDetailsScreen(placeId: gym.placeId),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[700],
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text(
                            'View Details',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDirections(GymPlace gym) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=${gym.latitude},${gym.longitude}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class GymComparisonResultScreen extends StatelessWidget {
  final List<GymDetails> gyms;

  const GymComparisonResultScreen({Key? key, required this.gyms}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NutriLiftScaffold(
      title: 'Compare Gyms',
      showBackButton: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Comparison Table
            Table(
              border: TableBorder.all(color: Colors.grey[300]!),
              children: [
                // Header Row
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey[100]),
                  children: [
                    _buildTableHeader(''),
                    ...gyms.map((gym) => _buildTableHeader(gym.name, isGym: true)),
                  ],
                ),
                // Rating Row
                TableRow(
                  children: [
                    _buildTableCell('Rating', isLabel: true),
                    ...gyms.map((gym) => _buildTableCell('${gym.rating} ⭐')),
                  ],
                ),
                // Reviews Row
                TableRow(
                  children: [
                    _buildTableCell('Reviews', isLabel: true),
                    ...gyms.map((gym) => _buildTableCell('${gym.userRatingsTotal}')),
                  ],
                ),
                // Price Row
                TableRow(
                  children: [
                    _buildTableCell('Price', isLabel: true),
                    ...gyms.map((gym) => _buildTableCell(gym.priceDisplay)),
                  ],
                ),
                // Status Row
                TableRow(
                  children: [
                    _buildTableCell('Status', isLabel: true),
                    ...gyms.map((gym) => _buildTableCell(
                          gym.isOpen == true ? 'Open' : gym.isOpen == false ? 'Closed' : 'Unknown',
                          color: gym.isOpen == true ? Colors.green : Colors.red,
                        )),
                  ],
                ),
                // Phone Row
                TableRow(
                  children: [
                    _buildTableCell('Phone', isLabel: true),
                    ...gyms.map((gym) => _buildTableCell(gym.phone ?? 'N/A')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Individual Gym Cards
            ...gyms.map((gym) => Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gym.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _call(gym.phone),
                                icon: const Icon(Icons.phone, size: 18),
                                label: const Text('Call'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _openDirections(gym),
                                icon: const Icon(Icons.directions, size: 18),
                                label: const Text('Directions'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE53935),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(String text, {bool isGym = false}) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: isGym ? 14 : 16,
        ),
        textAlign: isGym ? TextAlign.center : TextAlign.left,
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isLabel = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isLabel ? FontWeight.bold : FontWeight.normal,
          color: color ?? (isLabel ? Colors.black87 : Colors.black54),
        ),
        textAlign: isLabel ? TextAlign.left : TextAlign.center,
      ),
    );
  }

  Future<void> _call(String? phone) async {
    if (phone == null) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openDirections(GymDetails gym) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=${gym.latitude},${gym.longitude}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
