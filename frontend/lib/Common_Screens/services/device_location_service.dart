
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

      final locality = place.locality?.trim() ?? '';
      final subLocality = place.subLocality?.trim() ?? '';
      final administrativeArea =
          place.administrativeArea?.trim() ?? '';

      final parts = <String>[];

      if (subLocality.isNotEmpty) {
        parts.add(subLocality);
      }

      if (locality.isNotEmpty) {
        parts.add(locality);
      } else if (administrativeArea.isNotEmpty) {
        parts.add(administrativeArea);
      }

      return parts.isEmpty
          ? 'Current location detected'
          : parts.join(', ');
    } catch (e) {
      return 'Unable to detect location';
    }
  }
}
