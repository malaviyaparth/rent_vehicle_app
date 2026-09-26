import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../models/car.dart';
import '../models/vehicle_filter_model.dart';
import '../services/car_service.dart';
import '../services/location_service.dart';
import '../services/rental_service.dart';
import '../widgets/nearby_vehicle_card.dart';
import '../widgets/vehicle_filter_sheet.dart';
import 'car_details_screen.dart';

/// Screen for discovering nearby vehicles with advanced filtering,
/// search, and both List and interactive Google Map views.
class NearbyVehiclesScreen extends StatefulWidget {
  const NearbyVehiclesScreen({super.key});

  @override
  State<NearbyVehiclesScreen> createState() => _NearbyVehiclesScreenState();
}

class _NearbyVehiclesScreenState extends State<NearbyVehiclesScreen> {
  final VehicleFilter _filter = VehicleFilter();
  final TextEditingController _searchController = TextEditingController();
  bool _locationRequested = false;
  bool _isMapView = false;
  GoogleMapController? _mapController;
  Car? _selectedMapCar;
  double? _selectedMapCarDistance;

  // Default fallback center (Ahmedabad, India)
  static const _defaultCenter = LatLng(23.0225, 72.5714);

  @override
  void initState() {
    super.initState();
    // Request location when this screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestLocation();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _requestLocation() async {
    setState(() => _locationRequested = true);
    await context.read<LocationService>().getCurrentPosition();
  }

