import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:sango/services/storage_service.dart';

class DriverLocationService {
  static DriverLocationService? _instance;
  static DriverLocationService get instance =>
      _instance ??= DriverLocationService._();

  DriverLocationService._();

  Timer? _locationTimer;
  Location location = Location();
  final String _apiKey =
      'AIzaSyBXaMspN9XlQhkUHiyLCXkQoEurPKrMeog'; // Replace with your actual API key
  final String _baseUrl =
      'https://mis.sangotaxi.com/api/driver/update_location';

  bool _isRunning = false;

  /// Start sending location updates every 10 minutes
  Future<void> startLocationUpdates() async {
    if (_isRunning) return;

    _isRunning = true;

    // Send location immediately when starting
    await _sendCurrentLocation();

    // Set up periodic updates every 10 minutes
    _locationTimer = Timer.periodic(
      const Duration(minutes: 10),
      (timer) async {
        await _sendCurrentLocation();
      },
    );
  }

  /// Stop location updates
  void stopLocationUpdates() {
    _isRunning = false;
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  /// Send current location to the server
  Future<void> _sendCurrentLocation() async {
    try {
      // Check if location service is enabled
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          print('Location service not enabled');
          return;
        }
      }

      // Check permissions
      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          print('Location permission not granted');
          return;
        }
      }

      // Get current location
      LocationData locationData = await location.getLocation();
      final driverData = await StorageService.getDriverData();
      // Get driver ID from storage
      final driverId =
          driverData?['driver_id']?.toString(); // Assuming you have this method

      if (driverId == null) {
        print('Driver ID not found');
        return;
      }

      // Get address name using reverse geocoding
      String locationName = await _getReverseGeocodedAddress(
        locationData.latitude!,
        locationData.longitude!,
      );

      // Prepare request body
      final requestBody = {
        "driver_id": int.parse(driverId),
        "latitude": locationData.latitude.toString(),
        "longitude": locationData.longitude.toString(),
        "location": locationName,
      };
      print("Request body: $requestBody");
      // Send to server
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        print('Location updated successfully: ${response.body}');
      } else {
        print(
            'Failed to update location: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error sending location: $e');
    }
  }

  /// Get address from coordinates using reverse geocoding
  Future<String> _getReverseGeocodedAddress(double lat, double lng) async {
    final String url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$_apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['results'] != null && data['results'].isNotEmpty) {
          final result = data['results'][0];
          String formattedAddress = result['formatted_address'];

          // Get a shorter, more readable address
          String shortAddress =
              _extractShortAddress(result['address_components']);

          // Return the short address if available, otherwise the full formatted address
          return shortAddress.isNotEmpty ? shortAddress : formattedAddress;
        }
      }
    } catch (e) {
      print('Error in reverse geocoding: $e');
    }

    // Fallback to coordinates if reverse geocoding fails
    return 'Location (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})';
  }

  /// Helper method to extract a shorter, more readable address
  String _extractShortAddress(List addressComponents) {
    String streetNumber = '';
    String route = '';
    String locality = '';
    String sublocality = '';

    for (var component in addressComponents) {
      List<String> types = List<String>.from(component['types']);

      if (types.contains('street_number')) {
        streetNumber = component['long_name'];
      } else if (types.contains('route')) {
        route = component['long_name'];
      } else if (types.contains('locality')) {
        locality = component['long_name'];
      } else if (types.contains('sublocality') ||
          types.contains('sublocality_level_1')) {
        sublocality = component['long_name'];
      }
    }

    // Build a concise address
    List<String> addressParts = [];

    if (streetNumber.isNotEmpty && route.isNotEmpty) {
      addressParts.add('$streetNumber $route');
    } else if (route.isNotEmpty) {
      addressParts.add(route);
    }

    if (sublocality.isNotEmpty) {
      addressParts.add(sublocality);
    } else if (locality.isNotEmpty) {
      addressParts.add(locality);
    }

    return addressParts.join(', ');
  }
}
