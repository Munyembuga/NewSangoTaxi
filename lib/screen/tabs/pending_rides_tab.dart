import 'package:flutter/material.dart';
import 'package:sango/l10n/l10n.dart';
import 'package:sango/screen/login.dart';
import 'package:sango/services/auth_service.dart';
import '../../services/booking_service.dart';
import 'ride_data.dart';
import '../widgets/ride_card.dart';
import '../widgets/empty_state.dart';
import '../../services/storage_service.dart';
import '../../services/device_info_service.dart';
import 'package:shimmer/shimmer.dart'; // Add this import for Shimmer

class PendingRidesTab extends StatefulWidget {
  const PendingRidesTab({Key? key}) : super(key: key);

  @override
  State<PendingRidesTab> createState() => _PendingRidesTabState();
}

class _PendingRidesTabState extends State<PendingRidesTab> {
  bool _isLoading = false;
  String _errorMessage = '';
  List<dynamic> _pendingBookings = [];
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMoreData = false;
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
    _fetchPendingBookings();
  }

  Future<void> _handleTokenExpiry() async {
    try {
      await AuthService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  Future<void> _fetchPendingBookings({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      setState(() {
        _currentPage = 1;
        _errorMessage = '';
        _pendingBookings = [];
      });
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> response;

      if (_isGuestMode) {
        final deviceId = await DeviceInfoService.getDeviceId();

        response = await BookingService.getGuestPendingBookings(
          deviceId: deviceId,
          page: _currentPage,
        );
      } else {
        response = await BookingService.getPendingBookings(page: _currentPage);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (response['success']) {
            final data = response['data'];
            final bookings = data['bookings'] ?? [];

            if (refresh) {
              _pendingBookings = bookings;
            } else {
              _pendingBookings.addAll(bookings);
            }

            if (data['pagination'] != null) {
              _totalPages =
                  int.tryParse(data['pagination']['total_pages'].toString()) ??
                      1;
              _hasMoreData = _currentPage < _totalPages;
            }
          } else {
            _errorMessage = response['message'] ?? 'Failed to load bookings';
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

  void _loadMoreData() {
    if (!_isLoading && _hasMoreData) {
      _currentPage++;
      _fetchPendingBookings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!; // Get localization

    if (_isLoading && _pendingBookings.isEmpty) {
      return _buildLoadingState(); // Use the shimmer loading state
    }

    if (_errorMessage.isNotEmpty && _pendingBookings.isEmpty) {
      if (_errorMessage.toLowerCase().contains('invalid or expired token')) {
        _handleTokenExpiry();
        return const Center(child: CircularProgressIndicator());
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _fetchPendingBookings(refresh: true),
              child: Text(s.retry),
            ),
          ],
        ),
      );
    }

    if (_pendingBookings.isEmpty) {
      return EmptyState(
        icon: Icons.pending_outlined,
        title: s.noPendingRides,
        subtitle: s.pendingRidesWillAppearHere,
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchPendingBookings(refresh: true),
      child: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
            _loadMoreData();
            return true;
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _pendingBookings.length + (_hasMoreData ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _pendingBookings.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final ride =
                RideData.transformBookingToRide(_pendingBookings[index]);
            return RideCard(
              ride: ride,
              // showOtp: true, // Show OTP for pending rides
            );
          },
        ),
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
}
