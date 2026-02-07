import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../services/driver_service.dart';

class CompleteTripBottomSheet extends StatefulWidget {
  final Map<String, dynamic> trip;
  final Function()? onTripCompleted;

  const CompleteTripBottomSheet({
    Key? key,
    required this.trip,
    this.onTripCompleted,
  }) : super(key: key);

  @override
  State<CompleteTripBottomSheet> createState() =>
      _CompleteTripBottomSheetState();
}

class _CompleteTripBottomSheetState extends State<CompleteTripBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _kmUsedController = TextEditingController();
  final _paymentFeeController = TextEditingController();

  bool _isLoading = false;
  bool _isCompletingTrip = false;
  List<Map<String, dynamic>> _paymentModes = [];
  Map<String, dynamic>? _selectedPaymentMode;

  @override
  void initState() {
    super.initState();
    _fetchPaymentModes();
    _initializeFields();
  }

  @override
  void dispose() {
    _kmUsedController.dispose();
    _paymentFeeController.dispose();
    super.dispose();
  }

  void _initializeFields() {
    // Pre-fill with estimated values if available
    _paymentFeeController.text =
        widget.trip['estimated_price']?.toString() ?? '';
  }

  Future<void> _fetchPaymentModes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await DriverService.getPaymentModes(context: context);

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (response['success']) {
            _paymentModes = List<Map<String, dynamic>>.from(
                response['payment_modes'] ?? []);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.red,
                content:
                    Text(response['message'] ?? 'Failed to load payment modes'),
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('An error occurred while loading payment modes'),
          ),
        );
      }
    }
  }

  Future<void> _completeTrip() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedPaymentMode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Please select a payment mode'),
        ),
      );
      return;
    }

    setState(() {
      _isCompletingTrip = true;
    });

    try {
      final response = await DriverService.completeTrip(
        transactionId: int.parse(widget.trip['transaction_id'].toString()),
        // kmUsed: double.parse(_kmUsedController.text),
        paymentFee: double.parse(_paymentFeeController.text),
        paymentMode: int.parse(_selectedPaymentMode!['payment_mode_id']),
        context: context,
      );

      if (!mounted) return;

      if (response['success']) {
        Navigator.of(context).pop(); // Close bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(response['message'] ?? 'Trip completed successfully'),
          ),
        );

        // Call callback to refresh the trips list
        if (widget.onTripCompleted != null) {
          widget.onTripCompleted!();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(response['message'] ?? 'Failed to complete trip'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('An error occurred'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCompletingTrip = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Complete Trip',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Trip ID: ${widget.trip['booking_code'] ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),

                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  // // Kilometers Used
                  // TextFormField(
                  //   controller: _kmUsedController,
                  //   keyboardType:
                  //       const TextInputType.numberWithOptions(decimal: true),
                  //   decoration: const InputDecoration(
                  //     labelText: 'Kilometers Used',
                  //     hintText: 'Enter distance in KM',
                  //     border: OutlineInputBorder(),
                  //     suffixText: 'KM',
                  //   ),
                  //   validator: (value) {
                  //     if (value == null || value.isEmpty) {
                  //       return 'Please enter kilometers used';
                  //     }
                  //     final km = double.tryParse(value);
                  //     if (km == null || km <= 0) {
                  //       return 'Please enter a valid distance';
                  //     }
                  //     return null;
                  //   },
                  // ),
                  // const SizedBox(height: 16),

                  // Payment Fee
                  TextFormField(
                    controller: _paymentFeeController,
                    readOnly: true, // Make it read-only if needed
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Payment Fee',
                      hintText: 'Enter payment amount',
                      border: OutlineInputBorder(),
                      suffixText: 'FCFA',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter payment fee';
                      }
                      final fee = double.tryParse(value);
                      if (fee == null || fee <= 0) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Payment Mode Dropdown - Fixed for version 6.0.2
                  DropdownSearch<Map<String, dynamic>>(
                    items: (filter, infiniteScrollProps) => _paymentModes,
                    compareFn: (item1, item2) =>
                        item1['payment_mode_id'] == item2['payment_mode_id'],
                    popupProps: PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: const TextFieldProps(
                        decoration: InputDecoration(
                          hintText: 'Search payment modes...',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                      itemBuilder: (context, item, isSelected, isDisabled) {
                        return ListTile(
                          leading: const Icon(Icons.payment),
                          title: Text(item['mode_name'] ?? ''),
                          selected: isSelected,
                        );
                      },
                    ),
                    decoratorProps: const DropDownDecoratorProps(
                      decoration: InputDecoration(
                        labelText: 'Payment Mode',
                        hintText: 'Select payment method',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.payment),
                      ),
                    ),
                    itemAsString: (item) => item?['mode_name'] ?? '',
                    selectedItem: _selectedPaymentMode,
                    onChanged: (value) {
                      setState(() {
                        _selectedPaymentMode = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isCompletingTrip
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isCompletingTrip ? null : _completeTrip,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: _isCompletingTrip
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Complete Trip'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
