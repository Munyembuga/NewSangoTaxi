import 'package:flutter/material.dart';
import 'package:sango/l10n/l10n.dart'; // Add this import
import 'package:sango/screen/tabs/ride_data.dart';
import 'package:sango/screen/widgets/empty_state.dart';
import 'package:sango/services/driver_service.dart';
import 'package:sango/services/storage_service.dart';
import 'package:sango/screendriver/widgets/confirmed_ride_card.dart';

class ConfirmedRidesTab extends StatefulWidget {
  const ConfirmedRidesTab({Key? key}) : super(key: key);

  @override
  State<ConfirmedRidesTab> createState() => _ConfirmedRidesTabState();
}

class _ConfirmedRidesTabState extends State<ConfirmedRidesTab> {
  bool _isLoading = true;
  String _errorMessage = '';
  List<dynamic> _confirmedBookings = [];
  String _driverId = '1'; // Default value
  String _categoryId = '2'; // Default value
  Map<String, dynamic>? _currentLocation;
  String _driverStatus = '3'; // Default status is 'Available'
  String _driverStatusName = 'Available';
  int _totalConfirmed = 0;

  @override
  void initState() {
    super.initState();
    _loadDriverData();
  }

  Future<void> _loadDriverData() async {
    try {
      // Get driver data from storage
      final driverData = await StorageService.getDriverData();
      if (driverData != null) {
        setState(() {
          _driverId = driverData['driver_id']?.toString() ?? '1';
          _categoryId = driverData['catg_id']?.toString() ?? '2';
        });
      }

      _fetchConfirmedBookings();
    } catch (e) {
      print('Error loading driver data: $e');
      _fetchConfirmedBookings(); // Still try to fetch with default values
    }
  }

  Future<void> _fetchConfirmedBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await DriverService.getConfirmedBookings(
        context: context,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (response['success']) {
            // Store current location information
            if (response['current_location'] != null) {
              _currentLocation = response['current_location'];
            }

            // Update driver status
            _driverStatus = response['driver_status'] ?? '3';
            _driverStatusName = response['driver_status_name'] ?? 'Available';

            // Get confirmed bookings data
            _confirmedBookings = response['confirmed_bookings'] ?? [];
            _totalConfirmed = response['total_confirmed'] ?? 0;

            print('Confirmed bookings@@@@@@@@@@@@@@@@@@: $_confirmedBookings');
          } else {
            _errorMessage =
                response['message'] ?? 'Failed to load confirmed bookings';
          }
        });
      }
    } catch (e) {
      print('Error fetching confirmed bookings: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An error occurred while fetching data';
        });
      }
    }
  }

  Widget _buildStatusBanner() {
    final s = S.of(context)!;
    Color statusColor;
    IconData statusIcon;

    // Determine color and icon based on driver status
    switch (_driverStatus) {
      case '3': // Available
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case '4': // On Trip
        statusColor = Colors.blue;
        statusIcon = Icons.directions_car;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const SizedBox(width: 16),
              Icon(statusIcon, color: statusColor, size: 18),
              const SizedBox(width: 8),
              Text(
                s.statusWithValue(_driverStatusName),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Text(
              s.totalWithValue(_totalConfirmed.toString()),
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelTripBottomSheet(String transactionId) {
    final s = S.of(context)!;
    final TextEditingController reasonController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.cancelRide, // Changed from s.cancelTrip to s.cancelRide
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                s.provideCancellationReason,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: s.enterReason,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(s.cancel),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final reason = reasonController.text.trim();
                      if (reason.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(s.pleaseProvideReason),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      Navigator.pop(context); // Close the bottom sheet
                      await _cancelTrip(transactionId, reason);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(s.submit),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _cancelTrip(String transactionId, String reason) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await DriverService.cancelTripWithDriver(
        driverId: _driverId,
        transactionId: transactionId,
        reason: reason,
      );

      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']),
            backgroundColor: Colors.green,
          ),
        );
        _fetchConfirmedBookings(); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred while cancelling the trip'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchConfirmedBookings,
              child: Text(s.retry),
            ),
          ],
        ),
      );
    }

    if (_confirmedBookings.isEmpty) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildStatusBanner(),
          ),
          Expanded(
            child: EmptyState(
              icon: Icons.check_circle_outline,
              title: s.noConfirmedRides,
              subtitle: s.confirmedRidesWillAppearHere,
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchConfirmedBookings,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatusBanner(),
          ..._confirmedBookings.map((booking) {
            // Transform the booking data to match the expected format
            final transformedBooking = _transformConfirmedBooking(booking);
            return ConfirmedRideCard(
              ride: transformedBooking,
              onTripStarted: _fetchConfirmedBookings,
              onCancelTrip: () => _showCancelTripBottomSheet(
                transformedBooking['transaction_id'],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Map<String, dynamic> _transformConfirmedBooking(
      Map<String, dynamic> booking) {
    return {
      'id': booking['booking_id']?.toString() ?? 'N/A',
      'booking_id': booking['booking_id']?.toString() ?? 'N/A',
      'transaction_id': booking['transaction_id']?.toString() ??
          booking['transbook_id']?.toString() ??
          booking['booking_id']?.toString() ??
          'N/A',
      'from': booking['pickup_location']?.toString() ?? 'Unknown pickup',
      'pickup_latitude': booking['pickup_lat']?.toString() ?? '0.0',
      'pickup_longitude': booking['pickup_long']?.toString() ?? '0.0',
      'dropoff_latitude': booking['dropoff_lat']?.toString() ?? '0.0',
      'dropoff_longitude': booking['dropoff_long']?.toString() ?? '0.0',
      'to': booking['dropoff_location']?.toString() ?? 'Unknown destination',
      'distance': '${booking['distance']?.toString() ?? 'N/A'} km',
      'estimated_duration':
          '${booking['estimated_duration']?.toString() ?? 'N/A'} min',
      'fare': '${booking['estimated_price']?.toString() ?? 'N/A'} FCFA',
      'client_name':
          '${booking['f_name']?.toString() ?? ''} ${booking['l_name']?.toString() ?? ''}'
                  .trim()
                  .isNotEmpty
              ? '${booking['f_name']?.toString() ?? ''} ${booking['l_name']?.toString() ?? ''}'
                  .trim()
              : 'Unknown Client',
      'phone': booking['phone_number']?.toString(),
      'date': booking['created_at'] != null
          ? _formatDate(booking['created_at'].toString())
          : 'N/A',
      'time': booking['created_at'] != null
          ? _formatTime(booking['created_at'].toString())
          : 'N/A',
      'status': _mapStatus(
          booking['booking_status'] ?? booking['transaction_status']),
      'driver_id': _driverId,
      'category_id': booking['catg_id']?.toString(),
      'otp': booking['otp']?.toString() ?? '',
      'can_start_trip': booking['can_start_trip'] ?? false,
      'is_trip_active': booking['is_trip_active'] ?? false,
    };
  }

  String _mapStatus(dynamic status) {
    switch (status?.toString()) {
      case '7':
        return 'confirmed';
      case '8':
        return 'started';
      case '9':
        return 'completed';
      default:
        return 'confirmed';
    }
  }

  String _formatDate(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatTime(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }
}
