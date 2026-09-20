import 'package:flutter/material.dart';
import '../models/car.dart';

class CarListItem extends StatelessWidget {
  final Car car;
  final VoidCallback onTap;

  const CarListItem({
    super.key,
    required this.car,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: car.available ? Colors.green : Colors.red,
          child: Icon(
            car.available ? Icons.check : Icons.block,
            color: Colors.white,
          ),
        ),
        title: Text('${car.brand} ${car.model} (${car.year})'),
        subtitle: Text(
          '${car.licensePlate} • \$${car.pricePerDay.toStringAsFixed(2)}/day',
        ),
        trailing: Text(
          car.available ? 'Available' : 'Rented',
          style: TextStyle(
            color: car.available ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}