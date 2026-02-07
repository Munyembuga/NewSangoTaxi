import 'package:flutter/material.dart';
import 'package:sango/screen/login.dart';
import 'package:sango/services/auth_service.dart';
import 'package:sango/services/storage_service.dart';
import '../../services/driver_service.dart';
import '../widgets/canceled_ride_card.dart';
import '../../screen/widgets/empty_state.dart';

class CanceledRidesDriverTab extends StatefulWidget {
  const CanceledRidesDriverTab({Key? key}) : super(key: key);

  @override
  State<CanceledRidesDriverTab> createState() => _CanceledRidesDriverTabState();
}

class _CanceledRidesDriverTabState extends State<CanceledRidesDriverTab> {
  bool _isLoading = true;
  String _errorMessage = '';
  List<dynamic> _canceledTrips = [];
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMoreData = false;
  String? _driverId;
  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchCanceledTrips();
  }

  Future<void> _loadUserData() async {
    try {
      final driverData = await StorageService.getDriverData();
      print("Driver Data: $driverData");

      if (driverData != null) {
        setState(() {
          _driverId = driverData['driver_id']?.toString() ?? '0';
          print("Driver ID: $_driverId");
        });

        _fetchCanceledTrips();
      }
    } catch (e) {
      print("Error loading user data: $e");
    }
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
      print('Error during logout: $e');
    }
  }

  Future<void> _fetchCanceledTrips({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _isLoading = true;
        _errorMessage = '';
        _canceledTrips = [];
      });
    }

    try {
      final response = await DriverService.getCanceledTrips(
        driverId:
            _driverId.toString(), // Replace with dynamic driver ID if needed
        page: _currentPage,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (response['success']) {
            final canceledTrips = response['cancellations'] ?? [];

            if (refresh) {
              _canceledTrips = canceledTrips;
            } else {
              _canceledTrips.addAll(canceledTrips);
            }

            // Update pagination info
            if (response['pagination'] != null) {
              _totalPages = response['pagination']['total_pages'] ?? 1;
              _hasMoreData = _currentPage < _totalPages;
            }
          } else {
            _errorMessage =
                response['message'] ?? 'Failed to load canceled trips';
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
      _fetchCanceledTrips();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _canceledTrips.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty && _canceledTrips.isEmpty) {
      if (_errorMessage.toLowerCase().contains('invalid or expired token')) {
        _handleTokenExpiry();
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _fetchCanceledTrips(refresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_canceledTrips.isEmpty) {
      return const EmptyState(
        icon: Icons.cancel_outlined,
        title: 'No Canceled Trips',
        subtitle: 'Your canceled trips will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchCanceledTrips(refresh: true),
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
          itemCount: _canceledTrips.length + (_hasMoreData ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _canceledTrips.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            return CanceledRideCard(trip: _canceledTrips[index]);
          },
        ),
      ),
    );
  }
}
