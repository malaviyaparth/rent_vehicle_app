import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/car.dart';
import '../services/auth_service.dart';
import '../services/rental_service.dart';
import '../screens/payment_gateway_screen.dart';

/// Shows a dialog letting the user select rental duration and book an available vehicle.
/// Prevents overlapping bookings with smart calendar availability.
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
  late DateTime _startDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
  }

  double get _totalPrice => _days * widget.car.pricePerDay;
  DateTime get _endDate => _startDate.add(Duration(days: _days));

  Future<void> _selectStartDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate.isBefore(today) ? today : _startDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _startDate = DateTime(picked.year, picked.month, picked.day));
    }
  }

  void _proceedToPayment(RentalService rentalService) {
    final conflict = rentalService.getConflictingBooking(widget.car.id, _startDate, _endDate);
    if (conflict != null) {
      final s = '${conflict.startDate.day}/${conflict.startDate.month}/${conflict.startDate.year}';
      final e = '${conflict.endDate.day}/${conflict.endDate.month}/${conflict.endDate.year}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot book: vehicle is already booked from $s to $e.')),
      );
      return;
    }

    final authService = context.read<AuthService>();
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to book this vehicle.')),
      );
      return;
    }

    if (currentUser.isOwner || widget.car.ownerId == currentUser.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade800,
          content: Text(
            widget.car.ownerId == currentUser.uid
                ? 'You own this vehicle. Owners cannot rent their own vehicles.'
                : 'Vehicle owner accounts cannot rent vehicles. Please use a borrower account.',
          ),
        ),
      );
      return;
    }

    // Dismiss dialog and route to Razorpay Demo Gateway
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentGatewayScreen(
          car: widget.car,
          startDate: _startDate,
          days: _days,
          totalPrice: _totalPrice,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final car = widget.car;
    final rentalService = context.watch<RentalService>();

    final conflict = rentalService.getConflictingBooking(car.id, _startDate, _endDate);
    final maxDays = rentalService.maxAvailableDaysFrom(car.id, _startDate);
    final isConflicted = conflict != null;

    final dateFormat = DateFormat('dd/MM/yyyy');

    return AlertDialog(
      title: Text('Book ${car.brand} ${car.model}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${car.vehicleSubType} • ${car.fuelType} • ${car.licensePlate}',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // ── Start Date Selector ──
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_month, color: Colors.indigo),
              title: const Text('Start Date', style: TextStyle(fontSize: 13, color: Colors.grey)),
              subtitle: Text(
                dateFormat.format(_startDate),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              trailing: TextButton(
                onPressed: _selectStartDate,
                child: const Text('Change'),
              ),
            ),
            const Divider(),

            // ── Rental Duration (Days) ──
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Duration:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'Until ${dateFormat.format(_endDate)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _days > 1 ? () => setState(() => _days--) : null,
                ),
                Text(
                  '$_days day${_days > 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => setState(() => _days++),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Conflict Warning OR Price Card ──
            if (isConflicted)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.event_busy, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Unavailable for selected duration',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'This vehicle is already booked from ${dateFormat.format(conflict.startDate)} to ${dateFormat.format(conflict.endDate)}.',
                      style: TextStyle(fontSize: 12, color: Colors.red.shade900),
                    ),
                    if (maxDays != null && maxDays > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Max available from this date: $maxDays day(s)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => setState(() => _days = maxDays),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              visualDensity: VisualDensity.compact,
                            ),
                            child: Text('Set to $maxDays day(s)'),
                          ),
                        ],
                      ),
                    ] else if (maxDays == 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'This vehicle is in use on this start date. Please pick a later start date.',
                        style: TextStyle(fontSize: 12, color: Colors.red.shade800),
                      ),
                    ],
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Available (${dateFormat.format(_startDate)} → ${dateFormat.format(_endDate)})',
                          style: TextStyle(fontSize: 12, color: Colors.green.shade800, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹${car.pricePerDay.toStringAsFixed(0)} × $_days day(s)',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Total: ₹${_totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: (isConflicted) ? null : () => _proceedToPayment(rentalService),
          icon: const Icon(Icons.payment, size: 18),
          label: Text(
            isConflicted
                ? 'Unavailable'
                : 'Proceed to Payment (₹${_totalPrice.toStringAsFixed(0)})',
          ),
        ),
      ],
    );
  }
}