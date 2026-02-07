import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sango/l10n/l10n.dart'; // Add this import
import 'package:sango/services/driver_service.dart';
import 'package:sango/services/routingMapServices.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;

// Simple cache for routes to prevent redundant API calls
class RouteCache {
  static final Map<String, RouteResult> _cache = {};

  static String _generateKey(
      double startLat, double startLng, double endLat, double endLng) {
    return '${startLat.toStringAsFixed(5)},${startLng.toStringAsFixed(5)}_${endLat.toStringAsFixed(5)},${endLng.toStringAsFixed(5)}';
  }

  static RouteResult? getRoute(
      double startLat, double startLng, double endLat, double endLng) {
    final key = _generateKey(startLat, startLng, endLat, endLng);
    return _cache[key];
  }

  static void storeRoute(double startLat, double startLng, double endLat,
      double endLng, RouteResult route) {
    final key = _generateKey(startLat, startLng, endLat, endLng);
    _cache[key] = route;
    // Limit cache size
    if (_cache.length > 20) {
      _cache.remove(_cache.keys.first);
    }
  }
}

class ConfirmedRideCard extends StatefulWidget {
  final Map<String, dynamic> ride;
  final Function()? onTripStarted;
  final Function()? onCancelTrip;

  const ConfirmedRideCard({
    Key? key,
    required this.ride,
    this.onTripStarted,
    this.onCancelTrip,
  }) : super(key: key);

  @override
  State<ConfirmedRideCard> createState() => _ConfirmedRideCardState();
}

