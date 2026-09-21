import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/car_service.dart';
import '../services/auth_service.dart';
import '../widgets/car_list_item.dart';
import 'car_details_screen.dart';
import 'add_edit_car_screen.dart';

enum CarFilter { all, available, rented, myCars }

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
    final currentUser = authService.currentUser!;
    final isOwner = currentUser.isOwner;

    final List<dynamic> cars = switch (_selectedFilter) {
      CarFilter.all => carService.cars,
      CarFilter.available => carService.availableCars,
      CarFilter.rented => carService.rentedCars,
      CarFilter.myCars => carService.carsByOwner(currentUser.uid),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Cars'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => context.read<AuthService>().logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<CarFilter>(
                segments: [
                  const ButtonSegment(
                    value: CarFilter.all,
                    label: Text('All'),
                    icon: Icon(Icons.list),
                  ),
                  const ButtonSegment(
                    value: CarFilter.available,
                    label: Text('Available'),
                    icon: Icon(Icons.check_circle_outline),
                  ),
                  const ButtonSegment(
                    value: CarFilter.rented,
                    label: Text('Rented'),
                    icon: Icon(Icons.block),
                  ),
                  if (isOwner)
                    const ButtonSegment(
                      value: CarFilter.myCars,
                      label: Text('My Cars'),
                      icon: Icon(Icons.person),
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
                ? Center(child: Text(_emptyMessage()))
                : ListView.builder(
              itemCount: cars.length,
              itemBuilder: (context, index) {
                final car = cars[index];
                return CarListItem(
                  car: car,
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
          ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddEditCarScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      )
          : null,
    );
  }

  String _emptyMessage() {
    switch (_selectedFilter) {
      case CarFilter.all:
        return 'No cars available yet.';
      case CarFilter.available:
        return 'No cars are currently available.';
      case CarFilter.rented:
        return 'No cars are currently rented.';
      case CarFilter.myCars:
        return "You haven't listed any cars yet. Tap + to add one.";
    }
  }
}