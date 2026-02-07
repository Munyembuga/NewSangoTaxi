import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../models/product_category_model.dart';
import '../models/product_model.dart';
import '../models/cart_item_model.dart';
import '../l10n/l10n.dart';
import '../services/delivery_service.dart';
import '../services/storage_service.dart';
import 'package:sango/screen/cartScreen.dart';

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({Key? key}) : super(key: key);

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  List<ProductCategory> _categories = [];
  bool _isLoadingCategories = true;
  bool _hasCategoriesError = false;
  String _categoriesErrorMessage = '';

  List<Product> _products = [];
  bool _isLoadingProducts = false;
  bool _hasProductsError = false;
  String _productsErrorMessage = '';

  ProductCategory? _selectedCategory;

  // Cart items
  final List<CartItem> _cartItems = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadCart();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _hasCategoriesError = false;
    });

    try {
      final result = await DeliveryService.getProductCategories();

      if (result['success']) {
        final categoryData = result['data'] as List;
        setState(() {
          _categories = categoryData
              .map((json) => ProductCategory.fromJson(json))
              .where((category) => category.isActive)
              .toList();
          _isLoadingCategories = false;
        });
      } else {
        setState(() {
          _hasCategoriesError = true;
          _categoriesErrorMessage = result['message'];
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasCategoriesError = true;
        _categoriesErrorMessage = 'Failed to load categories: $e';
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _loadProductsByCategory(String categoryId) async {
    setState(() {
      _isLoadingProducts = true;
      _hasProductsError = false;
    });

    try {
      final result = await DeliveryService.getProductsByCategory(categoryId);

      if (result['success']) {
        final productData = result['data'] as List;
        setState(() {
          _products = productData
              .map((json) => Product.fromJson(json))
              .where((product) => product.isAvailable)
              .toList();
          _isLoadingProducts = false;
        });
      } else {
        setState(() {
          _hasProductsError = true;
          _productsErrorMessage = result['message'];
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasProductsError = true;
        _productsErrorMessage = 'Failed to load products: $e';
        _isLoadingProducts = false;
      });
    }
  }

  // Load cart items from API
  Future<void> _loadCart() async {
    try {
      final clientData = await StorageService.getClientData();

      if (clientData == null || clientData['user_id'] == null) {
        // User not logged in, skip loading cart
        return;
      }

      final userId = int.parse(clientData['user_id'].toString());
      final result = await DeliveryService.getCart(userId: userId);

      if (result['success']) {
        final data = result['data'];
        final items = data['items'] as List;

        setState(() {
          _cartItems.clear();
          for (var item in items) {
            // Create Product from cart item data
            final product = Product(
              productId: item['product_id'].toString(),
              productName: item['product_name'] ?? '',
              description: item['description'] ?? '',
              categoryId: '',
              price: item['price'].toString(),
              imageUrl: item['image_url'] ?? '',
              isAvailable: item['is_available'] == true || item['is_available'] == 1,
            );

            // Create CartItem with quantity and cart_id from API
            _cartItems.add(CartItem(
              product: product,
              quantity: int.parse(item['quantity'].toString()),
              cartId: item['cart_id'].toString(),
            ));
          }
        });

        print('Cart loaded: ${_cartItems.length} items'); // Debug log
      } else {
        print('Failed to load cart: ${result['message']}'); // Debug log
      }
    } catch (e) {
      print('Error loading cart: $e'); // Debug log
    }
  }

  // Add product to cart
  void _addToCart(Product product) async {
    try {
      // Get user data to retrieve user_id
      final clientData = await StorageService.getClientData();

      print('Client data: $clientData'); // Debug log

      if (clientData == null || clientData['user_id'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to add items to cart'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final userId = int.parse(clientData['user_id'].toString());

      print('User ID: $userId'); // Debug log
      print('Product ID: ${product.productId}'); // Debug log

      // Check if product already exists in cart to determine quantity
      final existingIndex = _cartItems.indexWhere(
        (item) => item.product.productId == product.productId,
      );

      final newQuantity = existingIndex != -1
          ? _cartItems[existingIndex].quantity + 1
          : 1;

      print('New quantity: $newQuantity'); // Debug log

      // Call API to add to cart
      final result = await DeliveryService.addToCart(
        userId: userId,
        productId: product.productId,
        quantity: newQuantity,
      );

      print('API Result: $result'); // Debug log

      if (result['success']) {
        // Reload cart from API to get updated data
        await _loadCart();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.productName} added to cart'),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFFF5141E),
          ),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to add to cart'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error in _addToCart: $e'); // Debug log
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding to cart: $e'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Get total items in cart
  int get _totalCartItems {
    return _cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  // Navigate to cart screen
  void _navigateToCart() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartScreen(
          cartItems: _cartItems,
          onCartUpdated: () {
            setState(() {});
          },
        ),
      ),
    );

    // Reload cart when returning from cart screen
    await _loadCart();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Delivery',
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
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: _navigateToCart,
              ),
              if (_totalCartItems > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _totalCartItems.toString(),
                      style: const TextStyle(
                        color: Color(0xFFF5141E),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _isLoadingCategories
          ? _buildCategoriesShimmer()
          : _hasCategoriesError
              ? _buildErrorWidget(_categoriesErrorMessage, _loadCategories)
              : Column(
                  children: [
                    // Categories Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Categories',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                final category = _categories[index];
                                final isSelected =
                                    _selectedCategory?.categoryId ==
                                        category.categoryId;
                                return _buildCategoryCard(category, isSelected);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Products Section
                    Expanded(
                      child: _selectedCategory == null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.shopping_basket_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Select a category to view products',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : _isLoadingProducts
                              ? _buildProductsShimmer()
                              : _hasProductsError
                                  ? _buildErrorWidget(
                                      _productsErrorMessage,
                                      () => _loadProductsByCategory(
                                          _selectedCategory!.categoryId),
                                    )
                                  : _products.isEmpty
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.inventory_2_outlined,
                                                size: 64,
                                                color: Colors.grey[400],
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'No products available',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16),
                                          child: GridView.builder(
                                            gridDelegate:
                                                const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 2,
                                              crossAxisSpacing: 12,
                                              mainAxisSpacing: 12,
                                              childAspectRatio: 0.65,
                                            ),
                                            itemCount: _products.length,
                                            itemBuilder: (context, index) {
                                              final product = _products[index];
                                              return _buildProductCard(product);
                                            },
                                          ),
                                        ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildCategoryCard(ProductCategory category, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
        _loadProductsByCategory(category.categoryId);
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            // Circular category container
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF5141E) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFF5141E)
                      : Colors.grey.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: category.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: category.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: isSelected
                              ? const Color(0xFFF5141E)
                              : Colors.grey[200],
                          child: Icon(
                            Icons.category,
                            size: 30,
                            color: isSelected ? Colors.white : const Color(0xFFF5141E),
                          ),
                        ),
                      )
                    : Container(
                        color: isSelected
                            ? const Color(0xFFF5141E)
                            : Colors.grey[100],
                        child: Icon(
                          Icons.category,
                          size: 30,
                          color: isSelected ? Colors.white : const Color(0xFFF5141E),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            // Category name
            Text(
              category.categoryName,
              style: TextStyle(
                color: isSelected ? const Color(0xFFF5141E) : Colors.black87,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () => _addToCart(product),
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: CachedNetworkImage(
                imageUrl: product.imageUrl,
                width: double.infinity,
                height: 100,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 100,
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 100,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, size: 40),
                ),
              ),
            ),
            // Product Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.productName,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          product.getFormattedPrice(),
                          style: const TextStyle(
                            color: Color(0xFFF5141E),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _addToCart(product),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5141E),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.add_shopping_cart,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildCategoriesShimmer() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              width: 150,
              height: 24,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) {
                return Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 16),
                  child: Column(
                    children: [
                      Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: Container(
                          width: 60,
                          height: 12,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget(String message, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF5141E),
            ),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
