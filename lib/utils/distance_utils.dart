import 'dart:math';

/// Calculates the great-circle distance between two GPS coordinates
/// using the Haversine formula.
///
/// Returns the distance in **kilometers**.
double calculateDistanceKm(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  const double earthRadiusKm = 6371.0;

  final double dLat = _degreesToRadians(lat2 - lat1);
  final double dLon = _degreesToRadians(lon2 - lon1);

  final double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_degreesToRadians(lat1)) *
          cos(_degreesToRadians(lat2)) *
          sin(dLon / 2) *
          sin(dLon / 2);

  final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return earthRadiusKm * c;
}

double _degreesToRadians(double degrees) => degrees * pi / 180;

/// Formats a distance in km into a human-readable string.
///
/// Examples:
/// - `0.45` → `"450 m"`
/// - `2.137` → `"2.1 km"`
String formatDistance(double km) {
  if (km < 1) {
    return '${(km * 1000).round()} m';
  }
  return '${km.toStringAsFixed(1)} km';
}
