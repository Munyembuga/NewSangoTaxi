import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_udid/flutter_udid.dart';

class DeviceInfoService {
  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  /// Gets the device's unique identifier
  static Future<String> getDeviceId() async {
    try {
      // Use flutter_udid to get a consistent ID across app reinstalls
      final String udid = await FlutterUdid.consistentUdid;
      return udid;
    } catch (e) {
      debugPrint('Error getting device ID: $e');
      // Fallback to another method if flutter_udid fails
      return _getDeviceIdFallback();
    }
  }

  /// Fallback method to get device ID if flutter_udid fails
  static Future<String> _getDeviceIdFallback() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        // Use Android ID as fallback (this may change on factory reset)
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        // Use identifierForVendor as fallback (this may change when app is reinstalled)
        return iosInfo.identifierForVendor ?? 'unknown';
      }
    } catch (e) {
      debugPrint('Error getting fallback device ID: $e');
    }
    return 'unknown_device';
  }

  /// Gets the device name (model, manufacturer, etc.)
  static Future<String> getDeviceName() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        // Combine manufacturer and model for a descriptive name
        return '${androidInfo.manufacturer} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        // iOS returns a human-readable name
        return iosInfo.name ?? iosInfo.model ?? 'iOS Device';
      }
    } catch (e) {
      debugPrint('Error getting device name: $e');
    }
    return 'Unknown Device';
  }

  /// Gets detailed device information as a Map
  static Future<Map<String, dynamic>> getDetailedDeviceInfo() async {
    final Map<String, dynamic> deviceData = <String, dynamic>{};

    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        deviceData['id'] = androidInfo.id;
        deviceData['brand'] = androidInfo.brand;
        deviceData['manufacturer'] = androidInfo.manufacturer;
        deviceData['model'] = androidInfo.model;
        deviceData['device'] = androidInfo.device;
        deviceData['product'] = androidInfo.product;
        deviceData['version'] = androidInfo.version.release;
        deviceData['sdkInt'] = androidInfo.version.sdkInt;
        deviceData['isPhysicalDevice'] = androidInfo.isPhysicalDevice;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        deviceData['name'] = iosInfo.name;
        deviceData['systemName'] = iosInfo.systemName;
        deviceData['systemVersion'] = iosInfo.systemVersion;
        deviceData['model'] = iosInfo.model;
        deviceData['localizedModel'] = iosInfo.localizedModel;
        deviceData['identifierForVendor'] = iosInfo.identifierForVendor;
        deviceData['isPhysicalDevice'] = iosInfo.isPhysicalDevice;
        deviceData['utsname.sysname'] = iosInfo.utsname.sysname;
        deviceData['utsname.nodename'] = iosInfo.utsname.nodename;
        deviceData['utsname.release'] = iosInfo.utsname.release;
        deviceData['utsname.version'] = iosInfo.utsname.version;
        deviceData['utsname.machine'] = iosInfo.utsname.machine;
      } else if (kIsWeb) {
        final webInfo = await _deviceInfoPlugin.webBrowserInfo;
        deviceData['browserName'] = webInfo.browserName.name;
        deviceData['platform'] = webInfo.platform;
        deviceData['userAgent'] = webInfo.userAgent;
      }
    } catch (e) {
      debugPrint('Error getting detailed device info: $e');
    }

    return deviceData;
  }
}
