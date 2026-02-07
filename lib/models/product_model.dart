class Product {
  final String productId;
  final String productName;
  final String description;
  final String categoryId;
  final String price;
  final String imageUrl;
  final bool isAvailable;
  final int? quantity;

  Product({
    required this.productId,
    required this.productName,
    required this.description,
    required this.categoryId,
    required this.price,
    required this.imageUrl,
    required this.isAvailable,
    this.quantity,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name'] ?? '',
      description: json['description'] ?? '',
      categoryId: json['category_id']?.toString() ?? '',
      price: json['price']?.toString() ?? '0',
      imageUrl: json['image_url'] ?? '',
      isAvailable: json['is_available'] == 1 || json['is_available'] == true,
      quantity: json['quantity'] != null
          ? int.tryParse(json['quantity'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'description': description,
      'category_id': categoryId,
      'price': price,
      'image_url': imageUrl,
      'is_available': isAvailable,
      'quantity': quantity,
    };
  }

  String getFormattedPrice() {
    try {
      final priceValue = double.parse(price);
      return '${priceValue.toStringAsFixed(0)} FCFA';
    } catch (e) {
      return '$price FCFA';
    }
  }
}