  void _openFilters() async {
    final result = await showVehicleFilterSheet(
      context,
      currentFilter: _filter,
    );
    if (result != null && mounted) {
      setState(() {
        _filter.radiusKm = result.radiusKm;
        _filter.vehicleCategory = result.vehicleCategory;
        _filter.carSubType = result.carSubType;
        _filter.fuelType = result.fuelType;
        _filter.minPrice = result.minPrice;
        _filter.maxPrice = result.maxPrice;
        _filter.availableOnly = result.availableOnly;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _filter.reset();
      _searchController.clear();
      _selectedMapCar = null;
    });
  }

  bool get _isMapSupported {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  void _goToUserLocation(LocationService locationService) async {
    final pos = await locationService.getCurrentPosition();
    if (pos != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(pos.latitude, pos.longitude),
            zoom: 14,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final carService = context.watch<CarService>();
    final locationService = context.watch<LocationService>();
    final rentalService = context.watch<RentalService>();

    // Update search query in the filter.
    _filter.searchQuery = _searchController.text;

    // Get filtered results.
    final results = carService.filterCars(
      _filter,
      userLat: locationService.latitude,
      userLng: locationService.longitude,
      rentedCarIds: rentalService.currentlyRentedCarIds,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Vehicles'),
        actions: [
          IconButton(
            icon: Icon(_isMapView ? Icons.view_list : Icons.map_outlined),
            tooltip: _isMapView ? 'Show List View' : 'Show Map View',
            onPressed: () {
              setState(() {
                _isMapView = !_isMapView;
              });
            },
          ),
          Badge(
            isLabelVisible: _filter.hasActiveFilters,
            child: IconButton(
              icon: const Icon(Icons.filter_list),
              tooltip: 'Filters',
              onPressed: _openFilters,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar + radius indicator ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by brand or model...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // ── Location status + active filters ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: locationService.hasLocation
                      ? Colors.green
                      : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  locationService.hasLocation
                      ? 'Within ${_filter.radiusKm.toInt()} km'
                      : locationService.isLoading
                          ? 'Getting location...'
                          : 'Location unavailable',
                  style: TextStyle(
                    fontSize: 13,
                    color: locationService.hasLocation
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                  ),
                ),
                const Spacer(),
                if (_filter.hasActiveFilters || _searchController.text.isNotEmpty)
                  TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Clear', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
          ),

          // ── Active filter chips ──
          if (_filter.hasActiveFilters)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: _buildFilterChips(),
              ),
            ),

          // ── Location error message ──
          if (!locationService.hasLocation &&
              !locationService.isLoading &&
              locationService.errorMessage != null &&
              _locationRequested)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          locationService.errorMessage!,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      TextButton(
                        onPressed: _requestLocation,
                        child: const Text('Retry', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Main Content Area: Map View or List View ──
          Expanded(
            child: _isMapView
                ? _buildMapView(results, locationService)
                : _buildListView(carService, results),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(CarService carService, List<MapEntry<Car, double?>> results) {
    if (carService.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (results.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final entry = results[index];
        return NearbyVehicleCard(
          car: entry.key,
          distanceKm: entry.value,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CarDetailsScreen(carId: entry.key.id),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMapView(
    List<MapEntry<Car, double?>> results,
    LocationService locationService,
  ) {
    if (!_isMapSupported) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 12),
              const Text(
                'Interactive Map View',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Interactive Google Maps view is available on Android, iOS, and Web platforms.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => setState(() => _isMapView = false),
                icon: const Icon(Icons.view_list),
                label: const Text('Switch to List View'),
              ),
            ],
          ),
        ),
      );
    }

    final initialTarget = locationService.hasLocation
        ? LatLng(locationService.latitude!, locationService.longitude!)
        : (results.isNotEmpty && results.first.key.hasPickupLocation
            ? LatLng(results.first.key.pickupLatitude!, results.first.key.pickupLongitude!)
            : _defaultCenter);

    final markers = <Marker>{};
    for (final entry in results) {
      final car = entry.key;
      final dist = entry.value;
      if (car.hasPickupLocation) {
        markers.add(
          Marker(
            markerId: MarkerId(car.id),
            position: LatLng(car.pickupLatitude!, car.pickupLongitude!),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              car.available ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueOrange,
            ),
            infoWindow: InfoWindow(
              title: '${car.brand} ${car.model}',
              snippet: '₹${car.pricePerDay.toStringAsFixed(0)}/day • ${car.available ? 'Available' : 'Rented'}',
            ),
            onTap: () {
              setState(() {
                _selectedMapCar = car;
                _selectedMapCarDistance = dist;
              });
            },
          ),
        );
      }
    }

    final circles = <Circle>{};
    if (locationService.hasLocation) {
      circles.add(
        Circle(
          circleId: const CircleId('search_radius'),
          center: LatLng(locationService.latitude!, locationService.longitude!),
          radius: _filter.radiusKm * 1000,
          fillColor: Colors.indigo.withValues(alpha: 0.08),
          strokeColor: Colors.indigo.withValues(alpha: 0.4),
          strokeWidth: 2,
        ),
      );
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: initialTarget,
            zoom: 13,
          ),
          onMapCreated: (controller) => _mapController = controller,
          myLocationEnabled: locationService.hasLocation,
          myLocationButtonEnabled: false,
          markers: markers,
          circles: circles,
          onTap: (_) {
            if (_selectedMapCar != null) {
              setState(() => _selectedMapCar = null);
            }
          },
        ),

        // Vehicles count badge
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.directions_car, size: 16, color: Colors.indigo),
                const SizedBox(width: 6),
                Text(
                  '${markers.length} on map',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
          ),
        ),

        // My location floating action button
        Positioned(
          top: 12,
          right: 12,
          child: FloatingActionButton.small(
            heroTag: 'nearby_my_loc',
            backgroundColor: Colors.white,
            foregroundColor: Colors.indigo,
            onPressed: () => _goToUserLocation(locationService),
            child: const Icon(Icons.my_location),
          ),
        ),

        // Empty state overlay if no cars
        if (results.isEmpty)
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'No vehicles found in this area',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Try increasing your search radius or changing filters.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _clearFilters,
                      child: const Text('Reset Filters'),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Floating selected car card
        if (_selectedMapCar != null)
          Positioned(
            left: 8,
            right: 8,
            bottom: 12,
            child: Stack(
              children: [
                NearbyVehicleCard(
                  car: _selectedMapCar!,
                  distanceKm: _selectedMapCarDistance,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CarDetailsScreen(carId: _selectedMapCar!.id),
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 10,
                  right: 18,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => setState(() => _selectedMapCar = null),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close, size: 16, color: Colors.black54),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  List<Widget> _buildFilterChips() {
    final chips = <Widget>[];

    if (_filter.vehicleCategory != null) {
      chips.add(Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Chip(
          label: Text(_filter.vehicleCategory!),
          onDeleted: () => setState(() {
            _filter.vehicleCategory = null;
            _filter.carSubType = null;
          }),
          visualDensity: VisualDensity.compact,
        ),
      ));
    }

    if (_filter.carSubType != null) {
      chips.add(Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Chip(
          label: Text(_filter.carSubType!),
          onDeleted: () => setState(() => _filter.carSubType = null),
          visualDensity: VisualDensity.compact,
        ),
      ));
    }

    if (_filter.fuelType != null) {
      chips.add(Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Chip(
          label: Text(_filter.fuelType!),
          onDeleted: () => setState(() => _filter.fuelType = null),
          visualDensity: VisualDensity.compact,
        ),
      ));
    }

    if (_filter.minPrice != null || _filter.maxPrice != null) {
      final min = _filter.minPrice?.round() ?? 0;
      final max = _filter.maxPrice?.round();
      chips.add(Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Chip(
          label: Text(max != null ? '₹$min–₹$max' : '₹$min+'),
          onDeleted: () => setState(() {
            _filter.minPrice = null;
            _filter.maxPrice = null;
          }),
          visualDensity: VisualDensity.compact,
        ),
      ));
    }

    if (_filter.radiusKm != 5) {
      chips.add(Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Chip(
          label: Text('${_filter.radiusKm.toInt()} km'),
          onDeleted: () => setState(() => _filter.radiusKm = 5),
          visualDensity: VisualDensity.compact,
        ),
      ));
    }

    return chips;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No vehicles found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Try:\n'
              '• Increasing the search radius\n'
              '• Removing some filters\n'
              '• Increasing your price range',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear Filters'),
            ),
          ],
        ),
      ),
    );
  }
}
