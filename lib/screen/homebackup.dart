// home_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sango/screen/bookingScreen.dart';
import 'package:sango/services/booking_service.dart';
import 'package:sango/models/category_model.dart';
import 'package:location/location.dart';
import 'package:carousel_slider/carousel_slider.dart';

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

  // Categories
  List<Category> _categories = [];
  bool _isLoadingCategories = true;
  bool _hasCategoriesError = false;
  String _categoriesErrorMessage = '';

  // Add carousel items
  final List<Map<String, dynamic>> _carouselItems = [
    {
      'image': 'assets/images/1.jpeg',
      'title': 'Fast & Reliable Rides',
      'subtitle': 'Get to your destination on time, every time'
    },
    {
      'image': 'assets/images/1.jpeg',
      'title': 'Safe & Secure',
      'subtitle': 'Your safety is our top priority'
    },
    {
      'image': 'assets/images/1.jpeg',
      'title': 'Affordable Prices',
      'subtitle': 'Enjoy premium service at competitive rates'
    },
    {
      'image': 'assets/images/1.jpeg',
      'title': 'Affordable Prices',
      'subtitle': 'Enjoy premium service at competitive rates'
    },
  ];

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocation();
      _fetchCategories();
    });
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

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _hasCategoriesError = false;
    });

    final result = await BookingService.getCategories(context);
    print('Fetching categories...');
    print('Result: $result');
    if (result['success']) {
      // The categories are now directly in the "data" field of the response
      final List<dynamic> categoryData = result['data']['data'] ?? [];
      setState(() {
        _categories =
            categoryData.map((json) => Category.fromJson(json)).toList();
        _isLoadingCategories = false;
      });
    } else {
      setState(() {
        _hasCategoriesError = true;
        _categoriesErrorMessage = result['message'];
        _isLoadingCategories = false;
      });
    }
  }

  void _navigateToBookingScreen(
      {String? categoryId, String vehicleType = 'Standard'}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingScreen(
          initialPickupLocation: _currentPosition,
          initialVehicleType: vehicleType,
          categoryId: categoryId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Icon(Icons.directions_car, color: Colors.white),
            SizedBox(width: 8),
            Text('Sango Ride',
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
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Add spacing at top
          const SizedBox(height: 15),

          // Carousel Slider
          CarouselSlider(
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
                    margin: const EdgeInsets.symmetric(horizontal: 5.0),
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
                        // You can use image assets or network images
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.asset(
                            item['image'],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                        // Text overlay
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['subtitle'],
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

          // Carousel Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _carouselItems.asMap().entries.map((entry) {
              return Container(
                width: 8.0,
                height: 8.0,
                margin:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
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
          // Vehicle Categories Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Vehicle Categories',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_hasCategoriesError)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _fetchCategories,
                    tooltip: 'Retry',
                  ),
              ],
            ),
          ),
          SizedBox(height: 20),
          // Vehicle Categories
          Expanded(
            child: _isLoadingCategories
                ? const Center(child: CircularProgressIndicator())
                : _hasCategoriesError
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Failed to load categories',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _fetchCategories,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: _categories.map((category) {
                              return SizedBox(
                                width:
                                    (MediaQuery.of(context).size.width - 44) /
                                        2,
                                child: _buildCategoryCard(category),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
          ),
          // SizedBox(height: 20),
          // Action Buttons
          // Expanded(
          //   flex: 2,
          //   child: Container(
          //     padding: const EdgeInsets.all(16),
          //     child: Column(
          //       children: [
          //         // Primary Action Button
          //         SizedBox(
          //           width: double.infinity,
          //           height: 60,
          //           child: ElevatedButton(
          //             onPressed: () {
          //               _navigateToBookingScreen();
          //             },
          //             style: ElevatedButton.styleFrom(
          //               backgroundColor: const Color(0xFFF5141E),
          //               foregroundColor: Colors.white,
          //               shape: RoundedRectangleBorder(
          //                 borderRadius: BorderRadius.circular(15),
          //               ),
          //               elevation: 5,
          //             ),
          //             child: const Row(
          //               mainAxisAlignment: MainAxisAlignment.center,
          //               children: [
          //                 Icon(Icons.add_location_alt,
          //                     size: 28, color: Colors.white),
          //                 SizedBox(width: 12),
          //                 Text(
          //                   'Book a Ride',
          //                   style: TextStyle(
          //                       fontSize: 18, fontWeight: FontWeight.bold),
          //                 ),
          //               ],
          //             ),
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        backgroundColor: const Color(0xFFF5141E),
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }

  Widget _buildCategoryCard(Category category) {
    // Map category names to icons and colors
    IconData icon;
    Color color;

    switch (category.catgName.toLowerCase()) {
      case 'standard ride':
        icon = Icons.directions_car;
        color = const Color(0xFF4CAF50);
        break;
      case 'executive':
        icon = Icons.car_rental;
        color = const Color(0xFF2196F3);
        break;
      case 'moto taxi':
        icon = Icons.motorcycle;
        color = const Color(0xFFA77D55);
        break;
      case 'economy':
        icon = Icons.directions_car;
        color = const Color(0xFFFF9800);
        break;
      case 'rent':
        icon = Icons.car_rental;
        color = const Color(0xFF607D8B);
        break;
      default:
        icon = Icons.directions_car;
        color = Colors.grey;
        break;
    }

    return GestureDetector(
      onTap: () => _navigateToBookingScreen(
        categoryId: category.catgId,
        vehicleType: category.catgName,
      ),
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const Spacer(),
                Text(
                  "${category.pricing?.getFormattedBaseFare() ?? 'Price varies'} FCFA",
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              category.catgName.toString(),
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${category.availableVehicles} vehicles available',
                  style: TextStyle(
                      color: Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
                Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey[600]),
              ],
            ),
            Text(
              category.pricing?.getFormattedPerKmRate() ?? 'Rate varies',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
