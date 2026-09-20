import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/car.dart';
import '../services/car_service.dart';
import 'add_edit_car_screen.dart';

class CarDetailsScreen extends StatelessWidget {
  final String carId;

  const CarDetailsScreen({super.key, required this.carId});

  Future<void> _confirmDelete(BuildContext context, Car car) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Car'),
        content: Text(
          'Are you sure you want to remove ${car.brand} ${car.model} '
              '(${car.licensePlate}) from the system?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<CarService>().removeCar(car.id);
      Navigator.pop(context); // back to home screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${car.brand} ${car.model} removed.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final carService = context.watch<CarService>();

    // If the car was deleted while this screen is open, pop back safely.
    Car? car;
    try {
      car = carService.getById(carId);
    } catch (_) {
      car = null;
    }

    if (car == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Car Details')),
        body: const Center(child: Text('This car no longer exists.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${car.brand} ${car.model}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _statusBanner(car),
          const SizedBox(height: 16),
          _infoTile(Icons.confirmation_number, 'License Plate', car.licensePlate),
          _infoTile(Icons.directions_car, 'Brand', car.brand),
          _infoTile(Icons.car_repair, 'Model', car.model),
          _infoTile(Icons.calendar_today, 'Year', car.year.toString()),
          _infoTile(
            Icons.attach_money,
            'Price per day',
            '\$${car.pricePerDay.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 12),
          const Text(
            'Description',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            car.description.isEmpty ? 'No description provided.' : car.description,
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditCarScreen(car: car),
                ),
              );
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit Car'),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: car.available ? Colors.orange : Colors.green,
            ),
            onPressed: () {
              context.read<CarService>().toggleAvailability(car!.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    car.available
                        ? '${car.brand} ${car.model} marked as rented.'
                        : '${car.brand} ${car.model} marked as available.',
                  ),
                ),
              );
            },
            icon: Icon(car.available ? Icons.key : Icons.key_off),
            label: Text(car.available ? 'Mark as Rented' : 'Mark as Available'),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _confirmDelete(context, car!);
            },
            icon: const Icon(Icons.delete),
            label: const Text('Remove Car'),
          ),
        ],
      ),
    );
  }

  Widget _statusBanner(Car car) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: car.available ? Colors.green.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        car.available ? 'AVAILABLE' : 'CURRENTLY RENTED',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: car.available ? Colors.green.shade800 : Colors.red.shade800,
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.indigo),
      title: Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontSize: 16)),
    );
  }
}