import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sango/services/routingMapServices.dart';
import 'package:sango/l10n/l10n.dart'; // Add this import
import 'complete_trip_bottom_sheet.dart';
import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;

class OnTripRideCard extends StatefulWidget {
  final Map<String, dynamic> trip;
  final Function()? onTripCompleted;

  const OnTripRideCard({
    Key? key,
    required this.trip,
    this.onTripCompleted,
  }) : super(key: key);

  @override
  State<OnTripRideCard> createState() => _OnTripRideCardState();
}

class _OnTripRideCardState extends State<OnTripRideCard> {
  GoogleMapController? _mapController;
  bool _isLoadingRoute = false;
  RouteResult? _routeResult;
  int _currentStepIndex = 0;
  Timer? _navigationTimer;
  bool _isNavigating = false;
  String _navigationInstruction = "Preparing navigation...";

  Location _location = Location();
  StreamSubscription<LocationData>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    getCurrentLocationAndAddress();
    // Start location tracking
    _startLocationTracking();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _navigationTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // Start tracking location changes
  void _startLocationTracking() async {
    try {
      // Configure location service
      await _location.changeSettings(
        accuracy: LocationAccuracy.high,
        interval: 10000, // Update every 10 seconds
        distanceFilter: 10, // Minimum distance (meters) before updates
      );

      _locationSubscription =
          _location.onLocationChanged.listen((LocationData currentLocation) {
        // Print location updates to terminal
        print('---------------------------------------');
        print('📍 LOCATION UPDATE:');
        print('   Latitude:  ${currentLocation.latitude}');
        print('   Longitude: ${currentLocation.longitude}');
        print('   Accuracy:  ${currentLocation.accuracy} meters');
        print('   Speed:     ${currentLocation.speed} m/s');
        print('   Time:      ${DateTime.now().toString()}');
        print('---------------------------------------');
      });
    } catch (e) {
      print('Error starting location tracking: $e');
    }
  }

  Future<void> getCurrentLocationAndAddress() async {
    final location = Location();

    try {
      // Check if service is enabled
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          print('Location services are disabled.');
          return;
        }
      }

