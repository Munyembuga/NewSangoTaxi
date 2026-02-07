// home_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sango/screen/bookingScreen.dart';
import 'package:sango/screen/car_rental_screen.dart';
import 'package:sango/screen/deliveryScreen.dart';
import 'package:sango/screen/login.dart';
import 'package:sango/services/booking_service.dart';
import 'package:sango/models/booking_type_model.dart';
import 'package:sango/services/device_info_service.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:sango/services/storage_service.dart';
import 'package:sango/l10n/l10n.dart';
import 'package:provider/provider.dart';
import 'package:sango/main.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sango/services/carousel_service.dart';
import 'package:sango/models/carousel_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Simple replacement classes for Google Maps types
class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);
}

class Marker {
  final String id;
  final LatLng position;
  final String title;
  final String? snippet;

  const Marker({
    required this.id,
    required this.position,
    this.title = '',
    this.snippet,
  });
}

class CameraPosition {
  final LatLng target;
  final double zoom;

  const CameraPosition({required this.target, this.zoom = 14.0});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Completer<void> _controller = Completer<void>();
  LocationData? _currentPosition;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Set<Marker> _markers = {};
  Location location = Location();
  int _currentCarouselIndex = 0;

  // Booking Types instead of Categories
  List<BookingType> _bookingTypes = [];
  bool _isLoadingBookingTypes = true;
  bool _hasBookingTypesError = false;
  String _bookingTypesErrorMessage = '';

