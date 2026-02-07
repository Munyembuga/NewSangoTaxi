import 'package:dio/dio.dart';
import 'package:sango/services/device_info_service.dart';

import '../constants/api_constants.dart';
import 'storage_service.dart';

class AuthService {
  static final Dio _dio = Dio();

  static Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phoneNumber,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.registerEndpoint}',
        data: {
          'fname': firstName,
          'lname': lastName,
          'email': email,
          'password': password,
          'phone_number': phoneNumber,
        },
      );

      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      String errorMessage = 'Registration failed';

      if (e.response != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
        // errorMessage = e.response?.data['message'] ?? errorMessage;
        print("&&&&&&&&&&&&&&&&&:  ${e.response?.data['message']}");
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

  static Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.verifyOtpEndpoint}',
        data: {
          'email': email,
          'otp': otp,
        },
      );

      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      String errorMessage = 'OTP verification failed';

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
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  static Future<Map<String, dynamic>> resendOtp({
    required String email,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.resendOtpEndpoint}',
        data: {
          'email': email,
        },
      );

      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      String errorMessage = 'Failed to resend OTP';

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
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  static Future<Map<String, dynamic>> login({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      // Get device info to include with login
      String deviceId = await DeviceInfoService.getDeviceId();
      String deviceName = await DeviceInfoService.getDeviceName();

      print('LOGIN REQUEST:');
      print(' URL: ${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}');

      final requestData = {
        'phone_number': phoneNumber,
        'password': password,
        'device_id': deviceId,
        'device_name': deviceName,
      };

      print('Data: ${requestData.toString().replaceAll(password, '****')}');
      final response = await _dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}',
        data: requestData,
      );

      if (response.data['success'] == true) {
        print("Login successful@@@@@@@@@@@:${response.data}");
        String userRole = response.data['user']['role'].toString();

        bool dataSaved = false; // Flag to prevent multiple save attempts

        if (userRole == '4' && !dataSaved) {
          // Client login - save with client data and company data
          await StorageService.saveLoginData(
            token: response.data['token'],
            userData: response.data['user'],
            clientData: response.data['client_data'],
            userType: response.data['user_type'],
            companyData: response.data['company_data'],
          );
          dataSaved = true;
        } else if (userRole == '3' && !dataSaved) {
          // Driver login - save with driver data and company data
          print("Driver data before saving: ${response.data['driver_data']}");

          // Verify driver_data exists before saving
          if (response.data.containsKey('driver_data') &&
              response.data['driver_data'] != null) {
            await StorageService.saveLoginData(
              token: response.data['token'],
              userData: response.data['user'],
              driverData: response.data['driver_data'],
              userType: response.data['user_type'],
              companyData: response.data['company_data'],
            );
            dataSaved = true;

            // Verify the data was saved correctly
            final savedDriverData = await StorageService.getDriverData();
            print("Driver data after saving: $savedDriverData");
          } else {
            print("ERROR: Missing driver_data in login response");
          }
        } else if (userRole == '6' && !dataSaved) {
          // Role 6 user login - save user data with company data
          await StorageService.saveLoginData(
            token: response.data['token'],
            userData: response.data['user'],
            userType: response.data['user_type'],
            companyData: response.data['company_data'],
          );
          dataSaved = true;
          print("Role 6 user data saved successfully");
        } else if (!dataSaved) {
          // Other roles - save basic user data with company data
          await StorageService.saveLoginData(
            token: response.data['token'],
            userData: response.data['user'],
            userType: response.data['user_type'],
            companyData: response.data['company_data'],
          );
          dataSaved = true;
          print("User data saved for role: $userRole");
        }
      }

      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      String errorMessage = 'Login failed';
      print(errorMessage);
      print(e);

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
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
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
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }
      print("token: $token");
      // Set up headers with the bearer token
      final options = Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      // Make the API call
      final response = await _dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.updateDriverStatusEndpoint}',
        data: {
          'driver_id': driverId,
          'status': status,
        },
        options: options,
      );
      print("RESPONSE: ${response.data}");

      // Check if the response indicates success
      if (response.data['success'] == true) {
        return {
          'success': true,
          'data': response.data,
          'status': response.data['status'],
        };
      } else {
        // API returned success: false
        return {
          'success': false,
          'message':
              response.data['message'] ?? 'Failed to update driver status',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to update driver status';

      if (e.response != null) {
        // Try to extract the message from the response
        final responseData = e.response?.data;
        if (responseData is Map<String, dynamic>) {
          errorMessage = responseData['message'] ?? errorMessage;
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

  // Delete account method
  static Future<Map<String, dynamic>> deleteAccount() async {
    try {
      // Get the auth token
      final token = await StorageService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      print('DELETE ACCOUNT REQUEST:');
      print(' URL: ${ApiConstants.baseUrl}auth/manage_account.php');

      final requestData = {
        'action': 'delete',
      };

      print('Data: $requestData');

      // Set up headers with the bearer token
      final options = Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final response = await _dio.post(
        '${ApiConstants.baseUrl}auth/manage_account.php',
        data: requestData,
        options: options,
      );

      print('DELETE ACCOUNT RESPONSE:');
      print(' Status Code: ${response.statusCode}');
      print(' Data: ${response.data}');

      return {
        'success': true,
        'data': response.data,
        'message': response.data['message'] ?? 'Account deleted successfully',
      };
    } on DioException catch (e) {
      String errorMessage = 'Failed to delete account';

      if (e.response != null) {
        print('DELETE ACCOUNT ERROR:');
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
      print('UNEXPECTED ERROR: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Logout method
  static Future<void> logout() async {
    await StorageService.clearAll();
  }

  // Forget Password - Step 1: Send reset token to email
  static Future<Map<String, dynamic>> sendOTP({
    required String email,
  }) async {
    try {
      print('FORGOT PASSWORD REQUEST:');
      print(' URL: ${ApiConstants.baseUrl}auth/forgetPassword');

      final requestData = {
        'action': 'forgot_password',
        'email': email,
      };

      print('Data: $requestData');

      final response = await _dio.post(
        '${ApiConstants.baseUrl}auth/forgetPassword',
        data: requestData,
      );

      print('FORGOT PASSWORD RESPONSE:');
      print(' Status Code: ${response.statusCode}');
      print(' Data: ${response.data}');

      return {
        'success': true,
        'data': response.data,
        'message': response.data['message'] ?? 'Reset token sent to your email',
      };
    } on DioException catch (e) {
      String errorMessage = 'Failed to send reset token';

      if (e.response != null) {
        print('FORGOT PASSWORD ERROR:');
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
      print('UNEXPECTED ERROR: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Forget Password - Step 2: Verify reset token (OTP)
  static Future<Map<String, dynamic>> verifyOTP({
    required String email,
    required String otp,
  }) async {
    try {
      print('VERIFY RESET TOKEN REQUEST:');
      print(' URL: ${ApiConstants.baseUrl}auth/forgetPassword');

      final requestData = {
        'action': 'verify_reset_token',
        'email': email,
        'reset_token': otp,
      };

      print('Data: $requestData');

      final response = await _dio.post(
        '${ApiConstants.baseUrl}auth/forgetPassword',
        data: requestData,
      );

      print('VERIFY RESET TOKEN RESPONSE:');
      print(' Status Code: ${response.statusCode}');
      print(' Data: ${response.data}');

      return {
        'success': true,
        'data': response.data,
        'message':
            response.data['message'] ?? 'Reset token verified successfully',
      };
    } on DioException catch (e) {
      String errorMessage = 'Failed to verify reset token';

      if (e.response != null) {
        print('VERIFY RESET TOKEN ERROR:');
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
      print('UNEXPECTED ERROR: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Forget Password - Step 3: Reset password with verified token
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      print('RESET PASSWORD REQUEST:');
      print(' URL: ${ApiConstants.baseUrl}auth/forgetPassword');

      final requestData = {
        'action': 'reset_password',
        'email': email,
        'reset_token': otp,
        'new_password': newPassword,
      };

      print('Data: ${requestData.toString().replaceAll(newPassword, '****')}');

      final response = await _dio.post(
        '${ApiConstants.baseUrl}auth/forgetPassword',
        data: requestData,
      );

      print('RESET PASSWORD RESPONSE:');
      print(' Status Code: ${response.statusCode}');
      print(' Data: ${response.data}');

      return {
        'success': true,
        'data': response.data,
        'message': response.data['message'] ?? 'Password reset successfully',
      };
    } on DioException catch (e) {
      String errorMessage = 'Failed to reset password';

      if (e.response != null) {
        print('RESET PASSWORD ERROR:');
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
      print('UNEXPECTED ERROR: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }
}
