import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/car.dart';

/// Acts as our in-memory "backend" for cars.
/// Later this can be swapped with real API calls without
/// changing how screens use it.
class CarService extends ChangeNotifier {
  final CollectionReference<Map<String, dynamic>> _carsRef =
      FirebaseFirestore.instance.collection('cars');

  late List<Car> _cars = [];
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

  List<Car> carsByOwner(String ownerId) =>
      _cars.where((c) => c.ownerId == ownerId).toList();

  Car getById(String id) => _cars.firstWhere((c) => c.id == id);

  Future<bool> isPlateTaken(String plate, {String? excludeId}) async {
    final normalized = plate.trim().toUpperCase();
    final query = await _carsRef.where('licensePlate', isEqualTo: normalized).get();
    return query.docs.any((doc) => doc.id != excludeId);
  }

  Future<void> addCar(Car car) async {
    await _carsRef.add(car.toMap());
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