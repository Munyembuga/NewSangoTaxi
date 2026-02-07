// Add these dependencies to your pubspec.yaml:
// dio: ^5.3.2
// google_polyline_algorithm: ^3.1.0

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteService {
  static const String _googleMapsApiKey =
      'AIzaSyBXaMspN9XlQhkUHiyLCXkQoEurPKrMeog';
  static const String _directionsBaseUrl =
      'https://maps.googleapis.com/maps/api/directions/json';

  // Create a Dio instance with default configuration
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    sendTimeout: const Duration(seconds: 10),
  ));

  // Route cache for better performance
  static final Map<String, RouteResult> _routeCache = {};
  static const int _maxCacheSize = 20;

  // Fast route method - optimized for quick display
  static Future<RouteResult?> getFastRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      // Generate a cache key
      final cacheKey =
          '${startLat.toStringAsFixed(5)},${startLng.toStringAsFixed(5)}_${endLat.toStringAsFixed(5)},${endLng.toStringAsFixed(5)}';

      // Check cache first
      if (_routeCache.containsKey(cacheKey)) {
        print('Route found in cache');
        return _routeCache[cacheKey];
      }

      // Minimal parameters for fastest response
      final queryParameters = {
        'origin': '$startLat,$startLng',
        'destination': '$endLat,$endLng',
        'mode': 'driving',
        'key': _googleMapsApiKey,
      };

      final response = await _dio.get(
        _directionsBaseUrl,
        queryParameters: queryParameters,
        options: Options(
          receiveTimeout: const Duration(seconds: 5), // Shorter timeout
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];

          // Decode polyline points
          final polylinePoints =
              decodePolyline(route['overview_polyline']['points']);
          final latLngPoints = polylinePoints
              .map((point) => LatLng(point[0].toDouble(), point[1].toDouble()))
              .toList();

          final result = RouteResult(
            polylinePoints: latLngPoints,
            distance: leg['distance']['text'],
            duration: leg['duration']['text'],
            distanceValue: leg['distance']['value'],
            durationValue: leg['duration']['value'],
            startAddress: leg['start_address'],
            endAddress: leg['end_address'],
            steps: [], // Empty for speed
            alternativeRoutes: [], // No alternatives for speed
          );

          // Cache the result
          if (_routeCache.length >= _maxCacheSize) {
            // Remove oldest entry
            _routeCache.remove(_routeCache.keys.first);
          }
          _routeCache[cacheKey] = result;

          return result;
        }
      }
      return null;
    } on DioException catch (e) {
      print('Fast route error: ${e.message}');
      return null;
    } catch (e) {
      print('Error getting fast route: $e');
      return null;
    }
  }

  // Get the best route between two points
  static Future<RouteResult?> getRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    String travelMode = 'driving', // driving, walking, bicycling, transit
    bool avoidHighways = false,
    bool avoidTolls = false,
    bool avoidFerries = false,
  }) async {
    try {
      final queryParameters = {
        'origin': '$startLat,$startLng',
        'destination': '$endLat,$endLng',
        'mode': travelMode,
        'avoid': _buildAvoidParameter(avoidHighways, avoidTolls, avoidFerries),
        'alternatives': 'true',
        'optimize': 'true',
        'key': _googleMapsApiKey,
      };

      final response = await _dio.get(
        _directionsBaseUrl,
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          // Get the best route (first one is usually optimal)
          final route = data['routes'][0];
          final leg = route['legs'][0];

          // Decode polyline points
          final polylinePoints =
              decodePolyline(route['overview_polyline']['points']);
          final latLngPoints = polylinePoints
              .map((point) => LatLng(point[0].toDouble(), point[1].toDouble()))
              .toList();

          return RouteResult(
            polylinePoints: latLngPoints,
            distance: leg['distance']['text'],
            duration: leg['duration']['text'],
            distanceValue: leg['distance']['value'], // in meters
            durationValue: leg['duration']['value'], // in seconds
            startAddress: leg['start_address'],
            endAddress: leg['end_address'],
            steps: _extractSteps(leg['steps']),
            alternativeRoutes: _extractAlternativeRoutes(data['routes']),
          );
        }
      }
      return null;
    } on DioException catch (e) {
      print('Dio error getting route: ${e.message}');
      if (e.response != null) {
        print('Response data: ${e.response?.data}');
        print('Response status: ${e.response?.statusCode}');
      }
      return null;
    } catch (e) {
      print('Error getting route: $e');
      return null;
    }
  }

  static String _buildAvoidParameter(bool highways, bool tolls, bool ferries) {
    List<String> avoid = [];
    if (highways) avoid.add('highways');
    if (tolls) avoid.add('tolls');
    if (ferries) avoid.add('ferries');
    return avoid.join('|');
  }

  static List<RouteStep> _extractSteps(List<dynamic> stepsData) {
    return stepsData
        .map((step) => RouteStep(
              instruction: step['html_instructions'],
              distance: step['distance']['text'],
              duration: step['duration']['text'],
              startLocation: LatLng(
                step['start_location']['lat'].toDouble(),
                step['start_location']['lng'].toDouble(),
              ),
              endLocation: LatLng(
                step['end_location']['lat'].toDouble(),
                step['end_location']['lng'].toDouble(),
              ),
            ))
        .toList();
  }

  static List<AlternativeRoute> _extractAlternativeRoutes(
      List<dynamic> routes) {
    return routes.skip(1).map((route) {
      final leg = route['legs'][0];
      final polylinePoints =
          decodePolyline(route['overview_polyline']['points']);
      final latLngPoints = polylinePoints
          .map((point) => LatLng(point[0].toDouble(), point[1].toDouble()))
          .toList();

      return AlternativeRoute(
        polylinePoints: latLngPoints,
        distance: leg['distance']['text'],
        duration: leg['duration']['text'],
        summary: route['summary'] ?? 'Alternative route',
      );
    }).toList();
  }

  // Optional: Add interceptors for logging, authentication, etc.
  static void setupInterceptors() {
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print(obj),
    ));

    // Add custom interceptor for API key management
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // You can add custom headers or modify requests here
        options.headers['User-Agent'] = 'Flutter Route App';
        handler.next(options);
      },
      onError: (error, handler) {
        // Handle errors globally
        if (error.response?.statusCode == 403) {
          print('API key might be invalid or quota exceeded');
        }
        handler.next(error);
      },
    ));
  }
}

