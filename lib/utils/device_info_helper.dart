import 'package:flutter/material.dart';
import 'package:sango/services/device_info_service.dart';

/// A helper class to demonstrate usage of DeviceInfoService
class DeviceInfoHelper {
  /// Shows device information in a dialog
  static Future<void> showDeviceInfo(BuildContext context) async {
    String deviceId = await DeviceInfoService.getDeviceId();
    String deviceName = await DeviceInfoService.getDeviceName();
    Map<String, dynamic> detailedInfo =
        await DeviceInfoService.getDetailedDeviceInfo();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Device Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Device ID:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SelectableText(deviceId),
              const SizedBox(height: 16),
              const Text('Device Name:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(deviceName),
              const SizedBox(height: 16),
              const Text('Detailed Info:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...detailedInfo.entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text("${entry.key}: ${entry.value}"),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
