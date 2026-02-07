import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';

class LocationService {
  static Position? _currentPosition;
  static String? _currentAddress;
  static Timer? _locationRefreshTimer;

  // Request location permission
  static Future<bool> requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('❌ Location services are disabled.');
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('❌ Location permissions are denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('❌ Location permissions are permanently denied');
      return false;
    }

    print('✅ Location permissions granted');
    return true;
  }

  // Get current location
  static Future<Map<String, dynamic>?> getCurrentLocation() async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        return null;
      }

      print('📍 Getting current location...');

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).timeout(const Duration(seconds: 15));

      _currentPosition = position;

      // Get address from coordinates
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          _currentAddress = [
            placemark.street,
            placemark.locality,
            placemark.administrativeArea,
            placemark.country
          ].where((e) => e != null && e.isNotEmpty).join(', ');
        }
      } catch (e) {
        print('❌ Error getting address: $e');
        _currentAddress = 'Unknown Location';
      }

      final locationData = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'location': _currentAddress ?? 'Unknown Location',
        'accuracy': position.accuracy,
        'timestamp': position.timestamp?.toIso8601String(),
      };

      print('📍 Current location: $locationData');
      return locationData;
    } on TimeoutException catch (e) {
      print('❌ Location timeout: $e');
      return null;
    } catch (e) {
      print('❌ Error getting location: $e');
      return null;
    }
  }

  // Get cached location data
  static Map<String, dynamic>? getCachedLocation() {
    if (_currentPosition != null) {
      return {
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
        'location': _currentAddress ?? 'Unknown Location',
        'accuracy': _currentPosition!.accuracy,
        'timestamp': _currentPosition!.timestamp?.toIso8601String(),
      };
    }
    return null;
  }

  // Start continuous location updates
  static void startContinuousLocationUpdates({
    Duration interval = const Duration(minutes: 2),
    Function(Map<String, dynamic>)? onLocationUpdate,
  }) {
    stopContinuousLocationUpdates();

    print(
        '🔄 Starting continuous location updates every ${interval.inMinutes} minutes');

    _locationRefreshTimer = Timer.periodic(interval, (timer) async {
      try {
        final location = await getCurrentLocation();
        if (location != null && onLocationUpdate != null) {
          onLocationUpdate(location);
        }
      } catch (e) {
        print('❌ Error in continuous location update: $e');
      }
    });
  }

  // Stop continuous location updates
  static void stopContinuousLocationUpdates() {
    if (_locationRefreshTimer != null) {
      _locationRefreshTimer!.cancel();
      _locationRefreshTimer = null;
      print('🛑 Continuous location updates stopped');
    }
  }

  // Update location in background
  static Future<void> updateLocationInBackground() async {
    try {
      await getCurrentLocation();
      print('📍 Location updated in background');
    } catch (e) {
      print('❌ Error updating location in background: $e');
    }
  }

  // Clear cached location
  static void clearCache() {
    _currentPosition = null;
    _currentAddress = null;
    stopContinuousLocationUpdates();
    print('🗑️ Location cache cleared');
  }

  // Check if location is available
  static bool hasLocationData() {
    return _currentPosition != null;
  }

  // Get location settings for high accuracy
  static LocationSettings getLocationSettings() {
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
  }
}
