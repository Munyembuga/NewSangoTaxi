import 'package:flutter/material.dart';
import 'package:sango/screen/login.dart';
import 'package:sango/screen/tabs/ride_data.dart';
import 'package:sango/screen/widgets/empty_state.dart';
import 'package:sango/services/auth_service.dart';
import 'package:sango/services/driver_service.dart';
import 'package:sango/services/storage_service.dart';
import 'package:sango/screendriver/widgets/request_card.dart';
import 'package:sango/screendriver/widgets/confirmed_ride_card.dart';

class AssignedRidesTab extends StatefulWidget {
  const AssignedRidesTab({Key? key}) : super(key: key);

  @override
  State<AssignedRidesTab> createState() => _AssignedRidesTabState();
}

class _AssignedRidesTabState extends State<AssignedRidesTab> {
  bool _isLoading = true;
  String _errorMessage = '';
  List<dynamic> _rides = [];
  String _driverId = '1'; // Default value
  String _categoryId = '2'; // Default value
  Map<String, dynamic>? _currentLocation;
  String _driverStatus = '3'; // Default status is 'Available'
  String _driverStatusName = 'Available';

  @override
  void initState() {
    super.initState();
    _loadDriverData();
  }

// Add this method to handle token expiry
  Future<void> _handleTokenExpiry() async {
    try {
      await AuthService.logout();

      // Navigate to login screen and remove all previous routes
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      // Handle logout error if needed
      print('Error during logout: $e');
    }
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

      _fetchRides();
    } catch (e) {
      print('Error loading driver data: $e');
      _fetchRides(); // Still try to fetch with default values
    }
  }

  Future<void> _fetchRides() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // For now, use hardcoded location or the last known location
      final lat = _currentLocation?['last_lat'] ?? "-1.9536000";
      final lng = _currentLocation?['last_long'] ?? "30.0605000";

      final response = await DriverService.getNearbyRequests(
        latitude: lat,
        longitude: lng,
        categoryId: _categoryId,
        assignId: _driverId,
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

            // Get rides data
            _rides = response['rides'] ?? [];

            // Update category ID if returned by API
            if (response['data'] != null &&
                response['data']['driver_category'] != null) {
              _categoryId = response['data']['driver_category'].toString();
            }
          } else {
            _errorMessage = response['message'] ?? 'Failed to load ride data';
          }
        });
      }
    } catch (e) {
      print('Error fetching rides: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An error occurred while fetching data';
        });
      }
    }
  }

  Widget _buildStatusBanner() {
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(statusIcon, color: statusColor, size: 18),
          const SizedBox(width: 8),
          Text(
            'Status: $_driverStatusName',
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      // Check if the error message indicates an invalid or expired token
      if (_errorMessage.toLowerCase().contains('invalid or expired token')) {
        // Automatically logout and redirect to login
        _handleTokenExpiry();
        return const Center(
          child: CircularProgressIndicator(), // Show loading while redirecting
        );
      }

      // For other error messages, show the retry UI
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchRides,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_rides.isEmpty) {
      // Determine the message and icon based on driver status and rides availability
      String emptyTitle;
      String emptySubtitle;
      IconData emptyIcon;

      if (_driverStatus == '4') {
        // On Trip
        emptyTitle = 'No Active Trip';
        emptySubtitle = 'You have no confirmed rides at the moment';
        emptyIcon = Icons.directions_car_outlined;
      } else {
        emptyTitle = 'No Nearby Requests';
        emptySubtitle = 'Available ride requests will appear here';
        emptyIcon = Icons.search_outlined;
      }

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildStatusBanner(),
          ),
          Expanded(
            child: EmptyState(
              icon: emptyIcon,
              title: emptyTitle,
              subtitle: emptySubtitle,
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchRides,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatusBanner(),
          ..._rides.map((ride) {
            // Use different card based on ride status
            final transformedRide = RideData.transformDriverRequestToRide(ride);
            print("objecttransformedRide: $transformedRide");

            // Check if it's confirmed (status 7) - this should now show in Confirmed tab
            if (transformedRide['status'] == 'confirmed') {
              return ConfirmedRideCard(
                ride: transformedRide,
                onTripStarted: _fetchRides,
              );
            } else {
              return RequestCard(
                request: transformedRide,
                driverId: _driverId,
                onRequestConfirmed: _fetchRides,
              );
            }
          }).toList(),
        ],
      ),
    );
  }
}
