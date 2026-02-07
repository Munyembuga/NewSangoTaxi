import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:sango/models/guest_user_model.dart';
import 'package:sango/services/device_info_service.dart';
import 'package:sango/services/storage_service.dart';

class UserService {
  static const String baseUrl = 'https://mis.sangotaxi.com/api';

  static Future<Map<String, dynamic>> getGuestUserInfo() async {
    try {
      final deviceId = await DeviceInfoService.getDeviceId();

      final response = await http.get(
        Uri.parse('$baseUrl/clientDash/guest_client_info?device_id=$deviceId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          final guestUserInfo = GuestUserModel.fromJson(data);

          return {
            'success': true,
            'data': guestUserInfo,
            'message': 'Guest user information retrieved successfully',
          };
        } else {
          return {
            'success': false,
            'data': null,
            'message':
                data['message'] ?? 'Failed to load guest user information',
          };
        }
      } else {
        return {
          'success': false,
          'data': null,
          'message': 'HTTP Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'data': null,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Update user profile
  /// Endpoint: /profile_api.php?action=update_profile
  static Future<Map<String, dynamic>> updateProfile({
    required String firstName,
    required String lastName,
    String? email,
    String? phoneNumber,
  }) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      final Map<String, dynamic> requestBody = {
        'action': 'update_profile',
        'fname': firstName,
        'lname': lastName,
      };

      // Add optional fields if provided
      if (email != null && email.isNotEmpty) {
        requestBody['email'] = email;
      }
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        requestBody['phone_number'] = phoneNumber;
      }

      print('UPDATE PROFILE REQUEST:');
      print(' URL: $baseUrl/profile_api.php?action=update_profile');
      print(' Data: $requestBody');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/profile_api.php?action=update_profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      print('UPDATE PROFILE RESPONSE:');
      print(' Status Code: ${response.statusCode}');
      print(' Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          // Update local storage with new data
          final userData = await StorageService.getUserData();
          if (userData != null) {
            userData['fname'] = firstName;
            userData['lname'] = lastName;
            if (email != null && email.isNotEmpty) {
              userData['email'] = email;
            }
            if (phoneNumber != null && phoneNumber.isNotEmpty) {
              userData['phone_number'] = phoneNumber;
            }
            await StorageService.saveUserData(userData);
          }

          // Also update client data if exists
          final clientData = await StorageService.getClientData();
          if (clientData != null) {
            clientData['f_name'] = firstName;
            clientData['l_name'] = lastName;
            if (email != null && email.isNotEmpty) {
              clientData['email'] = email;
            }
            if (phoneNumber != null && phoneNumber.isNotEmpty) {
              clientData['phone_number'] = phoneNumber;
            }
            await StorageService.saveClientData(clientData);
          }

          return {
            'success': true,
            'data': data,
            'message': data['message'] ?? 'Profile updated successfully',
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to update profile',
          };
        }
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        return {
          'success': false,
          'message':
              errorData['message'] ?? 'HTTP Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('UPDATE PROFILE ERROR: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Get user profile
  /// Endpoint: /profile_api.php?action=get_profile
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile_api.php?action=get_profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          return {
            'success': true,
            'data': data['data'],
            'message': 'Profile retrieved successfully',
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to get profile',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'HTTP Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Update profile image using file upload
  /// Endpoint: /ajax/profile_api.php?action=update_profile_image
  static Future<Map<String, dynamic>> updateProfileImage(File imageFile) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/auth/profile_api.php?action=update_profile_image'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(
        await http.MultipartFile.fromPath(
          'profile_image',
          imageFile.path,
        ),
      );

      print('UPDATE PROFILE IMAGE REQUESThh:');
      print(' URL: $baseUrl/auth/profile_api.php?action=update_profile_image');
      print(' File: ${imageFile.path}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('UPDATE PROFILE IMAGE RESPONSE:');
      print(' Status Code: ${response.statusCode}');
      print(' Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          // Save the image URL to local storage
          final imageUrl = data['image_url'] ?? data['profile_image'];
          if (imageUrl != null) {
            await StorageService.saveProfileImageUrl(imageUrl);
          }

          return {
            'success': true,
            'data': data,
            'imageUrl': imageUrl,
            'message': data['message'] ?? 'Profile image updated successfully',
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to update profile image',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'HTTP Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('UPDATE PROFILE IMAGE ERROR: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Update profile image using base64
  /// Endpoint: /ajax/profile_api.php?action=update_profile_image
  static Future<Map<String, dynamic>> updateProfileImageBase64(
      String base64Image) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }
      print("base64Image $base64Image");
      final response = await http.post(
        Uri.parse('$baseUrl/auth/profile_api.php?action=update_profile_image'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'base64': base64Image,
        }),
      );

      print('UPDATE PROFILE IMAGE BASE64 RESPONSE:');
      print(' Status Code: ${response.statusCode}');
      print(' Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          final imageUrl = data['image_url'] ?? data['profile_image'];
          if (imageUrl != null) {
            await StorageService.saveProfileImageUrl(imageUrl);
          }

          return {
            'success': true,
            'data': data,
            'imageUrl': imageUrl,
            'message': data['message'] ?? 'Profile image updated successfully',
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to update profile image',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'HTTP Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('UPDATE PROFILE IMAGE BASE64 ERROR: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Get profile image URL
  /// Endpoint: /ajax/profile_api.php?action=get_profile_image
  static Future<Map<String, dynamic>> getProfileImage() async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile_api.php?action=get_profile_image'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('GET PROFILE IMAGE RESPONSE:');
      print(' Status Code: ${response.statusCode}');
      print(' Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          final imageUrl = data['image_url'] ??
              data['profile_image'] ??
              data['data']?['profile_image'];

          if (imageUrl != null) {
            await StorageService.saveProfileImageUrl(imageUrl);
          }

          return {
            'success': true,
            'imageUrl': imageUrl,
            'message': 'Profile image retrieved successfully',
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to get profile image',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'HTTP Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('GET PROFILE IMAGE ERROR: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
}
