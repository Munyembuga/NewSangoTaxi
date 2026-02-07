import 'package:flutter/material.dart';
import 'package:sango/screen/login.dart';
import 'package:sango/screen/widgets/empty_state.dart';
import 'package:sango/services/auth_service.dart';
import 'package:sango/services/driver_service.dart';
import 'package:sango/services/storage_service.dart';
import 'package:sango/screendriver/widgets/ontrip_ride_card.dart';

class OnRidesTab extends StatefulWidget {
  const OnRidesTab({Key? key}) : super(key: key);

  @override
  State<OnRidesTab> createState() => _OnRidesTabState();
}

class _OnRidesTabState extends State<OnRidesTab> {
  bool _isLoading = true;
  String _errorMessage = '';
  List<dynamic> _activeTrips = [];
  String _driverId = '1'; // Default value
  String _categoryId = '2'; // Default value
  Map<String, dynamic>? _currentLocation;
  String _driverStatus = '3'; // Default status is 'Available'
  String _driverStatusName = 'Available';
  int _totalActive = 0;
  bool _driverOnTrip = false;

  @override
  void initState() {
    super.initState();
    _loadDriverData();
  }

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

      _fetchActiveTrips();
    } catch (e) {
      print('Error loading driver data: $e');
      _fetchActiveTrips(); // Still try to fetch with default values
    }
  }

  Future<void> _fetchActiveTrips() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await DriverService.getOnTripBookings(
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

            // Get active trips data
            _activeTrips = response['active_trips'] ?? [];
            _totalActive = response['total_active'] ?? 0;
            _driverOnTrip = response['driver_on_trip'] ?? false;

            print('Active trips: $_activeTrips');
          } else {
            _errorMessage =
                response['message'] ?? 'Failed to load active trips';
          }
        });
      }
    } catch (e) {
      print('Error fetching active trips: $e');
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const SizedBox(width: 16),
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
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Text(
              'Active: $_totalActive',
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
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
      if (_errorMessage.toLowerCase().contains('invalid or expired token')) {
        // Automatically logout and redirect to login
        _handleTokenExpiry();
        return const Center(
          child: CircularProgressIndicator(), // Show loading while redirecting
        );
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchActiveTrips,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_activeTrips.isEmpty) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildStatusBanner(),
          ),
          const Expanded(
            child: EmptyState(
              icon: Icons.directions_car_outlined,
              title: 'No Active Trips',
              subtitle: 'Your ongoing trips will appear here',
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchActiveTrips,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatusBanner(),
          ..._activeTrips.map((trip) {
            return OnTripRideCard(
              trip: trip,
              onTripCompleted: _fetchActiveTrips,
            );
          }).toList(),
        ],
      ),
    );
  }
}
