import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/cart_item_model.dart';
import '../services/delivery_service.dart';
import '../services/storage_service.dart';
import 'package:sango/screen/deliveryCheckoutScreen.dart';

class CartScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final VoidCallback onCartUpdated;

  const CartScreen({
    Key? key,
    required this.cartItems,
    required this.onCartUpdated,
  }) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  double get _subtotal {
    return widget.cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double get _deliveryFee => 5.00;

  double get _total => _subtotal + _deliveryFee;

  void _updateQuantity(int index, int newQuantity) async {
    if (newQuantity <= 0) {
      _removeItem(index);
    } else {
      try {
        final clientData = await StorageService.getClientData();
        if (clientData == null || clientData['user_id'] == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login to update cart'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final userId = int.parse(clientData['user_id'].toString());
        final cartItem = widget.cartItems[index];

        if (cartItem.cartId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid cart item'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Determine if we need to increment or decrement
        final currentQuantity = cartItem.quantity;
        Map<String, dynamic> result;

        if (newQuantity > currentQuantity) {
          // Increment
          result = await DeliveryService.incrementQuantity(
            userId: userId,
            cartId: cartItem.cartId!,
          );
        } else {
          // Decrement
          result = await DeliveryService.decrementQuantity(
            userId: userId,
            cartId: cartItem.cartId!,
          );
        }

        if (result['success']) {
          setState(() {
            widget.cartItems[index].quantity = newQuantity;
            widget.onCartUpdated();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to update cart'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        print('Error updating quantity: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating cart: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeItem(int index) async {
    try {
      final clientData = await StorageService.getClientData();
      if (clientData == null || clientData['user_id'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to update cart'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final userId = int.parse(clientData['user_id'].toString());
      final cartItem = widget.cartItems[index];

      if (cartItem.cartId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid cart item'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Remove via API
      final result = await DeliveryService.removeFromCart(
        userId: userId,
        cartId: cartItem.cartId!,
      );

      if (result['success']) {
        setState(() {
          widget.cartItems.removeAt(index);
          widget.onCartUpdated();
        });

        if (widget.cartItems.isEmpty) {
          Navigator.pop(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to remove item'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error removing item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing item: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _checkout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeliveryCheckoutScreen(
          cartItems: widget.cartItems,
          total: _total,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Shopping Cart',
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
      body: widget.cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 100,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.cartItems.length,
                    itemBuilder: (context, index) {
                      final cartItem = widget.cartItems[index];
                      return _buildCartItem(cartItem, index);
                    },
                  ),
                ),
                _buildSummary(),
              ],
            ),
    );
  }

  Widget _buildCartItem(CartItem cartItem, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: cartItem.product.imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 80,
                height: 80,
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFF5141E),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image, size: 40, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cartItem.product.productName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  cartItem.product.getFormattedPrice(),
                  style: const TextStyle(
                    color: Color(0xFFF5141E),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Decrease button
                    InkWell(
                      onTap: () =>
                          _updateQuantity(index, cartItem.quantity - 1),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.remove, size: 16),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '${cartItem.quantity}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Increase button
                    InkWell(
                      onTap: () =>
                          _updateQuantity(index, cartItem.quantity + 1),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5141E),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Remove button
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _removeItem(index),
              ),
              const SizedBox(height: 8),
              Text(
                cartItem.getFormattedTotalPrice(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Subtotal:',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  '${_subtotal.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Delivery Fee:',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  '${_deliveryFee.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_total.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF5141E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _checkout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5141E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Checkout',
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
    );
  }
}
