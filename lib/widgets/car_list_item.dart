import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/car.dart';
import '../models/rental_record.dart';
import '../utils/distance_utils.dart';

class CarListItem extends StatelessWidget {
  final Car car;
  final RentalRecord? activeRental;
  final bool showBorrowerDetails;
  final double? distanceKm;
  final VoidCallback onTap;
  final VoidCallback? onToggleAvailability;

  const CarListItem({
    super.key,
    required this.car,
    this.activeRental,
    this.showBorrowerDetails = false,
    this.distanceKm,
    required this.onTap,
    this.onToggleAvailability,
  });

  @override
  Widget build(BuildContext context) {
    final isRented = activeRental != null;
    final isInactive = !car.available && !isRented;
    final isAvailable = car.available && !isRented;
    final hasBorrower = showBorrowerDetails && activeRental != null;
    final isTwoWheeler = car.vehicleType.toLowerCase().contains('two') ||
        car.vehicleType.toLowerCase().contains('bike');

    final Color borderColor = isAvailable
        ? const Color(0xFFE2E8F0)
        : (isInactive ? const Color(0xFFFDE68A) : const Color(0xFFFECDD3));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: borderColor,
          width: 1.2,
        ),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        splashColor: const Color(0xFF2563EB).withValues(alpha: 0.08),
        highlightColor: const Color(0xFF2563EB).withValues(alpha: 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Image / Vehicle Graphic Header ──
            if (car.imageUrls.isNotEmpty)
              Stack(
                children: [
                  Image.network(
                    car.imageUrls.first,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildFallbackBanner(
                          isTwoWheeler,
                          isAvailable: isAvailable,
                          isInactive: isInactive,
                          isRented: isRented,
                        ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.35),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.4),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${car.vehicleType} • ${car.vehicleSubType}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _buildStatusPill(
                      isAvailable: isAvailable,
                      isInactive: isInactive,
                      isRented: isRented,
                    ),
                  ),
                ],
              )
            else
              _buildFallbackBanner(
                isTwoWheeler,
                isAvailable: isAvailable,
                isInactive: isInactive,
                isRented: isRented,
              ),

            // ── Main Details Section ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Price Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${car.brand} ${car.model}',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${car.year} • ${car.licensePlate}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (car.hasRatings)
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, size: 16, color: Color(0xFFD97706)),
                                  const SizedBox(width: 3),
                                  Text(
                                    car.averageRating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '(${car.totalRatings} ${car.totalRatings == 1 ? 'review' : 'reviews'})',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              )
                            else
                              Row(
                                children: [
                                  Icon(Icons.star_outline_rounded, size: 14, color: Colors.grey.shade400),
                                  const SizedBox(width: 3),
                                  Text(
                                    'No ratings yet',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '₹${car.pricePerDay.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                                const TextSpan(
                                  text: ' /day',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Specification Pills & Distance
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildSpecChip(Icons.local_gas_station_outlined, car.fuelType),
                      _buildSpecChip(
                        isTwoWheeler ? Icons.two_wheeler_outlined : Icons.directions_car_outlined,
                        car.vehicleSubType,
                      ),
                      if (distanceKm != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.near_me, size: 12, color: Color(0xFF2563EB)),
                              const SizedBox(width: 4),
                              Text(
                                '${formatDistance(distanceKm!)} away',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1D4ED8),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  // ── Borrower Ticket Section (For Rented Cars on Owner Side) ──
                  if (hasBorrower) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFECDD3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE11D48),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.person, size: 14, color: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Rented to: ${activeRental!.userName}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF881337),
                                      ),
                                    ),
                                    if (activeRental!.userPhone != null &&
                                        activeRental!.userPhone!.isNotEmpty)
                                      Text(
                                        '📞 ${activeRental!.userPhone}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF9F1239),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFFDA4AF)),
                                ),
                                child: Text(
                                  activeRental!.status.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFE11D48),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (activeRental!.userEmail != null &&
                              activeRental!.userEmail!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              '✉️ ${activeRental!.userEmail}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF9F1239)),
                            ),
                          ],
                          const Divider(height: 16, color: Color(0xFFFECDD3)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '🗓️ ${DateFormat('dd MMM').format(activeRental!.startDate)} – ${DateFormat('dd MMM yyyy').format(activeRental!.endDate)} (${activeRental!.days}d)',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF881337),
                                ),
                              ),
                              Text(
                                'Earned: ₹${activeRental!.totalPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF047857),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                // ── Owner Quick Availability Toggle Row ──
                if (showBorrowerDetails && onToggleAvailability != null) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isRented
                                ? Icons.lock_clock
                                : (isInactive
                                    ? Icons.pause_circle_filled
                                    : Icons.check_circle),
                            size: 16,
                            color: isRented
                                ? const Color(0xFFE11D48)
                                : (isInactive
                                    ? const Color(0xFFD97706)
                                    : const Color(0xFF059669)),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isRented
                                ? 'Currently Rented'
                                : (isInactive
                                    ? 'Status: Inactive'
                                    : 'Status: Available'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isRented
                                  ? const Color(0xFFE11D48)
                                  : (isInactive
                                      ? const Color(0xFFD97706)
                                      : const Color(0xFF059669)),
                            ),
                          ),
                        ],
                      ),
                      if (!isRented)
                        OutlinedButton.icon(
                          onPressed: onToggleAvailability,
                          icon: Icon(
                            isInactive
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded,
                            size: 15,
                            color: isInactive
                                ? const Color(0xFF059669)
                                : const Color(0xFFD97706),
                          ),
                          label: Text(
                            isInactive ? 'Mark Available' : 'Mark Inactive',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isInactive
                                  ? const Color(0xFF059669)
                                  : const Color(0xFFD97706),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            side: BorderSide(
                              color: isInactive
                                  ? const Color(0xFF6EE7B7)
                                  : const Color(0xFFFCD34D),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildFallbackBanner(
    bool isTwoWheeler, {
    required bool isAvailable,
    required bool isInactive,
    required bool isRented,
  }) {
    List<Color> gradientColors;
    if (isRented) {
      gradientColors = [const Color(0xFF4C0519), const Color(0xFF881337)];
    } else if (isInactive) {
      gradientColors = [const Color(0xFF451A03), const Color(0xFF78350F)];
    } else {
      gradientColors = [const Color(0xFF1E293B), const Color(0xFF334155)];
    }

    return Container(
      height: 90,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isTwoWheeler ? Icons.two_wheeler : Icons.directions_car,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${car.vehicleType} • ${car.vehicleSubType}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  car.fuelType,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _buildStatusPill(
            isAvailable: isAvailable,
            isInactive: isInactive,
            isRented: isRented,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill({
    required bool isAvailable,
    required bool isInactive,
    required bool isRented,
  }) {
    Color bg;
    Color border;
    Color dot;
    Color text;
    String label;

    if (isRented) {
      bg = const Color(0xFFFFF1F2);
      border = const Color(0xFFFDA4AF);
      dot = const Color(0xFFE11D48);
      text = const Color(0xFF9F1239);
      label = 'RENTED';
    } else if (isInactive) {
      bg = const Color(0xFFFFFBEB);
      border = const Color(0xFFFDE68A);
      dot = const Color(0xFFD97706);
      text = const Color(0xFF92400E);
      label = 'INACTIVE';
    } else {
      bg = const Color(0xFFECFDF5);
      border = const Color(0xFF6EE7B7);
      dot = const Color(0xFF059669);
      text = const Color(0xFF065F46);
      label = 'AVAILABLE';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dot,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: text,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}