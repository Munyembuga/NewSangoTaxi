import 'package:flutter/material.dart';
import '../services/delivery_service.dart';
import '../services/storage_service.dart';
import '../l10n/l10n.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Orders data
  List<dynamic> _pendingOrders = [];
  List<dynamic> _completedOrders = [];
  List<dynamic> _cancelledOrders = [];

  // Loading states
  bool _isLoadingPending = true;
  bool _isLoadingCompleted = true;
  bool _isLoadingCancelled = true;

  // Error states
  bool _hasErrorPending = false;
  bool _hasErrorCompleted = false;
  bool _hasErrorCancelled = false;

  String _errorMessagePending = '';
  String _errorMessageCompleted = '';
  String _errorMessageCancelled = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadOrders('pending');
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      switch (_tabController.index) {
        case 0:
          if (_pendingOrders.isEmpty && !_hasErrorPending) {
            _loadOrders('pending');
          }
          break;
        case 1:
          if (_completedOrders.isEmpty && !_hasErrorCompleted) {
            _loadOrders('completed');
          }
          break;
        case 2:
          if (_cancelledOrders.isEmpty && !_hasErrorCancelled) {
            _loadOrders('cancelled');
          }
          break;
      }
    }
  }

  Future<void> _loadOrders(String status) async {
    // Set loading state
    setState(() {
      if (status == 'pending') {
        _isLoadingPending = true;
        _hasErrorPending = false;
      } else if (status == 'completed') {
        _isLoadingCompleted = true;
        _hasErrorCompleted = false;
      } else {
        _isLoadingCancelled = true;
        _hasErrorCancelled = false;
      }
    });

    try {
      // Get user data
      final clientData = await StorageService.getClientData();

      if (clientData == null || clientData['user_id'] == null) {
        setState(() {
          if (status == 'pending') {
            _hasErrorPending = true;
            _errorMessagePending = 'pleaseLoginToViewOrders';
            _isLoadingPending = false;
          } else if (status == 'completed') {
            _hasErrorCompleted = true;
            _errorMessageCompleted = 'pleaseLoginToViewOrders';
            _isLoadingCompleted = false;
          } else {
            _hasErrorCancelled = true;
            _errorMessageCancelled = 'pleaseLoginToViewOrders';
            _isLoadingCancelled = false;
          }
        });
        return;
      }

      final userId = int.parse(clientData['user_id'].toString());

      // Fetch orders from API
      final result = await DeliveryService.getOrders(
        userId: userId,
        status: status,
      );

      if (result['success']) {
        final orders = result['data'] as List;

        setState(() {
          if (status == 'pending') {
            _pendingOrders = orders;
            _isLoadingPending = false;
          } else if (status == 'completed') {
            _completedOrders = orders;
            _isLoadingCompleted = false;
          } else {
            _cancelledOrders = orders;
            _isLoadingCancelled = false;
          }
        });
      } else {
        setState(() {
          if (status == 'pending') {
            _hasErrorPending = true;
            _errorMessagePending = result['message'] ?? 'failedToLoadOrders';
            _isLoadingPending = false;
          } else if (status == 'completed') {
            _hasErrorCompleted = true;
            _errorMessageCompleted = result['message'] ?? 'failedToLoadOrders';
            _isLoadingCompleted = false;
          } else {
            _hasErrorCancelled = true;
            _errorMessageCancelled = result['message'] ?? 'failedToLoadOrders';
            _isLoadingCancelled = false;
          }
        });
      }
    } catch (e) {
      setState(() {
        if (status == 'pending') {
          _hasErrorPending = true;
          _errorMessagePending = 'errorLoadingOrders:$e';
          _isLoadingPending = false;
        } else if (status == 'completed') {
          _hasErrorCompleted = true;
          _errorMessageCompleted = 'errorLoadingOrders:$e';
          _isLoadingCompleted = false;
        } else {
          _hasErrorCancelled = true;
          _errorMessageCancelled = 'errorLoadingOrders:$e';
          _isLoadingCancelled = false;
        }
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.access_time;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.myOrders,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFF5141E),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          tabs: [
            Tab(text: l10n.processing),
            Tab(text: l10n.completed),
            Tab(text: l10n.cancelled),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersList('pending', _pendingOrders, _isLoadingPending,
              _hasErrorPending, _errorMessagePending),
          _buildOrdersList('completed', _completedOrders, _isLoadingCompleted,
              _hasErrorCompleted, _errorMessageCompleted),
          _buildOrdersList('cancelled', _cancelledOrders, _isLoadingCancelled,
              _hasErrorCancelled, _errorMessageCancelled),
        ],
      ),
    );
  }

  // Build orders list for each tab
  Widget _buildOrdersList(String status, List<dynamic> orders, bool isLoading,
      bool hasError, String errorMessage) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFF5141E),
        ),
      );
    }

    if (hasError) {
      return _buildErrorState(errorMessage, status, () => _loadOrders(status));
    }

    if (orders.isEmpty) {
      return _buildEmptyState(status);
    }

    return RefreshIndicator(
      onRefresh: () => _loadOrders(status),
      color: const Color(0xFFF5141E),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  // Empty state for each tab
  Widget _buildEmptyState(String status) {
    final l10n = S.of(context)!;
    String message;
    IconData icon;

    switch (status) {
      case 'completed':
        message = l10n.noCompletedOrders;
        icon = Icons.check_circle_outline;
        break;
      case 'cancelled':
        message = l10n.noCancelledOrders;
        icon = Icons.cancel_outlined;
        break;
      default:
        message = l10n.noOrdersInProgress;
        icon = Icons.shopping_bag_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Error state
  Widget _buildErrorState(
      String messageKey, String status, VoidCallback onRetry) {
    final l10n = S.of(context)!;
    String displayMessage;

    // Translate the error message key
    if (messageKey == 'pleaseLoginToViewOrders') {
      displayMessage = l10n.pleaseLoginToViewOrders;
    } else if (messageKey == 'failedToLoadOrders') {
      displayMessage = l10n.failedToLoadOrders;
    } else if (messageKey.startsWith('errorLoadingOrders:')) {
      final error = messageKey.substring('errorLoadingOrders:'.length);
      displayMessage = l10n.errorLoadingOrders(error);
    } else {
      displayMessage = messageKey;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              displayMessage,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF5141E),
            ),
            child:
                Text(l10n.retry, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final l10n = S.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.orderWithId(order['order_id'].toString()),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(order['status']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getStatusColor(order['status']),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getStatusIcon(order['status']),
                      size: 16,
                      color: _getStatusColor(order['status']),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      order['status'].toString().toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(order['status']),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Order Details
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                order['created_at'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order['delivery_address'] ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const Divider(height: 24),

          // Order Total and Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.total,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${order['total_amount']?.toString() ?? '0'} FCFA',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF5141E),
                    ),
                  ),
                ],
              ),
              OutlinedButton(
                onPressed: () {
                  _showOrderDetails(order['order_id'].toString());
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFF5141E)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  l10n.viewDetails,
                  style: const TextStyle(color: Color(0xFFF5141E)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(String orderId) async {
    final l10n = S.of(context)!;
    try {
      // Get user data
      final clientData = await StorageService.getClientData();

      if (clientData == null || clientData['user_id'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.pleaseLoginToViewOrderDetails),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final userId = int.parse(clientData['user_id'].toString());

      // Show loading
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFF5141E),
            ),
          ),
        ),
      );

      // Fetch order details
      final result = await DeliveryService.getOrderDetails(
        userId: userId,
        orderId: orderId,
      );

      // Close loading
      Navigator.pop(context);

      if (result['success']) {
        final orderData = result['data'];
        _showOrderDetailsBottomSheet(orderData);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? l10n.failedToLoadOrderDetails),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading if open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorLoadingOrderDetails(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showOrderDetailsBottomSheet(Map<String, dynamic> orderData) {
    final l10n = S.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.orderWithId(orderData['order_id'].toString()),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(orderData['status'])
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getStatusColor(orderData['status']),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(orderData['status']),
                            size: 16,
                            color: _getStatusColor(orderData['status']),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            orderData['status'].toString().toUpperCase(),
                            style: TextStyle(
                              color: _getStatusColor(orderData['status']),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Order Info
                    _buildSectionTitle(l10n.orderInformation),
                    _buildInfoRow(
                        l10n.orderDate, orderData['created_at'] ?? ''),
                    _buildInfoRow(
                        l10n.paymentMethod,
                        orderData['payment_method']?.toString().toUpperCase() ??
                            ''),
                    if (orderData['notes'] != null &&
                        orderData['notes'].toString().isNotEmpty)
                      _buildInfoRow(l10n.notes, orderData['notes']),

                    const SizedBox(height: 20),

                    // Delivery Info
                    _buildSectionTitle(l10n.deliveryInformation),
                    _buildInfoRow(
                        l10n.address, orderData['delivery_address'] ?? ''),
                    _buildInfoRow(
                        l10n.customerName, orderData['user_name'] ?? ''),
                    _buildInfoRow(l10n.phone, orderData['user_phone'] ?? ''),

                    const SizedBox(height: 20),

                    // Order Items
                    _buildSectionTitle(l10n.orderItems),
                    const SizedBox(height: 8),
                    ...((orderData['items'] as List?) ?? []).map((item) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['product_name'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item['price'] ?? '0'} FCFA × ${item['quantity'] ?? '0'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${item['subtotal'] ?? '0'} FCFA',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF5141E),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),

                    const SizedBox(height: 20),

                    // Order Summary
                    _buildSectionTitle(l10n.orderSummary),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow(
                              l10n.subtotal,
                              '${orderData['subtotal_amount'] ?? '0'} FCFA',
                              false),
                          const SizedBox(height: 8),
                          _buildSummaryRow(
                              l10n.deliveryFee,
                              '${orderData['delivery_fee'] ?? '0'} FCFA',
                              false),
                          const Divider(height: 16),
                          _buildSummaryRow(l10n.total,
                              '${orderData['total_amount'] ?? '0'} FCFA', true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isBold) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isBold ? const Color(0xFFF5141E) : Colors.black,
          ),
        ),
      ],
    );
  }
}
