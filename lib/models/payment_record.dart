import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a payment transaction in the rental system.
/// Tracks payment gateway metadata, simulation details, and links directly to a booking.
class PaymentRecord {
  final String id;
  final String bookingId;
  final String userId;
  final String userName;
  final String userEmail;
  final String carId;
  final String carBrand;
  final String carModel;
  final String licensePlate;
  final double amount;
  final String paymentMethod; // 'UPI', 'Card', 'Net Banking', 'Pay at Pickup'
  final String paymentSubMethod; // e.g., 'Google Pay', 'Mock Visa **** 4242', 'HDFC Bank'
  final String transactionId; // e.g. MOCK_TXN_123456
  final String status; // 'success', 'pending', 'failed'
  final DateTime createdAt;
  final int days;
  final DateTime startDate;
  final DateTime endDate;

  PaymentRecord({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.carId,
    required this.carBrand,
    required this.carModel,
    required this.licensePlate,
    required this.amount,
    required this.paymentMethod,
    required this.paymentSubMethod,
    required this.transactionId,
    required this.status,
    required this.createdAt,
    required this.days,
    required this.startDate,
    required this.endDate,
  });

  bool get isSuccess => status == 'success';
  bool get isPending => status == 'pending';

  factory PaymentRecord.fromMap(String id, Map<String, dynamic> data) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return PaymentRecord(
      id: id,
      bookingId: data['bookingId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      carId: data['carId'] ?? '',
      carBrand: data['carBrand'] ?? '',
      carModel: data['carModel'] ?? '',
      licensePlate: data['licensePlate'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? 'UPI',
      paymentSubMethod: data['paymentSubMethod'] ?? '',
      transactionId: data['transactionId'] ?? '',
      status: data['status'] ?? 'success',
      createdAt: parseDate(data['createdAt']),
      days: data['days'] ?? 1,
      startDate: parseDate(data['startDate']),
      endDate: parseDate(data['endDate']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'carId': carId,
      'carBrand': carBrand,
      'carModel': carModel,
      'licensePlate': licensePlate,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'paymentSubMethod': paymentSubMethod,
      'transactionId': transactionId,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'days': days,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
    };
  }
}
