import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/car_service.dart';
import '../widgets/car_list_item.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final carService = context.watch<CarService>();
    final cars = carService.cars;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Cars'),
      ),
      body: cars.isEmpty
          ? const Center(child: Text('No cars available yet.'))
          : ListView.builder(
        itemCount: cars.length,
        itemBuilder: (context, index) {
          final car = cars[index];
          return CarListItem(
            car: car,
            onTap: () {
              // Details screen will be added in the next step
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add car screen will be added in a later step
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}