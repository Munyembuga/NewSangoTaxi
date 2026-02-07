import 'package:flutter/material.dart';
import 'package:sango/l10n/l10n.dart';
import 'package:sango/screen/login.dart';
import 'package:sango/services/auth_service.dart';
import 'package:sango/services/storage_service.dart';
import 'package:sango/services/device_info_service.dart';
import '../../services/booking_service.dart';
import '../widgets/client_completed_ride_card.dart';
import '../widgets/empty_state.dart';
import 'package:shimmer/shimmer.dart'; // Add this import for Shimmer

class CompletedRidesTab extends StatefulWidget {
  const CompletedRidesTab({Key? key}) : super(key: key);

  @override
  State<CompletedRidesTab> createState() => _CompletedRidesTabState();
}

class _CompletedRidesTabState extends State<CompletedRidesTab> {
  bool _isLoading = false;
  String _errorMessage = '';
  List<dynamic> _completedTrips = [];
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

    // Auto-fetch trips for both guest and logged-in users
    _fetchCompletedTrips();
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

  Future<void> _fetchCompletedTrips({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      setState(() {
        _currentPage = 1;
        _errorMessage = '';
        _completedTrips = [];
      });
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> response;

      if (_isGuestMode) {
        final deviceId = await DeviceInfoService.getDeviceId();

        response = await BookingService.getGuestCompletedBookings(
          deviceId: deviceId,
          page: _currentPage,
        );
      } else {
        response =
            await BookingService.getCompletedBookings(page: _currentPage);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (response['success']) {
            final data = response['data'];
            final completedTrips = data['completed_trips'] ?? [];

            if (refresh) {
              _completedTrips = completedTrips;
            } else {
              _completedTrips.addAll(completedTrips);
            }

            // Update pagination info
            if (data['pagination'] != null) {
              _totalPages = data['pagination']['total_pages'] ?? 1;
              _hasMoreData = _currentPage < _totalPages;
            }
          } else {
            _errorMessage =
                response['message'] ?? 'Failed to load completed trips';
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
      _fetchCompletedTrips();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!; // Get localization

    if (_isLoading && _completedTrips.isEmpty) {
      return _buildLoadingState(); // Use the shimmer loading state
    }

    if (_errorMessage.isNotEmpty && _completedTrips.isEmpty) {
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
              onPressed: () => _fetchCompletedTrips(refresh: true),
              child: Text(s.retry),
            ),
          ],
        ),
      );
    }

    if (_completedTrips.isEmpty) {
      return EmptyState(
        icon: Icons.check_circle_outline,
        title: s.noCompletedRides,
        subtitle: s.completedRidesWillAppearHere,
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchCompletedTrips(refresh: true),
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
            _loadMoreData();
            return true;
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _completedTrips.length + (_hasMoreData ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _completedTrips.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            return ClientCompletedRideCard(trip: _completedTrips[index]);
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

  @override
  void dispose() {
    super.dispose();
  }
}
