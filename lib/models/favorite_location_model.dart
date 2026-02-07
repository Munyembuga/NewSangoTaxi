import 'package:flutter/material.dart';

class FavoriteLocationModel {
  final bool success;
  final List<LocationItem> pickupLocations;
  final List<LocationItem> dropoffLocations;

  FavoriteLocationModel({
    required this.success,
    required this.pickupLocations,
    required this.dropoffLocations,
  });

  factory FavoriteLocationModel.fromJson(Map<String, dynamic> json) {
    return FavoriteLocationModel(
      success: json['success'] ?? false,
      pickupLocations: (json['pickup_locations'] as List<dynamic>?)
              ?.map((item) => LocationItem.fromJson(item))
              .toList() ??
          [],
      dropoffLocations: (json['dropoff_locations'] as List<dynamic>?)
              ?.map((item) => LocationItem.fromJson(item))
              .toList() ??
          [],
    );
  }

  List<LocationItem> get allLocations =>
      [...pickupLocations, ...dropoffLocations];
}

class LocationItem {
  final String id;
  String location;
  String? address;
  final int usageCount;
  final String type;

  LocationItem({
    required this.id,
    required this.location,
    this.address,
    required this.usageCount,
    required this.type,
  });

  factory LocationItem.fromJson(Map<String, dynamic> json) {
    return LocationItem(
      id: json['id']?.toString() ?? '',
      location: json['location'] ?? '',
      address: json['address'],
      usageCount: json['usage_count'] ?? 0,
      type: json['type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location': location,
      'address': address,
      'usage_count': usageCount,
      'type': type,
    };
  }

  // Helper method to get appropriate icon based on type
  IconData get icon {
    switch (type.toLowerCase()) {
      case 'pickup':
        return Icons.location_on;
      case 'dropoff':
        return Icons.flag;
      default:
        return Icons.place;
    }
  }

  // Helper method to get appropriate color based on type
  Color get color {
    switch (type.toLowerCase()) {
      case 'pickup':
        return Color(0xFFF5141E);
      case 'dropoff':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
