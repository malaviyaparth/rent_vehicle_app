import 'package:cloud_firestore/cloud_firestore.dart';

/// A rental/booking transaction record.
/// Supported statuses:
/// - 'pending'
/// - 'confirmed' (also encompasses legacy 'active')
/// - 'rejected'
/// - 'cancelled'
/// - 'completed'
class RentalRecord {
  String id;
  String carId;
  String carBrand;
  String carModel;
  String licensePlate;
  String ownerId;
  String userId;
  String userName;
  String? userEmail;
  String? userPhone;
  int days;
  double pricePerDay;
  double totalPrice;
  DateTime startDate;
  DateTime endDate;
  String status;
  DateTime? createdAt;
  DateTime? updatedAt;

  RentalRecord({
    required this.id,
    required this.carId,
    required this.carBrand,
    required this.carModel,
    required this.licensePlate,
    required this.ownerId,
    required this.userId,
    required this.userName,
    this.userEmail,
    this.userPhone,
    required this.days,
    required this.pricePerDay,
    required this.totalPrice,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  // Aliases for specification consistency
  String get vehicleId => carId;
  String get vehicleOwnerId => ownerId;

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed' || status == 'active';
  bool get isRejected => status == 'rejected';
  bool get isCancelled => status == 'cancelled';
  bool get isCompleted => status == 'completed';
  bool get isActive => isConfirmed;

  factory RentalRecord.fromMap(String id, Map<String, dynamic> data) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return RentalRecord(
      id: id,
      carId: data['carId'] ?? data['vehicleId'] ?? '',
      carBrand: data['carBrand'] ?? '',
      carModel: data['carModel'] ?? '',
      licensePlate: data['licensePlate'] ?? '',
      ownerId: data['ownerId'] ?? data['vehicleOwnerId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'],
      userPhone: data['userPhone'],
      days: data['days'] ?? 0,
      pricePerDay: (data['pricePerDay'] ?? 0).toDouble(),
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      startDate: (data['startDate'] is Timestamp)
          ? (data['startDate'] as Timestamp).toDate()
          : (DateTime.tryParse(data['startDate']?.toString() ?? '') ?? DateTime.now()),
      endDate: (data['endDate'] is Timestamp)
          ? (data['endDate'] as Timestamp).toDate()
          : (DateTime.tryParse(data['endDate']?.toString() ?? '') ?? DateTime.now()),
      status: data['status'] ?? 'confirmed',
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'carId': carId,
      'vehicleId': carId,
      'carBrand': carBrand,
      'carModel': carModel,
      'licensePlate': licensePlate,
      'ownerId': ownerId,
      'vehicleOwnerId': ownerId,
      'userId': userId,
      'userName': userName,
      'days': days,
      'pricePerDay': pricePerDay,
      'totalPrice': totalPrice,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'status': status,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (userEmail != null) map['userEmail'] = userEmail;
    if (userPhone != null) map['userPhone'] = userPhone;
    return map;
  }
}