import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/rental_record.dart';
import '../services/auth_service.dart';
import '../services/car_service.dart';
import '../services/map_service.dart';
import '../services/rental_service.dart';
import '../widgets/rating_dialog.dart';
import 'nearby_vehicles_screen.dart';

class MyRentalHistoryScreen extends StatelessWidget {
  const MyRentalHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rentalService = context.watch<RentalService>();
    final authService = context.watch<AuthService>();
    final currentUser = authService.currentUser!;

    final rentals = rentalService.rentalsByUser(currentUser.uid);

    return Scaffold(
      appBar: AppBar(title: const Text('My Booking History')),
      body: rentalService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : rentals.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: rentals.length,
                  itemBuilder: (context, index) => _RentalCard(rental: rentals[index]),
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.car_rental, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              "You don't have any bookings yet.",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Browse nearby vehicles and book one in seconds.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const NearbyVehiclesScreen()),
                );
              },
              icon: const Icon(Icons.near_me),
              label: const Text('Find Vehicles'),
            ),
          ],
        ),
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
    final carService = context.read<CarService>();
    final rentalService = context.read<RentalService>();

    final car = carService.tryGetById(rental.carId);
    final canCancel = rental.isPending || rental.isConfirmed;
    final canRate = rental.isCompleted && !rental.hasRated;
    final hasAlreadyRated = rental.isCompleted && rental.hasRated;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${rental.carBrand} ${rental.carModel}',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                _StatusBadge(status: rental.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(rental.licensePlate, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
            const Divider(height: 20),
            _row('Booking Period', '${rental.days} day(s)'),
            _row('Pick-up Date', dateFormat.format(rental.startDate)),
            _row('Return Date', dateFormat.format(rental.endDate)),
            _row('Rate', '₹${rental.pricePerDay.toStringAsFixed(2)}/day'),
            const SizedBox(height: 4),
            _row('Total Paid', '₹${rental.totalPrice.toStringAsFixed(2)}', bold: true),

            // ── Rating Section for Completed Trips ──
            if (canRate) ...[
              const Divider(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Trip completed! Rate this vehicle',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ],
                    ),
                    FilledButton.icon(
                      onPressed: () => showRatingDialog(context, rental),
                      icon: const Icon(Icons.rate_review, size: 16),
                      label: const Text('Rate Vehicle'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (hasAlreadyRated) ...[
              const Divider(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF059669)),
                    const SizedBox(width: 6),
                    Text(
                      rental.rating != null
                          ? 'Trip Rated (${rental.rating!.toStringAsFixed(1)} ★) • Thank you for your review!'
                          : 'Trip Rated • Thank you for your review!',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF065F46),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Actions row: Navigate & Cancel
            if (canCancel || (car != null && car.hasPickupLocation)) ...[
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (car != null && car.hasPickupLocation && rental.isConfirmed) ...[
                    OutlinedButton.icon(
                      onPressed: () {
                        MapService.launchNavigation(
                          car.pickupLatitude!,
                          car.pickupLongitude!,
                        );
                      },
                      icon: const Icon(Icons.navigation, size: 16),
                      label: const Text('Navigate'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                  if (canCancel) ...[
                    TextButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Cancel Booking?'),
                            content: const Text(
                              'Are you sure you want to cancel this booking? The vehicle will be released.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Keep Booking'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                                child: const Text('Cancel Booking'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          await rentalService.cancelRental(rental.id, rental.carId);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Booking has been cancelled.')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.close, size: 16, color: Colors.red),
                      label: const Text('Cancel', style: TextStyle(color: Colors.red)),
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              fontSize: bold ? 15 : 13,
              color: bold ? Colors.indigo : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg = Colors.grey.shade200;
    Color fg = Colors.grey.shade800;

    switch (status.toLowerCase()) {
      case 'active':
      case 'confirmed':
        bg = Colors.green.shade100;
        fg = Colors.green.shade800;
        break;
      case 'pending':
        bg = Colors.orange.shade100;
        fg = Colors.orange.shade800;
        break;
      case 'cancelled':
      case 'rejected':
        bg = Colors.red.shade100;
        fg = Colors.red.shade800;
        break;
      case 'completed':
        bg = Colors.blue.shade100;
        fg = Colors.blue.shade800;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }
}