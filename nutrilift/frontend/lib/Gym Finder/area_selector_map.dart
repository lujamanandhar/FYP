import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

/// Area selector map — user taps to set center, adjusts radius slider, confirms.
/// Returns: { 'latitude': double, 'longitude': double, 'radius': int }
class AreaSelectorMap extends StatefulWidget {
  final Position? currentPosition;
  const AreaSelectorMap({Key? key, this.currentPosition}) : super(key: key);

  @override
  State<AreaSelectorMap> createState() => _AreaSelectorMapState();
}

class _AreaSelectorMapState extends State<AreaSelectorMap> {
  late final MapController _mapController;
  LatLng? _selectedCenter;
  double _radiusInMeters = 2000;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    // Start at user's current location or default to Kathmandu
    _selectedCenter = widget.currentPosition != null
        ? LatLng(widget.currentPosition!.latitude, widget.currentPosition!.longitude)
        : const LatLng(27.7172, 85.3240);
  }

  void _confirmSelection() {
    if (_selectedCenter == null) return;
    Navigator.pop(context, {
      'latitude': _selectedCenter!.latitude,
      'longitude': _selectedCenter!.longitude,
      'radius': _radiusInMeters.toInt(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final center = _selectedCenter ?? const LatLng(27.7172, 85.3240);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Search Area'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 2,
        actions: [
          TextButton.icon(
            onPressed: _confirmSelection,
            icon: const Icon(Icons.check, color: Color(0xFFE53935)),
            label: const Text('Find Gyms',
                style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 13,
              onTap: (_, point) {
                setState(() => _selectedCenter = point);
                _mapController.move(point, _mapController.camera.zoom);
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
                // Fallback tile color when tiles fail to load
                tileBuilder: (context, tileWidget, tile) => tileWidget,
              ),
              // Search radius circle
              if (_selectedCenter != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _selectedCenter!,
                      radius: _radiusInMeters,
                      useRadiusInMeter: true,
                      color: const Color(0xFFE53935).withOpacity(0.15),
                      borderColor: const Color(0xFFE53935),
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
              // Center pin marker
              if (_selectedCenter != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedCenter!,
                      width: 48,
                      height: 48,
                      child: const Icon(
                        Icons.location_pin,
                        color: Color(0xFFE53935),
                        size: 44,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // ── Instruction card ─────────────────────────────────────────
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.touch_app, color: Color(0xFFE53935), size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tap anywhere on the map to set your search center',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── My location button ────────────────────────────────────────
          if (widget.currentPosition != null)
            Positioned(
              top: 80,
              right: 16,
              child: FloatingActionButton.small(
                heroTag: 'my_location',
                onPressed: () {
                  final pos = LatLng(
                    widget.currentPosition!.latitude,
                    widget.currentPosition!.longitude,
                  );
                  setState(() => _selectedCenter = pos);
                  _mapController.move(pos, 14);
                },
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
                child: const Icon(Icons.my_location),
              ),
            ),

          // ── Radius slider card ────────────────────────────────────────
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Search Radius',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${(_radiusInMeters / 1000).toStringAsFixed(1)} km',
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _radiusInMeters,
                      min: 500,
                      max: 10000,
                      divisions: 19,
                      activeColor: const Color(0xFFE53935),
                      label: '${(_radiusInMeters / 1000).toStringAsFixed(1)} km',
                      onChanged: (v) => setState(() => _radiusInMeters = v),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('0.5 km', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                        Text('10 km', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _confirmSelection,
                        icon: const Icon(Icons.search),
                        label: const Text('Find Gyms in This Area',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
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
