import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class DeviceLocationService {
  static final Geocoding _geocoding = Geocoding();

  static Future<String> getCurrentLocationLabel() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return 'Location services are off';
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return 'Location permission unavailable';
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
        ),
      );

      final placemarks =
      await _geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) {
        return 'Current location unavailable';
      }

      final place = placemarks.first;

      final parts = <String>[
        place.name?.trim() ?? '',
        // place.subLocality?.trim() ?? '',
        place.locality?.trim() ?? '',
        // place.subAdministrativeArea?.trim() ?? '',
        // place.administrativeArea?.trim() ?? '',
        place.postalCode?.trim() ?? '',
      ];

      final uniqueParts = <String>[];

      for (final part in parts) {
        if (part.isNotEmpty &&
            !uniqueParts.contains(part)) {
          uniqueParts.add(part);
        }
      }

      return uniqueParts.isEmpty
          ? 'Current location detected'
          : uniqueParts.join(', ');
    } catch (e) {
      return 'Unable to detect location';
    }
  }
}