class OverallStatsModel {
  final bool success;
  final ClientInfo? clientInfo;
  final String currentMonth; // Changed from int to String
  final OverallStats? overallStats;
  final String dashboardUpdatedAt;
  final bool isCurrentMonth;

  OverallStatsModel({
    required this.success,
    this.clientInfo,
    required this.currentMonth,
    this.overallStats,
    required this.dashboardUpdatedAt,
    required this.isCurrentMonth,
  });

  factory OverallStatsModel.fromJson(Map<String, dynamic> json) {
    return OverallStatsModel(
      success: json['success'] ?? false,
      clientInfo: json['client_info'] != null
          ? ClientInfo.fromJson(json['client_info'])
          : null,
      currentMonth: json['current_month']?.toString() ?? '', // Handle as string
      overallStats: json['overall_stats'] != null
          ? OverallStats.fromJson(json['overall_stats'])
          : null,
      dashboardUpdatedAt: json['dashboard_updated_at'] ?? '',
      isCurrentMonth: json['is_current_month'] ?? false,
    );
  }

  // Helper method to get formatted month display
  String get formattedCurrentMonth {
    if (currentMonth.isEmpty) return '2';
    try {
      // Extract month from "YYYY-MM" format
      final parts = currentMonth.split('-');
      if (parts.length >= 2) {
        final month = parts[1];
        return month.startsWith('0') ? month.substring(1) : month;
      }
      return currentMonth;
    } catch (e) {
      return currentMonth;
    }
  }

  // Helper method to get month name
  String get monthName {
    if (currentMonth.isEmpty) return '';
    try {
      final parts = currentMonth.split('-');
      if (parts.length >= 2) {
        final monthNum = int.parse(parts[1]);
        const months = [
          '',
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec'
        ];
        return monthNum > 0 && monthNum <= 12 ? months[monthNum] : '';
      }
      return '';
    } catch (e) {
      return '';
    }
  }
}

class ClientInfo {
  final bool success;
  final String clientId;
  final String name;
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String userType;
  final String deviceId;
  final String memberSince;
  final String lastUpdated;

  ClientInfo({
    required this.success,
    required this.clientId,
    required this.name,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.userType,
    required this.deviceId,
    required this.memberSince,
    required this.lastUpdated,
  });

  factory ClientInfo.fromJson(Map<String, dynamic> json) {
    return ClientInfo(
      success: json['success'] ?? false,
      clientId: json['client_id']?.toString() ?? '',
      name: json['name'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      userType: json['user_type'] ?? '',
      deviceId: json['device_id'] ?? '',
      memberSince: json['member_since'] ?? '',
      lastUpdated: json['last_updated'] ?? '',
    );
  }
}

class OverallStats {
  final int totalRides;
  final int completedRides;
  final int cancelledRides;
  final double completionRate; // Changed from int to double
  final String firstRideDate;
  final String lastRideDate;
  final double averageRideAmount;
  final int totalSpent;
  final int categoriesUsed;

  OverallStats({
    required this.totalRides,
    required this.completedRides,
    required this.cancelledRides,
    required this.completionRate,
    required this.firstRideDate,
    required this.lastRideDate,
    required this.averageRideAmount,
    required this.totalSpent,
    required this.categoriesUsed,
  });

  factory OverallStats.fromJson(Map<String, dynamic> json) {
    return OverallStats(
      totalRides: json['total_rides'] ?? 0,
      completedRides: json['completed_rides'] ?? 0,
      cancelledRides: json['cancelled_rides'] ?? 0,
      completionRate:
          (json['completion_rate'] ?? 0).toDouble(), // Ensure double conversion
      firstRideDate: json['first_ride_date'] ?? '',
      lastRideDate: json['last_ride_date'] ?? '',
      averageRideAmount: (json['average_ride_amount'] ?? 0).toDouble(),
      totalSpent: json['total_spent'] ?? 0,
      categoriesUsed: json['categories_used'] ?? 0,
    );
  }
}
