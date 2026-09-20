import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/car.dart';

/// Acts as our in-memory "backend" for cars.
/// Later this can be swapped with real API calls without
/// changing how screens use it.
class CarService extends ChangeNotifier {
  final _uuid = const Uuid();

  final List<Car> _cars = [
    Car(
      id: const Uuid().v4(),
      licensePlate: 'GJ06AB1234',
      brand: 'Toyota',
      model: 'Corolla',
      year: 2021,
      pricePerDay: 35.0,
      description: 'Fuel-efficient sedan, great for city driving.',
      available: true,
    ),
    Car(
      id: const Uuid().v4(),
      licensePlate: 'GJ06CD5678',
      brand: 'Honda',
      model: 'Civic',
      year: 2022,
      pricePerDay: 40.0,
      description: 'Comfortable and reliable compact car.',
      available: false,
    ),
    Car(
      id: const Uuid().v4(),
      licensePlate: 'GJ06EF9012',
      brand: 'Ford',
      model: 'Mustang',
      year: 2023,
      pricePerDay: 90.0,
      description: 'Sporty muscle car, weekend favorite.',
      available: true,
    ),
  ];

  List<Car> get cars => List.unmodifiable(_cars);

  List<Car> get availableCars => _cars.where((c) => c.available).toList();

  List<Car> get rentedCars => _cars.where((c) => !c.available).toList();

  Car getById(String id) => _cars.firstWhere((c) => c.id == id);

  /// Returns true if the plate already exists on another car.
  /// Pass [excludeId] when editing a car, so it can keep its own plate.
  bool isPlateTaken(String plate, {String? excludeId}) {
    final normalized = plate.trim().toUpperCase();
    return _cars.any(
          (c) => c.licensePlate.toUpperCase() == normalized && c.id != excludeId,
    );
  }

  void addCar(Car car) {
    _cars.add(car);
    notifyListeners();
  }

  void updateCar(Car updatedCar) {
    final index = _cars.indexWhere((c) => c.id == updatedCar.id);
    if (index != -1) {
      _cars[index] = updatedCar;
      notifyListeners();
    }
  }

  void toggleAvailability(String id) {
    final index = _cars.indexWhere((c) => c.id == id);
    if (index != -1) {
      _cars[index] = _cars[index].copyWith(available: !_cars[index].available);
      notifyListeners();
    }
  }

  void removeCar(String id) {
    _cars.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  String newId() => _uuid.v4();
}