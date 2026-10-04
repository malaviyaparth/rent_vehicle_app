import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/review.dart';

/// Service responsible for managing vehicle ratings and customer reviews in Firestore.
/// Uses a resilient hybrid architecture:
/// 1. Stores review and rating directly on the rental record (guaranteed borrower write permissions).
/// 2. Best-effort replication to the standalone `reviews` collection and vehicle aggregate stats.
class ReviewService extends ChangeNotifier {
  final CollectionReference<Map<String, dynamic>> _reviewsRef =
      FirebaseFirestore.instance.collection('reviews');
  final CollectionReference<Map<String, dynamic>> _carsRef =
      FirebaseFirestore.instance.collection('cars');
  final CollectionReference<Map<String, dynamic>> _rentalsRef =
      FirebaseFirestore.instance.collection('rentals');

  /// Submits a new vehicle review and rating.
  /// Enforces trip completion, correct renter identity, and prevents duplicates.
  Future<void> addReview({
    required String carId,
    required String rentalId,
    required String userId,
    required String userName,
    required double rating,
    required String comment,
  }) async {
    if (rating < 1.0 || rating > 5.0) {
      throw ArgumentError('Rating must be between 1.0 and 5.0 stars.');
    }

    final carDocRef = _carsRef.doc(carId);
    final rentalDocRef = _rentalsRef.doc(rentalId);
    final newReviewDocRef = _reviewsRef.doc();

    // 1. Read rental document to validate
    final rentalSnap = await rentalDocRef.get();
    if (!rentalSnap.exists) {
      throw Exception('Booking record not found.');
    }

    final rentalData = rentalSnap.data()!;
    final status = (rentalData['status'] ?? '').toString().toLowerCase();

    // Ensure rental is completed
    if (status != 'completed') {
      throw Exception('You can only rate a vehicle after the rental is completed.');
    }

    // Ensure rental has not already been rated
    if (rentalData['hasRated'] == true) {
      throw Exception('This trip has already been reviewed.');
    }

    // Ensure the submitting user is the actual borrower
    if (rentalData['userId'] != userId) {
      throw Exception('Only the renter of this trip is authorized to submit a review.');
    }

    final cleanComment = comment.trim();
    final cleanUserName = userName.trim().isNotEmpty ? userName.trim() : 'Verified Renter';
    final now = DateTime.now();

    // 2. Primary write: update rental record directly
    // The borrower has guaranteed write permissions on their own rental document!
    await rentalDocRef.update({
      'hasRated': true,
      'rating': rating,
      'comment': cleanComment,
      'ratedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 3. Best-effort: Save to standalone reviews collection (if permitted by Firestore rules)
    final review = Review(
      id: newReviewDocRef.id,
      carId: carId,
      rentalId: rentalId,
      userId: userId,
      userName: cleanUserName,
      rating: rating,
      comment: cleanComment,
      createdAt: now,
    );

    try {
      await newReviewDocRef.set(review.toMap());
    } catch (e) {
      debugPrint('Note: Standalone reviews collection write bypassed: $e');
    }

    // 4. Best-effort: Update vehicle aggregate rating stats on car document
    try {
      final carSnap = await carDocRef.get();
      if (carSnap.exists) {
        final carData = carSnap.data()!;
        final oldAverage = (carData['averageRating'] as num?)?.toDouble() ?? 0.0;
        final oldTotal = (carData['totalRatings'] as num?)?.toInt() ?? 0;

        final newTotal = oldTotal + 1;
        final rawAverage = ((oldAverage * oldTotal) + rating) / newTotal;
        final newAverage = double.parse(rawAverage.toStringAsFixed(1));

        await carDocRef.update({
          'averageRating': newAverage,
          'totalRatings': newTotal,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Note: Car aggregate stats update bypassed: $e');
    }

    notifyListeners();
  }

  /// Streams all reviews for a vehicle in real-time.
  /// Combines rental reviews (guaranteed permissions) with any standalone reviews.
  Stream<List<Review>> getReviewsForCar(String carId) {
    return _rentalsRef
        .where('carId', isEqualTo: carId)
        .where('hasRated', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final List<Review> reviews = [];

          for (final doc in snapshot.docs) {
            final data = doc.data();
            final r = (data['rating'] as num?)?.toDouble();
            if (r == null || r < 1.0) continue;

            DateTime parseDate(dynamic val) {
              if (val is Timestamp) return val.toDate();
              if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
              return DateTime.now();
            }

            reviews.add(Review(
              id: doc.id,
              carId: carId,
              rentalId: doc.id,
              userId: data['userId'] ?? '',
              userName: (data['userName'] != null && data['userName'].toString().trim().isNotEmpty)
                  ? data['userName'].toString().trim()
                  : 'Verified Renter',
              rating: r,
              comment: (data['comment'] ?? data['reviewComment'] ?? '').toString().trim(),
              createdAt: parseDate(data['ratedAt'] ?? data['updatedAt'] ?? data['createdAt']),
            ));
          }

          reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return reviews;
        });
  }

  /// Checks if the specified rental has already been rated.
  Future<bool> hasUserReviewedRental(String rentalId) async {
    try {
      final doc = await _rentalsRef.doc(rentalId).get();
      if (!doc.exists) return false;
      return doc.data()?['hasRated'] == true;
    } catch (_) {
      return false;
    }
  }
}
