import 'package:flutter/material.dart';
import 'package:sango/l10n/l10n.dart';
import 'package:sango/screen/login.dart';
import 'package:sango/services/auth_service.dart';
import 'package:sango/services/storage_service.dart';
import 'package:sango/services/device_info_service.dart';
import '../../services/booking_service.dart';
import 'ride_data.dart';
import '../widgets/ride_card.dart';
import '../widgets/empty_state.dart';
import 'package:shimmer/shimmer.dart'; // Add this import for Shimmer

class OnTripTab extends StatefulWidget {
  const OnTripTab({Key? key}) : super(key: key);

  @override
  State<OnTripTab> createState() => _OnTripTabState();
}

class _OnTripTabState extends State<OnTripTab> {
  bool _isLoading = false;
  String _errorMessage = '';
  List<dynamic> _onTripBookings = [];
  bool _clientOnTrip = false;
  bool _isGuestMode = false;

  @override
  void initState() {
    super.initState();
    _checkGuestMode();
  }

  Future<void> _checkGuestMode() async {
    final isGuest = await StorageService.isGuestMode();
    setState(() {
      _isGuestMode = isGuest;
    });

    // Auto-fetch bookings for both guest and logged-in users
    _fetchOnTripBookings();
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

  Future<void> _fetchOnTripBookings({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
        _onTripBookings = [];
      });
    } else if (!_isLoading) {
      // Only set loading to true if not already loading
      setState(() {
        _isLoading = true;
      });
    }

    try {
      Map<String, dynamic> response;

      if (_isGuestMode) {
        final deviceId = await DeviceInfoService.getDeviceId();

        response = await BookingService.getGuestOnTripBookings(
          deviceId: deviceId,
        );
      } else {
        response = await BookingService.getOnTripBookings();
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (response['success']) {
            final data = response['data'];
            _onTripBookings = data['bookings'] ?? [];
            _clientOnTrip = data['client_on_trip'] ?? false;
          } else {
            _errorMessage =
                response['message'] ?? 'Failed to load on trip bookings';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An error occurred while fetching data';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;

    if (_isLoading && _onTripBookings.isEmpty) {
      return _buildLoadingState(); // Use the shimmer loading state
    }

    if (_errorMessage.isNotEmpty && _onTripBookings.isEmpty) {
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
              onPressed: () => _fetchOnTripBookings(refresh: true),
              child: Text(s.retry),
            ),
          ],
        ),
      );
    }

    if (_onTripBookings.isEmpty) {
      return EmptyState(
        icon: Icons.directions_car_outlined,
        title: s.noActiveTrips,
        subtitle: s.activeTripsWillAppearHere,
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchOnTripBookings(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _onTripBookings.length,
        itemBuilder: (context, index) {
          final ride = RideData.transformBookingToRide(_onTripBookings[index]);
          return RideCard(ride: ride);
        },
      ),
    );
  }

  // Add the loading state method
  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
