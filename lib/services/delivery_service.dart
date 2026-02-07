import 'package:dio/dio.dart';
import '../models/product_category_model.dart';
import '../models/product_model.dart';

class DeliveryService {
  static final Dio _dio = Dio();
  static const String _baseUrl = 'http://mis.sangotaxi.com/api/delivery/';

  // Fetch product categories
  static Future<Map<String, dynamic>> getProductCategories() async {
    try {
      final response = await _dio.get(
        '${_baseUrl}get_categories.php',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Check if the API response has success field
        if (data['success'] == true) {
          return {
            'success': true,
            'data': data['data'],
            'count': data['count'],
            'message': data['message'],
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to fetch categories',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch categories',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to fetch product categories';

      if (e.response != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Server response timeout';
      } else if (e.type == DioExceptionType.unknown) {
        errorMessage = 'No internet connection';
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  // Fetch products by category
  static Future<Map<String, dynamic>> getProductsByCategory(
      String categoryId) async {
    try {
      final response = await _dio.get(
        '${_baseUrl}get_products_by_category.php',
        queryParameters: {
          'category_id': categoryId,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Check if the API response has success field
        if (data['success'] == true) {
          return {
            'success': true,
            'data': data['data'],
            'count': data['count'],
            'category_id': data['category_id'],
            'message': data['message'],
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to fetch products',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch products',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to fetch products';

      if (e.response != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Server response timeout';
      } else if (e.type == DioExceptionType.unknown) {
        errorMessage = 'No internet connection';
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  // Get cart items
  static Future<Map<String, dynamic>> getCart({
    required int userId,
  }) async {
    try {
      print('Fetching cart for User ID: $userId'); // Debug log

      final response = await _dio.get(
        '${_baseUrl}cart/get_cart.php',
        queryParameters: {
          'user_id': userId,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      print('Cart response status code: ${response.statusCode}'); // Debug log
      print('Cart response data: ${response.data}'); // Debug log

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'Cart retrieved successfully',
            'data': data['data'],
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to fetch cart',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch cart',
        };
      }
    } on DioException catch (e) {
      print('DioException fetching cart: ${e.toString()}'); // Debug log
      print('DioException response: ${e.response?.data}'); // Debug log

      String errorMessage = 'Failed to fetch cart';

      if (e.response != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Server response timeout';
      } else if (e.type == DioExceptionType.unknown) {
        errorMessage = 'No internet connection';
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      print('General error fetching cart: ${e.toString()}'); // Debug log

      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  // Add product to cart
  static Future<Map<String, dynamic>> addToCart({
    required int userId,
    required String productId,
    required int quantity,
  }) async {
    try {
      print('Sending cart request - User ID: $userId, Product ID: $productId, Quantity: $quantity'); // Debug log

      final response = await _dio.post(
        '${_baseUrl}cart/add_to_cart.php',
        data: {
          'user_id': userId,
          'product_id': productId,
          'quantity': quantity,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      print('Response status code: ${response.statusCode}'); // Debug log
      print('Response data: ${response.data}'); // Debug log

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'Product added to cart',
            'data': data['data'],
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to add product to cart',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to add product to cart',
        };
      }
    } on DioException catch (e) {
      print('DioException: ${e.toString()}'); // Debug log
      print('DioException response: ${e.response?.data}'); // Debug log

      String errorMessage = 'Failed to add product to cart';

      if (e.response != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Server response timeout';
      } else if (e.type == DioExceptionType.unknown) {
        errorMessage = 'No internet connection';
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      print('General error: ${e.toString()}'); // Debug log

      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  // Update cart item quantity
  static Future<Map<String, dynamic>> updateCartItem({
    required int userId,
    required String productId,
    required int quantity,
  }) async {
    try {
      print('Updating cart item - User ID: $userId, Product ID: $productId, Quantity: $quantity'); // Debug log

      final response = await _dio.put(
        '${_baseUrl}cart/update_cart.php',
        data: {
          'user_id': userId,
          'product_id': productId,
          'quantity': quantity,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      print('Update response status code: ${response.statusCode}'); // Debug log
      print('Update response data: ${response.data}'); // Debug log

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'Cart updated successfully',
            'data': data['data'],
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to update cart',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to update cart',
        };
      }
    } on DioException catch (e) {
      print('DioException updating cart: ${e.toString()}'); // Debug log
      String errorMessage = 'Failed to update cart';

      if (e.response != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      print('General error updating cart: ${e.toString()}'); // Debug log

      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  // Increment cart item quantity
  static Future<Map<String, dynamic>> incrementQuantity({
    required int userId,
    required String cartId,
  }) async {
    try {
      print('Incrementing quantity - User ID: $userId, Cart ID: $cartId'); // Debug log

      final response = await _dio.post(
        '${_baseUrl}cart/increment_quantity.php',
        data: {
          'user_id': userId,
          'cart_id': cartId,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      print('Increment response status code: ${response.statusCode}'); // Debug log
      print('Increment response data: ${response.data}'); // Debug log

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'Quantity incremented',
            'data': data['data'],
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to increment quantity',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to increment quantity',
        };
      }
    } on DioException catch (e) {
      print('DioException incrementing quantity: ${e.toString()}'); // Debug log
      String errorMessage = 'Failed to increment quantity';

      if (e.response != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      print('General error incrementing quantity: ${e.toString()}'); // Debug log

      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  // Decrement cart item quantity
  static Future<Map<String, dynamic>> decrementQuantity({
    required int userId,
    required String cartId,
  }) async {
    try {
      print('Decrementing quantity - User ID: $userId, Cart ID: $cartId'); // Debug log

      final response = await _dio.post(
        '${_baseUrl}cart/decrement_quantity.php',
        data: {
          'user_id': userId,
          'cart_id': cartId,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      print('Decrement response status code: ${response.statusCode}'); // Debug log
      print('Decrement response data: ${response.data}'); // Debug log

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'Quantity decremented',
            'data': data['data'],
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to decrement quantity',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to decrement quantity',
        };
      }
    } on DioException catch (e) {
      print('DioException decrementing quantity: ${e.toString()}'); // Debug log
      String errorMessage = 'Failed to decrement quantity';

      if (e.response != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      print('General error decrementing quantity: ${e.toString()}'); // Debug log

      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  // Remove item from cart
  static Future<Map<String, dynamic>> removeFromCart({
    required int userId,
    required String cartId,
  }) async {
    try {
      print('Removing cart item - User ID: $userId, Cart ID: $cartId'); // Debug log

      final response = await _dio.post(
        '${_baseUrl}cart/remove_from_cart.php',
        data: {
          'user_id': userId,
          'cart_id': cartId,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      print('Remove response status code: ${response.statusCode}'); // Debug log
      print('Remove response data: ${response.data}'); // Debug log

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'Item removed from cart',
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to remove item',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to remove item',
        };
      }
    } on DioException catch (e) {
      print('DioException removing from cart: ${e.toString()}'); // Debug log
      String errorMessage = 'Failed to remove item';

      if (e.response != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      print('General error removing from cart: ${e.toString()}'); // Debug log

      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  // Process order
  static Future<Map<String, dynamic>> processOrder({
    required int userId,
    required String deliveryAddress,
    required double deliveryLat,
    required double deliveryLng,
    required String paymentMethod,
    String? notes,
  }) async {
    try {
      print('Processing order - User ID: $userId, Address: $deliveryAddress'); // Debug log

      final response = await _dio.post(
        '${_baseUrl}orders/process_order.php',
        data: {
          'user_id': userId,
          'delivery_address': deliveryAddress,
          'delivery_lat': deliveryLat,
          'delivery_lng': deliveryLng,
          'payment_method': paymentMethod,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      print('Order response status code: ${response.statusCode}'); // Debug log
      print('Order response data: ${response.data}'); // Debug log

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'Order placed successfully',
            'data': data['data'],
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to process order',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to process order',
        };
      }
    } on DioException catch (e) {
      print('DioException processing order: ${e.toString()}'); // Debug log
      String errorMessage = 'Failed to process order';

      if (e.response != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      print('General error processing order: ${e.toString()}'); // Debug log

      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  // Get orders by status
  static Future<Map<String, dynamic>> getOrders({
    required int userId,
    required String status, // pending, completed, cancelled
  }) async {
    try {
      print('Fetching orders - User ID: $userId, Status: $status'); // Debug log

      final response = await _dio.get(
        '${_baseUrl}orders/get_orders.php',
        queryParameters: {
          'user_id': userId,
          'status': status,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      print('Orders response status code: ${response.statusCode}'); // Debug log
      print('Orders response data: ${response.data}'); // Debug log

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'Orders retrieved successfully',
            'data': data['data'],
            'count': data['count'],
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to fetch orders',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch orders',
        };
      }
    } on DioException catch (e) {
      print('DioException fetching orders: ${e.toString()}'); // Debug log
      String errorMessage = 'Failed to fetch orders';

      if (e.response != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      print('General error fetching orders: ${e.toString()}'); // Debug log

      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  // Get order details
  static Future<Map<String, dynamic>> getOrderDetails({
    required int userId,
    required String orderId,
  }) async {
    try {
      print('Fetching order details - User ID: $userId, Order ID: $orderId'); // Debug log

      final response = await _dio.get(
        '${_baseUrl}orders/get_order.php',
        queryParameters: {
          'user_id': userId,
          'order_id': orderId,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      print('Order details response status code: ${response.statusCode}'); // Debug log
      print('Order details response data: ${response.data}'); // Debug log

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'Order retrieved successfully',
            'data': data['data'],
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to fetch order details',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch order details',
        };
      }
    } on DioException catch (e) {
      print('DioException fetching order details: ${e.toString()}'); // Debug log
      String errorMessage = 'Failed to fetch order details';

      if (e.response != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      print('General error fetching order details: ${e.toString()}'); // Debug log

      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }
}
