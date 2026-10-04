import 'package:cloud_firestore/cloud_firestore.dart';

/// A review & star rating left by a borrower after a completed vehicle rental.
class Review {
  final String id;
  final String carId;
  final String rentalId;
  final String userId;
  final String userName;
  final double rating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.carId,
    required this.rentalId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromMap(String id, Map<String, dynamic> data) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return Review(
      id: id,
      carId: data['carId'] ?? '',
      rentalId: data['rentalId'] ?? '',
      userId: data['userId'] ?? '',
      userName: (data['userName'] != null && data['userName'].toString().trim().isNotEmpty)
          ? data['userName']
          : 'Verified Renter',
      rating: (data['rating'] as num?)?.toDouble() ?? 5.0,
      comment: data['comment'] ?? '',
      createdAt: parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'carId': carId,
      'rentalId': rentalId,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
