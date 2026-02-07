import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../constants/api_constants.dart';
import 'storage_service.dart';
import '../screen/login.dart';

class DriverService {
  static final Dio _dio = Dio();

  // Helper method to handle token expiration
  static Future<void> _handleTokenExpiration(String errorMessage,
      [BuildContext? context]) async {
    if (errorMessage.toLowerCase().contains('invalid') &&
            errorMessage.toLowerCase().contains('token') ||
        errorMessage.toLowerCase().contains('expired') &&
            errorMessage.toLowerCase().contains('token')) {
      await StorageService.clearAll();

      print('🔄 Token expired, navigating to login screen...');

      // Navigate to login screen if context is available
      if (context != null && context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  // Update driver status (active/inactive)
  static Future<Map<String, dynamic>> updateDriverStatus({
    required int driverId,
    required int status,
  }) async {
    try {
      // Get the auth token
      final token = await StorageService.getToken();
      print("token&&&&&&&&&&&&&&&: $token");
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      // Set up headers with the bearer token
      final options = Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      // Print request details
      final requestData = {
        'driver_id': driverId,
        'status': status,
      };
      print(' DRIVER STATUS UPDATE REQUEST:');
      print(
          ' URL&&&&&: ${ApiConstants.baseUrl}${ApiConstants.updateDriverStatusEndpoint}');
      print(' Headers: ${options.headers}');
      print(' Data: $requestData');

      // Make the API call
      final response = await _dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.updateDriverStatusEndpoint}',
        data: requestData,
        options: options,
      );

      // Print response details
      print(' DRIVER STATUS UPDATE RESPONSE:');
      print(' Status Code: ${response.statusCode}');
      print(' Data: ${response.data}');

      return {
        'success': true,
        'data': response.data,
        'status': response.data['status'],
        'message': response.data['message'] ?? 'Status updated successfully',
      };
      print(
          "response.data: ${response.data['message']}"); // Debugging line to check response data
    } on DioException catch (e) {
      // Print error details
      print(' DRIVER STATUS UPDATE ERROR:');
      print('Error type: ${e.type}');
      if (e.response != null) {
        print('Status code: ${e.response?.statusCode}');
        print('Error response: ${e.response?.data}');
      } else {
        print('Error message: ${e.message}');
      }

      String errorMessage = 'Failed to update driver status';

      if (e.response != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Server response timeout';
      } else {
        errorMessage = 'Network error';
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      print(' UNEXPECTED ERROR: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Get current driver status
  static Future<Map<String, dynamic>> getDriverStatus({
    required int driverId,
  }) async {
    try {
      // Get the auth token
      final token = await StorageService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      // Set up headers with the bearer token
      final options = Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      // Print request details
      print(' GET DRIVER STATUS REQUEST:');
      print('%%%%%%%%%%% URL: ${ApiConstants.baseUrl}/api/driver/get_status');
      print(' Headers: ${options.headers}');
      print(
          ' Data: {"driver_id": "$driverId"}'); // Quote the driver_id value to show it's sent as string

      // Make the API call - send driver_id as string since API expects string value
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/driver/get_status',
        data: {
          'driver_id':
              '$driverId', // Convert to string with string interpolation
        },
        options: options,
      );

      // Print response details
      print(' GET DRIVER STATUS RESPONSE:');
      print(' Status Code: ${response.statusCode}');
      print(' Data: ${response.data}');

      if (response.data['success'] == true) {
        return {
          'success': true,
          'data': response.data['data'],
          'status': response.data['data']['status'], // This will be a string
          'status_label': response.data['data']['status_label'],
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to get driver status',
        };
      }
    } on DioException catch (e) {
      // Print error details
      print(' GET DRIVER STATUS ERROR:');
      print('Error type: ${e.type}');
      if (e.response != null) {
        print('Status code: ${e.response?.statusCode}');
        print('Error response: ${e.response?.data}');
      } else {
        print('Error message: ${e.message}');
      }

      String errorMessage = 'Failed to get driver status';

      if (e.response != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Server response timeout';
      } else {
        errorMessage = 'Network error';
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      print(' UNEXPECTED ERROR: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Get nearby ride requests for driver
  static Future<Map<String, dynamic>> getNearbyRequests({
    required String latitude,
    required String longitude,
    required String categoryId,
    required String assignId,
  }) async {
    try {
      // Get the auth token
      final token = await StorageService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      // Set up headers with the bearer token
      final options = Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      // Print request details
      print(' GET NEARBY REQUESTS:');
      print(
          'URL: ${ApiConstants.baseUrl}${ApiConstants.getDriverRequestsEndpoint}');

      final queryParams = {
        'lat': latitude,
        'lng': longitude,
        'category_id': categoryId,
        'assign_id': assignId,
      };

      print(' Query Params: $queryParams');

      // Make the API call
      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.getDriverRequestsEndpoint}',
        queryParameters: queryParams,
        options: options,
      );

      // Print response details
      print(' NEARBY REQUESTS RESPONSE:');
      print(' Status Code: ${response.statusCode}');
      print('Data: ${response.data}');

      return {
        'success': true,
        'data': response.data,
        'driver_status': response.data['driver_status'] ?? '3',
        'driver_status_name':
            response.data['driver_status_name'] ?? 'Available',
        'current_location': response.data['current_location'],
        'rides': response.data['data'] ??
            [], // API now returns bookings under 'data' key
      };
    } on DioException catch (e) {
      // Print error details
      print(' NEARBY REQUESTS ERROR:');
      print('Error type: ${e.type}');
      if (e.response != null) {
        print('Status code: ${e.response?.statusCode}');
        print('Error response: ${e.response?.data}');
      } else {
        print('Error message: ${e.message}');
      }

      String errorMessage = 'Failed to get nearby requests';

      if (e.response != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Server response timeout';
      } else {
        errorMessage = 'Network error';
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      print(' UNEXPECTED ERROR: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Confirm a booking request
  static Future<Map<String, dynamic>> confirmBookingRequest({
    required String bookingId,
    required String driverId,
  }) async {
    try {
      // Get the auth token
      final token = await StorageService.getToken();
      print("token&&&&&&&&&&&&&&&: $token");
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      // Set up headers with the bearer token
      final options = Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final requestData = {
        'booking_id': bookingId,
      };

      // Print request details
      print(' CONFIRM BOOKING REQUEST:');
      print(
          ' URL: ${ApiConstants.baseUrl}${ApiConstants.confirmRequestEndpoint}');
      print(' Data: $requestData');

      // Make the API call
      final response = await _dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.confirmRequestEndpoint}',
        data: requestData,
        options: options,
      );

      // Print response details
      print(' CONFIRM BOOKING RESPONSE:');
      print(' Status Code: ${response.statusCode}');
      print(' Data: ${response.data}');

      return {
        'success': true,
        'data': response.data,
        'message': response.data['message'] ?? 'Booking confirmed successfully',
      };
    } on DioException catch (e) {
      // Print error details
      print(' CONFIRM BOOKING ERROR:');
      print('Error type: ${e.type}');
      if (e.response != null) {
        print('Status code: ${e.response?.statusCode}');
        print('Error response: ${e.response?.data}');
      } else {
        print('Error message: ${e.message}');
      }

      String errorMessage = 'Failed to confirm booking';

      if (e.response != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Server response timeout';
      } else {
        errorMessage = 'Network error';
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      print(' UNEXPECTED ERROR: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Start trip with OTP verification
  static Future<Map<String, dynamic>> startTrip({
    required String transactionId,
    required String otp,
    BuildContext? context,
  }) async {
    try {
      // Get the auth token
      final token = await StorageService.getToken();
      print("token&&&&&&&&&&&&&&&: $token");
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      // Set up headers with the bearer token
      final options = Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final requestData = {
        'transaction_id': int.parse(transactionId),
        'otp': otp,
      };

      // Print request details
      print(' START TRIP REQUEST:');
      print(' URL: ${ApiConstants.baseUrl}booking/startTrip');
      print(' Data: $requestData');

      // Make the API call
      final response = await _dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.startTripEndpoint}',
        data: requestData,
        options: options,
      );

      // Print response details
      print(' START TRIP RESPONSE:');
      print(' Status Code: ${response.statusCode}');
      print(' Data: ${response.data}');

      return {
        'success': true,
        'data': response.data,
        'message': response.data['message'] ?? 'Trip started successfully',
      };
    } on DioException catch (e) {
      // Print error details
      print(' START TRIP ERROR:');
      print('Error type: ${e.type}');
      if (e.response != null) {
        print('Status code: ${e.response?.statusCode}');
        print('Error response: ${e.response?.data}');
      } else {
        print('Error message: ${e.message}');
      }

      String errorMessage = 'Failed to start trip';

      if (e.response != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
        await _handleTokenExpiration(errorMessage, context);
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Server response timeout';
      } else {
        errorMessage = 'Network error';
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      print(' UNEXPECTED ERROR: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Get confirmed bookings for driver
  static Future<Map<String, dynamic>> getConfirmedBookings({
    BuildContext? context,
  }) async {
    try {
      // Get the auth token
      final token = await StorageService.getToken();
      print("token&&&&&&&&&&&&&&&: $token");
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      // Set up headers with the bearer token
      final options = Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      // Print request details
      print(' GET CONFIRMED BOOKINGS:');
      print(
          ' URL: ${ApiConstants.baseUrl}${ApiConstants.getConfirmedBookingsEndpoint}');

      // Make the API call
      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.getConfirmedBookingsEndpoint}',
        options: options,
      );

      // Print response details
      print(' CONFIRMED BOOKINGS RESPONSE:');
      print(' Status Code: ${response.statusCode}');
      print(' Data: ${response.data}');

      return {
        'success': true,
        'data': response.data,
        'driver_status': response.data['driver_status'] ?? '3',
        'driver_status_name':
            response.data['driver_status_name'] ?? 'Available',
        'current_location': response.data['current_location'],
        'confirmed_bookings': response.data['confirmed_bookings'] ?? [],
        'total_confirmed': response.data['total_confirmed'] ?? 0,
      };
    } on DioException catch (e) {
      // Print error details
      print(' CONFIRMED BOOKINGS ERROR:');
      print('Error type: ${e.type}');
      if (e.response != null) {
        print('Status code: ${e.response?.statusCode}');
        print('Error response: ${e.response?.data}');
      } else {
        print('Error message: ${e.message}');
      }

      String errorMessage = 'Failed to get confirmed bookings';

      if (e.response != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
        await _handleTokenExpiration(errorMessage, context);
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Server response timeout';
      } else {
        errorMessage = 'Network error';
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      print(' UNEXPECTED ERROR: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Get on-trip bookings for driver
  static Future<Map<String, dynamic>> getOnTripBookings({
    BuildContext? context,
  }) async {
    try {
      // Get the auth token
      final token = await StorageService.getToken();
      print("token&&&&&&&&&&&&&&&: $token");
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      // Set up headers with the bearer token
      final options = Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      // Print request details
      print('🔍 GET ON-TRIP BOOKINGS:');
      print(
          'URL: ${ApiConstants.baseUrl}${ApiConstants.getOnTripBookingsEndpoint}');

      // Make the API call
      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.getOnTripBookingsEndpoint}',
        options: options,
      );

      // Print response details
      print(' ON-TRIP BOOKINGS RESPONSE:');
      print(' Status Code: ${response.statusCode}');
      print(' Data: ${response.data}');

      return {
        'success': true,
        'data': response.data,
        'driver_status': response.data['driver_status'] ?? '3',
        'driver_status_name':
            response.data['driver_status_name'] ?? 'Available',
        'current_location': response.data['current_location'],
        'active_trips': response.data['active_trips'] ?? [],
        'total_active': response.data['total_active'] ?? 0,
        'driver_on_trip': response.data['driver_on_trip'] ?? false,
      };
    } on DioException catch (e) {
      // Print error details
      print(' ON-TRIP BOOKINGS ERROR:');
      print('Error type: ${e.type}');
      if (e.response != null) {
        print('Status code: ${e.response?.statusCode}');
        print('Error response: ${e.response?.data}');
      } else {
        print('Error message: ${e.message}');
      }

      String errorMessage = 'Failed to get on-trip bookings';

      if (e.response != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
        await _handleTokenExpiration(errorMessage, context);
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Server response timeout';
      } else {
        errorMessage = 'Network error';
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      print(' UNEXPECTED ERROR: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Get completed trips for driver
  static Future<Map<String, dynamic>> getCompletedTrips({
    int page = 1,
    BuildContext? context,
  }) async {
    try {
      // Get the auth token
      final token = await StorageService.getToken();
      print("token&&&&&&&&&&&&&&&: $token");
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      // Set up headers with the bearer token
      final options = Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      // Print request details
      print(' GET COMPLETED TRIPS:');
      print(
          'URL: ${ApiConstants.baseUrl}booking/drivergetcompleted?page=$page');

      // Make the API call
      final response = await _dio.get(
        '${ApiConstants.baseUrl}booking/drivergetcompleted?page=$page',
        options: options,
      );

      // Print response details
      print(' COMPLETED TRIPS RESPONSE:');
      print(' Status Code: ${response.statusCode}');
      print(' Data: ${response.data}');

      return {
        'success': true,
        'data': response.data,
        'completed_trips': response.data['completed_trips'] ?? [],
        'pagination': response.data['pagination'],
        'total_completed': response.data['total_completed'] ?? 0,
      };
    } on DioException catch (e) {
      // Print error details
      print(' COMPLETED TRIPS ERROR:');
      print('Error type: ${e.type}');
      if (e.response != null) {
        print('Status code: ${e.response?.statusCode}');
        print('Error response: ${e.response?.data}');
      } else {
        print('Error message: ${e.message}');
      }

      String errorMessage = 'Failed to get completed trips';

      if (e.response != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
        await _handleTokenExpiration(errorMessage, context);
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Server response timeout';
      } else {
        errorMessage = 'Network error';
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      print(' UNEXPECTED ERROR: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Get payment modes
  static Future<Map<String, dynamic>> getPaymentModes({
    BuildContext? context,
  }) async {
    try {
      // Print request details
      print(' GET PAYMENT MODES:');
      print(' URL: ${ApiConstants.baseUrl}booking/payment_mode');

      // Make the API call
      final response = await _dio.get(
        '${ApiConstants.baseUrl}booking/payment_mode',
      );

      // Print response details
      print(' PAYMENT MODES RESPONSE:');
      print('Status Code: ${response.statusCode}');
      print(' Data: ${response.data}');

      return {
        'success': true,
        'data': response.data,
        'payment_modes': response.data['payment_modes'] ?? [],
        'total_modes': response.data['total_modes'] ?? 0,
      };
    } on DioException catch (e) {
      // Print error details
      print(' PAYMENT MODES ERROR:');
      print('Error type: ${e.type}');
      if (e.response != null) {
        print('Status code: ${e.response?.statusCode}');
        print('Error response: ${e.response?.data}');
      } else {
        print('Error message: ${e.message}');
      }

      String errorMessage = 'Failed to get payment modes';

      if (e.response != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
        await _handleTokenExpiration(errorMessage, context);
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Server response timeout';
      } else {
        errorMessage = 'Network error';
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      print('UNEXPECTED ERROR: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Complete trip
  static Future<Map<String, dynamic>> completeTrip({
    required int transactionId,
    // required double kmUsed,
    required double paymentFee,
    required int paymentMode,
    BuildContext? context,
  }) async {
    try {
      // Get the auth token
      final token = await StorageService.getToken();
      print("token&&&&&&&&&&&&&&&: $token");
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      // Set up headers with the bearer token
      final options = Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final requestData = {
        'transaction_id': transactionId,
        // 'km_used': kmUsed,
        'payment_fee': paymentFee,
        'payment_mode': paymentMode,
      };

      // Print request details
      print(' COMPLETE TRIP REQUEST:');
      print(' URL: ${ApiConstants.baseUrl}booking/endingTrip.php');
      print(' Data: $requestData');

      // Make the API call
      final response = await _dio.post(
        '${ApiConstants.baseUrl}booking/endingTrip.php',
        data: requestData,
        options: options,
      );

      // Print response details
      print(' COMPLETE TRIP RESPONSE:');
      print(' Status Code: ${response.statusCode}');
      print(' Data: ${response.data}');

      return {
        'success': true,
        'data': response.data,
        'message': response.data['message'] ?? 'Trip completed successfully',
      };
    } on DioException catch (e) {
      // Print error details
      print(' COMPLETE TRIP ERROR:');
      print('Error type: ${e.type}');
      if (e.response != null) {
        print('Status code: ${e.response?.statusCode}');
        print('Error response: ${e.response?.data}');
      } else {
        print('Error message: ${e.message}');
      }

      String errorMessage = 'Failed to complete trip';

      if (e.response != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
        await _handleTokenExpiration(errorMessage, context);
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Server response timeout';
      } else {
        errorMessage = 'Network error';
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      print(' UNEXPECTED ERROR: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Cancel trip with driver
  static Future<Map<String, dynamic>> cancelTripWithDriver({
    required String driverId,
    required String transactionId,
    required String reason,
  }) async {
    try {
      // Get the auth token
      final token = await StorageService.getToken();
      print("token&&&&&&&&&&&&&&&: $token");
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      // Set up headers with the bearer token
      final options = Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final requestData = {
        'driver_id': driverId,
        'transaction_id': transactionId,
        'reason': reason,
      };

      // Print request details
      print(' CANCEL TRIP REQUEST:');
      print(' URL: ${ApiConstants.baseUrl}booking/cancel_tritp_with_driver');
      print(' Data: $requestData');

      // Make the API call
      final response = await _dio.post(
        '${ApiConstants.baseUrl}booking/cancel_tritp_with_driver',
        data: requestData,
        options: options,
      );

      // Print response details
      print(' CANCEL TRIP RESPONSE:');
      print(' Status Code: ${response.statusCode}');
      print(' Data: ${response.data}');

      return {
        'success': true,
        'data': response.data,
        'message': response.data['message'] ?? 'Trip cancelled successfully',
      };
    } on DioException catch (e) {
      // Print error details
      print(' CANCEL TRIP ERROR:');
      print('Error type: ${e.type}');
      if (e.response != null) {
        print('Status code: ${e.response?.statusCode}');
        print('Error response: ${e.response?.data}');
      } else {
        print('Error message: ${e.message}');
      }

      String errorMessage = 'Failed to cancel trip';

      if (e.response != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Server response timeout';
      } else {
        errorMessage = 'Network error';
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      print(' UNEXPECTED ERROR: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Get canceled trips for driver
  static Future<Map<String, dynamic>> getCanceledTrips({
    required String driverId,
    int page = 1,
  }) async {
    try {
      final token = await StorageService.getToken();
      print("token&&&&&&&&&&&&&&&: $token");
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      final response = await _dio.get(
        '${ApiConstants.baseUrl}booking/driver_cancellation_history',
        queryParameters: {
          'driver_id': driverId,
          'page': page,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      return {
        'success': true,
        'cancellations': response.data['cancellations'] ?? [],
        'pagination': response.data['pagination'],
        'total_cancelled': response.data['total_cancelled'] ?? 0,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to fetch data',
      };
    }
  }

  // Get driver monthly rides statistics
  static Future<Map<String, dynamic>> getDriverMonthlyRides({
    required int driverId,
    BuildContext? context,
  }) async {
    try {
      // Get the auth token
      final token = await StorageService.getToken();
      print("token&&&&&&&&&&&&&&&: $token");
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      // Set up headers with the bearer token
      final options = Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      // Print request details
      print('🔍 GET DRIVER MONTHLY RIDES:');
      print(
          'URL: ${ApiConstants.baseUrl}driver/driver_monthlyride?driver_id=$driverId');

      // Make the API call
      final response = await _dio.get(
        '${ApiConstants.baseUrl}driver/driver_monthlyride?driver_id=$driverId',
        options: options,
      );

      // Print response details
      print('📊 MONTHLY RIDES RESPONSE:');
      print('Status Code: ${response.statusCode}');
      print('Data: ${response.data}');

      if (response.data['success'] == true) {
        return {
          'success': true,
          'data': response.data,
          'month': response.data['month'],
          'month_name': response.data['month_name'],
          'rides_count': response.data['rides_count'] ?? 0,
          'completed_rides': response.data['completed_rides'] ?? 0,
          'confirmed_rides': response.data['confirmed_rides'] ?? 0,
          'on_trip_rides': response.data['on_trip_rides'] ?? 0,
          'statistics': response.data['statistics'] ?? {},
          'is_current_month': response.data['is_current_month'] ?? false,
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to get monthly rides',
        };
      }
    } on DioException catch (e) {
      // Print error details
      print('❌ MONTHLY RIDES ERROR:');
      print('Error type: ${e.type}');
      if (e.response != null) {
        print('Status code: ${e.response?.statusCode}');
        print('Error response: ${e.response?.data}');
      } else {
        print('Error message: ${e.message}');
      }

      String errorMessage = 'Failed to get monthly rides';

      if (e.response != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
        await _handleTokenExpiration(errorMessage, context);
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Server response timeout';
      } else {
        errorMessage = 'Network error';
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      print('💥 UNEXPECTED ERROR: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }
}
