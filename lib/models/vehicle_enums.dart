/// Central definitions for vehicle types and fuel types.
///
/// Supported top-level vehicleTypes:
/// - 'Car'
/// - 'TwoWheeler'
///
/// Supported sub-types:
/// - Car: Sedan, SUV, Hatchback, MUV, Coupe, Convertible
/// - Two-Wheeler: Bike, Scooter
///
/// Supported fuel types:
/// - Petrol, Diesel, Electric, CNG, Hybrid
library;

/// Top-level vehicle categories/types.
const List<String> vehicleTypes = ['Car', 'TwoWheeler'];

/// Legacy alias for compatibility with existing UI.
const List<String> vehicleCategories = ['Car', 'TwoWheeler'];

/// Car sub-types.
const List<String> carSubTypes = [
  'Sedan',
  'SUV',
  'Hatchback',
  'MUV',
  'Coupe',
  'Convertible',
];

/// Two-Wheeler sub-types.
const List<String> twoWheelerSubTypes = [
  'Bike',
  'Scooter',
];

/// All vehicle sub-types combined.
const List<String> allVehicleTypes = [
  ...carSubTypes,
  ...twoWheelerSubTypes,
];

/// Supported fuel types.
const List<String> fuelTypes = [
  'Petrol',
  'Diesel',
  'Electric',
  'CNG',
  'Hybrid',
];

/// Returns the sub-types appropriate for a given top-level category.
List<String> subTypesForCategory(String category) {
  if (category == 'Car') return carSubTypes;
  if (category == 'TwoWheeler' || category == 'Bike' || category == 'Scooter') {
    return twoWheelerSubTypes;
  }
  return [];
}

/// Returns the top-level category ('Car' or 'TwoWheeler') for a given type/sub-type string.
///
/// Example: `vehicleCategory('SUV')` → `'Car'`
///          `vehicleCategory('Bike')` → `'TwoWheeler'`
String vehicleCategory(String typeOrSubType) {
  if (typeOrSubType == 'TwoWheeler' || twoWheelerSubTypes.contains(typeOrSubType)) {
    return 'TwoWheeler';
  }
  return 'Car';
}
