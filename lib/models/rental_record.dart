import 'package:cloud_firestore/cloud_firestore.dart';

/// A single rental transaction: one user renting one car for N days.
class RentalRecord {
  String id;
  String carId;
  String carBrand;
  String carModel;
  String licensePlate;
  String ownerId;
  String userId;
  String userName;
  int days;
  double pricePerDay;
  double totalPrice;
  DateTime startDate;
  DateTime endDate;
  String status; // 'active' or 'completed'

  RentalRecord({
    required this.id,
    required this.carId,
    required this.carBrand,
    required this.carModel,
    required this.licensePlate,
    required this.ownerId,
    required this.userId,
    required this.userName,
    required this.days,
    required this.pricePerDay,
    required this.totalPrice,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  bool get isActive => status == 'active';

  factory RentalRecord.fromMap(String id, Map<String, dynamic> data) {
    return RentalRecord(
      id: id,
      carId: data['carId'] ?? '',
      carBrand: data['carBrand'] ?? '',
      carModel: data['carModel'] ?? '',
      licensePlate: data['licensePlate'] ?? '',
      ownerId: data['ownerId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      days: data['days'] ?? 0,
      pricePerDay: (data['pricePerDay'] ?? 0).toDouble(),
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      status: data['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'carId': carId,
      'carBrand': carBrand,
      'carModel': carModel,
      'licensePlate': licensePlate,
      'ownerId': ownerId,
      'userId': userId,
      'userName': userName,
      'days': days,
      'pricePerDay': pricePerDay,
      'totalPrice': totalPrice,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'status': status,
    };
  }
}