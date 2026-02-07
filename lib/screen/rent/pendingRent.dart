import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sango/l10n/l10n.dart'; // Add this import
import '../../services/booking_service.dart';
import '../../services/storage_service.dart';
import '../../services/device_info_service.dart';
import '../../services/driver_service.dart';

class PendingRent extends StatefulWidget {
  const PendingRent({Key? key}) : super(key: key);

  @override
  State<PendingRent> createState() => _PendingRentState();
}

class _PendingRentState extends State<PendingRent> {
  bool _isLoading = false;
  String _errorMessage = '';
  List<Map<String, dynamic>> _pendingRentals = [];
  bool _isGuestMode = false;

  // Add variables for payments
  bool _isLoadingPaymentModes = false;
  List<Map<String, dynamic>> _paymentModes = [];
  Map<String, dynamic>? _selectedPaymentMode;
  double _estimatedFare = 0.0;
  String _currentBookingId = '';
  double _initialPaymentAmount = 0.0; // Initial payment amount
  // Add a text controller for the payment amount
  final TextEditingController _paymentAmountController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkGuestMode();

    // Pre-fetch payment modes on app start for better performance
    _fetchPaymentModes();
  }

  @override
  void dispose() {
    _paymentAmountController.dispose();
    super.dispose();
  }

  // Helper method to get the correct icon for payment mode
  IconData _getIconForPaymentMode(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'money':
      case 'cash':
        return Icons.money;
      case 'credit_card':
      case 'card':
        return Icons.credit_card;
      case 'mobile':
      case 'phone':
      case 'phone_android':
        return Icons.phone_android;
      default:
        return Icons.payment;
    }
  }

  // Method to fetch payment modes using DriverService
  Future<void> _fetchPaymentModes() async {
    if (_isLoadingPaymentModes)
      return; // Prevent multiple simultaneous requests

    setState(() {
      _isLoadingPaymentModes = true;
    });

    try {
      // Use cached payment modes if available
      if (_paymentModes.isNotEmpty) {
        setState(() {
          _isLoadingPaymentModes = false;
          if (_selectedPaymentMode == null && _paymentModes.isNotEmpty) {
            _selectedPaymentMode = _paymentModes.first;
          }
        });
        print('Using cached payment modes');
        return;
      }

      print('Fetching payment modes...');

      // Try the better-performing API first
      final result = await BookingService.getPaymentModes();

      if (result['success']) {
        final paymentModesList = result['data']['payment_modes'] as List;
        print(
            'Loaded ${paymentModesList.length} payment modes from BookingService');

        setState(() {
          // Convert each item to a Map<String, dynamic>
          _paymentModes = List<Map<String, dynamic>>.from(paymentModesList);

          // Add missing fields if they don't exist in the API response
          for (var mode in _paymentModes) {
            if (!mode.containsKey('description')) {
              mode['description'] = 'Pay with ${mode['mode_name']}';
            }
            if (!mode.containsKey('icon')) {
              mode['icon'] = _getDefaultIconName(mode['mode_name']);
            }
            if (!mode.containsKey('is_active')) {
              mode['is_active'] = 1;
            }
          }

          // Set first payment mode as default if available
          if (_paymentModes.isNotEmpty) {
            _selectedPaymentMode = _paymentModes.first;
          }
          _isLoadingPaymentModes = false;
        });
      } else {
        // Try backup DriverService if BookingService fails
        print('BookingService failed. Trying DriverService...');
        final driverResult =
            await DriverService.getPaymentModes(context: context);

        if (driverResult['success']) {
          final paymentModesList = driverResult['payment_modes'] as List;
          print(
              'Loaded ${paymentModesList.length} payment modes from DriverService');

          setState(() {
            _paymentModes = List<Map<String, dynamic>>.from(paymentModesList);

            // Add missing fields
            for (var mode in _paymentModes) {
              if (!mode.containsKey('description')) {
                mode['description'] = 'Pay with ${mode['mode_name']}';
              }
              if (!mode.containsKey('icon')) {
                mode['icon'] = _getDefaultIconName(mode['mode_name']);
              }
              if (!mode.containsKey('is_active')) {
                mode['is_active'] = 1;
              }
            }

            // Set first payment mode as default if available
            if (_paymentModes.isNotEmpty) {
              _selectedPaymentMode = _paymentModes.first;
            }
            _isLoadingPaymentModes = false;
          });
        } else {
          print('All APIs failed. Using default payment modes.');
          setState(() {
            _paymentModes = _getDefaultPaymentModes();
            _selectedPaymentMode = _paymentModes.first;
            _isLoadingPaymentModes = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching payment modes: $e');
      setState(() {
        _paymentModes = _getDefaultPaymentModes();
        _selectedPaymentMode = _paymentModes.first;
        _isLoadingPaymentModes = false;
      });
    }
  }

  // Helper method to determine default icon based on payment mode name
  String _getDefaultIconName(String modeName) {
    final name = modeName.toLowerCase();
    if (name.contains('cash')) return 'money';
    if (name.contains('card') || name.contains('credit')) return 'credit_card';
    if (name.contains('mobile') ||
        name.contains('money') ||
        name.contains('airtel') ||
        name.contains('mtn')) return 'phone_android';
    return 'payment';
  }

  // Default payment modes in case API fails
  List<Map<String, dynamic>> _getDefaultPaymentModes() {
    return [
      {
        'payment_mode_id': '1',
        'mode_name': 'Cash',
        'description': 'Pay with cash to the driver',
        'icon': 'money',
        'is_active': 1
      },
      {
        'payment_mode_id': '2',
        'mode_name': 'Mobile Money',
        'description': 'Pay using mobile money',
        'icon': 'phone_android',
        'is_active': 1
      },
      {
        'payment_mode_id': '3',
        'mode_name': 'Credit Card',
        'description': 'Pay with credit/debit card',
        'icon': 'credit_card',
        'is_active': 1
      },
    ];
  }

  void _showPaymentOptionsBottomSheet(Map<String, dynamic> rental) {
    final s = S.of(context)!; // Get localization

    // Show loading indicator if payment modes aren't loaded yet
    if (_paymentModes.isEmpty && !_isLoadingPaymentModes) {
      _fetchPaymentModes();
    }

    // Set current booking ID and estimated fare
    _currentBookingId = rental['booking_id'].toString();
    _estimatedFare =
        double.tryParse(rental['estimated_price'].toString()) ?? 0.0;
    // Set the default amount in the controller
    _paymentAmountController.text = _estimatedFare.toStringAsFixed(0);
    _initialPaymentAmount =
        double.tryParse(rental['initial_payment'].toString()) ?? 0.0;

    // Show bottom sheet immediately
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Simple local state update function that handles both StatefulBuilder and widget state
            void updateLocalState() {
              setModalState(() {});
              if (mounted) setState(() {});
            }

            // If payment modes are empty but not loading, start loading them
            if (_paymentModes.isEmpty && !_isLoadingPaymentModes) {
              _isLoadingPaymentModes = true;
              updateLocalState();
              _fetchPaymentModes().then((_) => updateLocalState());
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          s.choosePaymentMethod,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF07723D).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: Color(0xFF07723D)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Total amount: ${_estimatedFare.toStringAsFixed(0)} FCFA',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Add Amount to Pay Text Field
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enter initial amount to pay: $_initialPaymentAmount FCFA  -  ${_estimatedFare.toStringAsFixed(0)} FCFA',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _paymentAmountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Amount in FCFA',
                              prefixIcon: const Icon(Icons.attach_money),
                              suffixText: 'FCFA',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Color(0xFFF5141E)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.car_rental, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Rental: ${rental["category_name"]} - ${rental["rental_duration_value"]} ${rental["rental_duration_unit"]}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Payment method selection
                    _isLoadingPaymentModes
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: 30,
                                  width: 30,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFFF5141E)),
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text("Loading payment methods...")
                              ],
                            ),
                          )
                        : _paymentModes.isEmpty
                            ? Center(
                                child: Column(
                                  children: [
                                    const Icon(Icons.warning,
                                        color: Colors.orange),
                                    const SizedBox(height: 8),
                                    const Text('No payment methods available'),
                                    TextButton(
                                      onPressed: () {
                                        _isLoadingPaymentModes = true;
                                        updateLocalState();
                                        _fetchPaymentModes()
                                            .then((_) => updateLocalState());
                                      },
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Select Payment Method',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // Use simpler dropdown instead of DropdownSearch
                                  DropdownButtonFormField<Map<String, dynamic>>(
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade300),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                    ),
                                    value: _selectedPaymentMode,
                                    items: _paymentModes.map((mode) {
                                      final iconName =
                                          mode['icon']?.toString() ??
                                              _getDefaultIconName(
                                                  mode['mode_name']);

                                      return DropdownMenuItem<
                                          Map<String, dynamic>>(
                                        value: mode,
                                        child: Row(
                                          children: [
                                            Icon(
                                                _getIconForPaymentMode(
                                                    iconName),
                                                color: const Color(0xFFF5141E)),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                mode['mode_name'] ?? 'Unknown',
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setModalState(() {
                                        _selectedPaymentMode = value;
                                      });
                                      setState(() {
                                        _selectedPaymentMode = value;
                                      });
                                    },
                                  ),

                                  if (_selectedPaymentMode != null) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5141E)
                                            .withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            _getIconForPaymentMode(
                                              _selectedPaymentMode!['icon']
                                                      ?.toString() ??
                                                  _getDefaultIconName(
                                                      _selectedPaymentMode![
                                                          'mode_name']),
                                            ),
                                            color: const Color(0xFFF5141E),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _selectedPaymentMode![
                                                          'mode_name'] ??
                                                      'Selected Payment',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  _selectedPaymentMode![
                                                          'description'] ??
                                                      'Pay with ${_selectedPaymentMode!['mode_name']}',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _selectedPaymentMode == null ||
                                _isLoadingPaymentModes
                            ? null
                            : () {
                                // Validate the payment amount
                                final enteredAmount = double.tryParse(
                                        _paymentAmountController.text) ??
                                    0.0;
                                if (enteredAmount <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Please enter a valid payment amount'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                Navigator.pop(context);
                                _processPayment(enteredAmount);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF5141E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Confirm Payment Method',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Update process payment to not use phone number for guest users
  Future<void> _processPayment([double? customAmount]) async {
    final s = S.of(context)!; // Get localization

    if (_selectedPaymentMode == null || _currentBookingId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.pleaseSelectPaymentMethod),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Use custom amount if provided, otherwise use estimated fare
    final paymentAmount = customAmount ?? _estimatedFare;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(s.paymentProcessing),
              const SizedBox(height: 8),
              Text(s.pleaseWait),
            ],
          ),
        );
      },
    );
    print(
        " _selectedPaymentMode?['payment_mode_id']: ${_selectedPaymentMode?['payment_mode_id']}");
    try {
      // Parse the payment mode ID
      final result = await BookingService.processPayment(
        bookingId: _currentBookingId,
        paymentAmount: paymentAmount, // Use the custom or default amount
        paymentModeId: _selectedPaymentMode?['payment_mode_id'],
        phoneNumber: null, // Remove phone number parameter
      );

      // Close loading dialog
      Navigator.pop(context);

      if (result['success']) {
        // Payment successful
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? s.paymentSuccessful),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Refresh the list of pending rentals
        _fetchPendingRentals();
      } else {
        // Payment failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.paymentFailed(result['message'])),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.paymentError(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _checkGuestMode() async {
    final isGuest = await StorageService.isGuestMode();
    setState(() {
      _isGuestMode = isGuest;
    });

    // Auto-fetch rentals for both guest and logged-in users
    _fetchPendingRentals();
  }

  Future<void> _fetchPendingRentals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      Map<String, dynamic> result;

      if (_isGuestMode) {
        final deviceId = await DeviceInfoService.getDeviceId();
        print('Guest mode detected. Device ID: $deviceId');
        // Custom implementation for guest users with device ID only
        final response = await BookingService.getPendingRentalsWithPhone(
          deviceId: deviceId,
        );
        result = response;
      } else {
        result = await BookingService.getPendingRentals();
      }

      if (result['success']) {
        final data = result['data'];
        final bookings = data['bookings'] as List;
        setState(() {
          _pendingRentals = List<Map<String, dynamic>>.from(bookings);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              result['message'] ?? 'Failed to fetch pending rentals';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred: $e';
        _isLoading = false;
      });
    }
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('MMM dd, yyyy - h:mm a').format(dateTime);
    } catch (e) {
      return dateTimeString;
    }
  }

  Widget _buildRentalCard(Map<String, dynamic> rental) {
    final s = S.of(context)!; // Get localization
    final startDateTime = _formatDateTime(rental['rental_start']);
    final endDateTime = _formatDateTime(rental['rental_end']);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with booking code
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5141E).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${s.bookingCode} #${rental['booking_code']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5141E).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Pending',
                    style: TextStyle(
                      color: Color(0xFFF5141E),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Car details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Car category and type
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.directions_car,
                        size: 24,
                        color: Color(0xFFF5141E),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rental['category_name'] ?? 'Car Rental',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            rental['booking_type_name'] ?? 'Standard Rental',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Rental duration
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            s.duration,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${rental['rental_duration_value']} ${rental['rental_duration_unit']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.pickupDate,
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  startDateTime,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward,
                            color: Color(0xFFF5141E),
                            size: 16,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  s.returnDate,
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  endDateTime,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Payment details
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5141E).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            s.initialPayment,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${rental['initial_payment'] ?? '0'} FCFA',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            s.totalEstimated,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${rental['estimated_price'] ?? '0'} FCFA',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF07723D),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Add cancel booking logic
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(s.cancelBooking),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Show payment options bottom sheet
                      _showPaymentOptionsBottomSheet(rental);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF5141E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(s.confirmBooking),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!; // Get localization

    return RefreshIndicator(
      onRefresh: _fetchPendingRentals,
      child: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF07723D)),
                  const SizedBox(height: 16),
                  Text(s.loadingRentals),
                ],
              ),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red[300],
                        size: 60,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _fetchPendingRentals,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF07723D),
                        ),
                        child: Text(s.retry),
                      ),
                    ],
                  ),
                )
              : _pendingRentals.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.car_rental,
                            color: Colors.grey,
                            size: 80,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            s.noRentalsFound,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            s.yourPendingRentalsWillAppear,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () {
                              // Navigate to booking screen
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF07723D),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            icon: const Icon(Icons.add),
                            label: Text(s.rentCar),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(top: 8, bottom: 20),
                      itemCount: _pendingRentals.length,
                      itemBuilder: (context, index) {
                        return _buildRentalCard(_pendingRentals[index]);
                      },
                    ),
    );
  }
}
