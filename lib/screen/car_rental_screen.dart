import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:sango/l10n/l10n.dart';
import 'package:sango/screen/bottomTab.dart';
import 'package:sango/screen/login.dart';
import 'package:sango/services/device_info_service.dart';
import 'package:sango/services/storage_service.dart';
import 'package:location/location.dart' as loc;
import 'package:sango/models/booking_type_model.dart';
import 'package:sango/services/booking_service.dart';

class CarRentalScreen extends StatefulWidget {
  final loc.LocationData? initialPickupLocation;
  final String? bookingTypeId;
  final String bookingTypeName;

  const CarRentalScreen({
    Key? key,
    this.initialPickupLocation,
    required this.bookingTypeId,
    required this.bookingTypeName,
  }) : super(key: key);

  @override
  State<CarRentalScreen> createState() => _CarRentalScreenState();
}

class _CarRentalScreenState extends State<CarRentalScreen> {
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _pickupDateController = TextEditingController();
  final TextEditingController _returnDateController = TextEditingController();

  DateTime _pickupDate = DateTime.now().add(const Duration(hours: 1));
  DateTime _returnDate = DateTime.now().add(const Duration(days: 1));

  loc.Location location = loc.Location();
  bool _isProcessingBooking = false;
  double _estimatedFare = 0.0;
  bool _isGuestMode = false;
  // Location coordinates
  double? _pickupLat;
  double? _pickupLng;
  double _finalPrice = 0.0;
  // Duration type selection
  String _selectedDurationType = 'day'; // Default to daily rental

  // Categories
  List<CategoryWithBookingType> _categories = [];
  CategoryWithBookingType? _selectedCategory;
  bool _isLoadingCategories = false;
  String _categoryError = '';

  // Add variables to track rental duration
  int _rentalDuration = 1;
  Map<String, double> _pricesByType = {};

  // Add a text controller for the duration quantity input
  final TextEditingController _durationQuantityController =
      TextEditingController(text: "1");

  // Add a flag to prevent infinite loops when syncing dates and duration
  bool _isUpdatingDates = false;

  // Add controllers for guest information
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _guestNameController = TextEditingController();

  // Variables to store pricing information
  double _baseDayPrice = 0.0;
  List<Map<String, dynamic>> _discounts = [];

  // Add a variable to store available vehicles for the selected category
  String _availableVehicles = '';

  @override
  void initState() {
    super.initState();
    _checkGuestMode();

    _fetchCategoriesByBookingType(
        widget.bookingTypeId ?? '2'); // Default to 2 if null

    if (widget.initialPickupLocation != null) {
      _pickupLat = widget.initialPickupLocation!.latitude;
      _pickupLng = widget.initialPickupLocation!.longitude;
      _pickupController.text =
          'Current Location (${widget.initialPickupLocation!.latitude!.toStringAsFixed(4)}, ${widget.initialPickupLocation!.longitude!.toStringAsFixed(4)})';
    } else {
      _setCurrentLocationAsPickup();
    }

    // Initialize date controllers and set default duration
    _updateDateControllers();

    // Add listener to duration quantity controller
    _durationQuantityController.addListener(_onDurationQuantityChanged);
  }

  // Handle manual duration quantity changes
  void _onDurationQuantityChanged() {
    if (_isUpdatingDates) return;

    final quantity = int.tryParse(_durationQuantityController.text) ?? 1;
    if (quantity < 1) {
      _durationQuantityController.text = '1';
      return;
    }

    // Update return date based on pickup date and duration
    _updateReturnDateFromDuration(quantity);

    // Recalculate fare
    _calculateRentalFare();
  }

  // Update return date based on selected duration quantity
  void _updateReturnDateFromDuration(int quantity) {
    if (quantity < 1) quantity = 1;

    _isUpdatingDates = true;

    switch (_selectedDurationType) {
      case 'day':
        _returnDate = _pickupDate.add(Duration(days: quantity));
        break;
      case 'week':
        _returnDate = _pickupDate.add(Duration(days: quantity * 7));
        break;
      case 'month':
        // Approximate a month as 30 days
        _returnDate = _pickupDate.add(Duration(days: quantity * 30));
        break;
    }

    // Update the date controller text
    _returnDateController.text =
        DateFormat('EEE, MMM d, yyyy - h:mm a').format(_returnDate);

    _isUpdatingDates = false;
  }

