import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/cart_item_model.dart';
import '../services/delivery_service.dart';
import '../services/storage_service.dart';

// Place suggestion model class
class PlaceSuggestion {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  PlaceSuggestion({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });
}

class DeliveryCheckoutScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final double total;

  const DeliveryCheckoutScreen({
    Key? key,
    required this.cartItems,
    required this.total,
  }) : super(key: key);

  @override
  State<DeliveryCheckoutScreen> createState() => _DeliveryCheckoutScreenState();
}

class _DeliveryCheckoutScreenState extends State<DeliveryCheckoutScreen> {
  final TextEditingController _deliveryAddressController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  double? _deliveryLat;
  double? _deliveryLng;
  bool _isLoadingLocation = false;

  static const String _apiKey = 'AIzaSyBXaMspN9XlQhkUHiyLCXkQoEurPKrMeog';

  @override
  void dispose() {
    _deliveryAddressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<List<PlaceSuggestion>> _getPlaceSuggestions(String query) async {
    if (query.isEmpty) return [];

    final url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$_apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final predictions = data['predictions'] as List;
        return predictions
            .map((prediction) => PlaceSuggestion(
                  placeId: prediction['place_id'],
                  description: prediction['description'],
                  mainText: prediction['structured_formatting']['main_text'],
                  secondaryText: prediction['structured_formatting']
                          ['secondary_text'] ??
                      '',
                ))
            .toList();
      }
    } catch (e) {
      print('Error getting place suggestions: $e');
    }
    return [];
  }

  Future<void> _getPlaceDetails(String placeId) async {
    setState(() {
      _isLoadingLocation = true;
    });

    final url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final location = data['result']['geometry']['location'];

        setState(() {
          _deliveryLat = location['lat'];
          _deliveryLng = location['lng'];
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      print('Error getting place details: $e');
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  void _placeOrder() async {
    if (_deliveryAddressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a delivery address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_deliveryLat == null || _deliveryLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a valid address from suggestions'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Get user data
      final clientData = await StorageService.getClientData();

      if (clientData == null || clientData['user_id'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to place order'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final userId = int.parse(clientData['user_id'].toString());

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFF5141E),
          ),
        ),
      );

      // Call API to process order
      final result = await DeliveryService.processOrder(
        userId: userId,
        deliveryAddress: _deliveryAddressController.text,
        deliveryLat: _deliveryLat!,
        deliveryLng: _deliveryLng!,
        paymentMethod: 'cash', // Default to cash payment
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      // Close loading indicator
      Navigator.pop(context);

      if (result['success']) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Order Placed'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your order has been placed successfully!'),
                const SizedBox(height: 16),
                Text(
                  'Delivery Address:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(_deliveryAddressController.text),
                const SizedBox(height: 8),
                Text(
                  'Total: ${widget.total.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (_notesController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Notes: ${_notesController.text}'),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close checkout
                  Navigator.pop(context); // Close cart
                  Navigator.pop(context); // Close delivery screen
                },
                child: const Text(
                  'OK',
                  style: TextStyle(color: Color(0xFFF5141E)),
                ),
              ),
            ],
          ),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to place order'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Close loading indicator if it's showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      print('Error placing order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error placing order: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFF5141E),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Summary
              const Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    ...widget.cartItems.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.product.productName} x${item.quantity}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              Text(
                                item.getFormattedTotalPrice(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.total.toStringAsFixed(0)} FCFA',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF5141E),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Delivery Address
              const Text(
                'Delivery Address',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TypeAheadField<PlaceSuggestion>(
                controller: _deliveryAddressController,
                suggestionsCallback: (pattern) async {
                  return await _getPlaceSuggestions(pattern);
                },
                itemBuilder: (context, PlaceSuggestion suggestion) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Color(0xFFF5141E),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                suggestion.mainText,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (suggestion.secondaryText.isNotEmpty)
                                Text(
                                  suggestion.secondaryText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  );
                },
                onSelected: (PlaceSuggestion suggestion) {
                  _deliveryAddressController.text = suggestion.description;
                  _getPlaceDetails(suggestion.placeId);
                },
                builder: (context, controller, focusNode) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      hintText: 'Enter delivery address',
                      prefixIcon: _isLoadingLocation
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : const Icon(Icons.location_on),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                },
                decorationBuilder: (context, child) {
                  return Material(
                    type: MaterialType.card,
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    child: child,
                  );
                },
                offset: const Offset(0, 4),
                constraints: const BoxConstraints(maxHeight: 300),
                hideOnEmpty: true,
                hideOnError: true,
                hideOnLoading: false,
                animationDuration: const Duration(milliseconds: 300),
                direction: VerticalDirection.down,
              ),

              const SizedBox(height: 16),

              // Delivery Notes
              const Text(
                'Delivery Notes (Optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add any special instructions for delivery...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Place Order Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5141E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Place Order',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
