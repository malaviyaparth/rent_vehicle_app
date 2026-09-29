import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/car.dart';
import '../services/car_service.dart';
import '../services/auth_service.dart';
import '../services/rental_service.dart';
import '../services/location_service.dart';
import '../utils/distance_utils.dart';
import '../widgets/car_list_item.dart';
import 'car_details_screen.dart';
import 'add_edit_car_screen.dart';
import 'my_rental_history_screen.dart';
import 'nearby_vehicles_screen.dart';
import 'admin_dashboard_screen.dart';
import 'profile_screen.dart';

enum CarFilter { all, available, rented }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CarFilter _selectedFilter = CarFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthService>();
      if (auth.currentUser?.isOwner != true) {
        context.read<LocationService>().getCurrentPosition();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final carService = context.watch<CarService>();
    final authService = context.watch<AuthService>();
    final rentalService = context.watch<RentalService>();
    final locationService = context.watch<LocationService>();
    final currentUser = authService.currentUser!;
    final isOwner = currentUser.isOwner;
    final isAdmin = currentUser.isAdmin;

    final rentedIds = rentalService.currentlyRentedCarIds;
    // An owner ONLY sees their own added vehicles (UNCHANGED on owner side).
    // A borrower ONLY sees vehicles within a 50 km radius!
    final List<Car> poolOfCars;
    final Map<String, double?> carDistances = {};

    if (isOwner) {
      poolOfCars = carService.carsByOwner(currentUser.uid);
    } else {
      if (locationService.hasLocation) {
        final uLat = locationService.latitude!;
        final uLng = locationService.longitude!;
        final List<MapEntry<Car, double>> nearbyList = [];

        for (final car in carService.cars) {
          if (car.hasPickupLocation) {
            final dist = calculateDistanceKm(
              uLat,
              uLng,
              car.pickupLatitude!,
              car.pickupLongitude!,
            );
            if (dist <= 50.0) {
              nearbyList.add(MapEntry(car, dist));
              carDistances[car.id] = dist;
            }
          }
        }
        nearbyList.sort((a, b) => a.value.compareTo(b.value));
        poolOfCars = nearbyList.map((e) => e.key).toList();
      } else {
        poolOfCars = carService.cars;
      }
    }

    final List<Car> baseCars = switch (_selectedFilter) {
      CarFilter.all => poolOfCars,
      CarFilter.available => poolOfCars.where((c) => c.available && !rentedIds.contains(c.id)).toList(),
      CarFilter.rented => poolOfCars.where((c) => !c.available || rentedIds.contains(c.id)).toList(),
    };
    final List<Car> cars = baseCars.map((c) {
      final isRented = !c.available || rentedIds.contains(c.id);
      return isRented && c.available ? c.copyWith(available: false) : c;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(isOwner ? 'My Vehicles' : 'Rental Vehicles'),
        actions: [
          if (!isOwner)
            IconButton(
              icon: const Icon(Icons.near_me),
              tooltip: 'Nearby Vehicles',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NearbyVehiclesScreen()),
                );
              },
            ),
          if (!isOwner)
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'My Rental History',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyRentalHistoryScreen()),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: 'My Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Admin Dashboard',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => context.read<AuthService>().logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Owner Fleet Status Dashboard ──
          if (isOwner)
            Container(
              margin: const EdgeInsets.fromLTRB(14, 12, 14, 4),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Fleet Overview',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '${poolOfCars.length} vehicles registered',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          'Total',
                          '${poolOfCars.length}',
                          const Color(0xFF2563EB),
                          const Color(0xFFEFF6FF),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricTile(
                          'Available',
                          '${poolOfCars.where((c) => c.available && !rentedIds.contains(c.id)).length}',
                          const Color(0xFF059669),
                          const Color(0xFFECFDF5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricTile(
                          'Rented',
                          '${poolOfCars.where((c) => !c.available || rentedIds.contains(c.id)).length}',
                          const Color(0xFFE11D48),
                          const Color(0xFFFFF1F2),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // ── Borrower GPS 50km Status Banner ──
          if (!isOwner) ...[
            if (locationService.isLoading)
              Container(
                margin: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Detecting your location to show vehicles within 50 km...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1D4ED8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (!locationService.hasLocation)
              Container(
                margin: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_searching, size: 20, color: Color(0xFFD97706)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        locationService.errorMessage ??
                            'Enable GPS to view vehicles strictly within 50 km radius.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF92400E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: const Color(0xFFD97706),
                      ),
                      onPressed: () => locationService.getCurrentPosition(),
                      child: const Text('DETECT GPS', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              )
            else
              Container(
                margin: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.near_me, size: 18, color: Color(0xFF2563EB)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Showing vehicles within 50 km radius (${poolOfCars.length} available nearby)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],

          // ── Filter Segment Bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<CarFilter>(
                segments: const [
                  ButtonSegment(
                    value: CarFilter.all,
                    label: Text('All'),
                    icon: Icon(Icons.grid_view, size: 16),
                  ),
                  ButtonSegment(
                    value: CarFilter.available,
                    label: Text('Available'),
                    icon: Icon(Icons.check_circle_outline, size: 16),
                  ),
                  ButtonSegment(
                    value: CarFilter.rented,
                    label: Text('Rented'),
                    icon: Icon(Icons.lock_clock, size: 16),
                  ),
                ],
                selected: {_selectedFilter},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _selectedFilter = newSelection.first;
                  });
                },
              ),
            ),
          ),

          // ── Vehicles List ──
          Expanded(
            child: carService.isLoading
                ? const Center(child: CircularProgressIndicator())
                : cars.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isOwner ? Icons.car_rental : Icons.directions_car_outlined,
                                  size: 48,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _emptyTitle(isOwner),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _emptyMessage(isOwner, locationService.hasLocation),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 4, bottom: 20),
                        itemCount: cars.length,
                        itemBuilder: (context, index) {
                          final car = cars[index];
                          final isRented = !car.available || rentedIds.contains(car.id);
                          final isCarOwner = isOwner && car.ownerId == currentUser.uid;
                          final activeRental = (isCarOwner && (isRented || _selectedFilter == CarFilter.rented))
                              ? rentalService.activeRentalForCar(car.id)
                              : null;

                          return CarListItem(
                            car: car,
                            activeRental: activeRental,
                            showBorrowerDetails: isCarOwner,
                            distanceKm: carDistances[car.id],
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CarDetailsScreen(carId: car.id),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: isOwner
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddEditCarScreen(),
                  ),
                );
              },
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Vehicle', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _buildMetricTile(String label, String value, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  String _emptyTitle(bool isOwner) {
    if (isOwner) return 'No Fleet Vehicles Found';
    return 'No Vehicles In Range';
  }

  String _emptyMessage(bool isOwner, bool hasLocation) {
    if (isOwner) {
      switch (_selectedFilter) {
        case CarFilter.all:
          return "You haven't listed any vehicles yet.\nTap '+ Add Vehicle' below to start renting.";
        case CarFilter.available:
          return 'All of your listed vehicles are currently booked or inactive.';
        case CarFilter.rented:
          return 'None of your listed vehicles are rented right now.';
      }
    }
    if (hasLocation) {
      switch (_selectedFilter) {
        case CarFilter.all:
          return 'No vehicles are located within 50 km of your position.';
        case CarFilter.available:
          return 'No available vehicles found within 50 km.';
        case CarFilter.rented:
          return 'No currently rented vehicles within 50 km.';
      }
    }
    switch (_selectedFilter) {
      case CarFilter.all:
        return 'No vehicles available yet in the system.';
      case CarFilter.available:
        return 'No vehicles are currently available.';
      case CarFilter.rented:
        return 'No vehicles are currently rented.';
    }
  }
}