  void _updateDateControllers() {
    _pickupDateController.text =
        DateFormat('EEE, MMM d, yyyy - h:mm a').format(_pickupDate);
    _returnDateController.text =
        DateFormat('EEE, MMM d, yyyy - h:mm a').format(_returnDate);

    // Calculate duration based on selected type without triggering listener
    _calculateRentalDuration();

    // Recalculate fare when dates change
    _calculateRentalFare();
  }

  void _calculateRentalDuration() {
    if (_isUpdatingDates) return;

    final difference = _returnDate.difference(_pickupDate);
    int calculatedDuration = 1;

    if (_selectedDurationType == 'day') {
      calculatedDuration = difference.inDays < 1 ? 1 : difference.inDays;
    } else if (_selectedDurationType == 'week') {
      calculatedDuration = (difference.inDays / 7).ceil();
      if (calculatedDuration < 1) calculatedDuration = 1;
    } else if (_selectedDurationType == 'month') {
      calculatedDuration = (difference.inDays / 30).ceil();
      if (calculatedDuration < 1) calculatedDuration = 1;
    }

    // Update the duration controller without triggering the listener
    _isUpdatingDates = true;
    _durationQuantityController.text = calculatedDuration.toString();
    _rentalDuration = calculatedDuration;
    _isUpdatingDates = false;

    print('Rental duration: $_rentalDuration $_selectedDurationType(s)');
  }

