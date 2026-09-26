import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/car.dart';
import '../models/rental_record.dart';

class CarListItem extends StatelessWidget {
  final Car car;
  final RentalRecord? activeRental;
  final bool showBorrowerDetails;
  final VoidCallback onTap;

  const CarListItem({
    super.key,
    required this.car,
    this.activeRental,
    this.showBorrowerDetails = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAvailable = car.available;
    final hasBorrower = showBorrowerDetails && activeRental != null;

    return Card(
      elevation: isAvailable ? 2 : 1.5,
      color: isAvailable ? Colors.white : const Color(0xFFFFF7F7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isAvailable ? Colors.grey.shade200 : Colors.red.shade300,
          width: isAvailable ? 1 : 1.5,
        ),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: Avatar, Info, Status Badge ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isAvailable ? Colors.green.shade600 : Colors.red.shade600,
                    child: Icon(
                      isAvailable ? Icons.check : Icons.lock_clock,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${car.brand} ${car.model} (${car.year})',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isAvailable ? Colors.black87 : Colors.red.shade900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${car.licensePlate} • ${car.vehicleType} • ${car.fuelType}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isAvailable ? Colors.grey.shade700 : Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${car.pricePerDay.toStringAsFixed(0)}/day',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.indigo,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAvailable ? Colors.green.shade50 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isAvailable ? Colors.green.shade400 : Colors.red.shade400,
                      ),
                    ),
                    child: Text(
                      isAvailable ? 'AVAILABLE' : 'RENTED',
                      style: TextStyle(
                        color: isAvailable ? Colors.green.shade800 : Colors.red.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),

              // ── Borrower Information Section (Displayed on Rented car) ──
              if (hasBorrower) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person_pin, size: 16, color: Colors.indigo.shade700),
                          const SizedBox(width: 6),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 13, color: Colors.black87),
                                children: [
                                  const TextSpan(
                                    text: 'Borrower: ',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(
                                    text: activeRental!.userName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo.shade900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.amber.shade400),
                            ),
                            child: Text(
                              activeRental!.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (activeRental!.userEmail != null && activeRental!.userEmail!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.email_outlined, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                activeRental!.userEmail!,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (activeRental!.userPhone != null && activeRental!.userPhone!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.phone_outlined, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                activeRental!.userPhone!,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Period: ${DateFormat('dd MMM').format(activeRental!.startDate)} – ${DateFormat('dd MMM yyyy').format(activeRental!.endDate)} (${activeRental!.days}d)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          Text(
                            'Revenue: ₹${activeRental!.totalPrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}