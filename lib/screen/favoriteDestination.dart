import 'package:flutter/material.dart';
import 'package:sango/services/favorite_location_service.dart';
import 'package:sango/models/favorite_location_model.dart';
import 'package:sango/services/storage_service.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sango/l10n/l10n.dart'; // Changed import for localization

class FavoriteDestinationsScreen extends StatefulWidget {
  const FavoriteDestinationsScreen({Key? key}) : super(key: key);

  @override
  State<FavoriteDestinationsScreen> createState() =>
      _FavoriteDestinationsScreenState();
}

class _FavoriteDestinationsScreenState
    extends State<FavoriteDestinationsScreen> {
  // Replace sample data with API data
  FavoriteLocationModel? _favoriteLocations;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _isGuestMode = false;

  @override
  void initState() {
    super.initState();
    _checkGuestMode();
    _fetchFavoriteLocations();
  }

  Future<void> _checkGuestMode() async {
    final isGuest = await StorageService.isGuestMode();
    setState(() {
      _isGuestMode = isGuest;
    });
  }

  Future<void> _fetchFavoriteLocations() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final result = await FavoriteLocationService.getFavoriteLocations();

    if (result['success']) {
      setState(() {
        _favoriteLocations = result['data'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _hasError = true;
        _errorMessage = result['message'];
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!; // Changed to use S instead of AppLocalizations
    return Scaffold(
      appBar: AppBar(
        title: Text(
          s.favoriteDestinations,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFF5141E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchFavoriteLocations,
            tooltip: s.retry,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _hasError
              ? _buildErrorState()
              : _favoriteLocations == null ||
                      _favoriteLocations!.allLocations.isEmpty
                  ? _buildEmptyState()
                  : _buildDestinationsList(),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => _buildShimmerCard(),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final s = S.of(context)!; // Changed to use S instead of AppLocalizations
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              s.failedToLoadDestinations ?? 'Failed to Load Destinations',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchFavoriteLocations,
              icon: const Icon(Icons.refresh),
              label: Text(s.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5141E),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final s = S.of(context)!; // Changed to use S instead of AppLocalizations
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border,
                size: 60,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _isGuestMode
                  ? s.noFavoriteDestinationsYet ??
                      'No Favorite Destinations Yet'
                  : s.noFavoriteDestinations ?? 'No Favorite Destinations',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isGuestMode
                  ? s.favoritesWillAppearAsYouUse ??
                      'Your frequently visited locations will appear here as you use the app'
                  : s.addPlacesYouVisit ??
                      'Add places you visit frequently to save time on future bookings',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _fetchFavoriteLocations,
              icon: const Icon(Icons.refresh),
              label: Text(s.refresh ?? 'Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5141E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationsList() {
    final s = S.of(context)!; // Changed to use S instead of AppLocalizations
    final locations = _favoriteLocations!.allLocations;

    // Group locations by type
    final pickupLocations =
        locations.where((loc) => loc.type == 'pickup').toList();
    final dropoffLocations =
        locations.where((loc) => loc.type == 'dropoff').toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header info
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFF5141E).withOpacity(0.1),
                  const Color(0xFFF5141E).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFF5141E).withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: const Color(0xFFF5141E),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    s.frequentlyUsedLocations ??
                        'These are your most frequently used locations. Tap to use as destination.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Pickup Locations Section
          if (pickupLocations.isNotEmpty) ...[
            _buildSectionHeader(s.pickupLocations ?? 'Pickup Locations',
                Icons.location_on, const Color(0xFFF5141E)),
            ...pickupLocations.map((location) => _buildLocationCard(location)),
            const SizedBox(height: 16),
          ],

          // Dropoff Locations Section
          if (dropoffLocations.isNotEmpty) ...[
            _buildSectionHeader(s.dropoffLocations ?? 'Drop-off Locations',
                Icons.flag, Colors.blue),
            ...dropoffLocations.map((location) => _buildLocationCard(location)),
          ],

          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(LocationItem location) {
    final s = S.of(context)!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // Navigate to booking screen with this destination
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(s.usingDestination(location.location) ??
                  'Using "${location.location}" as destination...'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: location.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  location.icon,
                  color: location.color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),

              // Location info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.location,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.history,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          s.usedTimes(location.usageCount.toString(),
                                  location.usageCount != 1 ? 's' : '') ??
                              'Used ${location.usageCount} time${location.usageCount != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: location.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            (location.type == 'pickup' ? s.pickup : s.dropoff)
                                    ?.toUpperCase() ??
                                location.type.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              color: location.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow icon
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
