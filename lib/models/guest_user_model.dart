class GuestUserModel {
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

  GuestUserModel({
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

  factory GuestUserModel.fromJson(Map<String, dynamic> json) {
    return GuestUserModel(
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
