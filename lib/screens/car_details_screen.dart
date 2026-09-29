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
    final rentalService = context.read<RentalService>();
    final isRented = rentalService.isCarCurrentlyRented(car.id) ||
        rentalService.upcomingBookingsForCar(car.id).isNotEmpty;

    if (isRented) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.block, color: Colors.red, size: 44),
          title: const Text('Cannot Remove Vehicle'),
          content: Text(
            '${car.brand} ${car.model} is currently rented or has confirmed bookings by a borrower. '
            'You cannot remove a vehicle while it has active or scheduled rentals.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Understood'),
            ),
          ],
        ),
      );
      return;
    }

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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('${car.brand} ${car.model}'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // ── Vehicle Showcase Media / Hero ──
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: car.imageUrls.isNotEmpty
                ? Stack(
                    children: [
                      Image.network(
                        car.imageUrls.first,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildPlaceholderHero(car!),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.2),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.5),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: _statusBadge(car, isRentedRightNow),
                      ),
                    ],
                  )
                : _buildPlaceholderHero(car, isRentedRightNow: isRentedRightNow),
          ),

          const SizedBox(height: 18),

          // ── Vehicle Name, Year & Rate Card ──
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${car.brand} ${car.model}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${car.year}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            car.licensePlate,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${car.pricePerDay.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      const Text(
                        'per day',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Key Specifications 2x2 Grid ──
          Row(
            children: [
              Expanded(
                child: _buildSpecCard(
                  icon: Icons.category_outlined,
                  label: 'Category',
                  value: car.vehicleType,
                  color: const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSpecCard(
                  icon: Icons.tune,
                  label: 'Sub-Type',
                  value: car.vehicleSubType,
                  color: const Color(0xFF7C3AED),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildSpecCard(
                  icon: Icons.local_gas_station_outlined,
                  label: 'Fuel Type',
                  value: car.fuelType,
                  color: const Color(0xFF059669),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSpecCard(
                  icon: Icons.confirmation_number_outlined,
                  label: 'Plate No',
                  value: car.licensePlate,
                  color: const Color(0xFFD97706),
                ),
              ),
            ],
          ),

          // ── Upcoming Bookings Info (Owner & Admin Only) ──
          if (isOwnerOrAdmin && upcomingBookings.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.event_note, color: Color(0xFFD97706), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Active Bookings & Borrowers (${upcomingBookings.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...upcomingBookings.map((b) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              b.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              '₹${b.totalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                        if (b.userPhone != null && b.userPhone!.isNotEmpty)
                          Text(
                            '📞 ${b.userPhone}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        Text(
                          '🗓️ ${dateFormat.format(b.startDate)} – ${dateFormat.format(b.endDate)} (${b.days} days)',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // ── Description Card ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'About Vehicle',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  car.description.isEmpty ? 'No description provided by the owner.' : car.description,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.45),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Pickup Location Section ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.location_on, color: Color(0xFF2563EB), size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Pickup & Return Location',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (car.hasPickupLocation) ...[
                  Text(
                    'GPS: ${car.pickupLatitude!.toStringAsFixed(5)}, ${car.pickupLongitude!.toStringAsFixed(5)}',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                  if (distanceKm != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.near_me, size: 14, color: Color(0xFF059669)),
                          const SizedBox(width: 6),
                          Text(
                            '${formatDistance(distanceKm)} from your current position',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF065F46),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
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
                      icon: const Icon(Icons.directions, color: Color(0xFF2563EB)),
                      label: const Text('Open in Google Maps Navigation'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ] else ...[
                  const Text(
                    'Pickup location has not been registered on the map by the owner.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Owner / Admin Action Buttons ──
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
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit Vehicle Details'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: car.available ? const Color(0xFFD97706) : const Color(0xFF059669),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () async {
                final wasAvailable = car!.available;
                await context.read<CarService>().toggleAvailability(car.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        wasAvailable
                            ? '${car!.brand} ${car.model} marked as inactive.'
                            : '${car!.brand} ${car.model} marked as available.',
                      ),
                    ),
                  );
                }
              },
              icon: Icon(car.available ? Icons.pause_circle_outline : Icons.play_circle_outline),
              label: Text(car.available ? 'Mark as Inactive' : 'Mark as Available'),
            ),
            const SizedBox(height: 10),
            Builder(builder: (context) {
              final isCarRented = isRentedRightNow || upcomingBookings.isNotEmpty;
              return ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCarRented ? const Color(0xFF94A3B8) : const Color(0xFFE11D48),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: isCarRented
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Colors.red,
                            content: Text(
                              'Cannot remove vehicle: This vehicle is currently rented or booked by a borrower.',
                            ),
                          ),
                        );
                      }
                    : () => _confirmDelete(context, car!),
                icon: const Icon(Icons.delete_outline),
                label: Text(
                  isCarRented ? 'Cannot Remove (Vehicle Rented)' : 'Remove Vehicle',
                ),
              );
            }),
          ],

          // ── Borrower Book Now / Restriction Notices ──
          if (car.ownerId == currentUser.uid) ...[
            Container(
              margin: const EdgeInsets.only(top: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You are the owner of this vehicle. Self-booking is restricted.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (currentUser.isOwner) ...[
            Container(
              margin: const EdgeInsets.only(top: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Owner accounts cannot rent vehicles. Please switch to a borrower account to book.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: car.available
                  ? () => showRentCarDialog(context, car!)
                  : null,
              icon: const Icon(Icons.calendar_month),
              label: Text(
                !car.available
                    ? 'Currently Inactive'
                    : isRentedRightNow
                        ? 'Book for Future Dates'
                        : 'Book Now',
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF2563EB),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPlaceholderHero(Car car, {bool isRentedRightNow = false}) {
    final isTwoWheeler = car.vehicleType.toLowerCase().contains('two') ||
        car.vehicleType.toLowerCase().contains('bike');

    return Container(
      height: 180,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isTwoWheeler ? Icons.two_wheeler : Icons.directions_car,
            size: 64,
            color: Colors.white.withValues(alpha: 0.9),
          ),
          const SizedBox(height: 10),
          _statusBadge(car, isRentedRightNow),
        ],
      ),
    );
  }

  Widget _statusBadge(Car car, bool isRentedRightNow) {
    final bool isAvailable = car.available && !isRentedRightNow;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isAvailable ? const Color(0xFF059669) : const Color(0xFFE11D48),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isAvailable ? 'AVAILABLE FOR RENT' : 'CURRENTLY RENTED',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}