  // Replace the old carousel items list with CarouselItem model
  List<CarouselItem> _carouselItems = [];
  bool _isLoadingCarousel = true;
  bool _hasCarouselError = false;
  String _carouselErrorMessage = '';

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.0,
  );

  bool _isGuestMode = false;

  // Add shimmer placeholder count
  final int _shimmerCount = 3;

  @override
  void initState() {
    super.initState(); // Get device ID and name
// Show all device info in a dialog
    _checkGuestMode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocation();
      _fetchBookingTypes();
      _fetchCarouselItems(); // Replace _initCarouselItems with API call
    });
  }

  // Remove the old _initCarouselItems method and replace with API fetch
  Future<void> _fetchCarouselItems() async {
    setState(() {
      _isLoadingCarousel = true;
      _hasCarouselError = false;
    });

    final result = await CarouselService.getCarouselItems();

    if (result['success']) {
      setState(() {
        _carouselItems = result['data'];
        _isLoadingCarousel = false;
      });
    } else {
      setState(() {
        _hasCarouselError = true;
        _carouselErrorMessage = result['message'];
        _isLoadingCarousel = false;
        // Fallback to empty list or show error
        _carouselItems = [];
      });
    }
  }

  Future<void> _checkGuestMode() async {
    final isGuest = await StorageService.isGuestMode();
    if (isGuest) {
      setState(() {
        _isGuestMode = true;
      });
    }
  }

  Future<void> _initializeLocation() async {
    try {
      await _getCurrentLocation();
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Location service error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          setState(() {
            _hasError = true;
            _errorMessage = 'Location service is disabled';
            _isLoading = false;
          });
          return;
        }
      }

      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          setState(() {
            _hasError = true;
            _errorMessage = 'Location permission denied';
            _isLoading = false;
          });
          return;
        }
      }

      LocationData locationData = await location.getLocation();
      setState(() {
        _currentPosition = locationData;
        _markers.add(
          Marker(
            id: 'current_location',
            position: LatLng(locationData.latitude!, locationData.longitude!),
            title: 'Your Location',
          ),
        );
        _isLoading = false;
        _hasError = false;
      });

      if (!_controller.isCompleted) {
        _controller.complete();
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchBookingTypes() async {
    setState(() {
      _isLoadingBookingTypes = true;
      _hasBookingTypesError = false;
    });

    final result = await BookingService.getBookingTypes();
    print('Fetching booking types...');
    print('Result: $result');

    if (result['success']) {
      final List<dynamic> bookingTypeData = result['data']['data'] ?? [];
      setState(() {
        _bookingTypes = bookingTypeData
            .map((json) => BookingType.fromJson(json))
            .where((bookingType) => bookingType.isActive)
            .toList();
        _isLoadingBookingTypes = false;
      });
    } else {
      setState(() {
        _hasBookingTypesError = true;
        _bookingTypesErrorMessage = result['message'];
        _isLoadingBookingTypes = false;
      });
    }
  }

  void _navigateToBookingScreen({
    String? bookingTypeId,
    String bookingTypeName = 'Ride with Driver',
  }) {
    // If in guest mode, show login prompt
    // if (_isGuestMode) {
    //   _showLoginPrompt();
    //   return;
    // }

    // For booking type 4 (delivery), navigate to delivery screen
    if (bookingTypeId == '4') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const DeliveryScreen(),
        ),
      );
    }
    // For booking types 2 and 3 (car rentals), navigate to the specialized rental screen
    else if (bookingTypeId == '2' || bookingTypeId == '3') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CarRentalScreen(
            initialPickupLocation: _currentPosition,
            bookingTypeId: bookingTypeId,
            bookingTypeName: bookingTypeName,
          ),
        ),
      );
    } else {
      // For normal rides, use the regular booking screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookingScreen(
            initialPickupLocation: _currentPosition,
            initialVehicleType: bookingTypeName,
            bookingTypeId: bookingTypeId,
          ),
        ),
      );
    }
  }

  // Show a dialog prompting the user to log in
  void _showLoginPrompt() {
    final l10n = S.of(context)!;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.loginRequired),
          content: Text(l10n.loginMessage),
          actions: <Widget>[
            TextButton(
              child: Text(l10n.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child:
                  Text(l10n.login, style: TextStyle(color: Color(0xFFF5141E))),
              onPressed: () {
                // Clear guest session and navigate to login
                StorageService.clearGuestSession().then((_) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => LoginScreen(),
                    ),
                  );
                });
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context)!;
    final locale = Localizations.localeOf(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Icon(Icons.directions_car, color: Colors.white),
            SizedBox(width: 8),
            Text(l10n.appName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                )),
          ],
        ),
        backgroundColor: const Color(0xFFF5141E),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 25.0), // Adjust as needed
            child: DropdownButton<Locale>(
              value: locale,
              icon: const Icon(Icons.language, color: Colors.white),
              underline: Container(),
              dropdownColor: const Color(0xFFF5141E),
              items: S.supportedLocales
                  .map<DropdownMenuItem<Locale>>((Locale locale) {
                final flag = _getFlag(locale.languageCode);
                return DropdownMenuItem<Locale>(
                  value: locale,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(flag, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        locale.languageCode.toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (Locale? newLocale) {
                if (newLocale != null) {
                  localeProvider.setLocale(newLocale);
                }
              },
            ), // IconButton(
            //   icon: const Icon(Icons.notifications),
            //   onPressed: () {
            //     if (_isGuestMode) {
            //       _showLoginPrompt();
            //     } else {
            //       // Handle notifications
            //     }
            //   },
            // ),
            // if (_isGuestMode)
            //   Padding(
            //     padding: const EdgeInsets.only(right: 8.0),
            //     child: Chip(
            //       label: Text(l10n.guestMode),
            //       backgroundColor: Colors.amber.shade100,
            //       labelStyle: const TextStyle(fontSize: 12),
            //     ),
            //   )
          ),
        ],
      ),
      body: Column(
        children: [
          // Add spacing at top
          const SizedBox(height: 15),

          // Carousel Slider with loading state
          _isLoadingCarousel
              ? _buildCarouselShimmer()
              : _hasCarouselError
                  ? _buildCarouselError()
                  : _carouselItems.isEmpty
                      ? _buildEmptyCarousel()
                      : CarouselSlider(
                          options: CarouselOptions(
                            height: 220,
                            autoPlay: true,
                            enlargeCenterPage: true,
                            viewportFraction: 0.9,
                            aspectRatio: 16 / 9,
                            initialPage: 0,
                            autoPlayInterval: const Duration(seconds: 5),
                            onPageChanged: (index, reason) {
                              setState(() {
                                _currentCarouselIndex = index;
                              });
                            },
                          ),
                          items: _carouselItems.map((item) {
                            return Builder(
                              builder: (BuildContext context) {
                                return Container(
                                  width: MediaQuery.of(context).size.width,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 5.0),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        spreadRadius: 1,
                                        blurRadius: 5,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: CachedNetworkImage(
                                          imageUrl: item.imageUrl,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                          placeholder: (context, url) =>
                                              Container(
                                            color: Colors.grey[300],
                                            child: const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) =>
                                              Container(
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.error,
                                                size: 50),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                const BorderRadius.only(
                                              bottomLeft: Radius.circular(15),
                                              bottomRight: Radius.circular(15),
                                            ),
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.transparent,
                                                Colors.black.withOpacity(0.7),
                                              ],
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.title,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                item.subtitle,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),

          // Carousel Indicators - only show if carousel items exist
          if (!_isLoadingCarousel &&
              !_hasCarouselError &&
              _carouselItems.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _carouselItems.asMap().entries.map((entry) {
                return Container(
                  width: 8.0,
                  height: 8.0,
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 4.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentCarouselIndex == entry.key
                        ? const Color(0xFFF5141E)
                        : Colors.grey.withOpacity(0.3),
                  ),
                );
              }).toList(),
            ),

          SizedBox(height: 40),
          // Booking Types Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.bookingTypes,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_hasBookingTypesError)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _fetchBookingTypes,
                    tooltip: l10n.retry,
                  ),
              ],
            ),
          ),
          SizedBox(height: 20),
          // Booking Types
          Expanded(
            child: _isLoadingBookingTypes
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SingleChildScrollView(
                      child: Column(
                        children: List.generate(_shimmerCount,
                            (index) => _buildBookingTypeShimmer()),
                      ),
                    ),
                  )
                : _hasBookingTypesError
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l10n.failedToLoad,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _fetchBookingTypes,
                              child: Text(l10n.retry),
                            ),
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SingleChildScrollView(
                          child: Column(
                            children: _buildBookingTypeGrid(),
                          ),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        backgroundColor: const Color(0xFFF5141E),
        tooltip: l10n.myLocation,
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }

  // Build booking types in a grid layout (2 cards per row)
  List<Widget> _buildBookingTypeGrid() {
    List<Widget> rows = [];

    for (int i = 0; i < _bookingTypes.length; i += 2) {
      List<Widget> rowChildren = [];

      // Add first card
      rowChildren.add(
        Expanded(
          child: _buildBookingTypeCard(_bookingTypes[i]),
        ),
      );

      // Add spacing
      if (i + 1 < _bookingTypes.length) {
        rowChildren.add(const SizedBox(width: 12));
      }

      // Add second card if it exists
      if (i + 1 < _bookingTypes.length) {
        rowChildren.add(
          Expanded(
            child: _buildBookingTypeCard(_bookingTypes[i + 1]),
          ),
        );
      } else {
        // Add empty space if odd number of items
        rowChildren.add(const Expanded(child: SizedBox()));
      }

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rowChildren,
          ),
        ),
      );
    }

    return rows;
  }

  Widget _buildBookingTypeCard(BookingType bookingType) {
    // Map booking type names to icons and colors
    IconData icon;
    Color color;

    switch (bookingType.bookingTypeId.toLowerCase()) {
      case '1':
        icon = Icons.directions_car;
        color = const Color(0xFF4CAF50);
        break;
      case '2':
        icon = Icons.drive_eta;
        color = const Color(0xFF2196F3);
        break;
      case '3':
        icon = Icons.car_rental;
        color = const Color(0xFFFF9800);
        break;
      case '4':
        icon = Icons.local_taxi;
        color = const Color(0xFFE91E63);
        break;
      default:
        icon = Icons.directions_car;
        color = Colors.grey;
        break;
    }

    return GestureDetector(
      onTap: () => _navigateToBookingScreen(
        bookingTypeId: bookingType.bookingTypeId,
        bookingTypeName: bookingType.typeName,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              bookingType.typeName,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              bookingType.description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Shimmer placeholder for booking type card
  Widget _buildBookingTypeShimmer() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 120,
                      height: 12,
                      color: Colors.grey[300],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 16,
                height: 16,
                color: Colors.grey[300],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Add this helper method to get the flag emoji
  String _getFlag(String code) {
    switch (code) {
      case 'fr':
        return '🇫🇷';
      case 'en':
      default:
        return '🇺🇸';
    }
  }

  // Add carousel loading shimmer
  Widget _buildCarouselShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: 220,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }

  // Add carousel error widget
  Widget _buildCarouselError() {
    return Container(
      height: 220,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 8),
            Text(
              'Failed to load carousel',
              style: TextStyle(color: Colors.red[700]),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _fetchCarouselItems,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // Add empty carousel widget
  Widget _buildEmptyCarousel() {
    return Container(
      height: 220,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Center(
        child: Text(
          'No carousel items available',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
