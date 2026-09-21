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
  });

  Car copyWith({
    String? licensePlate,
    String? brand,
    String? model,
    int? year,
    double? pricePerDay,
    String? description,
    bool? available,
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
    );
  }

  factory Car.fromMap(String id, Map<String, dynamic> data) {
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
    };
  }
}