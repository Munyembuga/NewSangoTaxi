import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../services/car_checking_service.dart';
import '../../models/car_checking_models.dart';

class ServicesScreen extends StatefulWidget {
  @override
  _ServicesScreenState createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  List<Transaction> _transactions = [];
  List<CheckType> _checkTypes = [];
  Transaction? _selectedTransaction;
  CheckType? _selectedCheckType;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final transactionsResult =
          await CarCheckingService.getEligibleTransactions();
      final checkTypesResult = await CarCheckingService.getCheckTypes();

      if (transactionsResult['success'] && checkTypesResult['success']) {
        setState(() {
          _transactions = (transactionsResult['data']['transactions'] as List)
              .map((json) => Transaction.fromJson(json))
              .toList();
          _checkTypes = (checkTypesResult['data']['check_types'] as List)
              .map((json) => CheckType.fromJson(json))
              .toList();
        });
      } else {
        setState(() {
          _errorMessage = transactionsResult['message'] ??
              checkTypesResult['message'] ??
              'Failed to load data';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred while loading data';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitCheck() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTransaction == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a transaction')),
      );
      return;
    }

    if (_selectedCheckType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a check type')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await CarCheckingService.createCheck(
        transcode: _selectedTransaction!.bookingCode,
        checkingtype: _selectedCheckType!.id,
        amount: _amountController.text.trim(),
        notes: _notesController.text.trim(),
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _clearForm();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to create check'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred while submitting'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _clearForm() {
    setState(() {
      _selectedTransaction = null;
      _selectedCheckType = null;
    });
    _amountController.clear();
    _notesController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Car Checking Services'),
        backgroundColor: const Color(0xFF07723D),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error, color: Colors.red.shade600),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage,
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                            TextButton(
                              onPressed: _loadData,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),

                    // Transaction Searchable Dropdown
                    const Text(
                      'Select Transaction',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownSearch<Transaction>(
                      items: (String filter, LoadProps? loadProps) async {
                        return _transactions;
                      },
                      itemAsString: (Transaction transaction) =>
                          transaction.displayText,
                      selectedItem: _selectedTransaction,
                      compareFn: (Transaction? item1, Transaction? item2) {
                        if (item1 == null || item2 == null) return false;
                        return item1.bookingCode == item2.bookingCode;
                      },
                      onChanged: (Transaction? value) {
                        setState(() {
                          _selectedTransaction = value;
                        });
                      },
                      decoratorProps: DropDownDecoratorProps(
                        decoration: InputDecoration(
                          hintText: 'Search and select a transaction',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          prefixIcon: const Icon(Icons.receipt_long),
                        ),
                      ),
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                          decoration: InputDecoration(
                            hintText: 'Search transactions...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        itemBuilder: (context, item, isDisabled, isSelected) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Text(
                              item.displayText,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color:
                                    isSelected ? const Color(0xFF07723D) : null,
                              ),
                            ),
                          );
                        },
                        emptyBuilder: (context, searchEntry) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('No transactions found'),
                            ),
                          );
                        },
                        listViewProps: const ListViewProps(
                          padding: EdgeInsets.all(8),
                        ),
                      ),
                      validator: (Transaction? value) {
                        if (value == null) {
                          return 'Please select a transaction';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Check Type Searchable Dropdown
                    const Text(
                      'Select Check Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownSearch<CheckType>(
                      items: (String filter, LoadProps? loadProps) async {
                        return _checkTypes;
                      },
                      itemAsString: (CheckType checkType) => checkType.name,
                      selectedItem: _selectedCheckType,
                      compareFn: (CheckType? item1, CheckType? item2) {
                        if (item1 == null || item2 == null) return false;
                        return item1.id == item2.id;
                      },
                      onChanged: (CheckType? value) {
                        setState(() {
                          _selectedCheckType = value;
                        });
                      },
                      decoratorProps: DropDownDecoratorProps(
                        decoration: InputDecoration(
                          hintText: 'Search and select a check type',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          prefixIcon: const Icon(Icons.checklist),
                        ),
                      ),
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                          decoration: InputDecoration(
                            hintText: 'Search check types...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        itemBuilder: (context, item, isDisabled, isSelected) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Text(
                              item.name,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color:
                                    isSelected ? const Color(0xFF07723D) : null,
                              ),
                            ),
                          );
                        },
                        emptyBuilder: (context, searchEntry) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('No check types found'),
                            ),
                          );
                        },
                        listViewProps: const ListViewProps(
                          padding: EdgeInsets.all(8),
                        ),
                      ),
                      validator: (CheckType? value) {
                        if (value == null) {
                          return 'Please select a check type';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Amount Field
                    const Text(
                      'Amount',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        hintText: 'Enter amount',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        prefixIcon: const Icon(Icons.money),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an amount';
                        }
                        if (double.tryParse(value.trim()) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Notes Field
                    const Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        hintText: 'Enter notes (optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        prefixIcon: const Icon(Icons.notes),
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 30),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitCheck,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF07723D),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isSubmitting
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                'Submit Check',
                                style: TextStyle(fontSize: 16),
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
