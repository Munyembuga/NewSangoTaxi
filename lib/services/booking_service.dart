import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../constants/api_constants.dart';
import 'storage_service.dart';
import 'device_info_service.dart';

class BookingService {
  static final Dio _dio = Dio();

  static Future<Map<String, dynamic>> getCategories(
      [BuildContext? context]) async {
    try {
      // Get token from storage
      final token = await StorageService.getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.getCategoriesEndpoint}',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      // The API now returns data directly under "data" key, not nested in "data.data"
      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      String errorMessage = 'Failed to fetch categories';

      if (e.response != null) {
        if (e.response?.statusCode == 401) {
          errorMessage = e.response?.data['message'];
        } else {
          errorMessage = e.response?.data['message'] ?? errorMessage;
        }
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
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  static Future<Map<String, dynamic>> getPriceByCategory(String categoryId,
      [BuildContext? context]) async {
    try {
      // Get token from storage
      final token = await StorageService.getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.getPriceByCategoryEndpoint}?catg_id=$categoryId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      String errorMessage = 'Failed to fetch category pricing';

      if (e.response != null) {
        if (e.response?.statusCode == 401) {
          errorMessage = e.response?.data['message'];
        } else {
          errorMessage = e.response?.data['message'] ?? errorMessage;
        }
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
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  static Future<Map<String, dynamic>> createBooking({
    required String pickupLocation,
    required double pickupLat,
    required double pickupLong,
    required String dropoffLocation,
    required double dropoffLat,
    required double dropoffLong,
    required String estimatedDuration,
    required String estimated_km,
    required String estimatedPrice,
    required int categoryId,
    String? phoneNumber,
    String? guestName,
    String? bookingTypeId, // Add booking type ID parameter
    BuildContext? context,
  }) async {
    try {
      // Check if user is in guest mode
      final isGuestMode = await StorageService.isGuestMode();

      Map<String, dynamic> requestData;

      if (isGuestMode) {
        // Guest booking - use device info and guest details
        final deviceId = await DeviceInfoService.getDeviceId();

        // Ensure estimated duration is not 0
        final parsedDuration = int.tryParse(estimatedDuration) ?? 0;
        final validDuration = parsedDuration > 0 ? parsedDuration : 15; // Default to 15 minutes

        requestData = {
          "device_id": deviceId,
          "phone_number": phoneNumber ?? "",
          "guest_name": guestName ?? "Guest User",
          "catg_id": categoryId,
          "booking_type":
              bookingTypeId ?? "1", // Include booking type ID with default
          "pickup_location": pickupLocation,
          "pickup_lat": pickupLat,
          "pickup_long": pickupLong,
          "dropoff_location": dropoffLocation,
          "dropoff_lat": dropoffLat,
          "dropoff_long": dropoffLong,
          "estimated_duration": validDuration,
          "estimated_km": estimated_km,
          "estimated_price": int.tryParse(estimatedPrice) ?? 0,
        };

        print('CREATE GUEST BOOKING REQUEST:');
        print('URL: ${ApiConstants.baseUrl}booking/create_guest_booking');
        print('Data: $requestData');

        final response = await _dio.post(
          '${ApiConstants.baseUrl}booking/create_booking',
          data: requestData,
          options: Options(
            headers: {
              'Content-Type': 'application/json',
            },
          ),
        );

        print(' CREATE GUEST BOOKING RESPONSE:');
        print(' Status Code: ${response.statusCode}');
        print(' Data: ${response.data}');

        return {
          'success': true,
          'data': response.data,
        };
      } else {
        // Regular authenticated booking
        final token = await StorageService.getToken();
        if (token == null) {
          return {
            'success': false,
            'message': 'Authentication token not found',
          };
        }

        // Get client data to extract client_id
        final clientData = await StorageService.getClientData();
        if (clientData == null) {
          return {
            'success': false,
            'message': 'Client data not found',
          };
        }

        final clientId = clientData['client_id'] ?? '1';

        // Ensure estimated duration is not 0
        final parsedDuration = int.tryParse(estimatedDuration) ?? 0;
        final validDuration = parsedDuration > 0 ? parsedDuration : 15; // Default to 15 minutes

        requestData = {
          "client_id": clientId,
          "pickup_location": pickupLocation,
          "pickup_lat": pickupLat,
          "pickup_long": pickupLong,
          "dropoff_location": dropoffLocation,
          "dropoff_lat": dropoffLat,
          "dropoff_long": dropoffLong,
          "estimated_duration": validDuration,
          "estimated_km": estimated_km,
          "estimated_price": estimatedPrice,
          "catg_id": categoryId,
          "booking_type":
              bookingTypeId ?? "1", // Include booking type ID with default
        };

        print(' CREATE BOOKING REQUEST:');
        print(' URL: ${ApiConstants.baseUrl}booking/create_booking');
        print(' Data: $requestData');

        final response = await _dio.post(
          '${ApiConstants.baseUrl}booking/create_booking',
          data: requestData,
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          ),
        );

        print(' CREATE BOOKING RESPONSE:');
        print(' Status Code: ${response.statusCode}');
        print(' Data: ${response.data}');

        return {
          'success': true,
          'data': response.data,
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to create booking';

      if (e.response != null) {
        print('CREATE BOOKING ERROR:');
        print('Status code: ${e.response?.statusCode}');
        print('Error response: ${e.response?.data}');

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

  static Future<Map<String, dynamic>> getPendingBookings(
      {int page = 1, BuildContext? context}) async {
    try {
      // Check if user is in guest mode
      final isGuestMode = await StorageService.isGuestMode();

      if (isGuestMode) {
        // For guest users, we need device_id and phone_number from storage or user input
        final deviceId = await DeviceInfoService.getDeviceId();

        // You might want to store the phone number when guest makes a booking
        // or prompt them to enter it for checking bookings
        // For now, we'll return an error asking them to provide phone number
        return {
          'success': false,
          'message': 'Please provide your phone number to check bookings',
          'guest_mode': true,
        };
      }

      // Regular authenticated user flow
      final token = await StorageService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.getPendingBookingsEndpoint}?page=$page',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      print(' PENDING BOOKINGS RESPONSE:');
      print(' Status Code: ${response.statusCode}');
      print(' Data: ${response.data}');

      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      String errorMessage = 'Failed to fetch pending bookings';

      if (e.response != null) {
        print(' PENDING BOOKINGS ERROR:');
        print('Status code: ${e.response?.statusCode}');
        print('Error response: ${e.response?.data}');
        print(' Token expired or invalid: ${e.response?.data['message']}');

        if (e.response?.statusCode == 401) {
          errorMessage = e.response?.data['message'];
          print(' Token expired or invalid: $errorMessage');
        } else {
          errorMessage = e.response?.data['message'] ?? errorMessage;
        }
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

  // Get pending bookings for guest users using device_id and phone_number
  static Future<Map<String, dynamic>> getGuestPendingBookings({
    required String deviceId,
    // required String phoneNumber,
    int page = 1,
  }) async {
    try {
      print(' GET GUEST PENDING BOOKINGS:');
      print(
          ' URL: ${ApiConstants.baseUrl}booking/pending_booking?device_id=$deviceId&page=$page');

      final response = await _dio.get(
        '${ApiConstants.baseUrl}booking/pending_booking',
        queryParameters: {
          'device_id': deviceId,
          // 'phone_number': phoneNumber,
          'page': page,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      print(' GUEST PENDING BOOKINGS RESPONSE:');
      print(' Status Code: ${response.statusCode}');
      print(' Data: ${response.data}');

      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      print(' GUEST PENDING BOOKINGS ERROR:');
      print('Error type: ${e.type}');
      if (e.response != null) {
        print('Status code: ${e.response?.statusCode}');
        print('Error response: ${e.response?.data}');
      } else {
        print('Error message: ${e.message}');
      }

      String errorMessage = 'Failed to fetch pending bookings';

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

  // Get on-trip bookings for guest users using device_id and phone_number
  static Future<Map<String, dynamic>> getGuestOnTripBookings({
    required String deviceId,
    // required String phoneNumber,
  }) async {
    try {
      print(' GET GUEST ON-TRIP BOOKINGS:');
      print(
          ' URL: ${ApiConstants.baseUrl}booking/client_active?device_id=$deviceId');

      final response = await _dio.get(
        '${ApiConstants.baseUrl}booking/client_active',
        queryParameters: {
          'device_id': deviceId,
          // 'phone_number': phoneNumber,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      print(' GUEST ON-TRIP BOOKINGS RESPONSE:');
      print(' Status Code: ${response.statusCode}');
      print(' Data: ${response.data}');

      // Transform the response to match the expected structure
      final responseData = response.data;
      final transformedData = {
        'bookings': responseData['active_trips'] ?? [],
        'pagination': {
          'current_page': 1,
          'total_pages': 1,
          'total': responseData['total_active'] ?? 0,
        },
        'client_on_trip': responseData['client_on_trip'] ?? false,
      };

      return {
        'success': true,
        'data': transformedData,
      };
    } on DioException catch (e) {
      print(' GUEST ON-TRIP BOOKINGS ERROR:');
      print('Error type: ${e.type}');
      if (e.response != null) {
        print('Status code: ${e.response?.statusCode}');
        print('Error response: ${e.response?.data}');
      } else {
        print('Error message: ${e.message}');
      }

      String errorMessage = 'Failed to fetch on-trip bookings';

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

  static Future<Map<String, dynamic>> getOnTripBookings(
      {int page = 1, BuildContext? context}) async {
    try {
      // Check if user is in guest mode
      final isGuestMode = await StorageService.isGuestMode();

      if (isGuestMode) {
        // For guest users, we need device_id and phone_number from storage or user input
        final deviceId = await DeviceInfoService.getDeviceId();

        // You might want to store the phone number when guest makes a booking
        // or prompt them to enter it for checking bookings
        // For now, we'll return an error asking them to provide phone number
        return {
          'success': false,
          'message': 'Please provide your phone number to check active trips',
          'guest_mode': true,
        };
      }

      // Regular authenticated user flow
      final token = await StorageService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      final response = await _dio.get(
        '${ApiConstants.baseUrl}booking/client_active',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      print(' ON TRIP BOOKINGS RESPONSE:');
      print(' Status Code: ${response.statusCode}');
      print(' Data: ${response.data}');

      // Transform the response to match the expected structure
      final responseData = response.data;
      final transformedData = {
        'bookings': responseData['active_trips'] ?? [],
        'pagination': {
          'current_page': 1,
          'total_pages': 1,
          'total': responseData['total_active'] ?? 0,
        },
        'client_on_trip': responseData['client_on_trip'] ?? false,
      };

      return {
        'success': true,
        'data': transformedData,
      };
    } on DioException catch (e) {
      String errorMessage = 'Failed to fetch on trip bookings';

      if (e.response != null) {
        print(' ON TRIP BOOKINGS ERROR:');
        print('Status code: ${e.response?.statusCode}');
        print('Error response: ${e.response?.data}');

        if (e.response?.statusCode == 401) {
          errorMessage = e.response?.data['message'];
          print('Token expired or invalid: $errorMessage');
        } else {
          errorMessage = e.response?.data['message'] ?? errorMessage;
        }
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

  // Get completed bookings for guest users using device_id and phone_number
  static Future<Map<String, dynamic>> getGuestCompletedBookings({
    required String deviceId,
    // required String phoneNumber,
    int page = 1,
  }) async {
    try {
      print(' GET GUEST COMPLETED BOOKINGS:');
      print(
          ' URL: ${ApiConstants.baseUrl}booking/client_completed?device_id=$deviceId&page=$page');

      final response = await _dio.get(
        '${ApiConstants.baseUrl}booking/client_completed',
        queryParameters: {
          'device_id': deviceId,
          // 'phone_number': phoneNumber,
          'page': page,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      print(' GUEST COMPLETED BOOKINGS RESPONSE:');
      print(' Status Code: ${response.statusCode}');
      print(' Data: ${response.data}');

      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      print(' GUEST COMPLETED BOOKINGS ERROR:');
      print('Error type: ${e.type}');
      if (e.response != null) {
        print('Status code: ${e.response?.statusCode}');
        print('Error response: ${e.response?.data}');
      } else {
        print('Error message: ${e.message}');
      }

      String errorMessage = 'Failed to fetch completed bookings';

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

  static Future<Map<String, dynamic>> getCompletedBookings(
      {int page = 1, BuildContext? context}) async {
    try {
      // Check if user is in guest mode
      final isGuestMode = await StorageService.isGuestMode();

      if (isGuestMode) {
        // For guest users, we need device_id and phone_number from storage or user input
        final deviceId = await DeviceInfoService.getDeviceId();

        // You might want to store the phone number when guest makes a booking
        // or prompt them to enter it for checking bookings
        // For now, we'll return an error asking them to provide phone number
        return {
          'success': false,
          'message':
              'Please provide your phone number to check completed trips',
          'guest_mode': true,
        };
      }

      // Regular authenticated user flow
      final token = await StorageService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      final response = await _dio.get(
        '${ApiConstants.baseUrl}booking/client_completed?page=$page',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      print(' COMPLETED BOOKINGS RESPONSE:');
      print(' Status Code: ${response.statusCode}');
      print(' Data: ${response.data}');

      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      String errorMessage = 'Failed to fetch completed bookings';

      if (e.response != null) {
        print(' COMPLETED BOOKINGS ERROR:');
        print('Status code: ${e.response?.statusCode}');
        print('Error response: ${e.response?.data}');

        if (e.response?.statusCode == 401) {
          errorMessage = e.response?.data['message'];
          print('Token expired or invalid: $errorMessage');
        } else {
          errorMessage = e.response?.data['message'] ?? errorMessage;
        }
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

  // Get booking types (no auth required)
  static Future<Map<String, dynamic>> getBookingTypes() async {
    try {
      print(' GET BOOKING TYPES:');
      print(' URL: ${ApiConstants.baseUrl}booking/scr/get_booking_types');

      final response = await _dio.get(
        '${ApiConstants.baseUrl}booking/scr/get_booking_types',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      print(' BOOKING TYPES RESPONSE:');
      print(' Status Code: ${response.statusCode}');
      print(' Data: ${response.data}');

      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      print(' BOOKING TYPES ERROR:');
      print('Error type: ${e.type}');
      if (e.response != null) {
        print('Status code: ${e.response?.statusCode}');
        print('Error response: ${e.response?.data}');
      } else {
        print('Error message: ${e.message}');
      }

      String errorMessage = 'Failed to fetch booking types';

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

  // Get categories by booking type ID (no auth required)
  static Future<Map<String, dynamic>> getCategoriesByBookingType(
      String bookingTypeId) async {
    try {
      print(' GET CATEGORIES BY BOOKING TYPE:');
      print(
          ' URL: ${ApiConstants.baseUrl}booking/scr/get_categories?booking_type_id=$bookingTypeId');

      final response = await _dio.get(
        '${ApiConstants.baseUrl}booking/scr/get_categories?booking_type_id=$bookingTypeId',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      print(' CATEGORIES BY BOOKING TYPE RESPONSE:');
      print(' Status Code: ${response.statusCode}');
      print(' Data: ${response.data}');

      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      print(' CATEGORIES BY BOOKING TYPE ERROR:');
      print('Error type: ${e.type}');
      if (e.response != null) {
        print('Status code: ${e.response?.statusCode}');
        print('Error response: ${e.response?.data}');
      } else {
        print('Error message: ${e.message}');
      }

      String errorMessage = 'Failed to fetch categories';

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
      print('UNEXPECTED ERROR: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Get price by category and booking type with discounts
  static Future<Map<String, dynamic>> getPriceByCategoryAndType({
    required String categoryId,
    required String bookingTypeId,
  }) async {
    try {
      final String url =
          '${ApiConstants.baseUrl}booking/scr/get_pricebycateg?catg_id=$categoryId&booking_type_id=$bookingTypeId';
      print(' GET PRICE WITH DISCOUNTS REQUEST:');
      print(' URL: $url');

      final response = await _dio.get(url);

      print(' PRICE WITH DISCOUNTS RESPONSE:');
      print(' Status Code: ${response.statusCode}');
      print(' Data: ${response.data}');

      // Handle the response structure that includes discounts
      if (response.data['success'] == true && response.data['data'] != null) {
        return {
          'success': true,
          'data': response.data['data'],
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to fetch pricing data',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to fetch price information';

      if (e.response != null) {
        print(' GET PRICE WITH DISCOUNTS ERROR:');
        print('Status code: ${e.response?.statusCode}');
        print('Error response: ${e.response?.data}');
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

  static Future<Map<String, dynamic>> rentCar({
    required int categoryId,
    required String bookingTypeId,
    required String pickupLocation,
    required int rentalDurationValue,
    required String rentalDurationUnit,
    required String rentalStart,
    required String rentalEnd,
    required double estimatedPrice,
    String? clientId,
    String? deviceId,
    String? phoneNumber,
    String? guestName,
  }) async {
    try {
      final token = await StorageService.getToken();
      if (token == null && clientId != null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      final requestData = {
        "catg_id": categoryId,
        "booking_type_id": bookingTypeId,
        "pickup_location": pickupLocation,
        "rental_duration_value": rentalDurationValue,
        "rental_duration_unit": rentalDurationUnit,
        "rental_start": rentalStart,
        "rental_end": rentalEnd,
        "estimated_price": estimatedPrice,
        if (clientId != null) "client_id": clientId,
        if (deviceId != null) "device_id": deviceId,
        if (phoneNumber != null) "phone_number": phoneNumber,
        if (guestName != null) "guest_name": guestName,
      };

      print(' RENT CAR REQUEST:');
      print(' URL: ${ApiConstants.baseUrl}booking/renting/newRent');
      print(' Data: $requestData');

      final response = await _dio.post(
        '${ApiConstants.baseUrl}booking/renting/newRent',
        data: requestData,
        options: Options(
          headers: {
            if (clientId != null) 'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      print(' RENT CAR RESPONSE:');
      print(' Status Code: ${response.statusCode}');
      print(' Data: ${response.data}');

      return {
        'success': true,
        'data': response.data,
        'message': response.data['message'] ?? 'Car rented successfully',
      };
    } on DioException catch (e) {
      print(' RENT CAR ERROR:');
      print('Error type: ${e.type}');
      if (e.response != null) {
        print('Status code: ${e.response?.statusCode}');
        print('Error response: ${e.response?.data}');
      } else {
        print('Error message: ${e.message}');
      }

      String errorMessage = 'Failed to rent car';

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

  // Get pending rentals - works for both registered and guest users
  static Future<Map<String, dynamic>> getPendingRentals() async {
    try {
      // Check if user is in guest mode
      final isGuestMode = await StorageService.isGuestMode();
      String url;

      if (isGuestMode) {
        // For guest users, use device ID without phone number
        final deviceId = await DeviceInfoService.getDeviceId();

        // Return error for guest users - they should use getPendingRentalsWithPhone instead
        return {
          'success': false,
          'message': 'Please provide your phone number to check bookings',
          'guest_mode': true,
        };
      } else {
        // For registered users, use client ID
        final clientData = await StorageService.getClientData();
        final clientId = clientData?['client_id'] ?? '1';
        url =
            '${ApiConstants.baseUrl}booking/renting/get_pending_renting?client_id=$clientId';

        // Add token for authenticated users
        final token = await StorageService.getToken();
        if (token == null) {
          return {
            'success': false,
            'message': 'Authentication token not found',
          };
        }

        print(' FETCHING PENDING RENTALS:');
        print(' URL: $url');

        final response = await _dio.get(url);

        print(' PENDING RENTALS RESPONSE:');
        print(' Status Code: ${response.statusCode}');
        print(' Data: ${response.data}');

        return {
          'success': true,
          'data': response.data,
        };
      }
    } on DioException catch (e) {
      print(' PENDING RENTALS ERROR:');
      String errorMessage = 'Failed to fetch pending rentals';

      if (e.response != null) {
        print('Status code: ${e.response?.statusCode}');
        print('Error response: ${e.response?.data}');
        errorMessage = e.response?.data['message'] ?? errorMessage;
      } else {
        print('Error type: ${e.type}');
        print('Error message: ${e.message}');
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

  // Get pending rentals with specific phone number - for guest users
  static Future<Map<String, dynamic>> getPendingRentalsWithPhone({
    required String deviceId,
    // required String phoneNumber,
  }) async {
    try {
      final url =
          '${ApiConstants.baseUrl}booking/renting/get_pending_renting?device_id=$deviceId';

      print(' FETCHING PENDING RENTALS WITH PHONE:');
      print(' URL: $url');
      // print(' Phone: $phoneNumber');
      print(' Device ID: $deviceId');

      final response = await _dio.get(url);

      print(' PENDING RENTALS RESPONSE:');
      print(' Status Code: ${response.statusCode}');
      print(' Data: ${response.data}');

      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      print(' PENDING RENTALS WITH PHONE ERROR:');
      String errorMessage = 'Failed to fetch pending rentals';

      if (e.response != null) {
        print('Status code: ${e.response?.statusCode}');
        print('Error response: ${e.response?.data}');
        errorMessage = e.response?.data['message'] ?? errorMessage;
      } else {
        print('Error type: ${e.type}');
        print('Error message: ${e.message}');
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

  // Get confirmed rentals - works for both registered and guest users
  static Future<Map<String, dynamic>> getConfirmedRentals() async {
    try {
      // Check if user is in guest mode
      final isGuestMode = await StorageService.isGuestMode();
      String url;

      if (isGuestMode) {
        // For guest users, use device ID without phone number
        final deviceId = await DeviceInfoService.getDeviceId();

        // Return error for guest users - they should use getConfirmedRentalsWithPhone instead
        return {
          'success': false,
          'message':
              'Please provide your phone number to check confirmed bookings',
          'guest_mode': true,
        };
      } else {
        // For registered users, use client ID
        final clientData = await StorageService.getClientData();
        final clientId = clientData?['client_id'] ?? '1';
        url =
            '${ApiConstants.baseUrl}booking/renting/get_confirmed_renting?client_id=$clientId';

        // Add token for authenticated users
        final token = await StorageService.getToken();
        if (token == null) {
          return {
            'success': false,
            'message': 'Authentication token not found',
          };
        }

        print(' FETCHING CONFIRMED RENTALS:');
        print(' URL: $url');

        final response = await _dio.get(url);

        print(' CONFIRMED RENTALS RESPONSE:');
        print(' Status Code: ${response.statusCode}');
        print(' Data: ${response.data}');

        return {
          'success': true,
          'data': response.data,
        };
      }
    } on DioException catch (e) {
      print('CONFIRMED RENTALS ERROR:');
      String errorMessage = 'Failed to fetch confirmed rentals';

      if (e.response != null) {
        print('Status code: ${e.response?.statusCode}');
        print('Error response: ${e.response?.data}');
        errorMessage = e.response?.data['message'] ?? errorMessage;
      } else {
        print('Error type: ${e.type}');
        print('Error message: ${e.message}');
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

  // Get confirmed rentals with specific phone number - for guest users
  static Future<Map<String, dynamic>> getConfirmedRentalsWithPhone({
    required String deviceId,
    // required String phoneNumber,
  }) async {
    try {
      final url =
          '${ApiConstants.baseUrl}booking/renting/get_confirmed_renting?device_id=$deviceId';

      print(' FETCHING CONFIRMED RENTALS WITH PHONE:');
      print(' URL: $url');
      // print(' Phone: $phoneNumber');
      print(' Device ID: $deviceId');

      final response = await _dio.get(url);

      print(' CONFIRMED RENTALS RESPONSE:');
      print(' Status Code: ${response.statusCode}');
      print(' Data: ${response.data}');

      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      print(' CONFIRMED RENTALS WITH PHONE ERROR:');
      String errorMessage = 'Failed to fetch confirmed rentals';

      if (e.response != null) {
        print('Status code: ${e.response?.statusCode}');
        print('Error response: ${e.response?.data}');
        errorMessage = e.response?.data['message'] ?? errorMessage;
      } else {
        print('Error type: ${e.type}');
        print('Error message: ${e.message}');
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

  // Process payment for a booking
  static Future<Map<String, dynamic>> processPayment({
    required String bookingId,
    required double paymentAmount,
    required String paymentModeId,
    String? clientId,
    String? deviceId,
    String? phoneNumber,
  }) async {
    try {
      final isGuestMode = await StorageService.isGuestMode();
      Map<String, dynamic> requestData;

      // Convert paymentModeId to int to ensure proper type
      // int paymentModeIdInt;
      // try {
      //   paymentModeIdInt = int.parse(paymentModeId);
      // } catch (e) {
      //   print('Error parsing paymentModeId: $e, using default value 1');
      //   paymentModeIdInt = 1;
      // }

      if (isGuestMode) {
        // Guest payment
        final actualDeviceId =
            deviceId ?? await DeviceInfoService.getDeviceId();

        requestData = {
          "device_id": actualDeviceId,
          "phone_number": phoneNumber ?? "",
          "booking_id": bookingId,
          "payment_amount": paymentAmount,
          "payment_mode_id": paymentModeId, // Use int value
        };
      } else {
        // Registered user payment
        final token = await StorageService.getToken();
        if (token == null) {
          return {
            'success': false,
            'message': 'Authentication token not found',
          };
        }

        final userData = await StorageService.getClientData();
        final actualClientId = clientId ?? userData?['client_id'] ?? '0';
        print("Using client ID: $actualClientId");
        requestData = {
          "client_id": actualClientId,
          "booking_id": bookingId,
          "payment_amount": paymentAmount,
          "payment_mode_id": paymentModeId, // Use int value
        };
      }

      print(' PROCESS PAYMENT REQUEST:');
      print(' URL: ${ApiConstants.baseUrl}booking/renting/confirm_renting.php');
      print(' Data: $requestData');

      final response = await _dio.post(
        '${ApiConstants.baseUrl}booking/renting/confirm_renting.php',
        data: requestData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (!isGuestMode)
              'Authorization': 'Bearer ${await StorageService.getToken()}',
          },
        ),
      );

      print(' PAYMENT RESPONSE:');
      print(' Status Code: ${response.statusCode}');
      print(' Data: ${response.data}');

      return {
        'success': true,
        'data': response.data,
        'message': response.data['message'] ?? 'Payment processed successfully',
      };
    } on DioException catch (e) {
      print(' PAYMENT ERROR:');
      print('Error type: ${e.type}');
      if (e.response != null) {
        print('Status code: ${e.response?.statusCode}');
        print('Error response: ${e.response?.data}');
      } else {
        print('Error message: ${e.message}');
      }

      String errorMessage = 'Failed to process payment';

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

  // Fetch available payment modes - improved version
  static Future<Map<String, dynamic>> getPaymentModes() async {
    try {
      final url = '${ApiConstants.baseUrl}payment/get_payment_modes';

      print(' FETCHING PAYMENT MODES:');
      print(' URL: $url');

      // Set a shorter timeout for better UX
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ),
      );

      print(' PAYMENT MODES RESPONSE:');
      print(' Status Code: ${response.statusCode}');
      print(' Data: ${response.data}');

      if (response.data.containsKey('payment_modes')) {
        return {
          'success': true,
          'data': response.data,
        };
      } else if (response.data.containsKey('data') &&
          response.data['data'].containsKey('payment_modes')) {
        // Handle nested data structure
        return {
          'success': true,
          'data': {
            'payment_modes': response.data['data']['payment_modes'],
            'total_modes': response.data['data']['payment_modes'].length,
          },
        };
      } else {
        // Create a standardized format if API structure is unexpected
        return {
          'success': true,
          'data': {
            'payment_modes': response.data,
            'total_modes': response.data is List ? response.data.length : 0,
          },
        };
      }
    } on DioException catch (e) {
      // If timeout or other network error, fail fast
      print(' GET PAYMENT MODES ERROR: ${e.type}');
      return {
        'success': false,
        'message': 'Connection error - please try again',
      };
    } catch (e) {
      print(' UNEXPECTED ERROR: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }
}
