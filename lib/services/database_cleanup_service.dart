import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service to clean up dummy, test, and legacy data from Firestore collections.
class DatabaseCleanupService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Deletes all dummy test bookings/rentals from Firestore
  static Future<int> deleteAllRentals() async {
    try {
      final snap = await _firestore.collection('rentals').get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
      return snap.docs.length;
    } catch (e) {
      debugPrint('Error deleting rentals: $e');
      return 0;
    }
  }

  /// Deletes all dummy payment records from Firestore
  static Future<int> deleteAllPayments() async {
    try {
      final snap = await _firestore.collection('payments').get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
      return snap.docs.length;
    } catch (e) {
      debugPrint('Error deleting payments: $e');
      return 0;
    }
  }

  /// Deletes vehicles from Firestore
  static Future<int> deleteAllCars() async {
    try {
      final snap = await _firestore.collection('cars').get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
      return snap.docs.length;
    } catch (e) {
      debugPrint('Error deleting cars: $e');
      return 0;
    }
  }

  /// Clears all dummy data (rentals, payments, and optionally cars)
  static Future<Map<String, int>> clearAllDummyData({bool deleteVehicles = true}) async {
    final rentalsCount = await deleteAllRentals();
    final paymentsCount = await deleteAllPayments();
    int carsCount = 0;
    if (deleteVehicles) {
      carsCount = await deleteAllCars();
    } else {
      // Mark all existing cars as available
      try {
        final snap = await _firestore.collection('cars').get();
        for (final doc in snap.docs) {
          await doc.reference.update({'available': true});
        }
      } catch (_) {}
    }

    return {
      'rentals': rentalsCount,
      'payments': paymentsCount,
      'cars': carsCount,
    };
  }
}
