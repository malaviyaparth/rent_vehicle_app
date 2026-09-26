import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/car.dart';
import '../models/vehicle_enums.dart';
import '../models/vehicle_filter_model.dart';
import '../utils/distance_utils.dart';

/// Firestore-backed vehicle service.
/// Listens to the `cars` collection in real time and provides
/// multi-factor filtering, search, sorting, and management operations.
class CarService extends ChangeNotifier {
  final CollectionReference<Map<String, dynamic>> _carsRef =
      FirebaseFirestore.instance.collection('cars');

  List<Car> _cars = [];
  bool _loading = true;
  StreamSubscription? _subscription;

  CarService() {
    _subscription = _carsRef.snapshots().listen((snapshot) {
      final List<Car> loadedCars = [];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final brand = (data['brand'] ?? '').toString().toLowerCase();
        final model = (data['model'] ?? '').toString().toLowerCase();
        final year = data['year']?.toString() ?? '';
        final type = (data['vehicleType'] ?? '').toString().toLowerCase();

        // Check for 'Bike 2016' dummy record
        final isBike2016 = (year == '2016' && (brand.contains('bike') || model.contains('bike') || type.contains('bike'))) ||
            (brand == 'bike' && year == '2016') ||
            (model == 'bike' && year == '2016') ||
            (year == '2016');

        if (isBike2016) {
          doc.reference.delete().catchError((_) {});
          continue;
        }

        loadedCars.add(Car.fromMap(doc.id, data));
      }

      _cars = loadedCars;
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

  /// Cars belonging to a specific owner.
  List<Car> carsByOwner(String ownerId) =>
      _cars.where((c) => c.ownerId == ownerId).toList();

  Car getById(String id) => _cars.firstWhere((c) => c.id == id);

  Car? tryGetById(String id) {
    try {
      return _cars.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Returns true if the plate already exists on another car.
  Future<bool> isPlateTaken(String plate, {String? excludeId}) async {
    final normalized = plate.trim().toUpperCase();
    final query = await _carsRef.where('licensePlate', isEqualTo: normalized).get();
    return query.docs.any((doc) => doc.id != excludeId);
  }

  Future<void> addCar(Car car) async {
    final docRef = await _carsRef.add(car.toMap());

    final addedCar = car.copyWith();
    addedCar.id = docRef.id;

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
    await _carsRef.doc(id).update({
      'available': !car.available,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setAvailability(String id, bool available) async {
    await _carsRef.doc(id).update({
      'available': available,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeCar(String id) async {
    await _carsRef.doc(id).delete();
  }

  /// Applies all filter conditions (AND logic) and returns results
  /// sorted according to [filter.sortBy].
  List<MapEntry<Car, double?>> filterCars(
    VehicleFilter filter, {
    double? userLat,
    double? userLng,
    Set<String>? rentedCarIds,
  }) {
    final bool hasUserLocation = userLat != null && userLng != null;

    final List<MapEntry<Car, double?>> results = [];

    for (final car in _cars) {
      final isRented = !car.available || (rentedCarIds != null && rentedCarIds.contains(car.id));

      // --- Availability filter ---
      if (filter.availableOnly && isRented) continue;

      // --- Text search (Brand, Model, SubType) ---
      if (filter.searchQuery.isNotEmpty) {
        final q = filter.searchQuery.toLowerCase();
        final matchesBrand = car.brand.toLowerCase().contains(q);
        final matchesModel = car.model.toLowerCase().contains(q);
        final matchesSubType = car.vehicleSubType.toLowerCase().contains(q);
        if (!matchesBrand && !matchesModel && !matchesSubType) continue;
      }

      // --- Vehicle category filter (Car or TwoWheeler) ---
      if (filter.vehicleCategory != null) {
        final carCat = vehicleCategory(car.vehicleType);
        if (carCat != filter.vehicleCategory) continue;

        // Sub-type filter
        if (filter.carSubType != null) {
          if (car.vehicleSubType != filter.carSubType) continue;
        }
      } else if (filter.carSubType != null) {
        if (car.vehicleSubType != filter.carSubType) continue;
      }

      // --- Fuel type filter ---
      if (filter.fuelType != null && car.fuelType != filter.fuelType) continue;

      // --- Price range filter ---
      if (filter.minPrice != null && car.pricePerDay < filter.minPrice!) continue;
      if (filter.maxPrice != null && car.pricePerDay > filter.maxPrice!) continue;

      // --- Distance filter ---
      double? distance;
      if (hasUserLocation && car.hasPickupLocation) {
        distance = calculateDistanceKm(
          userLat,
          userLng,
          car.pickupLatitude!,
          car.pickupLongitude!,
        );
        if (distance > filter.radiusKm) continue;
      } else if (hasUserLocation && !car.hasPickupLocation) {
        distance = null;
      }

      final effectiveCar = isRented && car.available ? car.copyWith(available: false) : car;
      results.add(MapEntry(effectiveCar, distance));
    }

    // --- Sorting ---
    switch (filter.sortBy) {
      case VehicleSort.nearest:
        if (hasUserLocation) {
          results.sort((a, b) {
            if (a.value == null && b.value == null) return 0;
            if (a.value == null) return 1;
            if (b.value == null) return -1;
            return a.value!.compareTo(b.value!);
          });
        }
        break;

      case VehicleSort.priceLowToHigh:
        results.sort((a, b) => a.key.pricePerDay.compareTo(b.key.pricePerDay));
        break;

      case VehicleSort.priceHighToLow:
        results.sort((a, b) => b.key.pricePerDay.compareTo(a.key.pricePerDay));
        break;

      case VehicleSort.newest:
        results.sort((a, b) {
          if (a.key.createdAt != null && b.key.createdAt != null) {
            return b.key.createdAt!.compareTo(a.key.createdAt!);
          }
          return b.key.year.compareTo(a.key.year);
        });
        break;
    }

    return results;
  }
}