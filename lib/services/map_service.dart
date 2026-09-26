import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

/// Utility for launching Google Maps navigation to a destination.
class MapService {
  MapService._();

  /// Opens Google Maps (or browser fallback) with navigation directions
  /// to [destLat], [destLng].
  ///
  /// Returns `true` if the URL was launched successfully.
  static Future<bool> launchNavigation(double destLat, double destLng) async {
    // Google Maps URL — works on Android (opens the Maps app if installed)
    // and on web (opens in browser).
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=$destLat,$destLng'
      '&travelmode=driving',
    );

    try {
      final launched = await launchUrl(
        googleMapsUrl,
        mode: LaunchMode.externalApplication,
      );
      return launched;
    } catch (e) {
      debugPrint('MapService.launchNavigation error: $e');
      return false;
    }
  }

  /// Opens Google Maps centered on a specific location (view only, no directions).
  static Future<bool> openLocationOnMap(double lat, double lng) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );

    try {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('MapService.openLocationOnMap error: $e');
      return false;
    }
  }
}
