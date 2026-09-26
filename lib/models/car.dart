import 'package:cloud_firestore/cloud_firestore.dart';
import 'vehicle_enums.dart';

class Car {
  String id;
  String ownerId;
  String licensePlate;
  String brand;
  String model;
  int year;
  double pricePerDay;
  String description;
  bool available;

  /// Top-level vehicle type: 'Car' or 'TwoWheeler'.
  String vehicleType;

  /// Specific sub-type:
  /// - For Car: Sedan, SUV, Hatchback, MUV, Coupe, Convertible
  /// - For TwoWheeler: Bike, Scooter
  String vehicleSubType;

  /// Fuel type: Petrol, Diesel, Electric, CNG, Hybrid.
  String fuelType;

  /// Pickup location coordinates: { 'latitude': double, 'longitude': double }.
  Map<String, double>? pickupLocation;

  /// Optional list of image URLs.
  List<String> imageUrls;

  DateTime? createdAt;
  DateTime? updatedAt;

  Car({
    required this.id,
    required this.ownerId,
    required this.licensePlate,
    required this.brand,
    required this.model,
    required this.year,
    required this.pricePerDay,
    required this.description,
    this.available = true,
    this.vehicleType = 'Car',
    this.vehicleSubType = 'Sedan',
    this.fuelType = 'Petrol',
    this.pickupLocation,
    this.imageUrls = const [],
    this.createdAt,
    this.updatedAt,
  });

  /// Convenience getters for pickup location.
  double? get pickupLatitude => pickupLocation?['latitude'];
  double? get pickupLongitude => pickupLocation?['longitude'];
  bool get hasPickupLocation =>
      pickupLocation != null &&
      pickupLatitude != null &&
      pickupLongitude != null;

  /// User-friendly category subtitle (e.g., 'SUV • Diesel' or 'Bike • Petrol').
  String get typeAndFuel => '$vehicleSubType • $fuelType';

  Car copyWith({
    String? licensePlate,
    String? brand,
    String? model,
    int? year,
    double? pricePerDay,
    String? description,
    bool? available,
    String? vehicleType,
    String? vehicleSubType,
    String? fuelType,
    Map<String, double>? Function()? pickupLocation,
    List<String>? imageUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Car(
      id: id,
      ownerId: ownerId,
      licensePlate: licensePlate ?? this.licensePlate,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      description: description ?? this.description,
      available: available ?? this.available,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleSubType: vehicleSubType ?? this.vehicleSubType,
      fuelType: fuelType ?? this.fuelType,
      pickupLocation: pickupLocation != null ? pickupLocation() : this.pickupLocation,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Car.fromMap(String id, Map<String, dynamic> data) {
    // Parse pickupLocation safely.
    Map<String, double>? pickup;
    if (data['pickupLocation'] is Map) {
      final raw = data['pickupLocation'] as Map;
      final lat = (raw['latitude'] as num?)?.toDouble();
      final lng = (raw['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        pickup = {'latitude': lat, 'longitude': lng};
      }
    }

    // Parse vehicleType & vehicleSubType with backward compatibility.
    final rawType = (data['vehicleType'] ?? 'Car').toString();
    String vType = rawType;
    String subType = (data['vehicleSubType'] ?? '').toString();

    if (subType.isEmpty) {
      if (rawType == 'Bike' || rawType == 'Scooter') {
        vType = 'TwoWheeler';
        subType = rawType;
      } else if (carSubTypes.contains(rawType)) {
        vType = 'Car';
        subType = rawType;
      } else {
        vType = 'Car';
        subType = 'Sedan';
      }
    }

    // Parse image URLs.
    List<String> images = [];
    if (data['imageUrls'] is List) {
      images = (data['imageUrls'] as List).map((e) => e.toString()).toList();
    }

    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return Car(
      id: id,
      ownerId: data['ownerId'] ?? '',
      licensePlate: data['licensePlate'] ?? '',
      brand: data['brand'] ?? '',
      model: data['model'] ?? '',
      year: data['year'] ?? 0,
      pricePerDay: (data['pricePerDay'] ?? 0).toDouble(),
      description: data['description'] ?? '',
      available: data['available'] ?? true,
      vehicleType: vType,
      vehicleSubType: subType,
      fuelType: data['fuelType'] ?? 'Petrol',
      pickupLocation: pickup,
      imageUrls: images,
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'licensePlate': licensePlate,
      'brand': brand,
      'model': model,
      'year': year,
      'pricePerDay': pricePerDay,
      'description': description,
      'available': available,
      'vehicleType': vehicleType,
      'vehicleSubType': vehicleSubType,
      'fuelType': fuelType,
      'pickupLocation': pickupLocation,
      'imageUrls': imageUrls,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}