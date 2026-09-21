import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/car_service.dart';
import '../widgets/car_list_item.dart';
import 'car_details_screen.dart';
import 'add_edit_car_screen.dart';

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

    final List<dynamic> cars = switch (_selectedFilter) {
      CarFilter.all => carService.cars,
      CarFilter.available => carService.availableCars,
      CarFilter.rented => carService.rentedCars,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome!'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
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
          Expanded(
            child: cars.isEmpty
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddEditCarScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text("Add Car"),
      ),
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
    }
  }
}