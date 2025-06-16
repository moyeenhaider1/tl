import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:travel_lens/core/errors/app_exception.dart';

class LocationService {
  /// Get the current device location
  Future<Position> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw AppException('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw AppException('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw AppException(
            'Location permissions are permanently denied, we cannot request permissions');
      }

      return await Geolocator.getCurrentPosition();
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (e is AppException) {
        rethrow;
      }
      throw AppException('Failed to get location: $e');
    }
  }

  /// Get place name from coordinates
  Future<String> getPlaceFromCoordinates(
      double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        // Build a meaningful place name from components
        final components = [
          place.name,
          place.thoroughfare,
          place.locality,
          place.administrativeArea,
          place.country,
        ]
            .where((component) =>
                component != null &&
                component.isNotEmpty &&
                component != 'Unnamed Road')
            .toList();

        if (components.isEmpty) {
          return 'Unknown location';
        }

        return components.join(', ');
      }

      return 'Unknown location';
    } catch (e) {
      debugPrint('Error getting place name: $e');
      return 'Unknown location';
    }
  }
}
