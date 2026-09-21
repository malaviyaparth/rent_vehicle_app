import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/rental_record.dart';
import '../services/auth_service.dart';
import '../services/rental_service.dart';

class MyRentalHistoryScreen extends StatelessWidget {
  const MyRentalHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rentalService = context.watch<RentalService>();
    final authService = context.watch<AuthService>();
    final currentUser = authService.currentUser!;

    final rentals = rentalService.rentalsByUser(currentUser.uid);

    return Scaffold(
      appBar: AppBar(title: const Text('My Rental History')),
      body: rentalService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : rentals.isEmpty
          ? const Center(child: Text("You haven't rented any cars yet."))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: rentals.length,
        itemBuilder: (context, index) => _RentalCard(rental: rentals[index]),
      ),
    );
  }
}

class _RentalCard extends StatelessWidget {
  final RentalRecord rental;

  const _RentalCard({required this.rental});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${rental.carBrand} ${rental.carModel}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                _StatusChip(isActive: rental.isActive),
              ],
            ),
            const SizedBox(height: 4),
            Text(rental.licensePlate, style: TextStyle(color: Colors.grey.shade700)),
            const Divider(height: 20),
            _row('Duration', '${rental.days} day(s)'),
            _row('From', dateFormat.format(rental.startDate)),
            _row('To', dateFormat.format(rental.endDate)),
            _row('Price/day', '\$${rental.pricePerDay.toStringAsFixed(2)}'),
            const SizedBox(height: 6),
            _row(
              'Total Paid',
              '\$${rental.totalPrice.toStringAsFixed(2)}',
              bold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isActive;

  const _StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade100 : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'ACTIVE' : 'COMPLETED',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isActive ? Colors.green.shade800 : Colors.grey.shade700,
        ),
      ),
    );
  }
}