      // Check for permission
      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          print('Location permission not granted.');
          return;
        }
      }

      // Get location data
      print('Getting current location...');
      LocationData locationData = await location.getLocation();
      double? latitude = locationData.latitude;
      double? longitude = locationData.longitude;

      // Print coordinates clearly
      print('===================================');
      print('CURRENT LOCATION:');
      print('   Latitude:  $latitude');
      print('   Longitude: $longitude');
      print('   Accuracy:  ${locationData.accuracy} meters');
      print('   Time:      ${DateTime.now().toString()}');
      print('===================================\n');

      if (latitude == null || longitude == null) {
        print(' Failed to get coordinates.');
        return;
      }

      // Use your Google Maps Geocoding API key
      const String apiKey = 'AIzaSyBXaMspN9XlQhkUHiyLCXkQoEurPKrMeog';
      String geocodeUrl =
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$apiKey';

      final response = await http.get(Uri.parse(geocodeUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          String formattedAddress = data['results'][0]['formatted_address'];
          print('Latitude: $latitude');
          print('Longitude: $longitude');
          print('Address: $formattedAddress');
        } else {
          print('No address found for coordinates.');
        }
      } else {
        print('Geocoding API error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting location/address: $e');
    }
  }

  Future<void> _showCompleteTripBottomSheet() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CompleteTripBottomSheet(
        trip: widget.trip,
        onTripCompleted: widget.onTripCompleted,
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanedNumber = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: cleanedNumber,
    );

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        throw 'Could not launch $launchUri';
      }
    } catch (e) {
      print('Could not launch $launchUri: $e');
    }
  }

  // Improved map dialog with navigation features
  void _showMapDialog() {
    final s = S.of(context)!;
    final double? fromLat = _parseDouble(widget.trip['pickup_lat']);
    final double? fromLng = _parseDouble(widget.trip['pickup_long']);
    final double? toLat = _parseDouble(widget.trip['dropoff_lat']);
    final double? toLng = _parseDouble(widget.trip['dropoff_long']);

    // Check for missing coordinates first
    if (fromLat == null || fromLng == null || toLat == null || toLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange,
          content: Text(s.locationCoordsNotAvailable),
        ),
      );
      return;
    }

    // Show the dialog and load route
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.all(10),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.8,
                child: Column(
                  children: [
                    // Navigation Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Navigation',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_routeResult != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      '${_routeResult!.distance} (${_routeResult!.duration})',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              _stopNavigation();
                              Navigator.of(context).pop();
                            },
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                    ),

                    // Turn-by-turn instruction bar
                    if (_routeResult != null && _routeResult!.steps.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: Colors.grey[800],
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.directions,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _navigationInstruction,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Map Content with Loading Overlay
                    Expanded(
                      child: Stack(
                        children: [
                          GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(fromLat, fromLng),
                              zoom: 15.0,
                              tilt: 45.0, // Add tilt for better navigation view
                            ),
                            onMapCreated: (GoogleMapController controller) {
                              _mapController = controller;
                              _loadRouteForNavigation(
                                fromLat,
                                fromLng,
                                toLat,
                                toLng,
                                setDialogState,
                              );
                            },
                            markers: _createNavigationMarkers(
                                fromLat, fromLng, toLat, toLng),
                            polylines: _createDetailedPolylines(),
                            mapType: MapType.normal,
                            myLocationEnabled: true,
                            myLocationButtonEnabled: true,
                            zoomControlsEnabled: true,
                            compassEnabled: true,
                            trafficEnabled: true,
                          ),

                          // Loading indicator
                          if (_isLoadingRoute)
                            Container(
                              color: Colors.black54,
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Calculating best route...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Navigation Controls
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.grey[200],
                      child: Column(
                        children: [
                          // First row - Toggle navigation mode
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: Icon(
                                _isNavigating ? Icons.pause : Icons.navigation,
                                color: Colors.white,
                                size: 16,
                              ),
                              label: Text(
                                _isNavigating
                                    ? 'Pause'
                                    : 'Démarrer la navigation',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isNavigating
                                    ? Colors.orange
                                    : Color(0xFFF5141E),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                              ),
                              onPressed: () {
                                if (_routeResult == null) return;

                                setDialogState(() {
                                  if (_isNavigating) {
                                    _stopNavigation();
                                  } else {
                                    _startNavigation(setDialogState);
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Second row - Launch external navigation app
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.open_in_new,
                                  color: Colors.white, size: 16),
                              label: const Text('Google Maps',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                              ),
                              onPressed: () => _launchExternalNavigation(
                                  fromLat, fromLng, toLat, toLng),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Location footer
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.trip_origin,
                                  color: Colors.green, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.trip['trip_pickup']?.toString() ??
                                      widget.trip['pickup_location']
                                          ?.toString() ??
                                      'Unknown pickup',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  color: Colors.red, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.trip['trip_dropoff']?.toString() ??
                                      widget.trip['dropoff_location']
                                          ?.toString() ??
                                      'Unknown destination',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Load route information for navigation
  Future<void> _loadRouteForNavigation(double fromLat, double fromLng,
      double toLat, double toLng, StateSetter setState) async {
    setState(() {
      _isLoadingRoute = true;
    });

    try {
      // Use the route optimization service for best route
      final route = await RouteOptimizationService.getBestRoute(
        startLat: fromLat,
        startLng: fromLng,
        endLat: toLat,
        endLng: toLng,
        preference: RoutePreference.fastest,
      );

      if (route != null) {
        setState(() {
          _routeResult = route;
          _isLoadingRoute = false;

          if (route.steps.isNotEmpty) {
            _navigationInstruction = _stripHtmlTags(route.steps[0].instruction);
          }
        });

        // Fit the map to show the entire route
        _fitRouteOnMap(fromLat, fromLng, toLat, toLng);
      } else {
        setState(() {
          _isLoadingRoute = false;
        });

        // Show error if route couldn't be loaded
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content:
                Text('Could not calculate route. Using direct path instead.'),
          ),
        );
      }
    } catch (e) {
      print('Error loading route: $e');
      setState(() {
        _isLoadingRoute = false;
      });
    }
  }

  // Fit the map to show the entire route
  void _fitRouteOnMap(
      double fromLat, double fromLng, double toLat, double toLng) {
    if (_mapController == null) return;

    if (_routeResult != null && _routeResult!.polylinePoints.isNotEmpty) {
      // Calculate bounds that include all points in the route
      double minLat = double.infinity;
      double maxLat = -double.infinity;
      double minLng = double.infinity;
      double maxLng = -double.infinity;

      for (final point in _routeResult!.polylinePoints) {
        minLat = min(minLat, point.latitude);
        maxLat = max(maxLat, point.latitude);
        minLng = min(minLng, point.longitude);
        maxLng = max(maxLng, point.longitude);
      }

      final bounds = LatLngBounds(
        southwest: LatLng(minLat - 0.01, minLng - 0.01),
        northeast: LatLng(maxLat + 0.01, maxLng + 0.01),
      );

      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50.0),
      );
    } else {
      // Fallback if no route points are available
      final bounds = LatLngBounds(
        southwest: LatLng(
          min(fromLat, toLat) - 0.01,
          min(fromLng, toLng) - 0.01,
        ),
        northeast: LatLng(
          max(fromLat, toLat) + 0.01,
          max(fromLng, toLng) + 0.01,
        ),
      );

      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50.0),
      );
    }
  }

  // Start turn-by-turn navigation
  void _startNavigation(StateSetter setState) {
    if (_routeResult == null || _routeResult!.steps.isEmpty) return;

    _isNavigating = true;
    _currentStepIndex = 0;

    // Focus on first step
    _focusOnCurrentStep();

    // Update instruction
    setState(() {
      _navigationInstruction =
          _stripHtmlTags(_routeResult!.steps[_currentStepIndex].instruction);
    });

    // Start navigation timer that advances through steps
    _navigationTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (_currentStepIndex < _routeResult!.steps.length - 1) {
        _currentStepIndex++;
        _focusOnCurrentStep();

        setState(() {
          _navigationInstruction = _stripHtmlTags(
              _routeResult!.steps[_currentStepIndex].instruction);
        });
      } else {
        _stopNavigation();

        // Show arrival message
        setState(() {
          _navigationInstruction = "You have arrived at your destination";
        });
      }
    });
  }

  // Focus map on the current navigation step
  void _focusOnCurrentStep() {
    if (_mapController == null ||
        _routeResult == null ||
        _currentStepIndex >= _routeResult!.steps.length) return;

    final step = _routeResult!.steps[_currentStepIndex];

    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(step.startLocation, 17.0),
    );
  }

  // Stop turn-by-turn navigation
  void _stopNavigation() {
    _navigationTimer?.cancel();
    _navigationTimer = null;
    _isNavigating = false;
  }

  // Launch external navigation app (Google Maps)
  Future<void> _launchExternalNavigation(
      double fromLat, double fromLng, double toLat, double toLng) async {
    final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&origin=$fromLat,$fromLng&destination=$toLat,$toLng&travelmode=driving');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Could not launch Google Maps'),
          ),
        );
      }
    } catch (e) {
      print('Error launching navigation: $e');
    }
  }

  Set<Marker> _createNavigationMarkers(
      double fromLat, double fromLng, double toLat, double toLng) {
    Set<Marker> markers = {};

    // Origin marker
    markers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(fromLat, fromLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'Pickup Location',
          snippet: widget.trip['trip_pickup']?.toString() ??
              widget.trip['pickup_location']?.toString() ??
              'Pickup point',
        ),
      ),
    );

    // Destination marker
    markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: LatLng(toLat, toLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'Destination',
          snippet: widget.trip['trip_dropoff']?.toString() ??
              widget.trip['dropoff_location']?.toString() ??
              'Destination',
        ),
      ),
    );

    // Add current step marker if navigating
    if (_isNavigating &&
        _routeResult != null &&
        _currentStepIndex < _routeResult!.steps.length) {
      final currentStep = _routeResult!.steps[_currentStepIndex];
      markers.add(
        Marker(
          markerId: const MarkerId('current_step'),
          position: currentStep.startLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: 'Current Step',
            snippet: _stripHtmlTags(currentStep.instruction),
          ),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _createDetailedPolylines() {
    Set<Polyline> polylines = {};

    // If we have route data, use it to create a detailed polyline
    if (_routeResult != null && _routeResult!.polylinePoints.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: _routeResult!.polylinePoints,
          color: Colors.blue,
          width: 5,
        ),
      );

      // If in navigation mode, highlight the current step
      if (_isNavigating && _currentStepIndex < _routeResult!.steps.length) {
        final step = _routeResult!.steps[_currentStepIndex];
        polylines.add(
          Polyline(
            polylineId: const PolylineId('current_step'),
            points: [step.startLocation, step.endLocation],
            color: Colors.red,
            width: 8,
          ),
        );
      }
    }

    return polylines;
  }

  // Helper method to strip HTML tags from instructions
  String _stripHtmlTags(String htmlString) {
    // Simple regex to remove HTML tags
    return htmlString.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withOpacity(0.3), width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with trip status and duration
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Inline solution - directly in the Text widget
                      Text(
                        () {
                          String bookingCode =
                              widget.trip['booking_code'] ?? '';
                          String truncatedCode = (bookingCode.length > 13)
                              ? '${bookingCode.substring(0, 8)}...${bookingCode.substring(bookingCode.length - 5)}'
                              : bookingCode;
                          return s.tripWithId(truncatedCode);
                        }(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer, size: 14, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          widget.trip['trip_duration']?.toString() ??
                              '00:00:00',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Route information
              Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 2,
                        height: 30,
                        color: Colors.grey[300],
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.trip['trip_pickup']?.toString() ??
                              widget.trip['pickup_location']?.toString() ??
                              'Unknown pickup',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          widget.trip['trip_dropoff']?.toString() ??
                              widget.trip['dropoff_location']?.toString() ??
                              'Unknown destination',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Trip details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            'Started: ${_formatTime(widget.trip['started_at']?.toString())}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.directions_car,
                              size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.trip['distance']?.toString() ?? 'N/A'} km',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    '${widget.trip['payment_fee']?.toString() ?? widget.trip['estimated_price']?.toString() ?? 'N/A'} FCFA',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Client info and complete trip button - Two-row layout (Recommended)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    // First row - Client info
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.blue,
                          child:
                              Icon(Icons.person, size: 20, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${widget.trip['f_name']?.toString() ?? ''} ${widget.trip['l_name']?.toString() ?? ''}'
                                        .trim()
                                        .isNotEmpty
                                    ? '${widget.trip['f_name']?.toString() ?? ''} ${widget.trip['l_name']?.toString() ?? ''}'
                                        .trim()
                                    : 'Unknown Client',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              if (widget.trip['phone_number'] != null)
                                GestureDetector(
                                  onTap: () => _makePhoneCall(
                                      widget.trip['phone_number'].toString()),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.phone,
                                          size: 12, color: Colors.blue),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          widget.trip['phone_number']
                                              .toString(),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Second row - Complete trip button (on new line to prevent overflow)
                    if (widget.trip['can_complete_trip'] == true ||
                        widget.trip['is_trip_active'] == true) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _showCompleteTripBottomSheet,
                          icon: const Icon(
                            Icons.check_circle,
                            size: 12,
                            color: Colors.white,
                          ),
                          label: Text(s.complete,
                              style: const TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.schedule,
                                size: 16, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text(
                              s.inProgress,
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Add navigation button in actions
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _showMapDialog,
                      icon: const Icon(Icons.navigation, size: 12),
                      label: Text(
                        s.navigateToPickup,
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(String? dateTimeString) {
    if (dateTimeString == null) return 'N/A';
    try {
      final DateTime dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }
}
