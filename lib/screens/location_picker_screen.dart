import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../services/location_service.dart';

/// Full-screen Google Map where the owner can tap to pick a vehicle
/// pickup location. Returns the selected coordinates via Navigator.pop().
///
/// On platforms where Google Maps is not supported (e.g. Windows desktop),
/// a manual lat/lng text-field fallback is shown.
class LocationPickerScreen extends StatefulWidget {
  /// If editing an existing location, pass it here to center the map.
  final Map<String, double>? initialLocation;

  const LocationPickerScreen({super.key, this.initialLocation});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng? _selectedLocation;
  GoogleMapController? _mapController;

  // Default center: Ahmedabad, India.
  static const _defaultCenter = LatLng(23.0225, 72.5714);

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _selectedLocation = LatLng(
        widget.initialLocation!['latitude']!,
        widget.initialLocation!['longitude']!,
      );
    }
  }

  LatLng get _initialCenter =>
      _selectedLocation ?? _defaultCenter;

  void _onMapTap(LatLng position) {
    setState(() {
      _selectedLocation = position;
    });
  }

  void _confirmLocation() {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tap on the map to select a location.')),
      );
      return;
    }
    Navigator.pop(context, {
      'latitude': _selectedLocation!.latitude,
      'longitude': _selectedLocation!.longitude,
    });
  }

  void _goToUserLocation() async {
    final locationService = context.read<LocationService>();
    final position = await locationService.getCurrentPosition();
    if (position != null && mounted) {
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() => _selectedLocation = latLng);
      _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
    } else if (mounted && locationService.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(locationService.errorMessage!)),
      );
    }
  }

  /// Returns true if the current platform supports Google Maps Flutter SDK.
  bool get _isMapSupported {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isMapSupported) {
      return _ManualLocationFallback(
        initialLocation: widget.initialLocation,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Pickup Location'),
        actions: [
          TextButton(
            onPressed: _confirmLocation,
            child: const Text('CONFIRM', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialCenter,
              zoom: 14,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onTap: _onMapTap,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            markers: _selectedLocation != null
                ? {
                    Marker(
                      markerId: const MarkerId('pickup'),
                      position: _selectedLocation!,
                      draggable: true,
                      onDragEnd: (newPosition) {
                        setState(() => _selectedLocation = newPosition);
                      },
                    ),
                  }
                : {},
          ),
          // Info bar at the bottom.
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedLocation != null
                          ? 'Lat: ${_selectedLocation!.latitude.toStringAsFixed(5)}, '
                            'Lng: ${_selectedLocation!.longitude.toStringAsFixed(5)}'
                          : 'Tap on the map to place the pickup pin',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToUserLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}

// ── Fallback for unsupported platforms (e.g. Windows desktop) ──

class _ManualLocationFallback extends StatefulWidget {
  final Map<String, double>? initialLocation;
  const _ManualLocationFallback({this.initialLocation});

  @override
  State<_ManualLocationFallback> createState() => _ManualLocationFallbackState();
}

class _ManualLocationFallbackState extends State<_ManualLocationFallback> {
  late TextEditingController _latController;
  late TextEditingController _lngController;

  @override
  void initState() {
    super.initState();
    _latController = TextEditingController(
      text: widget.initialLocation?['latitude']?.toString() ?? '',
    );
    _lngController = TextEditingController(
      text: widget.initialLocation?['longitude']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _confirm() {
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    if (lat == null || lng == null || lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid latitude (-90 to 90) and longitude (-180 to 180).')),
      );
      return;
    }
    Navigator.pop(context, {'latitude': lat, 'longitude': lng});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter Pickup Location')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.map, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'Google Maps is not available on this platform.\n'
              'Enter the coordinates manually.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _latController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: const InputDecoration(
                labelText: 'Latitude',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lngController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: const InputDecoration(
                labelText: 'Longitude',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _confirm,
              child: const Text('Confirm Location'),
            ),
          ],
        ),
      ),
    );
  }
}
