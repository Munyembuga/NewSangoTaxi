import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'storage_service.dart';

class CarCheckingService {
  static final Dio _dio = Dio();

  // Get eligible transactions
  static Future<Map<String, dynamic>> getEligibleTransactions() async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      final options = Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final response = await _dio.get(
        'https://sango.itecsoft.site/api/car_checking/get_eligible_transactions.php',
        options: options,
      );

      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      String errorMessage = 'Failed to get transactions';
      if (e.response != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
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

  // Get check types
  static Future<Map<String, dynamic>> getCheckTypes() async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      final options = Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final response = await _dio.get(
        'https://sango.itecsoft.site/api/car_checking/get_check_types.php',
        options: options,
      );

      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      String errorMessage = 'Failed to get check types';
      if (e.response != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
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

  // Create check
  static Future<Map<String, dynamic>> createCheck({
    required String transcode,
    required String checkingtype,
    required String amount,
    required String notes,
  }) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      final options = Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final response = await _dio.post(
        'https://mis.sangotaxi.com/api/car_checking/create_check.php',
        data: {
          'transcode': transcode,
          'checkingtype': checkingtype,
          'amount': amount,
          'notes': notes,
        },
        options: options,
      );

      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      String errorMessage = 'Failed to create check';
      if (e.response != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
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
}
