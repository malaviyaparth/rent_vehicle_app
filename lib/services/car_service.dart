import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/car.dart';

/// Firestore-backed car "backend".
/// Listens to the `cars` collection in real time and exposes it the same
/// way the old in-memory version did, so screens barely had to change.
class CarService extends ChangeNotifier {
  final CollectionReference<Map<String, dynamic>> _carsRef =
  FirebaseFirestore.instance.collection('cars');

  List<Car> _cars = [];
  bool _loading = true;
  StreamSubscription? _subscription;

  CarService() {
    _subscription = _carsRef.snapshots().listen((snapshot) {
      _cars = snapshot.docs.map((doc) => Car.fromMap(doc.id, doc.data())).toList();
      _loading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  bool get isLoading => _loading;

  List<Car> get cars => List.unmodifiable(_cars);

  List<Car> get availableCars => _cars.where((c) => c.available).toList();

  List<Car> get rentedCars => _cars.where((c) => !c.available).toList();

  /// Cars belonging to a specific owner (used for the "My Cars" section).
  List<Car> carsByOwner(String ownerId) =>
      _cars.where((c) => c.ownerId == ownerId).toList();

  Car getById(String id) => _cars.firstWhere((c) => c.id == id);

  /// Returns true if the plate already exists on another car.
  /// Pass [excludeId] when editing a car, so it can keep its own plate.
  Future<bool> isPlateTaken(String plate, {String? excludeId}) async {
    final normalized = plate.trim().toUpperCase();
    final query = await _carsRef.where('licensePlate', isEqualTo: normalized).get();
    return query.docs.any((doc) => doc.id != excludeId);
  }

  Future<void> addCar(Car car) async {
    final docRef = await _carsRef.add(car.toMap());

    final addedCar = Car(
      id: docRef.id,
      ownerId: car.ownerId,
      licensePlate: car.licensePlate,
      brand: car.brand,
      model: car.model,
      year: car.year,
      pricePerDay: car.pricePerDay,
      description: car.description,
      available: car.available,
    );
    if (!_cars.any((c) => c.id == addedCar.id)) {
      _cars = [..._cars, addedCar];
      notifyListeners();
    }
  }

  Future<void> updateCar(Car updatedCar) async {
    await _carsRef.doc(updatedCar.id).update(updatedCar.toMap());
  }

  Future<void> toggleAvailability(String id) async {
    final car = getById(id);
    await _carsRef.doc(id).update({'available': !car.available});
  }

  Future<void> removeCar(String id) async {
    await _carsRef.doc(id).delete();
  }
}