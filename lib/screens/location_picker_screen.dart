import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../services/location_service.dart';

/// Full-screen Google Map where the owner can tap to pick a vehicle
/// pickup location. Returns the selected coordinates via Navigator.pop().
///
/// Automatically confirms and returns the selected location upon tapping the map
/// or pressing the prominent confirmation button.
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

  LatLng get _initialCenter => _selectedLocation ?? _defaultCenter;

  void _onMapTap(LatLng position) {
    setState(() {
      _selectedLocation = position;
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLng(position),
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.indigo.shade800,
        content: Text(
          'Location chosen: ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}',
        ),
      ),
    );
  }

  void _confirmLocation() {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tap on the map to choose a pickup location.')),
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
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Centered to your current GPS position.')),
      );
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // If the owner selected a location, automatically register it on back
        if (_selectedLocation != null) {
          Navigator.pop(context, {
            'latitude': _selectedLocation!.latitude,
            'longitude': _selectedLocation!.longitude,
          });
        } else {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Select Pickup Location'),
          actions: [
            TextButton.icon(
              onPressed: _confirmLocation,
              icon: const Icon(Icons.check, color: Colors.green),
              label: const Text(
                'REGISTER',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
              ),
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
              zoomControlsEnabled: true,
              markers: _selectedLocation != null
                  ? {
                      Marker(
                        markerId: const MarkerId('pickup_pin'),
                        position: _selectedLocation!,
                        infoWindow: const InfoWindow(
                          title: 'Pickup Location',
                          snippet: 'Tap Confirm below to set this location',
                        ),
                        draggable: true,
                        onDragEnd: (newPosition) {
                          setState(() => _selectedLocation = newPosition);
                        },
                      ),
                    }
                  : {},
            ),

            // Top Guidance Pill
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 6),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.touch_app, color: Colors.amber, size: 18),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Tap anywhere on the map to set the pickup pin',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Confirmation Panel
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _selectedLocation != null ? Icons.location_on : Icons.location_off,
                            color: _selectedLocation != null ? Colors.green : Colors.grey,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedLocation != null
                                      ? 'Pickup Pin Placed'
                                      : 'No Location Selected',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _selectedLocation != null
                                      ? 'Lat: ${_selectedLocation!.latitude.toStringAsFixed(5)}, Lng: ${_selectedLocation!.longitude.toStringAsFixed(5)}'
                                      : 'Tap on the map to drop the pickup marker',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: _selectedLocation != null
                                ? Colors.green.shade700
                                : Colors.grey.shade400,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _selectedLocation != null ? _confirmLocation : null,
                          icon: const Icon(Icons.check_circle),
                          label: Text(
                            _selectedLocation != null
                                ? 'CONFIRM & REGISTER PICKUP LOCATION'
                                : 'TAP ON MAP TO SELECT',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 120),
          child: FloatingActionButton(
            heroTag: 'loc_picker_my_pos',
            onPressed: _goToUserLocation,
            backgroundColor: Colors.white,
            foregroundColor: Colors.indigo,
            tooltip: 'My Current Location',
            child: const Icon(Icons.my_location),
          ),
        ),
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
  bool _isDetecting = false;

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

  void _detectLocation() async {
    setState(() => _isDetecting = true);
    final locationService = context.read<LocationService>();
    final position = await locationService.getCurrentPosition();
    if (!mounted) return;
    setState(() => _isDetecting = false);

    if (position != null) {
      _latController.text = position.latitude.toStringAsFixed(5);
      _lngController.text = position.longitude.toStringAsFixed(5);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Detected current GPS coordinates!'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(locationService.errorMessage ?? 'Could not detect location.')),
      );
    }
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.location_on, size: 64, color: Colors.indigo),
            const SizedBox(height: 12),
            const Text(
              'Set the pickup location for your vehicle.\n'
              'Click "Detect GPS" or enter coordinates below.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _isDetecting ? null : _detectLocation,
              icon: _isDetecting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location),
              label: Text(_isDetecting ? 'Detecting GPS...' : 'Detect My Current GPS Location'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _latController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: const InputDecoration(
                labelText: 'Latitude (e.g. 23.0225)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lngController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: const InputDecoration(
                labelText: 'Longitude (e.g. 72.5714)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _confirm,
              icon: const Icon(Icons.check_circle),
              label: const Text('CONFIRM & REGISTER LOCATION', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
