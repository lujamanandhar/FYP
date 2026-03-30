import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class AreaSelectorMap extends StatefulWidget {
  final Position? currentPosition;

  const AreaSelectorMap({Key? key, this.currentPosition}) : super(key: key);

  @override
  State<AreaSelectorMap> createState() => _AreaSelectorMapState();
}

class _AreaSelectorMapState extends State<AreaSelectorMap> {
  GoogleMapController? _mapController;
  LatLng? _selectedCenter;
  double _radiusInMeters = 2000; // Default 2km
  Set<Circle> _circles = {};
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    // Initialize with current position or default to Kathmandu
    if (widget.currentPosition != null) {
      _selectedCenter = LatLng(
        widget.currentPosition!.latitude,
        widget.currentPosition!.longitude,
      );
    } else {
      // Default to Kathmandu, Nepal
      _selectedCenter = const LatLng(27.7172, 85.3240);
    }
    _updateCircle();
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _selectedCenter = position;
      _updateCircle();
    });
  }

  void _updateCircle() {
    if (_selectedCenter == null) return;

    setState(() {
      _circles = {
        Circle(
          circleId: const CircleId('search_area'),
          center: _selectedCenter!,
          radius: _radiusInMeters,
          fillColor: const Color(0xFFE53935).withOpacity(0.2),
          strokeColor: const Color(0xFFE53935),
          strokeWidth: 2,
        ),
      };

      _markers = {
        Marker(
          markerId: const MarkerId('center'),
          position: _selectedCenter!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Search Center',
            snippet: 'Radius: ${(_radiusInMeters / 1000).toStringAsFixed(1)} km',
          ),
        ),
      };
    });
  }

  void _confirmSelection() {
    if (_selectedCenter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an area on the map')),
      );
      return;
    }

    Navigator.pop(context, {
      'latitude': _selectedCenter!.latitude,
      'longitude': _selectedCenter!.longitude,
      'radius': _radiusInMeters.toInt(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final initialPosition = widget.currentPosition != null
        ? LatLng(widget.currentPosition!.latitude, widget.currentPosition!.longitude)
        : const LatLng(27.7172, 85.3240);

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
            label: const Text(
              'Confirm',
              style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialPosition,
              zoom: 13,
            ),
            circles: _circles,
            markers: _markers,
            onTap: _onMapTap,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            mapType: MapType.normal,
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),
          
          // Instructions Card
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Color(0xFFE53935)),
                        const SizedBox(width: 8),
                        const Text(
                          'Select Search Area',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap anywhere on the map to set your search center',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Radius Slider
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Search Radius',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${(_radiusInMeters / 1000).toStringAsFixed(1)} km',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _radiusInMeters,
                      min: 500,
                      max: 10000,
                      divisions: 19,
                      activeColor: const Color(0xFFE53935),
                      label: '${(_radiusInMeters / 1000).toStringAsFixed(1)} km',
                      onChanged: (value) {
                        setState(() {
                          _radiusInMeters = value;
                          _updateCircle();
                        });
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('0.5 km', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        Text('10 km', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
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

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
