import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sango/models/overall_stats_model.dart';
import 'package:sango/services/storage_service.dart';
import 'package:sango/services/device_info_service.dart';

class StatsService {
  static const String baseUrl = 'https://mis.sangotaxi.com/api';

  static Future<Map<String, dynamic>> getOverallStats() async {
    try {
      // First check if we're in guest mode
      final isGuestMode = await StorageService.isGuestMode();
      String url;

      if (isGuestMode) {
        // Guest mode: use device ID
        final deviceId = await DeviceInfoService.getDeviceId();
        if (deviceId.isEmpty) {
          print('Error: Empty device ID for guest user');
          return {
            'success': false,
            'data': null,
            'message': 'Could not get device ID for guest user',
          };
        }
        print(
            'Fetching overall ride statistics for guest user with device ID: $deviceId');
        url = '$baseUrl/clientDash/overallRide?device_id=$deviceId';
      } else {
        // Regular user: check which ID to use (user or client)
        final userData = await StorageService.getUserData();
        final clientData = await StorageService.getClientData();

        if (userData != null && userData['id'] != null) {
          print(
              'Fetching overall ride statistics for user ID: ${userData['id']}');
          url = '$baseUrl/clientDash/overallRide?client_id=${userData['id']}';
        } else if (clientData != null && clientData['id'] != null) {
          print(
              'Fetching overall ride statistics for client ID: ${clientData['id']}');
          url = '$baseUrl/clientDash/overallRide?client_id=${clientData['id']}';
        } else {
          // Fallback to device ID if no user/client ID found
          final deviceId = await DeviceInfoService.getDeviceId();
          print('No user/client ID found, using device ID: $deviceId');
          url = '$baseUrl/clientDash/overallRide?device_id=$deviceId';
        }
      }

      print('Sending request to: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('Response: ${response.body}');

        if (data['success'] == true) {
          final overallStats = OverallStatsModel.fromJson(data);

          return {
            'success': true,
            'data': overallStats,
            'message': 'Statistics retrieved successfully',
          };
        } else {
          print('API returned success: false. Message: ${data['message']}');
          return {
            'success': false,
            'data': null,
            'message': data['message'] ?? 'Failed to load statistics',
          };
        }
      } else {
        print('HTTP Error: ${response.statusCode}, ${response.body}');
        return {
          'success': false,
          'data': null,
          'message': 'HTTP Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error fetching overall ride statistics: ${e.toString()}');
      return {
        'success': false,
        'data': null,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
}
