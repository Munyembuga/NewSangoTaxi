import 'product_model.dart';

class CartItem {
  final Product product;
  int quantity;
  final String? cartId; // Cart ID from API

  CartItem({
    required this.product,
    this.quantity = 1,
    this.cartId,
  });

  double get totalPrice {
    try {
      final price = double.parse(product.price);
      return price * quantity;
    } catch (e) {
      return 0.0;
    }
  }

  String getFormattedTotalPrice() {
    return '${totalPrice.toStringAsFixed(0)} FCFA';
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
      'total_price': totalPrice,
    };
  }
}
