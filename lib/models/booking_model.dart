class Booking {
  final String bookingId;
  final String bookingCode;
  final String clientId;
  final String categoryId;
  final String otp;
  final String pickupLocation;
  final double pickupLat;
  final double pickupLong;
  final String dropoffLocation;
  final double dropoffLat;
  final double dropoffLong;
  final String estimatedDuration;
  final String estimatedPrice;
  final String status;
  final String createdAt;
  final String? eligibleDrivers;
  final String categoryName;
  final String categoryImage;
  final String statusName;
  final Driver? driver;

  Booking({
    required this.bookingId,
    required this.bookingCode,
    required this.clientId,
    required this.categoryId,
    required this.otp,
    required this.pickupLocation,
    required this.pickupLat,
    required this.pickupLong,
    required this.dropoffLocation,
    required this.dropoffLat,
    required this.dropoffLong,
    required this.estimatedDuration,
    required this.estimatedPrice,
    required this.status,
    required this.createdAt,
    this.eligibleDrivers,
    required this.categoryName,
    required this.categoryImage,
    required this.statusName,
    this.driver,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      bookingId: json['booking_id'] ?? '',
      bookingCode: json['booking_code'] ?? '',
      clientId: json['client_id'] ?? '',
      categoryId: json['catg_id'] ?? '',
      otp: json['otp'] ?? '',
      pickupLocation: json['pickup_location'] ?? '',
      pickupLat: double.tryParse(json['pickup_lat'] ?? '0.0') ?? 0.0,
      pickupLong: double.tryParse(json['pickup_long'] ?? '0.0') ?? 0.0,
      dropoffLocation: json['dropoff_location'] ?? '',
      dropoffLat: double.tryParse(json['dropoff_lat'] ?? '0.0') ?? 0.0,
      dropoffLong: double.tryParse(json['dropoff_long'] ?? '0.0') ?? 0.0,
      estimatedDuration: json['estimated_duration'] ?? '',
      estimatedPrice: json['estimated_price'] ?? '',
      status: json['sts'] ?? '',
      createdAt: json['created_at'] ?? '',
      eligibleDrivers: json['eligible_drivers'],
      categoryName: json['catg_name'] ?? '',
      categoryImage: json['catg_image'] ?? '',
      statusName: json['status_name'] ?? '',
      driver: json['driver'] != null ? Driver.fromJson(json['driver']) : null,
    );
  }
}

class Driver {
  final String driverId;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String vehicleModel;
  final String modelType;
  final String vehicleColor;
  final String vehiclePlaque;
  final String transbookId;

  Driver({
    required this.driverId,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.vehicleModel,
    required this.modelType,
    required this.vehicleColor,
    required this.vehiclePlaque,
    required this.transbookId,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    // Handle null json case
    if (json == null) {
      return Driver(
        driverId: '',
        firstName: '',
        lastName: '',
        phoneNumber: '',
        vehicleModel: '',
        modelType: '',
        vehicleColor: '',
        vehiclePlaque: '',
        transbookId: '',
      );
    }

    return Driver(
      driverId: json['driver_id'] ?? '',
      firstName: json['fname'] ?? '',
      lastName: json['lname'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      vehicleModel: json['vehicle_model'] ?? '',
      modelType: json['model_type'] ?? '',
      vehicleColor: json['vehicle_color'] ?? '',
      vehiclePlaque: json['vehicle_plaque'] ?? '',
      transbookId: json['transbook_id'] ?? '',
    );
  }
}
