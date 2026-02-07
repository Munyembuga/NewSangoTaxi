import 'package:flutter/material.dart';
import 'package:sango/services/storage_service.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({Key? key}) : super(key: key);

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  bool isLoading = true;
  List<PaymentMethod> paymentMethods = [];
  String? selectedPaymentMethod;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    try {
      // Simulate API call or fetch from storage
      await Future.delayed(const Duration(seconds: 1));

      // Mock data - replace with actual API call
      setState(() {
        paymentMethods = [
          PaymentMethod(
            id: '1',
            type: PaymentType.mobileWallet,
            name: 'MTN Mobile Money',
            details: '**** **** **** 1234',
            isDefault: true,
            logoAsset: 'assets/images/mtn_logo.png', // Add your asset
          ),
          PaymentMethod(
            id: '2',
            type: PaymentType.mobileWallet,
            name: 'Airtel Money',
            details: '**** **** **** 5678',
            isDefault: false,
            logoAsset: 'assets/images/airtel_logo.png', // Add your asset
          ),
          PaymentMethod(
            id: '3',
            type: PaymentType.creditCard,
            name: 'Visa Card',
            details: '**** **** **** 9012',
            isDefault: false,
            logoAsset: 'assets/images/visa_logo.png', // Add your asset
          ),
          PaymentMethod(
            id: '4',
            type: PaymentType.cash,
            name: 'Cash Payment',
            details: 'Pay with cash',
            isDefault: false,
            logoAsset: 'assets/images/cash_icon.png', // Add your asset
          ),
        ];
        selectedPaymentMethod =
            paymentMethods.firstWhere((method) => method.isDefault).id;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorSnackBar('Failed to load payment methods');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _setDefaultPaymentMethod(String methodId) {
    setState(() {
      for (var method in paymentMethods) {
        method.isDefault = method.id == methodId;
      }
      selectedPaymentMethod = methodId;
    });
    _showSuccessSnackBar('Default payment method updated');
  }

  void _deletePaymentMethod(String methodId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Payment Method'),
          content: const Text(
              'Are you sure you want to delete this payment method?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  paymentMethods.removeWhere((method) => method.id == methodId);
                });
                Navigator.of(context).pop();
                _showSuccessSnackBar('Payment method deleted');
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showAddPaymentMethodDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddPaymentMethodSheet(
        onPaymentMethodAdded: (PaymentMethod newMethod) {
          setState(() {
            paymentMethods.add(newMethod);
          });
          _showSuccessSnackBar('Payment method added successfully');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Payment Methods',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFDE091E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          color: Color(0xFFDE091E),
                          size: 28,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Manage Payment Methods',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Add, edit, or remove your payment options',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Payment Methods List
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Section Header
                        Container(
                          padding: const EdgeInsets.all(20),
                          child: const Row(
                            children: [
                              Text(
                                'Your Payment Methods',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Payment Methods
                        ...paymentMethods.asMap().entries.map((entry) {
                          int index = entry.key;
                          PaymentMethod method = entry.value;
                          bool isLast = index == paymentMethods.length - 1;

                          return _buildPaymentMethodTile(method, isLast);
                        }).toList(),

                        // Add Payment Method Button
                        Container(
                          padding: const EdgeInsets.all(20),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _showAddPaymentMethodDialog,
                              icon: const Icon(Icons.add,
                                  color: Color(0xFFDE091E)),
                              label: const Text(
                                'Add New Payment Method',
                                style: TextStyle(
                                  color: Color(0xFFDE091E),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                side:
                                    const BorderSide(color: Color(0xFFDE091E)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPaymentMethodTile(PaymentMethod method, bool isLast) {
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _getPaymentMethodIcon(method.type),
            color: const Color(0xFFDE091E),
            size: 24,
          ),
        ),
        title: Text(
          method.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              method.details,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            if (method.isDefault)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Default',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (String value) {
            switch (value) {
              case 'setDefault':
                _setDefaultPaymentMethod(method.id);
                break;
              case 'delete':
                _deletePaymentMethod(method.id);
                break;
            }
          },
          itemBuilder: (BuildContext context) => [
            if (!method.isDefault)
              const PopupMenuItem<String>(
                value: 'setDefault',
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 18),
                    SizedBox(width: 8),
                    Text('Set as Default'),
                  ],
                ),
              ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPaymentMethodIcon(PaymentType type) {
    switch (type) {
      case PaymentType.mobileWallet:
        return Icons.phone_android;
      case PaymentType.creditCard:
        return Icons.credit_card;
      case PaymentType.cash:
        return Icons.money;
      default:
        return Icons.payment;
    }
  }
}

// Add Payment Method Bottom Sheet
class _AddPaymentMethodSheet extends StatefulWidget {
  final Function(PaymentMethod) onPaymentMethodAdded;

  const _AddPaymentMethodSheet({required this.onPaymentMethodAdded});

  @override
  State<_AddPaymentMethodSheet> createState() => _AddPaymentMethodSheetState();
}

class _AddPaymentMethodSheetState extends State<_AddPaymentMethodSheet> {
  PaymentType? selectedType;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              'Add Payment Method',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Payment Type Selection
            const Text(
              'Payment Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),

            ...PaymentType.values
                .map((type) => RadioListTile<PaymentType>(
                      title: Text(_getPaymentTypeName(type)),
                      value: type,
                      groupValue: selectedType,
                      onChanged: (PaymentType? value) {
                        setState(() {
                          selectedType = value;
                        });
                      },
                    ))
                .toList(),

            const SizedBox(height: 20),

            // Name Field
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Payment Method Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            // Details Field
            TextField(
              controller: _detailsController,
              decoration: const InputDecoration(
                labelText: 'Details (e.g., last 4 digits)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _addPaymentMethod,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDE091E),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Add'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addPaymentMethod() {
    if (selectedType == null ||
        _nameController.text.isEmpty ||
        _detailsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final newMethod = PaymentMethod(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: selectedType!,
      name: _nameController.text,
      details: _detailsController.text,
      isDefault: false,
      logoAsset: '',
    );

    widget.onPaymentMethodAdded(newMethod);
    Navigator.pop(context);
  }

  String _getPaymentTypeName(PaymentType type) {
    switch (type) {
      case PaymentType.mobileWallet:
        return 'Mobile Wallet';
      case PaymentType.creditCard:
        return 'Credit/Debit Card';
      case PaymentType.cash:
        return 'Cash';
    }
  }
}

// Data Models
enum PaymentType {
  mobileWallet,
  creditCard,
  cash,
}

class PaymentMethod {
  final String id;
  final PaymentType type;
  final String name;
  final String details;
  bool isDefault;
  final String logoAsset;

  PaymentMethod({
    required this.id,
    required this.type,
    required this.name,
    required this.details,
    required this.isDefault,
    required this.logoAsset,
  });
}