class _ConfirmedRideCardState extends State<ConfirmedRideCard> {
  bool _isStartingTrip = false;
  bool _isCancellingTrip = false;
  bool _isLoadingRoute = false;
  bool _isRoutePreloaded = false;
  final TextEditingController _otpController = TextEditingController();
  GoogleMapController? _mapController;
  RouteResult? _currentRoute;
  List<AlternativeRoute> _alternativeRoutes = [];
//  GoogleMapController? _mapController;
  // bool _isLoadingRoute = false;
  RouteResult? _routeResult;
  int _currentStepIndex = 0;
  Timer? _navigationTimer;
  bool _isNavigating = false;
  double? _latitude;
  double? _longitude;
  String _navigationInstruction = "Preparing navigation...";
  @override
  void initState() {
    super.initState();
    // Pre-fetch route data when the card is created
    _preloadRoute();
    getCurrentLocationAndAddress();
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
      if (mounted) {
        setState(() {
          _latitude = locationData.latitude;
          _longitude = locationData.longitude;
        });
      }
      // _latitude = locationData.latitude;
      // _longitude = locationData.longitude;

      // Print coordinates clearly
      print('===================================');
      print('CURRENT LOCATION:');
      print('   Latitude:  ${_latitude}');
      print('   Longitude: ${_longitude}');
      print('   Accuracy:  ${locationData.accuracy} meters');
      print('   Time:      ${DateTime.now().toString()}');
      print('===================================\n');

      if (_latitude == null || _longitude == null) {
        print(' Failed to get coordinates.');
        return;
      }

      // Use your Google Maps Geocoding API key
      const String apiKey = 'AIzaSyBXaMspN9XlQhkUHiyLCXkQoEurPKrMeog';
      String geocodeUrl =
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=$_latitude,$_longitude&key=$apiKey';

      final response = await http.get(Uri.parse(geocodeUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          String formattedAddress = data['results'][0]['formatted_address'];
          print('Latitude: ${_latitude}');
          print('Longitude: ${_longitude} ');
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

  // Improved map dialog with navigation features
  void _showMapDialog() async {
    final s = S.of(context)!;
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange,
          content: Text('Please wait...'),
        ),
      );

      // Try to get current location
      await getCurrentLocationAndAddress();

      // // Check again if we have location
      // if (_latitude == null || _longitude == null) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       backgroundColor: Colors.red,
      //       content: Text(s.locationCoordsNotAvailable),
      //     ),
      //   );
      //   return;
      // }
    }
    final double? fromLat = _parseDouble(_latitude);
    final double? fromLng = _parseDouble(_longitude);
    final double? toLat = _parseDouble(widget.ride['pickup_latitude']);
    final double? toLng = _parseDouble(widget.ride['pickup_longitude']);
    print("lat&&&&&&&&&&&&&&&&&&&&&: $_latitude, lng: $_longitude");
    print(
        "fromLat&&&&&&&&&&&&&&&&&&&&&&&&&: $fromLat, fromLng: $fromLng, toLat: $toLat, toLng: $toLng");
    // Check for missing coordinates
    if (fromLat == null || fromLng == null || toLat == null || toLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange,
          content: Text(s.locationCoordsNotAvailable),
        ),
      );
      return;
    }

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
                                Text(
                                  s.navigation,
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
                                      'Getting best route...',
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
                      padding: const EdgeInsets.all(16),
                      color: Colors.grey[200],
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // Toggle navigation mode
                          ElevatedButton.icon(
                            icon: Icon(
                              _isNavigating ? Icons.pause : Icons.navigation,
                              color: Colors.white,
                            ),
                            label: Text(
                              _isNavigating ? s.pause : s.startNavigation,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _isNavigating ? Colors.orange : Colors.green,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
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

                          // Launch external navigation app
                          ElevatedButton.icon(
                            icon: const Icon(Icons.open_in_new,
                                color: Colors.white),
                            label: Text(s.googleMaps,
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                            ),
                            onPressed: () => _launchExternalNavigation(
                                fromLat, fromLng, toLat, toLng),
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
                                  widget.ride['trip_pickup']?.toString() ??
                                      widget.ride['pickup_location']
                                          ?.toString() ??
                                      s.unknownPickup,
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
                                  widget.ride['trip_dropoff']?.toString() ??
                                      widget.ride['dropoff_location']
                                          ?.toString() ??
                                      s.unknownDestination,
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
          snippet: widget.ride['trip_pickup']?.toString() ??
              widget.ride['pickup_location']?.toString() ??
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
          snippet: widget.ride['trip_dropoff']?.toString() ??
              widget.ride['dropoff_location']?.toString() ??
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

  // Pre-fetch route to improve map opening speed
  Future<void> _preloadRoute() async {
    final double? fromLat = _parseDouble(widget.ride['pickup_latitude']);
    final double? fromLng = _parseDouble(widget.ride['pickup_longitude']);
    final double? toLat = _parseDouble(widget.ride['dropoff_latitude']);
    final double? toLng = _parseDouble(widget.ride['dropoff_longitude']);

    if (fromLat == null || fromLng == null || toLat == null || toLng == null)
      return;

    // Check if route is already in cache
    final cachedRoute = RouteCache.getRoute(fromLat, fromLng, toLat, toLng);
    if (cachedRoute != null) {
      if (mounted) {
        setState(() {
          _currentRoute = cachedRoute;
          _alternativeRoutes = cachedRoute.alternativeRoutes;
          _isRoutePreloaded = true;
        });
      }
      return;
    }

    // Don't show loading state for preloading
    try {
      // Use the fast route method instead of the optimization service
      final route = await RouteService.getFastRoute(
        startLat: fromLat,
        startLng: fromLng,
        endLat: toLat,
        endLng: toLng,
      );

      if (route != null && mounted) {
        setState(() {
          _currentRoute = route;
          _alternativeRoutes = []; // Don't load alternatives during preload
          _isRoutePreloaded = true;
        });

        // Store in cache
        RouteCache.storeRoute(fromLat, fromLng, toLat, toLng, route);
      }
    } catch (e) {
      print('Error preloading route: $e');
    }
  }

  // Load route when map dialog is shown - optimized version

  Future<void> _showOtpDialog() async {
    final s = S.of(context)!;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: Text(s.startTrip),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.enterOtpMessage,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: s.enterOTP,
                      hintText: s.sixDigitCode,
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _isStartingTrip
                      ? null
                      : () {
                          _otpController.clear();
                          Navigator.of(context).pop();
                        },
                  child: Text(s.cancel),
                ),
                ElevatedButton(
                  onPressed:
                      _isStartingTrip ? null : () => _startTrip(dialogSetState),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: _isStartingTrip
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(s.startTrip),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _startTrip(StateSetter dialogSetState) async {
    if (_otpController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter OTP')),
      );
      return;
    }

    dialogSetState(() {
      _isStartingTrip = true;
    });

    try {
      final response = await DriverService.startTrip(
        transactionId: widget.ride['transaction_id'].toString(),
        otp: _otpController.text.trim(),
        context: context,
      );

      if (!mounted) return;

      if (response['success'] == true) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(
              response['message'] ?? 'Trip started successfully',
            ),
          ),
        );

        if (widget.onTripStarted != null) {
          widget.onTripStarted!();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              response['message'] ?? 'Failed to start trip',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('An error occurred'),
        ),
      );
    } finally {
      if (mounted) {
        dialogSetState(() {
          _isStartingTrip = false;
        });
      }
    }
  }

  Future<void> _cancelTrip() async {
    setState(() {
      _isCancellingTrip = true;
    });

    try {
      final response = await DriverService.cancelTripWithDriver(
        driverId: widget.ride['driver_id'].toString(),
        transactionId: widget.ride['transaction_id'].toString(),
        reason: 'Driver canceled the trip',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor:
              response['success'] == true ? Colors.green : Colors.red,
          content: Text(
            response['message'] ??
                (response['success'] == true
                    ? 'Trip cancelled successfully'
                    : 'Failed to cancel trip'),
          ),
        ),
      );

      if (response['success'] == true && widget.onCancelTrip != null) {
        widget.onCancelTrip!();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('An error occurred'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCancellingTrip = false;
        });
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;

    // Determine the status display based on booking status
    final status = widget.ride['status']?.toString().toLowerCase() ?? '';
    final isOnTrip = status == 'started' || status == 'on trip';
    final statusColor = isOnTrip ? Colors.blue : Colors.green;
    final statusText = isOnTrip ? s.onTrip : s.confirmed;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status and enhanced route info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        s.tripWithId(widget.ride['id']) + ' - $statusText',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA77D55).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFA77D55).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.directions_car,
                            size: 14, color: Color(0xFFA77D55)),
                        const SizedBox(width: 4),
                        Text(
                          _currentRoute?.distance ??
                              widget.ride['distance']?.toString() ??
                              'N/A',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFA77D55),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Enhanced route information with route quality indicator
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
                          widget.ride['from']?.toString() ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          widget.ride['to']?.toString() ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Enhanced map button with route indicator
                  GestureDetector(
                    onTap: _showMapDialog,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.route,
                            color: Colors.blue,
                            size: 20,
                          ),
                          if (_currentRoute != null)
                            Text(
                              'Route',
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Enhanced duration, time, and fare with route info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.timer, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            _currentRoute?.duration ??
                                widget.ride['estimated_duration']?.toString() ??
                                'N/A',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.ride['date'] ?? 'N/A'} ${widget.ride['time'] ?? ''}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      // Traffic info if available
                      if (_currentRoute != null) const SizedBox(height: 4),
                      if (_currentRoute != null)
                        Row(
                          children: [
                            Icon(Icons.traffic,
                                size: 14, color: Colors.orange[700]),
                            const SizedBox(width: 4),
                            Text(
                              'Live traffic',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.ride['fare']?.toString() ?? 'N/A',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      if (_alternativeRoutes.isNotEmpty)
                        Text(
                          '${_alternativeRoutes.length + 1} routes',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Client info and enhanced action buttons
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    // First row - Client info
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: statusColor,
                          child: const Icon(Icons.person,
                              size: 20, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.ride['client_name']?.toString() ??
                                    s.unknownClient,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              if (widget.ride['phone'] != null)
                                GestureDetector(
                                  onTap: () => _makePhoneCall(
                                      widget.ride['phone'].toString()),
                                  child: Row(
                                    children: [
                                      Icon(Icons.phone,
                                          size: 14, color: statusColor),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          widget.ride['phone'].toString(),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: statusColor,
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

                    // Second row - Action buttons (on new line to prevent overflow)
                    if (!isOnTrip) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Enhanced Navigation button
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _showMapDialog,
                              icon: const Icon(Icons.navigation, size: 16),
                              label: Text(s.navigate),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Start Trip button
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _showOtpDialog,
                              icon: const Icon(Icons.play_arrow, size: 16),
                              label: Text(s.start),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.directions_car,
                                size: 16, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(
                              s.inProgress,
                              style: const TextStyle(
                                color: Colors.blue,
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

              const SizedBox(height: 12),

              // Cancel trip button (visible only for confirmed trips)
              if (!isOnTrip)
                Center(
                  child: TextButton(
                    onPressed: _cancelTrip,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.red.withOpacity(0.3)),
                      ),
                    ),
                    child: _isCancellingTrip
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.red),
                            ),
                          )
                        : Text(
                            s.cancelRide, // Changed from s.cancelTrip to s.cancelRide
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
