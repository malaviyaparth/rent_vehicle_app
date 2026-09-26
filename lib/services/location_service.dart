import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Wraps the `geolocator` plugin, handling permission requests and errors.
///
/// Only fetches location on demand — no continuous background tracking.
class LocationService extends ChangeNotifier {
  Position? _currentPosition;
  String? _errorMessage;
  bool _loading = false;

  Position? get currentPosition => _currentPosition;
  double? get latitude => _currentPosition?.latitude;
  double? get longitude => _currentPosition?.longitude;
  bool get hasLocation => _currentPosition != null;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _loading;

  /// Attempts to get the user's current GPS position.
  ///
  /// Returns the [Position] on success, or `null` on failure.
  /// Sets [errorMessage] with a user-friendly explanation on failure.
  Future<Position?> getCurrentPosition() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Check if location services are enabled.
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _errorMessage = 'Location services are disabled. '
            'Please enable GPS in your device settings.';
        _loading = false;
        notifyListeners();
        return null;
      }

      // 2. Check / request permission.
      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _errorMessage = 'Location permission was denied. '
              'Please allow location access to find nearby vehicles.';
          _loading = false;
          notifyListeners();
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _errorMessage = 'Location permission is permanently denied. '
            'Please enable it from your device settings.';
        _loading = false;
        notifyListeners();
        return null;
      }

      // 3. Get the current position.
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      _errorMessage = null;
      _loading = false;
      notifyListeners();
      return _currentPosition;
    } catch (e) {
      _errorMessage = 'Could not determine your location. '
          'Please check your settings and try again.';
      debugPrint('LocationService error: $e');
      _loading = false;
      notifyListeners();
      return null;
    }
  }

  /// Clears any stored position and error.
  void clearLocation() {
    _currentPosition = null;
    _errorMessage = null;
    notifyListeners();
  }
}
