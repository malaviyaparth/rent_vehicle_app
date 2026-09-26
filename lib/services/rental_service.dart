import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/rental_record.dart';

/// Firestore-backed rental and booking service.
/// Tracks real-time bookings and provides smart date-range availability calculations.
class RentalService extends ChangeNotifier {
  final CollectionReference<Map<String, dynamic>> _rentalsRef =
      FirebaseFirestore.instance.collection('rentals');
  final CollectionReference<Map<String, dynamic>> _carsRef =
      FirebaseFirestore.instance.collection('cars');

  List<RentalRecord> _rentals = [];
  bool _loading = true;
  StreamSubscription? _subscription;
  Timer? _expiryTimer;

  RentalService() {
    _subscription = _rentalsRef.snapshots().listen((snapshot) {
      _rentals = snapshot.docs.map((doc) => RentalRecord.fromMap(doc.id, doc.data())).toList();
      _loading = false;
      notifyListeners();
      _checkExpiredRentals();
    });

    _expiryTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkExpiredRentals();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _expiryTimer?.cancel();
    super.dispose();
  }

  bool get isLoading => _loading;

  List<RentalRecord> get all => List.unmodifiable(_rentals);

  /// A user's own rental history (most recent first).
  List<RentalRecord> rentalsByUser(String userId) {
    final list = _rentals.where((r) => r.userId == userId).toList();
    list.sort((a, b) => b.startDate.compareTo(a.startDate));
    return list;
  }

  /// All rentals across every car an owner owns (most recent first).
  List<RentalRecord> rentalsByOwner(String ownerId) {
    final list = _rentals.where((r) => r.ownerId == ownerId).toList();
    list.sort((a, b) => b.startDate.compareTo(a.startDate));
    return list;
  }

  /// Rental history for one specific car (most recent first).
  List<RentalRecord> rentalsForCar(String carId) {
    final list = _rentals.where((r) => r.carId == carId).toList();
    list.sort((a, b) => b.startDate.compareTo(a.startDate));
    return list;
  }

