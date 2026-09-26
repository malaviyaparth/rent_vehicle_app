import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/car.dart';
import '../services/car_service.dart';
import '../services/auth_service.dart';
import '../services/rental_service.dart';
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
  Widget build(BuildContext context) {
    final carService = context.watch<CarService>();
    final authService = context.watch<AuthService>();
    final rentalService = context.watch<RentalService>();
    final currentUser = authService.currentUser!;
    final isOwner = currentUser.isOwner;
    final isAdmin = currentUser.isAdmin;

    final rentedIds = rentalService.currentlyRentedCarIds;
    // An owner ONLY sees their own added vehicles and their statuses!
    final List<Car> poolOfCars = isOwner ? carService.carsByOwner(currentUser.uid) : carService.cars;

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
          if (isOwner)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 10, 12, 2),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.directions_car, size: 18, color: Colors.teal.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your Listed Fleet: ${poolOfCars.length} total • ${poolOfCars.where((c) => c.available && !rentedIds.contains(c.id)).length} Available • ${poolOfCars.where((c) => !c.available || rentedIds.contains(c.id)).length} Rented',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<CarFilter>(
                segments: const [
                  ButtonSegment(
                    value: CarFilter.all,
                    label: Text('All'),
                    icon: Icon(Icons.list),
                  ),
                  ButtonSegment(
                    value: CarFilter.available,
                    label: Text('Available'),
                    icon: Icon(Icons.check_circle_outline),
                  ),
                  ButtonSegment(
                    value: CarFilter.rented,
                    label: Text('Rented'),
                    icon: Icon(Icons.block),
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
          Expanded(
            child: carService.isLoading
                ? const Center(child: CircularProgressIndicator())
                : cars.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _emptyMessage(isOwner),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 15, color: Colors.grey),
                          ),
                        ),
                      )
                    : ListView.builder(
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
              icon: const Icon(Icons.add),
              label: const Text('Add Vehicle'),
            )
          : null,
    );
  }

  String _emptyMessage(bool isOwner) {
    if (isOwner) {
      switch (_selectedFilter) {
        case CarFilter.all:
          return "You haven't added any vehicles yet.\nTap '+ Add Vehicle' below to list your first car.";
        case CarFilter.available:
          return 'None of your vehicles are currently available.';
        case CarFilter.rented:
          return 'None of your vehicles are currently rented.';
      }
    }
    switch (_selectedFilter) {
      case CarFilter.all:
        return 'No vehicles available yet.';
      case CarFilter.available:
        return 'No vehicles are currently available.';
      case CarFilter.rented:
        return 'No vehicles are currently rented.';
    }
  }
}