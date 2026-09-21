import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/rental_record.dart';
import '../services/auth_service.dart';
import '../services/rental_service.dart';

class OwnerRentalHistoryScreen extends StatelessWidget {
  const OwnerRentalHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rentalService = context.watch<RentalService>();
    final authService = context.watch<AuthService>();
    final currentUser = authService.currentUser!;

    final rentals = rentalService.rentalsByOwner(currentUser.uid);

    // Group rentals by carId, preserving most-recent-first order within each group.
    final Map<String, List<RentalRecord>> grouped = {};
    for (final rental in rentals) {
      grouped.putIfAbsent(rental.carId, () => []).add(rental);
    }

    final carIds = grouped.keys.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Rental History (My Cars)')),
      body: rentalService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : rentals.isEmpty
          ? const Center(child: Text('None of your cars have been rented yet.'))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: carIds.length,
        itemBuilder: (context, index) {
          final carId = carIds[index];
          final carRentals = grouped[carId]!;
          final sample = carRentals.first;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ExpansionTile(
              title: Text(
                '${sample.carBrand} ${sample.carModel}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${sample.licensePlate} • ${carRentals.length} rental(s)',
              ),
              children: carRentals
                  .map((rental) => _RenterTile(rental: rental))
                  .toList(),
            ),
          );
        },
      ),
    );
  }
}

class _RenterTile extends StatelessWidget {
  final RentalRecord rental;

  const _RenterTile({required this.rental});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: rental.isActive ? Colors.green : Colors.grey,
        child: const Icon(Icons.person, color: Colors.white, size: 20),
      ),
      title: Text(rental.userName.isEmpty ? 'Unknown user' : rental.userName),
      subtitle: Text(
        '${dateFormat.format(rental.startDate)} → ${dateFormat.format(rental.endDate)} '
            '(${rental.days} day(s))',
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '\$${rental.totalPrice.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            rental.isActive ? 'Active' : 'Completed',
            style: TextStyle(
              fontSize: 11,
              color: rental.isActive ? Colors.green.shade700 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}