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

    final Map<String, List<RentalRecord>> grouped = {};
    for (final rental in rentals) {
      grouped.putIfAbsent(rental.carId, () => []).add(rental);
    }

    final carIds = grouped.keys.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Rental Bookings (My Vehicles)')),
      body: rentalService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : rentals.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'None of your vehicles have any bookings yet.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                )
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
                        initiallyExpanded: index == 0,
                        leading: const Icon(Icons.directions_car, color: Colors.indigo),
                        title: Text(
                          '${sample.carBrand} ${sample.carModel}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${sample.licensePlate} • ${carRentals.length} booking(s)',
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
    final rentalService = context.read<RentalService>();

    Color statusColor = Colors.grey;
    if (rental.isConfirmed) statusColor = Colors.green;
    if (rental.isPending) statusColor = Colors.orange;
    if (rental.isCancelled) statusColor = Colors.red;

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.person, size: 18, color: Colors.indigo),
                  const SizedBox(width: 6),
                  Text(
                    rental.userName.isEmpty ? 'Customer' : rental.userName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  rental.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${dateFormat.format(rental.startDate)} → ${dateFormat.format(rental.endDate)} '
            '(${rental.days} days)',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 4),
          Text(
            'Total Earned: ₹${rental.totalPrice.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigo),
          ),
          if (rental.isPending) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => rentalService.rejectRental(rental.id, rental.carId),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => rentalService.acceptRental(rental.id),
                  child: const Text('Accept Booking'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}