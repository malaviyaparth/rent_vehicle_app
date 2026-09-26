import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/car.dart';
import '../services/car_service.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/map_service.dart';
import '../services/rental_service.dart';
import '../utils/distance_utils.dart';
import 'add_edit_car_screen.dart';
import '../widgets/rent_car_dialog.dart';

class CarDetailsScreen extends StatelessWidget {
  final String carId;

  const CarDetailsScreen({super.key, required this.carId});

  Future<void> _confirmDelete(BuildContext context, Car car) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Vehicle'),
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
      await context.read<CarService>().removeCar(car.id);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${car.brand} ${car.model} removed.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final carService = context.watch<CarService>();
    final authService = context.watch<AuthService>();
    final locationService = context.watch<LocationService>();
    final rentalService = context.watch<RentalService>();
    final currentUser = authService.currentUser!;

    Car? car;
    try {
      car = carService.getById(carId);
    } catch (_) {
      car = null;
    }

    if (car == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Vehicle Details')),
        body: const Center(child: Text('This vehicle no longer exists.')),
      );
    }

    final isOwnerOrAdmin = car.ownerId == currentUser.uid || currentUser.isAdmin;
    final isRentedRightNow = rentalService.isCarCurrentlyRented(car.id);
    final upcomingBookings = rentalService.upcomingBookingsForCar(car.id);

    double? distanceKm;
    if (locationService.hasLocation && car.hasPickupLocation) {
      distanceKm = calculateDistanceKm(
        locationService.latitude!,
        locationService.longitude!,
        car.pickupLatitude!,
        car.pickupLongitude!,
      );
    }

    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text('${car.brand} ${car.model}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Vehicle Image (Optional) ──
          if (car.imageUrls.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                car.imageUrls.first,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 120,
                  color: Colors.grey.shade200,
                  alignment: Alignment.center,
                  child: const Icon(Icons.directions_car, size: 48, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          _statusBanner(car, isRentedRightNow),
          const SizedBox(height: 16),
          _infoTile(Icons.confirmation_number, 'License Plate', car.licensePlate),
          _infoTile(Icons.directions_car, 'Brand', car.brand),
          _infoTile(Icons.car_repair, 'Model', car.model),
          _infoTile(Icons.calendar_today, 'Year', car.year.toString()),
          _infoTile(Icons.category, 'Category', car.vehicleType),
          _infoTile(Icons.tune, 'Sub-Type', car.vehicleSubType),
          _infoTile(Icons.local_gas_station, 'Fuel Type', car.fuelType),
          _infoTile(
            Icons.currency_rupee,
            'Price per day',
            '₹${car.pricePerDay.toStringAsFixed(2)}',
          ),

          // ── Upcoming Bookings info (Visible exclusively to vehicle owner & admin) ──
          if (isOwnerOrAdmin && upcomingBookings.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.event, color: Colors.orange, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Bookings & Borrowers (${upcomingBookings.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...upcomingBookings.map((b) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• Borrowed by ${b.userName}${b.userPhone != null && b.userPhone!.isNotEmpty ? ' (${b.userPhone})' : ''} • ${dateFormat.format(b.startDate)}–${dateFormat.format(b.endDate)} (${b.days}d) • ₹${b.totalPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade900,
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ],

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

          // ── Pickup Location Section ──
          const SizedBox(height: 20),
          const Text(
            'Vehicle Pickup Location',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          if (car.hasPickupLocation) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.indigo.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.indigo, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Coordinates: ${car.pickupLatitude!.toStringAsFixed(5)}, '
                          '${car.pickupLongitude!.toStringAsFixed(5)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  if (distanceKm != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.straighten, color: Colors.grey, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '${formatDistance(distanceKm)} from your current position',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Navigate button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final launched = await MapService.launchNavigation(
                    car!.pickupLatitude!,
                    car.pickupLongitude!,
                  );
                  if (!launched && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Could not open Google Maps navigation.'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.navigation),
                label: const Text('Navigate to Vehicle (Google Maps)'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.location_off, color: Colors.grey, size: 20),
                  SizedBox(width: 8),
                  Text('Pickup location not set.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // ── Owner / Admin Controls ──
          if (isOwnerOrAdmin) ...[
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
              label: const Text('Edit Vehicle'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: car.available ? Colors.orange : Colors.green,
              ),
              onPressed: () async {
                final wasAvailable = car!.available;
                await context.read<CarService>().toggleAvailability(car.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        wasAvailable
                            ? '${car!.brand} ${car.model} marked as rented.'
                            : '${car!.brand} ${car.model} marked as available.',
                      ),
                    ),
                  );
                }
              },
              icon: Icon(car.available ? Icons.key : Icons.key_off),
              label: Text(car.available ? 'Mark as Inactive' : 'Mark as Available'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => _confirmDelete(context, car!),
              icon: const Icon(Icons.delete),
              label: const Text('Remove Vehicle'),
            ),
          ],

          // ── Owner Restriction Notice or Borrower Book / Schedule Button ──
          if (car.ownerId == currentUser.uid) ...[
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.indigo, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You own this vehicle. Owners cannot rent their own vehicles.',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.indigo),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (currentUser.isOwner) ...[
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.brown, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vehicle owner accounts cannot rent vehicles. Please log in with a borrower account.',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.brown),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: car.available
                  ? () => showRentCarDialog(context, car!)
                  : null,
              icon: const Icon(Icons.calendar_today),
              label: Text(
                !car.available
                    ? 'Currently Inactive'
                    : isRentedRightNow
                        ? 'Book for Future Dates'
                        : 'Book Now',
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusBanner(Car car, bool isRentedRightNow) {
    final bool isAvailable = car.available && !isRentedRightNow;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.green.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        isAvailable ? 'AVAILABLE FOR RENT' : 'CURRENTLY RENTED / IN USE',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isAvailable ? Colors.green.shade800 : Colors.red.shade800,
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