import 'package:flutter/material.dart';
import '../models/car.dart';
import '../utils/distance_utils.dart';

/// A card displaying a vehicle in the nearby-vehicles list and map preview,
/// matching Section 18 of the specification.
class NearbyVehicleCard extends StatelessWidget {
  final Car car;
  final double? distanceKm;
  final VoidCallback onTap;

  const NearbyVehicleCard({
    super.key,
    required this.car,
    required this.distanceKm,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAvailable = car.available;

    return Card(
      elevation: isAvailable ? 2 : 1,
      color: isAvailable ? Colors.white : const Color(0xFFFFF2F2),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isAvailable ? Colors.grey.shade200 : Colors.red.shade300,
          width: isAvailable ? 1 : 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Vehicle Image (if available) ──
            if (car.imageUrls.isNotEmpty)
              Stack(
                children: [
                  Image.network(
                    car.imageUrls.first,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                  if (!isAvailable)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.35),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.shade900.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_clock, color: Colors.white, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'CURRENTLY RENTED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Row 1: Title + availability ──
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${car.brand} ${car.model}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: car.available
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          car.available ? 'Available' : 'Rented',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: car.available
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // ── Row 2: Sub-Type + Fuel chips ──
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _chip(car.vehicleSubType, theme.colorScheme.primaryContainer),
                      _chip(car.fuelType, theme.colorScheme.secondaryContainer),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ── Row 3: Distance + Price + View Details ──
                  Row(
                    children: [
                      if (distanceKm != null) ...[
                        Icon(Icons.location_on, size: 16, color: Colors.indigo.shade600),
                        const SizedBox(width: 3),
                        Text(
                          '${formatDistance(distanceKm!)} away',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        '₹${car.pricePerDay.toStringAsFixed(0)}/day',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
