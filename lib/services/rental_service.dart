import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/rental_record.dart';

/// Firestore-backed rental history + active rental tracking.
/// Also auto-releases cars whose rental period has ended, either when
/// fresh data arrives or on a periodic timer while the app is open.
///
/// NOTE: this expiry check only runs while some device has the app open
/// (it's a client-side check, not a server cron job). For a production
/// app you'd move this to a scheduled Cloud Function, but for now this
/// keeps things fully working without needing a paid Firebase plan.
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

    // Safety net: also check every 30 seconds in case no new snapshot
    // arrives (e.g. nobody else changed data) but a rental's time is up.
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

  /// Creates a rental record AND marks the car unavailable, atomically.
  Future<void> createRental(RentalRecord rental) async {
    final batch = FirebaseFirestore.instance.batch();
    final newRentalDoc = _rentalsRef.doc();
    batch.set(newRentalDoc, rental.toMap());
    batch.update(_carsRef.doc(rental.carId), {'available': false});
    await batch.commit();
  }

  Future<void> _checkExpiredRentals() async {
    final now = DateTime.now();
    for (final rental in _rentals) {
      if (rental.isActive && now.isAfter(rental.endDate)) {
        await _completeRental(rental);
      }
    }
  }

  /// Marks a rental as completed AND releases the car back to available,
  /// atomically. Called automatically on expiry.
  Future<void> _completeRental(RentalRecord rental) async {
    final batch = FirebaseFirestore.instance.batch();
    batch.update(_rentalsRef.doc(rental.id), {'status': 'completed'});
    batch.update(_carsRef.doc(rental.carId), {'available': true});
    await batch.commit();
  }
}