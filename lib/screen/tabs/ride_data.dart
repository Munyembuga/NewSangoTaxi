class RideData {
  // This method will be deprecated once we fully integrate with the API
  static List<Map<String, dynamic>> getRidesByStatus(String status) {
    return [];
  }

  // Transform API booking data to the format expected by RideCard
  static Map<String, dynamic> transformBookingToRide(dynamic booking) {
    // Check if this is an "On Trip" booking (has driver info and trip duration)
    if (booking['driver'] != null && booking['trip_duration'] != null) {
      return transformOnTripBookingToRide(booking);
    }

    final String status = booking['sts'] == '6' ? 'pending' : 'confirmed';

    // Format the date and time
    final DateTime createdDate = DateTime.parse(booking['created_at']);
    final String date =
        '${createdDate.day}/${createdDate.month}/${createdDate.year}';
    final String time =
        '${createdDate.hour.toString().padLeft(2, '0')}:${createdDate.minute.toString().padLeft(2, '0')}';

    // Build driver info if available
    String driverName = 'Not assigned';
    String vehicleInfo = 'Not available';
    String? phone;

    if (booking['driver'] != null) {
      final driver = booking['driver'];
      driverName = '${driver['fname']} ${driver['lname']}';
      vehicleInfo = '${driver['vehicle_model']} (${driver['vehicle_plaque']})';
      if (driver['vehicle_color'] != null) {
        vehicleInfo = '${driver['vehicle_color']} $vehicleInfo';
      }
      phone = driver['phone_number'];
    }

    return {
      'id': booking['booking_code'],
      'status': status,
      'from': booking['pickup_location'],
      'to': booking['dropoff_location'],
      'date': date,
      'time': time,
      'fare': '${booking['estimated_price']} FCFA',
      'driver': driverName,
      'vehicle': vehicleInfo,
      'phone': phone,
      'otp': booking['otp']?.toString(),
      'raw_booking': booking, // Keep the raw data for additional details
    };
  }

  // Transform "On Trip" booking data to the format expected by RideCard
  static Map<String, dynamic> transformOnTripBookingToRide(dynamic booking) {
    // Format the date and time
    final DateTime createdDate = DateTime.parse(booking['created_at']);
    final String date =
        '${createdDate.day}/${createdDate.month}/${createdDate.year}';
    final String time =
        '${createdDate.hour.toString().padLeft(2, '0')}:${createdDate.minute.toString().padLeft(2, '0')}';

    // Build driver info
    String driverName = 'Not assigned';
    String vehicleInfo = 'Not available';
    String? phone;

    if (booking['driver'] != null) {
      final driver = booking['driver'];
      driverName = driver['name'] ?? 'Unknown Driver';
      phone = driver['phone'];

      if (driver['vehicle'] != null) {
        final vehicle = driver['vehicle'];
        vehicleInfo =
            '${vehicle['color']} ${vehicle['model']} (${vehicle['plaque']})';
      }
    }

    // Format trip duration
    String tripDuration = 'N/A';
    if (booking['trip_duration'] != null) {
      tripDuration = booking['trip_duration'];
    }

    return {
      'id': booking['booking_code'],
      'status': 'on_trip',
      'from': booking['pickup_location'],
      'to': booking['dropoff_location'],
      'date': date,
      'time': time,
      'fare': '${booking['estimated_price']} FCFA',
      'driver': driverName,
      'vehicle': vehicleInfo,
      'phone': phone,
      'trip_duration': tripDuration,
      'category_name': booking['catg_name'],
      'status_name': booking['status_name'],
      'is_trip_active': booking['is_trip_active'] ?? false,
      'can_track_driver': booking['can_track_driver'] ?? false,
      'trip_duration_minutes': booking['trip_duration_minutes'],
      'raw_booking': booking, // Keep the raw data for additional details
    };
  }

  // Transform API driver request data to the format expected by RequestCard
  static Map<String, dynamic> transformDriverRequestToRide(
      Map<String, dynamic> apiData) {
    return {
      'id': apiData['booking_id']?.toString() ?? 'N/A',
      'booking_id': apiData['booking_id']?.toString() ?? 'N/A',
      'booking_code': apiData['booking_code']?.toString() ?? 'N/A',
      'transaction_id': apiData['transaction_id']?.toString() ??
          apiData['transbook_id']?.toString() ??
          apiData['booking_id']?.toString() ??
          'N/A',
      'from': apiData['pickup_location']?.toString() ?? 'Unknown pickup',
      'to': apiData['dropoff_location']?.toString() ?? 'Unknown destination',
      'distance': '${apiData['distance']?.toString() ?? 'N/A'} km',
      'estimated_duration':
          '${apiData['estimated_duration']?.toString() ?? 'N/A'} min',
      'fare': '${apiData['estimated_price']?.toString() ?? 'N/A'} FCFA',
      'client_name':
          '${apiData['f_name']?.toString() ?? ''} ${apiData['l_name']?.toString() ?? ''}'
                  .trim()
                  .isNotEmpty
              ? '${apiData['f_name']?.toString() ?? ''} ${apiData['l_name']?.toString() ?? ''}'
                  .trim()
              : 'Unknown Client',
      'phone': apiData['phone_number']?.toString(),
      'date': apiData['created_at'] != null
          ? _formatDate(apiData['created_at'].toString())
          : 'N/A',
      'time': apiData['created_at'] != null
          ? _formatTime(apiData['created_at'].toString())
          : 'N/A',
      'status': _mapStatus(apiData['booking_status'] ?? apiData['status']),
      'driver_id': apiData['driver_id']?.toString(),
      'category_id': apiData['catg_id']?.toString(),
      'otp': apiData['otp']?.toString() ?? '',
    };
  }

  // Transform completed trip data to the format expected by RideCard
  static Map<String, dynamic> transformCompletedTripToRide(dynamic trip) {
    // Format the dates
    final DateTime createdDate = DateTime.parse(trip['created_at']);
    final String date =
        '${createdDate.day}/${createdDate.month}/${createdDate.year}';
    final String time =
        '${createdDate.hour.toString().padLeft(2, '0')}:${createdDate.minute.toString().padLeft(2, '0')}';

    // Format completion time
    String completedTime = 'N/A';
    if (trip['completed_at'] != null) {
      try {
        final DateTime completedDate = DateTime.parse(trip['completed_at']);
        completedTime =
            '${completedDate.hour.toString().padLeft(2, '0')}:${completedDate.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        completedTime = 'N/A';
      }
    }

    return {
      'id': trip['booking_code']?.toString() ?? 'N/A',
      'status': 'completed',
      'from': trip['pickup_location']?.toString() ?? 'Unknown pickup',
      'to': trip['dropoff_location']?.toString() ?? 'Unknown destination',
      'date': date,
      'time': time,
      'completed_time': completedTime,
      'fare': '${trip['payment_fee']?.toString() ?? '0'} FCFA',
      'distance': '${trip['km_used']?.toString() ?? '0'} km',
      'duration': trip['actual_trip_duration']?.toString() ?? 'N/A',
      'duration_minutes':
          trip['actual_trip_duration_minutes']?.toString() ?? '0',
      'client_name': trip['client']?['name']?.toString() ?? 'Unknown Client',
      'client_phone': trip['client']?['phone']?.toString() ?? '',
      'category_name': trip['catg_name']?.toString() ?? 'N/A',
      'status_name': trip['status_name']?.toString() ?? 'Completed',
      'payment_method':
          trip['earnings']?['payment_method']?.toString() ?? 'N/A',
      'total_amount': trip['earnings']?['total_amount']?.toString() ?? '0',
      'is_trip_completed': trip['is_trip_completed'] ?? true,
      'raw_trip': trip, // Keep the raw data for additional details
    };
  }

  static String _mapStatus(dynamic status) {
    switch (status?.toString()) {
      case '1':
        return 'pending';
      case '2':
        return 'confirmed';
      case '3':
        return 'started';
      case '4':
        return 'completed';
      default:
        return 'pending';
    }
  }

  static String _formatDate(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  static String _formatTime(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }
}
