import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/car.dart';
import '../models/rental_record.dart';
import '../services/auth_service.dart';
import '../services/rental_service.dart';

/// Shows a dialog letting the current user pick a rental duration (in days),
/// then creates the rental record and marks the car unavailable.
/// Returns true via Navigator.pop if the rental was created successfully.
Future<void> showRentCarDialog(BuildContext context, Car car) async {
  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => RentCarDialog(car: car),
  );
}

class RentCarDialog extends StatefulWidget {
  final Car car;

  const RentCarDialog({super.key, required this.car});

  @override
  State<RentCarDialog> createState() => _RentCarDialogState();
}

class _RentCarDialogState extends State<RentCarDialog> {
  int _days = 1;
  bool _isSubmitting = false;

  double get _totalPrice => _days * widget.car.pricePerDay;

  Future<void> _confirmRent() async {
    setState(() => _isSubmitting = true);

    final authService = context.read<AuthService>();
    final rentalService = context.read<RentalService>();
    final currentUser = authService.currentUser!;
    final car = widget.car;

    final startDate = DateTime.now();
    final endDate = startDate.add(Duration(days: _days));

    final rental = RentalRecord(
      id: '', // ignored — Firestore assigns the real id
      carId: car.id,
      carBrand: car.brand,
      carModel: car.model,
      licensePlate: car.licensePlate,
      ownerId: car.ownerId,
      userId: currentUser.uid,
      userName: currentUser.name,
      days: _days,
      pricePerDay: car.pricePerDay,
      totalPrice: _totalPrice,
      startDate: startDate,
      endDate: endDate,
      status: 'active',
    );

    try {
      await rentalService.createRental(rental);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Rented ${car.brand} ${car.model} for $_days day(s). Total: \$${_totalPrice.toStringAsFixed(2)}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rental failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final car = widget.car;

    return AlertDialog(
      title: Text('Rent ${car.brand} ${car.model}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${car.licensePlate} • \$${car.pricePerDay.toStringAsFixed(2)}/day'),
          const SizedBox(height: 20),
          const Text('Number of days:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _days > 1 ? () => setState(() => _days--) : null,
              ),
              Text(
                '$_days',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => setState(() => _days++),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              'Total: \$${_totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _confirmRent,
          child: _isSubmitting
              ? const SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
              : const Text('Confirm Rent'),
        ),
      ],
    );
  }
}