  Future<void> _fetchCategoriesByBookingType(String bookingTypeId) async {
    setState(() {
      _isLoadingCategories = true;
      _categoryError = '';
    });

    try {
      final result =
          await BookingService.getCategoriesByBookingType(bookingTypeId);

      if (result['success']) {
        final dynamic categoryData = result['data']['data'] ?? result['data'];
        List<dynamic> categoryList = [];

        if (categoryData is List) {
          categoryList = categoryData;
        } else if (categoryData is Map<String, dynamic>) {
          categoryList = [categoryData];
        } else {
          setState(() {
            _categoryError = 'Unexpected data format received';
            _isLoadingCategories = false;
          });
          return;
        }

        setState(() {
          _categories = categoryList
              .map((json) => CategoryWithBookingType.fromJson(json))
              .where((category) => category.isActive)
              .toList();

          if (_categories.isNotEmpty) {
            _selectedCategory = _categories.first;
            // Set available vehicles for the first category
            _availableVehicles =
                _selectedCategory?.availableVehicles?.toString() ?? '';
          }

          _isLoadingCategories = false;
        });

        // Calculate initial fare
        _calculateRentalFare();
      } else {
        setState(() {
          _categoryError = result['message'];
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      setState(() {
        _categoryError = 'Failed to fetch categories: $e';
        _isLoadingCategories = false;
      });
    }
  }

  // Modified to fetch price details for selected category
  Future<void> _fetchPriceDetails(String categoryId) async {
    if (widget.bookingTypeId == null) return;

    try {
      final result = await BookingService.getPriceByCategoryAndType(
        categoryId: categoryId,
        bookingTypeId: widget.bookingTypeId!,
      );

      if (result['success']) {
        final dynamic data = result['data'];

        if (data != null && data['pricing'] != null) {
          final pricing = data['pricing'];

          setState(() {
            _pricesByType.clear();
            _baseDayPrice = 0.0;
            _discounts = [];

            // Handle the new pricing structure
            if (pricing['details'] != null) {
              final details = pricing['details'] as List;

              for (var item in details) {
                final type = item['price_type_name'].toString();
                double price = 0;

                if (pricing['type'] == 'rental_with_driver') {
                  price = double.tryParse(item['total_price'].toString()) ?? 0;
                } else {
                  // Use car_rent_price for rental type
                  price =
                      double.tryParse(item['car_rent_price'].toString()) ?? 0;
                }

                _pricesByType[type] = price;

                // Store base day price for discount calculations
                if (type == 'day') {
                  _baseDayPrice = price;
                }
              }
            }
            print("discounts: ${pricing['discounts']}");
            // Store discount information
            if (pricing['discounts'] != null) {
              _discounts =
                  List<Map<String, dynamic>>.from(pricing['discounts']);
            }
          });

          print('Base day price: $_baseDayPrice');
          print('Discounts loaded: $_discounts');
          print('Prices loaded: $_pricesByType');
          _calculateRentalFare();
        }
      } else {
        print('Error fetching price details: ${result['message']}');
      }
    } catch (e) {
      print('Error fetching price details: $e');
    }
  }

  void _calculateRentalFare() {
    if (_selectedCategory == null) return;

    // Get rental duration from the controller
    final quantity = int.tryParse(_durationQuantityController.text) ?? 1;
    _rentalDuration = quantity < 1 ? 1 : quantity;

    // Convert all durations to days for discount calculation
    int totalDays = _rentalDuration;
    switch (_selectedDurationType) {
      case 'week':
        totalDays = _rentalDuration * 7;
        break;
      case 'month':
        totalDays = _rentalDuration * 30;
        break;
    }

    double basePrice = 0.0;

    // Use cached prices if available
    if (_pricesByType.isNotEmpty &&
        _pricesByType.containsKey(_selectedDurationType)) {
      basePrice = _pricesByType[_selectedDurationType]! * _rentalDuration;
    } else {
      // Fallback to category pricing data
      final pricing = _selectedCategory!.pricing;
      if (pricing != null && pricing['details'] != null) {
        final details = pricing['details'] as List;
        final durationPrices = details
            .where(
                (detail) => detail['price_type_name'] == _selectedDurationType)
            .toList();

        if (durationPrices.isNotEmpty) {
          final priceDetail = durationPrices.first;
          double price = 0;

          if (priceDetail.containsKey('total_price')) {
            price = double.tryParse(priceDetail['total_price'].toString()) ?? 0;
          } else if (priceDetail.containsKey('car_rent_price')) {
            price =
                double.tryParse(priceDetail['car_rent_price'].toString()) ?? 0;
          }

          basePrice = price * _rentalDuration;
        }
      }
    }

    // Apply discount based on total days
    _finalPrice = basePrice;
    double discountPercentage = 0.0;
    String discountDescription = '';

    // Find applicable discount
    for (var discount in _discounts) {
      final minLim = int.tryParse(discount['min_lim'].toString()) ?? 0;
      final maxLim = int.tryParse(discount['max_lim'].toString()) ?? 365;
      final percentage =
          double.tryParse(discount['percentage'].toString()) ?? 0;

      if (totalDays >= minLim && totalDays <= maxLim) {
        discountPercentage = percentage;
        discountDescription = discount['Description'] ?? '';
        break;
      }
    }

    // Apply discount if applicable
    if (discountPercentage > 0) {
      final discountAmount = (basePrice * discountPercentage) / 100;
      _finalPrice = basePrice - discountAmount;
    }

    setState(() {
      _estimatedFare = _finalPrice;
    });

    print('Total days: $totalDays');
    print('Base price: $basePrice');
    print('Discount: $discountPercentage%h - $discountDescription');
    print('Final price: $_finalPrice');
  }

  void _setCurrentLocationAsPickup() async {
    try {
      loc.LocationData locationData = await location.getLocation();
      setState(() {
        _pickupLat = locationData.latitude;
        _pickupLng = locationData.longitude;
        _pickupController.text =
            'Current Location (${locationData.latitude!.toStringAsFixed(4)}, ${locationData.longitude!.toStringAsFixed(4)})';
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _selectPickupDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _pickupDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFF5141E),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_pickupDate),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFFF5141E),
                onPrimary: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          _pickupDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );

          // Ensure return date is after pickup date
          if (_returnDate.isBefore(_pickupDate)) {
            _returnDate = _pickupDate.add(const Duration(days: 1));
          }

          // Update return date based on current duration
          final quantity = int.tryParse(_durationQuantityController.text) ?? 1;
          _updateReturnDateFromDuration(quantity);

          _updateDateControllers();
        });
      }
    }
  }

  Future<void> _selectReturnDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _returnDate.isBefore(_pickupDate)
          ? _pickupDate.add(const Duration(days: 1))
          : _returnDate,
      firstDate: _pickupDate,
      lastDate: _pickupDate.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFF5141E),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_returnDate),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFFF5141E),
                onPrimary: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          _returnDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );

          // Recalculate the duration when return date changes
          _calculateRentalDuration();
          _updateDateControllers();
        });
      }
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

  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Login Required'),
          content: const Text(
            'You need to create an account or log in to book a ride.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Log In',
                  style: TextStyle(color: Color(0xFFF5141E))),
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

  void _confirmRental() async {
    // Prevent rental if no vehicles available
    if (_selectedCategory != null &&
        (_selectedCategory!.availableVehicles == null ||
            (_selectedCategory!.availableVehicles is int
                ? _selectedCategory!.availableVehicles == 0
                : int.tryParse(
                        _selectedCategory!.availableVehicles.toString()) ==
                    0))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No vehicles available for this category.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_isGuestMode) {
      _showGuestRentalDialog();
      return;
    }

    // Regular rental flow for authenticated users
    _processRental();
  }

  void _showGuestRentalDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Complete Your Rental'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Please provide your contact information to complete the rental:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _guestNameController,
                  decoration: InputDecoration(
                    labelText: 'Your Name',
                    hintText: 'Enter your full name',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '0788123456',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_guestNameController.text.trim().isEmpty ||
                    _phoneController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all fields'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                Navigator.of(context).pop();
                _processRental();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5141E),
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm Rental'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processRental() async {
    setState(() {
      _isProcessingBooking = true;
    });

    try {
      final rentalStart = DateFormat('yyyy-MM-dd HH:mm:ss').format(_pickupDate);
      final rentalEnd = DateFormat('yyyy-MM-dd HH:mm:ss').format(_returnDate);
      print("total_price&&&&&&&&&&&&&&&&&&: $_finalPrice");
      final response = await BookingService.rentCar(
        categoryId: int.parse(_selectedCategory!.catgId),
        bookingTypeId: widget.bookingTypeId ?? '2',
        pickupLocation: _pickupController.text,
        rentalDurationValue: _rentalDuration,
        rentalDurationUnit: _selectedDurationType,
        rentalStart: rentalStart,
        rentalEnd: rentalEnd,
        estimatedPrice: _finalPrice,
        clientId: _isGuestMode
            ? null
            : (await StorageService.getClientData())?['client_id'],
        deviceId: _isGuestMode ? await DeviceInfoService.getDeviceId() : null,
        phoneNumber: _isGuestMode ? _phoneController.text.trim() : null,
        guestName: _isGuestMode ? _guestNameController.text.trim() : null,
      );
      print("response###########################: $response");
      setState(() {
        _isProcessingBooking = false;
      });

      if (response['success']) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => BottomNavigation(
              initialIndex: 2, // Navigate to third tab (MainRentScreen)
              isGuestMode: _isGuestMode,
            ),
          ),
          (route) => false, // Remove all previous routes
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']),
            backgroundColor: Colors.green,
          ),
        );
        // Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessingBooking = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing rental: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.bookingTypeId == '3'
            ? S.of(context)?.rentCarWithDriver ?? 'Rent Car with Driver'
            : S.of(context)?.rentCar ?? 'Rent Car'),
        backgroundColor: const Color(0xFFF5141E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoadingCategories
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading rental options...')
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    widget.bookingTypeId == '3'
                        ? S.of(context)?.rentCarWithDriver ??
                            'Rent a car with driver'
                        : S.of(context)?.rentCar ?? 'Rent a car',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Vehicle Categories
                  if (_categories.isNotEmpty) _buildCategoryDropdown(),

                  const SizedBox(height: 10),

                  // Duration Type Selector
                  // Text(
                  //   S.of(context)?.rentalDurationType ?? 'Rental Duration Type',
                  //   style: TextStyle(
                  //     fontSize: 16,
                  //     fontWeight: FontWeight.w600,
                  //     color: Colors.black87,
                  //   ),
                  // ),
                  // const SizedBox(height: 8),
                  // _buildDurationTypeSelector(),

                  // Add Quantity Input
                  Text(
                    S.of(context)?.numberOfUnits ?? 'Number of Day(s)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildQuantityInput(),
                  const SizedBox(height: 24),

                  // Date Selectors
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              S.of(context)?.pickupDate ?? 'Pickup Date',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8),
                            TextField(
                              controller: _pickupDateController,
                              readOnly: true,
                              onTap: () => _selectPickupDate(context),
                              decoration: InputDecoration(
                                hintText: 'Select Pickup Date',
                                prefixIcon: const Icon(Icons.calendar_today,
                                    color: Color(0xFFF5141E)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: Color(0xFFF5141E), width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              S.of(context)?.returnDate ?? 'Return Date',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _returnDateController,
                              readOnly: true,
                              onTap: () => _selectReturnDate(context),
                              decoration: InputDecoration(
                                hintText: 'Select Return Date',
                                prefixIcon: const Icon(Icons.abc_outlined,
                                    color: Color(0xFFF5141E)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: Color(0xFFF5141E), width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Price Information
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5141E).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFFF5141E).withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.access_time,
                                    color: Color(0xFFF5141E), size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  S.of(context)?.durationType(
                                            _selectedDurationType != null &&
                                                    _selectedDurationType
                                                        .isNotEmpty
                                                ? _selectedDurationType[0]
                                                        .toUpperCase() +
                                                    _selectedDurationType
                                                        .substring(1)
                                                : '',
                                          ) ??
                                      '',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_month,
                                    color: Color(0xFFF5141E), size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  S.of(context)?.totalDuration(
                                            '$_rentalDuration',
                                            '${_selectedDurationType}${_rentalDuration > 1 ? 's' : ''}',
                                          ) ??
                                      '',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (_pricesByType.isNotEmpty &&
                            _pricesByType[_selectedDurationType] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.monetization_on,
                                        color: Color(0xFFF5141E), size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Rate: ${_pricesByType[_selectedDurationType]?.toInt()} USD per $_selectedDurationType',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                        // Show discount information if applicable
                        if (_hasApplicableDiscount())
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.local_offer,
                                    color: Colors.green, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Discount: ${_getApplicableDiscountText()}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.attach_money,
                                color: Color(0xFFF5141E), size: 24),
                            Text(
                              S.of(context)?.totalPrice(
                                      '${_estimatedFare.toInt()}') ??
                                  '',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF5141E),
                              ),
                            ),
                          ],
                        ),
                        if (_selectedCategory != null &&
                            widget.bookingTypeId == '3')
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'Price includes driver',
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Confirm Button
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 56),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF5141E), Color(0xFFF5141E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: (!_isProcessingBooking &&
                              (_selectedCategory?.availableVehicles != null &&
                                  (int.tryParse(_selectedCategory!
                                              .availableVehicles
                                              .toString()) !=
                                          null &&
                                      int.tryParse(_selectedCategory!
                                              .availableVehicles
                                              .toString())! >
                                          0)))
                          ? _confirmRental
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isProcessingBooking
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _estimatedFare > 0
                                        ? S.of(context)?.confirmRentalWithPrice(
                                                _estimatedFare
                                                    .toStringAsFixed(0)) ??
                                            ''
                                        : S.of(context)?.confirmRental ?? '',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                  // Show warning if no vehicles available
                  if (_selectedCategory != null &&
                      (_selectedCategory!.availableVehicles == null ||
                          (int.tryParse(_selectedCategory!.availableVehicles
                                  .toString()) ==
                              0)))
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        'No vehicles available for this category.',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context)?.rentCarWithDriver ?? 'Select Vehicle',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownSearch<CategoryWithBookingType>(
          items: (filter, infiniteScrollProps) => _categories,
          selectedItem: _selectedCategory,
          itemAsString: (CategoryWithBookingType category) => category.catgName,
          compareFn:
              (CategoryWithBookingType item1, CategoryWithBookingType item2) {
            return item1.catgId == item2.catgId;
          },
          decoratorProps: DropDownDecoratorProps(
            decoration: InputDecoration(
              hintText: 'Select a vehicle',
              prefixIcon:
                  const Icon(Icons.directions_car, color: Color(0xFFF5141E)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFFF5141E), width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          popupProps: PopupProps.menu(
            showSearchBox: true,
            searchFieldProps: const TextFieldProps(
              decoration: InputDecoration(
                hintText: 'Search vehicles...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            menuProps: const MenuProps(
              backgroundColor: Colors.white,
              elevation: 8,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            itemBuilder: (context, item, isSelected, isFocused) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFF5141E).withOpacity(0.1)
                      : isFocused
                          ? Colors.grey.withOpacity(0.1)
                          : null,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade200,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5141E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.directions_car,
                        color: Color(0xFFF5141E),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.catgName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? const Color(0xFF07723D)
                                  : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.displayPrice,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF07723D),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          // Show available vehicles
                          if (item.availableVehicles != null)
                            Text(
                              'Available vehicles: ${item.availableVehicles}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFFF5141E),
                        size: 20,
                      ),
                  ],
                ),
              );
            },
            fit: FlexFit.loose,
            constraints: const BoxConstraints(maxHeight: 300),
          ),
          onChanged: (CategoryWithBookingType? newValue) {
            setState(() {
              _selectedCategory = newValue;
              _availableVehicles =
                  newValue?.availableVehicles?.toString() ?? '';
            });
            if (newValue != null) {
              _fetchPriceDetails(newValue.catgId);
            }
            _calculateRentalFare();
          },
          validator: (CategoryWithBookingType? item) {
            if (item == null) {
              return "Please select a vehicle";
            }
            return null;
          },
          dropdownBuilder: (context, selectedItem) {
            if (selectedItem == null) {
              return const Text(
                'Select a vehicle',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              );
            }

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5141E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.directions_car,
                      color: Color(0xFFF5141E),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          selectedItem.catgName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          selectedItem.displayPrice,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF07723D),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        // Show available vehicles for selected item
                        if (selectedItem.availableVehicles != null)
                          Text(
                            'Available vehicles: ${selectedItem.availableVehicles}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        // Show available vehicles below dropdown for selected category
        // if (_availableVehicles.isNotEmpty)
        //   Padding(
        //     padding: const EdgeInsets.only(top: 8),
        //     child: Text(
        //       'Available vehiclessdd: $_availableVehicles',
        //       style: const TextStyle(
        //         fontSize: 14,
        //         color: Colors.green,
        //         fontWeight: FontWeight.w600,
        //       ),
        //     ),
        //   ),
      ],
    );
  }

  // Override dispose to clean up controllers
  @override
  void dispose() {
    _pickupController.dispose();
    _pickupDateController.dispose();
    _returnDateController.dispose();
    _durationQuantityController.removeListener(_onDurationQuantityChanged);
    _durationQuantityController.dispose();
    _phoneController.dispose();
    _guestNameController.dispose();
    super.dispose();
  }

  // Add a widget for the quantity input
  Widget _buildQuantityInput() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Decrement button
          Material(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            color: const Color(0xFFF5141E).withOpacity(0.1),
            child: InkWell(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              onTap: () {
                final currentValue =
                    int.tryParse(_durationQuantityController.text) ?? 1;
                if (currentValue > 1) {
                  _durationQuantityController.text =
                      (currentValue - 1).toString();
                }
              },
              child: Container(
                width: 48,
                height: 54,
                alignment: Alignment.center,
                child: Icon(Icons.remove, color: const Color(0xFFF5141E)),
              ),
            ),
          ),

          // Input field
          Expanded(
            child: TextField(
              controller: _durationQuantityController,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 16),
                hintText: "1",
                suffixText: _selectedDurationType == 'day'
                    ? 'day(s)'
                    : _selectedDurationType == 'week'
                        ? 'week(s)'
                        : 'month(s)',
                suffixStyle: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ),

          // Increment button
          Material(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            color: const Color(0xFFF5141E).withOpacity(0.1),
            child: InkWell(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              onTap: () {
                final currentValue =
                    int.tryParse(_durationQuantityController.text) ?? 1;
                _durationQuantityController.text =
                    (currentValue + 1).toString();
              },
              child: Container(
                width: 48,
                height: 54,
                alignment: Alignment.center,
                child: Icon(Icons.add, color: const Color(0xFFF5141E)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to check if there's an applicable discount
  bool _hasApplicableDiscount() {
    if (_discounts.isEmpty) return false;

    // Convert rental duration to total days
    int totalDays = _rentalDuration;
    switch (_selectedDurationType) {
      case 'week':
        totalDays = _rentalDuration * 7;
        break;
      case 'month':
        totalDays = _rentalDuration * 30;
        break;
    }

    for (var discount in _discounts) {
      final minLim = int.tryParse(discount['min_lim'].toString()) ?? 0;
      final maxLim = int.tryParse(discount['max_lim'].toString()) ?? 365;

      if (totalDays >= minLim && totalDays <= maxLim) {
        return true;
      }
    }

    return false;
  }

  // Helper method to get discount text
  String _getApplicableDiscountText() {
    if (_discounts.isEmpty) return '';

    // Convert rental duration to total days
    int totalDays = _rentalDuration;
    switch (_selectedDurationType) {
      case 'week':
        totalDays = _rentalDuration * 7;
        break;
      case 'month':
        totalDays = _rentalDuration * 30;
        break;
    }

    for (var discount in _discounts) {
      final minLim = int.tryParse(discount['min_lim'].toString()) ?? 0;
      final maxLim = int.tryParse(discount['max_lim'].toString()) ?? 365;
      final percentage = discount['percentage'].toString();
      final description = discount['Description'] ?? '';

      if (totalDays >= minLim && totalDays <= maxLim) {
        return '$percentage% off - $description';
      }
    }

    return '';
  }
}
