class ApiConstants {
  static const String baseUrl = 'https://mis.sangotaxi.com/api/';
  static const String registerEndpoint = 'auth/register';
  static const String verifyOtpEndpoint = 'auth/verify-otp';
  static const String resendOtpEndpoint = 'auth/resend_otp';
  static const String loginEndpoint = 'auth/login';
  static const String getCategoriesEndpoint = 'booking/scr/get_categories';
  static const String getPriceByCategoryEndpoint =
      'booking/scr/get_pricebycateg';
  static const String getPriceByCategoryTypeEndpoint =
      'booking/scr/get_pricebycateg';
  static const String updateDriverStatusEndpoint = 'driver/update_status';
  static const String getDriverStatusEndpoint = 'driver/get_status';
  static const String createBookingEndpoint = 'booking/create_booking';
  static const String getPendingBookingsEndpoint = 'booking/pending_booking';
  static const String getDriverRequestsEndpoint = 'booking/drivergetrequest';
  static const String confirmRequestEndpoint = 'booking/confirmrequest';
  static const String startTripEndpoint = 'booking/startTrip';
  static const String getConfirmedBookingsEndpoint = 'booking/confirmed';
  static const String getOnTripBookingsEndpoint = 'booking/ontrip';
}