  DateTime _toMidnight(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  /// Returns true if the vehicle is currently booked and in-use today.
  bool isCarCurrentlyRented(String carId) {
    final today = _toMidnight(DateTime.now());
    return _rentals.any((r) {
      if (r.carId != carId || !r.isConfirmed) return false;
      final start = _toMidnight(r.startDate);
      final end = _toMidnight(r.endDate);
      return (today.isAtSameMomentAs(start) || today.isAfter(start)) && today.isBefore(end);
    });
  }

  /// Set of all car IDs that are currently in-use today.
  Set<String> get currentlyRentedCarIds {
    final today = _toMidnight(DateTime.now());
    final set = <String>{};
    for (final r in _rentals) {
      if (!r.isConfirmed) continue;
      final start = _toMidnight(r.startDate);
      final end = _toMidnight(r.endDate);
      if ((today.isAtSameMomentAs(start) || today.isAfter(start)) && today.isBefore(end)) {
        set.add(r.carId);
      }
    }
    return set;
  }

  /// Returns active or upcoming bookings for a specific vehicle.
  List<RentalRecord> upcomingBookingsForCar(String carId) {
    final today = _toMidnight(DateTime.now());
    final list = _rentals.where((r) {
      if (r.carId != carId || !r.isConfirmed) return false;
      final end = _toMidnight(r.endDate);
      return end.isAfter(today);
    }).toList();
    list.sort((a, b) => a.startDate.compareTo(b.startDate));
    return list;
  }

  /// Returns the current active or upcoming confirmed rental record for a car.
  RentalRecord? activeRentalForCar(String carId) {
    final today = _toMidnight(DateTime.now());
    // 1. Check if vehicle is currently in-use today
    for (final r in _rentals) {
      if (r.carId != carId || !r.isConfirmed) continue;
      final start = _toMidnight(r.startDate);
      final end = _toMidnight(r.endDate);
      if ((today.isAtSameMomentAs(start) || today.isAfter(start)) && today.isBefore(end)) {
        return r;
      }
    }
    // 2. Check next upcoming booking
    final upcoming = upcomingBookingsForCar(carId);
    if (upcoming.isNotEmpty) {
      return upcoming.first;
    }
    // 3. Fallback to latest confirmed booking
    final confirmed = _rentals.where((r) => r.carId == carId && r.isConfirmed).toList();
    if (confirmed.isNotEmpty) {
      confirmed.sort((a, b) => b.startDate.compareTo(a.startDate));
      return confirmed.first;
    }
    return null;
  }

  /// Checks if [requestedStart] to [requestedEnd] conflicts with any existing confirmed booking.
  /// Returns the conflicting [RentalRecord], or null if completely available.
  RentalRecord? getConflictingBooking(
    String carId,
    DateTime requestedStart,
    DateTime requestedEnd,
  ) {
    final reqStart = _toMidnight(requestedStart);
    final reqEnd = _toMidnight(requestedEnd);

    for (final r in _rentals) {
      if (r.carId != carId || !r.isConfirmed) continue;
      final bookedStart = _toMidnight(r.startDate);
      final bookedEnd = _toMidnight(r.endDate);

      // Overlap condition:
      // Start of A < End of B AND End of A > Start of B
      if (reqStart.isBefore(bookedEnd) && reqEnd.isAfter(bookedStart)) {
        return r;
      }
    }
    return null;
  }

  /// Returns the maximum days a car can be booked starting from [startDate]
  /// before the next booking begins. Returns null if unlimited.
  int? maxAvailableDaysFrom(String carId, DateTime startDate) {
    final reqStart = _toMidnight(startDate);
    final futureBookings = _rentals.where((r) {
      if (r.carId != carId || !r.isConfirmed) return false;
      final bStart = _toMidnight(r.startDate);
      return bStart.isAfter(reqStart);
    }).toList();

    if (futureBookings.isEmpty) return null;

    futureBookings.sort((a, b) => a.startDate.compareTo(b.startDate));
    final nextBooking = futureBookings.first;
    final diff = _toMidnight(nextBooking.startDate).difference(reqStart).inDays;
    return diff > 0 ? diff : 0;
  }

  /// Creates a rental/booking record and validates against date conflicts.
  Future<void> createRental(RentalRecord rental) async {
    // 1. Smart date conflict check
    final conflict = getConflictingBooking(rental.carId, rental.startDate, rental.endDate);
    if (conflict != null) {
      final s = '${conflict.startDate.day}/${conflict.startDate.month}/${conflict.startDate.year}';
      final e = '${conflict.endDate.day}/${conflict.endDate.month}/${conflict.endDate.year}';
      throw Exception('This vehicle is already booked from $s to $e.');
    }

    // 2. Check if car exists and is not disabled by owner
    final carDoc = await _carsRef.doc(rental.carId).get();
    if (!carDoc.exists) {
      throw Exception('Vehicle no longer exists.');
    }
    final isAvailable = carDoc.data()?['available'] ?? false;
    if (!isAvailable) {
      throw Exception('This vehicle has been marked inactive by its owner.');
    }

    // 3. Create the rental record in Firestore
    final newRentalDoc = _rentalsRef.doc();
    await newRentalDoc.set(rental.toMap());

    // 4. Update vehicle availability in Firestore if it starts today
    final today = _toMidnight(DateTime.now());
    final rentalStart = _toMidnight(rental.startDate);
    if (rentalStart.isAtSameMomentAs(today) || rentalStart.isBefore(today)) {
      try {
        await _carsRef.doc(rental.carId).update({
          'available': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Note: Car availability update skipped on client: $e');
      }
    }
  }

  /// Borrower or admin cancels an active/pending rental.
  Future<void> cancelRental(String rentalId, String carId) async {
    await _rentalsRef.doc(rentalId).update({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    try {
      await _carsRef.doc(carId).update({
        'available': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Note: Car availability restore skipped on client: $e');
    }
  }

  /// Owner accepts a pending booking.
  Future<void> acceptRental(String rentalId) async {
    await _rentalsRef.doc(rentalId).update({
      'status': 'confirmed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Owner or admin rejects a pending booking.
  Future<void> rejectRental(String rentalId, String carId) async {
    final batch = FirebaseFirestore.instance.batch();
    batch.update(_rentalsRef.doc(rentalId), {
      'status': 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_carsRef.doc(carId), {
      'available': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  /// Marks a rental as completed and releases the car back to available.
  Future<void> completeRental(RentalRecord rental) async {
    final batch = FirebaseFirestore.instance.batch();
    batch.update(_rentalsRef.doc(rental.id), {
      'status': 'completed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_carsRef.doc(rental.carId), {
      'available': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  /// Admin-only: deletes a booking record.
  Future<void> deleteRental(String rentalId) async {
    await _rentalsRef.doc(rentalId).delete();
  }

  Future<void> _checkExpiredRentals() async {
    final now = DateTime.now();
    for (final rental in _rentals) {
      if (rental.isConfirmed && now.isAfter(rental.endDate)) {
        await completeRental(rental);
      }
    }
  }
}