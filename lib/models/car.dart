class Car {
  String id;
  String licensePlate;
  String brand;
  String model;
  int year;
  double pricePerDay;
  String description;
  bool available;

  Car({
    required this.id,
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
      licensePlate: licensePlate ?? this.licensePlate,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      description: description ?? this.description,
      available: available ?? this.available,
    );
  }
}