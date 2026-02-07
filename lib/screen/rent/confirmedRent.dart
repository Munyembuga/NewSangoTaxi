import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sango/l10n/l10n.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/booking_service.dart';
import '../../services/storage_service.dart';
import '../../services/device_info_service.dart';

class ConfirmedRent extends StatefulWidget {
  const ConfirmedRent({Key? key}) : super(key: key);

  @override
  State<ConfirmedRent> createState() => _ConfirmedRentState();
}

class _ConfirmedRentState extends State<ConfirmedRent> {
  bool _isLoading = false;
  String _errorMessage = '';
  List<Map<String, dynamic>> _confirmedRentals = [];
  bool _isGuestMode = false;
  double _totalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _checkGuestModeAndFetchRentals();
  }

  Future<void> _launchCommunication(String type) async {
    Uri? uri;

    try {
      switch (type) {
        case 'email':
          uri = Uri.parse('mailto:munyembugajd@gmail.com');
          break;
        case 'phone':
          uri = Uri.parse('tel:+250 782 282 744');
          break;
        case 'whatsapp':
          // Fix the WhatsApp URL format
          uri = Uri.parse('whatsapp://send?phone=250782282744');
          break;
        case 'messagephone':
          // Fix the WhatsApp URL format
          uri = Uri.parse('sms:0782282744');
          break;
        default:
          return;
      }

      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $uri');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      // Show a snackbar or alert to inform the user
    }
  }

  Future<void> _checkGuestModeAndFetchRentals() async {
    final isGuest = await StorageService.isGuestMode();
    setState(() {
      _isGuestMode = isGuest;
    });

    // Automatically fetch rentals for both guest and registered users
    _fetchConfirmedRentals();
  }

  Future<void> _fetchConfirmedRentals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      Map<String, dynamic> result;

      if (_isGuestMode) {
        // For guest users, use only device ID
        final deviceId = await DeviceInfoService.getDeviceId();

        // Use device ID only for guest users
        result = await BookingService.getConfirmedRentalsWithPhone(
          deviceId: deviceId,
        );
      } else {
        // For registered users, use the normal method
        result = await BookingService.getConfirmedRentals();
      }

      if (result['success']) {
        final data = result['data'];
        final bookings = data['bookings'] as List;
        setState(() {
          _confirmedRentals = List<Map<String, dynamic>>.from(bookings);
          _totalAmount =
              double.tryParse(data['total_amount']?.toString() ?? '0') ?? 0.0;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              result['message'] ?? 'Failed to fetch confirmed rentals';
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
              color: Color(0xFFF5141E).withOpacity(0.1),
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
                    color: Color(0xFFF5141E).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    s.confirmed,
                    style: const TextStyle(
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
                            rental['category_name'] ?? s.carRental,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            rental['booking_type_name'] ?? s.standardRental,
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
                                  s.startDate,
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
                                  s.endDate,
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
                    color: Color(0xFFF5141E).withOpacity(0.05),
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
                            '${rental['initial_payment_amount'] ?? '0'} FCFA',
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
                              color: Color(0xFFF5141E),
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
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _launchCommunication('phone');
                    },
                    icon: const Icon(Icons.phone),
                    label: Text(s.contactUs),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(0xFFF5141E),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFF5141E)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalAmountIndicator() {
    final s = S.of(context)!; // Get localization
    if (_confirmedRentals.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.payment, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.totalInitialPayment,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${_totalAmount.toStringAsFixed(0)} FCFA",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "${_confirmedRentals.length} ${s.rentals}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
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
      onRefresh: _fetchConfirmedRentals,
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.green),
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
                        onPressed: _fetchConfirmedRentals,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: Text(s.tryAgain),
                      ),
                    ],
                  ),
                )
              : _confirmedRentals.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: Colors.grey,
                            size: 80,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            s.noConfirmedRentalsFound,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            s.confirmedRentalsWillAppearHere,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        _buildTotalAmountIndicator(),
                        Expanded(
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(top: 8, bottom: 20),
                            itemCount: _confirmedRentals.length,
                            itemBuilder: (context, index) {
                              return _buildRentalCard(_confirmedRentals[index]);
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }
}