class RouteResult {
  final List<LatLng> polylinePoints;
  final String distance;
  final String duration;
  final int distanceValue;
  final int durationValue;
  final String startAddress;
  final String endAddress;
  final List<RouteStep> steps;
  final List<AlternativeRoute> alternativeRoutes;

  RouteResult({
    required this.polylinePoints,
    required this.distance,
    required this.duration,
    required this.distanceValue,
    required this.durationValue,
    required this.startAddress,
    required this.endAddress,
    required this.steps,
    required this.alternativeRoutes,
  });
}

class RouteStep {
  final String instruction;
  final String distance;
  final String duration;
  final LatLng startLocation;
  final LatLng endLocation;

  RouteStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.startLocation,
    required this.endLocation,
  });
}

class AlternativeRoute {
  final List<LatLng> polylinePoints;
  final String distance;
  final String duration;
  final String summary;

  AlternativeRoute({
    required this.polylinePoints,
    required this.distance,
    required this.duration,
    required this.summary,
  });
}

// Enhanced route optimization service
class RouteOptimizationService {
  static final Dio _dio = RouteService._dio;

  // Find the best route considering traffic, distance, and time
  static Future<RouteResult?> getBestRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    List<LatLng>? waypoints,
    RoutePreference preference = RoutePreference.fastest,
  }) async {
    try {
      String optimizeFor = '';
      switch (preference) {
        case RoutePreference.fastest:
          optimizeFor = 'duration';
          break;
        case RoutePreference.shortest:
          optimizeFor = 'distance';
          break;
        case RoutePreference.fuelEfficient:
          optimizeFor = 'duration'; // Can be enhanced with eco-routing
          break;
      }

      // Build waypoints parameter
      final queryParameters = {
        'origin': '$startLat,$startLng',
        'destination': '$endLat,$endLng',
        'mode': 'driving',
        'departure_time': 'now',
        'traffic_model': 'best_guess',
        'alternatives': 'true',
        'key': RouteService._googleMapsApiKey,
      };

      // Add waypoints if provided
      if (waypoints != null && waypoints.isNotEmpty) {
        final waypointStrings = waypoints
            .map((point) => '${point.latitude},${point.longitude}')
            .join('|');
        queryParameters['waypoints'] = 'optimize:true|$waypointStrings';
      }

      final response = await _dio.get(
        RouteService._directionsBaseUrl,
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          // Select best route based on preference
          final bestRoute = _selectBestRoute(data['routes'], preference);
          final leg = bestRoute['legs'][0];

          final polylinePoints =
              decodePolyline(bestRoute['overview_polyline']['points']);
          final latLngPoints = polylinePoints
              .map((point) => LatLng(point[0].toDouble(), point[1].toDouble()))
              .toList();

          return RouteResult(
            polylinePoints: latLngPoints,
            distance: leg['distance']['text'],
            duration:
                leg['duration_in_traffic']?['text'] ?? leg['duration']['text'],
            distanceValue: leg['distance']['value'],
            durationValue: leg['duration_in_traffic']?['value'] ??
                leg['duration']['value'],
            startAddress: leg['start_address'],
            endAddress: leg['end_address'],
            steps: RouteService._extractSteps(leg['steps']),
            alternativeRoutes:
                RouteService._extractAlternativeRoutes(data['routes']),
          );
        }
      }
      return null;
    } on DioException catch (e) {
      print('Dio error getting optimized route: ${e.message}');
      if (e.response != null) {
        print('Response data: ${e.response?.data}');
        print('Response status: ${e.response?.statusCode}');
      }
      return null;
    } catch (e) {
      print('Error getting optimized route: $e');
      return null;
    }
  }

  static Map<String, dynamic> _selectBestRoute(
      List<dynamic> routes, RoutePreference preference) {
    if (routes.length == 1) return routes[0];

    switch (preference) {
      case RoutePreference.fastest:
        routes.sort((a, b) {
          final aDuration = a['legs'][0]['duration_in_traffic']?['value'] ??
              a['legs'][0]['duration']['value'];
          final bDuration = b['legs'][0]['duration_in_traffic']?['value'] ??
              b['legs'][0]['duration']['value'];
          return aDuration.compareTo(bDuration);
        });
        break;
      case RoutePreference.shortest:
        routes.sort((a, b) {
          final aDistance = a['legs'][0]['distance']['value'];
          final bDistance = b['legs'][0]['distance']['value'];
          return aDistance.compareTo(bDistance);
        });
        break;
      case RoutePreference.fuelEfficient:
        // Simple heuristic: balance of time and distance
        routes.sort((a, b) {
          final aScore = (a['legs'][0]['duration']['value'] * 0.6) +
              (a['legs'][0]['distance']['value'] * 0.4);
          final bScore = (b['legs'][0]['duration']['value'] * 0.6) +
              (b['legs'][0]['distance']['value'] * 0.4);
          return aScore.compareTo(bScore);
        });
        break;
    }

    return routes[0];
  }
}

enum RoutePreference {
  fastest,
  shortest,
  fuelEfficient,
}

// Example usage with error handling and retry mechanism
class RouteServiceWithRetry {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(seconds: 15),
  ));

  static Future<RouteResult?> getRouteWithRetry({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    int maxRetries = 3,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final result = await RouteService.getRoute(
          startLat: startLat,
          startLng: startLng,
          endLat: endLat,
          endLng: endLng,
        );

        if (result != null) {
          return result;
        }
      } on DioException catch (e) {
        print('Attempt $attempt failed: ${e.message}');

        if (attempt == maxRetries) {
          print('All retry attempts failed');
          return null;
        }

        // Wait before retrying (exponential backoff)
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }

    return null;
  }
}
