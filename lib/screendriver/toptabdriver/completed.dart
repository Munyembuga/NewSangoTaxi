import 'package:flutter/material.dart';
import 'package:sango/screen/login.dart';
import 'package:sango/services/auth_service.dart';
import '../../services/driver_service.dart';
import '../widgets/completed_ride_card.dart';
import '../../screen/widgets/empty_state.dart';

class CompletedRidesDriverTab extends StatefulWidget {
  const CompletedRidesDriverTab({Key? key}) : super(key: key);

  @override
  State<CompletedRidesDriverTab> createState() =>
      _CompletedRidesDriverTabState();
}

class _CompletedRidesDriverTabState extends State<CompletedRidesDriverTab> {
  bool _isLoading = true;
  String _errorMessage = '';
  List<dynamic> _completedTrips = [];
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMoreData = false;

  @override
  void initState() {
    super.initState();
    _fetchCompletedTrips();
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

  Future<void> _fetchCompletedTrips({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _isLoading = true;
        _errorMessage = '';
        _completedTrips = [];
      });
    }

    try {
      final response =
          await DriverService.getCompletedTrips(page: _currentPage);

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (response['success']) {
            final completedTrips = response['completed_trips'] ?? [];

            if (refresh) {
              _completedTrips = completedTrips;
            } else {
              _completedTrips.addAll(completedTrips);
            }

            // Update pagination info
            if (response['pagination'] != null) {
              _totalPages = response['pagination']['total_pages'] ?? 1;
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
    if (_isLoading && _completedTrips.isEmpty) {
      return const Center(child: CircularProgressIndicator());
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
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_completedTrips.isEmpty) {
      return const EmptyState(
        icon: Icons.check_circle_outline,
        title: 'No Completed Trips',
        subtitle: 'Your completed trips will appear here',
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

            return CompletedRideCard(trip: _completedTrips[index]);
          },
        ),
      ),
    );
  }
}
