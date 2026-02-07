import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class StorageService {
  static const _storage = FlutterSecureStorage();

  // Storage keys
  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';
  static const String _clientDataKey = 'client_data';
  static const String _userTypeKey = 'user_type';
  static const String _driverDataKey = 'driver_data';
  static const String _companyDataKey = 'company_data';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _isGuestModeKey = 'is_guest_mode';
  static const String _guestPhoneKey = 'guest_phone_number';
  static const String _profileImageUrlKey = 'profile_image_url';

  // Save login data - made parameters optional to handle both client and driver
  static Future<void> saveLoginData({
    required String token,
    required Map<String, dynamic> userData,
    Map<String, dynamic>? clientData,
    required String userType,
    Map<String, dynamic>? driverData,
    Map<String, dynamic>? companyData,
  }) async {
    // Add stack trace to debug where this method is being called from
    print("saveLoginData called from:\n${StackTrace.current}");

    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userDataKey, value: jsonEncode(userData));
    await _storage.write(key: _userTypeKey, value: userType);
    await _storage.write(key: _isLoggedInKey, value: 'true');

    // Clear any previous data to avoid conflicts
    await _storage.delete(key: _clientDataKey);
    await _storage.delete(key: _driverDataKey);
    await _storage.delete(key: _companyDataKey);

    // Save client data only if provided
    if (clientData != null) {
      await _storage.write(key: _clientDataKey, value: jsonEncode(clientData));
      print("Saved client data: $clientData");
    }

    // Save driver data only if provided - ADD VALIDATION
    if (driverData != null) {
      // Verify we're saving actual driver data, not user data accidentally
      if (driverData.containsKey('driver_id')) {
        await _storage.write(
            key: _driverDataKey, value: jsonEncode(driverData));
        print("Saved driver data: $driverData");
      } else {
        print("WARNING: Attempted to save invalid driver data: $driverData");
        print("Driver data must contain driver_id field");
        // Don't save if it doesn't look like valid driver data
      }
    }

    // Save company data if provided
    if (companyData != null) {
      await _storage.write(
          key: _companyDataKey, value: jsonEncode(companyData));
      print("Saved company data: $companyData");
    }
  }

  // Save guest session data
  static Future<void> saveGuestSession({String? phoneNumber}) async {
    await _storage.write(key: _isGuestModeKey, value: 'true');
    await _storage.write(key: _isLoggedInKey, value: 'true');

    // Set default user type for guests
    await _storage.write(key: _userTypeKey, value: 'guest');

    // Create basic user data for guest
    final guestData = {
      'id': 'guest',
      'name': 'Guest User',
      'email': '',
      'role': '4', // Client role
    };

    await _storage.write(key: _userDataKey, value: jsonEncode(guestData));

    if (phoneNumber != null) {
      await saveGuestPhoneNumber(phoneNumber);
    }

    print("Guest session saved");
  }

  // Save guest phone number for future reference
  static Future<void> saveGuestPhoneNumber(String phoneNumber) async {
    await _storage.write(key: _guestPhoneKey, value: phoneNumber);
  }

  // Get saved guest phone number
  static Future<String?> getGuestPhoneNumber() async {
    return await _storage.read(key: _guestPhoneKey);
  }

  // Get token
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Get user data
  static Future<Map<String, dynamic>?> getUserData() async {
    final userData = await _storage.read(key: _userDataKey);
    if (userData != null) {
      return jsonDecode(userData);
    }
    return null;
  }

  // Save user data
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _storage.write(key: _userDataKey, value: jsonEncode(userData));
    print("Updated user data: $userData");
  }

  // Get client data
  static Future<Map<String, dynamic>?> getClientData() async {
    final clientData = await _storage.read(key: _clientDataKey);
    if (clientData != null) {
      return jsonDecode(clientData);
    }
    return null;
  }

  // Save client data
  static Future<void> saveClientData(Map<String, dynamic> clientData) async {
    await _storage.write(key: _clientDataKey, value: jsonEncode(clientData));
    print("Updated client data: $clientData");
  }

  // Get driver data with additional validation
  static Future<Map<String, dynamic>?> getDriverData() async {
    final driverData = await _storage.read(key: _driverDataKey);
    if (driverData != null) {
      try {
        final decodedData = jsonDecode(driverData);
        print("Retrieved driver data from storage: $decodedData");

        // Verify this is actually driver data by checking for driver-specific fields
        if (decodedData.containsKey('driver_id')) {
          return decodedData;
        } else {
          print("Warning: Retrieved data does not contain driver_id field");
          return decodedData; // Return anyway for backward compatibility
        }
      } catch (e) {
        print("Error decoding driver data: $e");
        return null;
      }
    }
    return null;
  }

  // Get company data
  static Future<Map<String, dynamic>?> getCompanyData() async {
    final companyData = await _storage.read(key: _companyDataKey);
    if (companyData != null) {
      try {
        final decodedData = jsonDecode(companyData);
        print("Retrieved company data from storage: $decodedData");
        return decodedData;
      } catch (e) {
        print("Error decoding company data: $e");
        return null;
      }
    }
    return null;
  }

  // Get user type
  static Future<String?> getUserType() async {
    return await _storage.read(key: _userTypeKey);
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final isLoggedIn = await _storage.read(key: _isLoggedInKey);
    final isGuest = await _storage.read(key: _isGuestModeKey);
    return isLoggedIn == 'true' || isGuest == 'true';
  }

  // Get user role from stored user data
  static Future<String?> getUserRole() async {
    final userData = await getUserData();
    return userData?['role']?.toString();
  }

  // Check if current user is a client
  static Future<bool> isClient() async {
    final role = await getUserRole();
    return role == '4';
  }

  // Check if current user is a driver
  static Future<bool> isDriver() async {
    final role = await getUserRole();
    return role == '3';
  }

  // Check if user is in guest mode
  static Future<bool> isGuestMode() async {
    final isGuest = await _storage.read(key: _isGuestModeKey);
    return isGuest == 'true';
  }

  // Clear all data (logout), including guest session
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // Log out guest session
  static Future<void> clearGuestSession() async {
    await _storage.delete(key: _isGuestModeKey);
    await _storage.delete(key: _isLoggedInKey);
    await _storage.delete(key: _userDataKey);
    await _storage.delete(key: _userTypeKey);
  }

  // Save profile image URL
  static Future<void> saveProfileImageUrl(String imageUrl) async {
    await _storage.write(key: _profileImageUrlKey, value: imageUrl);
    print("Saved profile image URL: $imageUrl");
  }

  // Get profile image URL
  static Future<String?> getProfileImageUrl() async {
    return await _storage.read(key: _profileImageUrlKey);
  }

  // Clear profile image URL
  static Future<void> clearProfileImageUrl() async {
    await _storage.delete(key: _profileImageUrlKey);
  }
}
