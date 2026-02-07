class CancellationHistoryResponse {
  final bool success;
  final String message;
  final Pagination pagination;
  final List<Cancellation> cancellations;
  final int totalCancelled;
  final String userType;
  final String clientId;
  final RequestParams requestParams;

  CancellationHistoryResponse({
    required this.success,
    required this.message,
    required this.pagination,
    required this.cancellations,
    required this.totalCancelled,
    required this.userType,
    required this.clientId,
    required this.requestParams,
  });

  factory CancellationHistoryResponse.fromJson(Map<String, dynamic> json) {
    return CancellationHistoryResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
      cancellations: (json['cancellations'] as List<dynamic>?)
              ?.map((cancellation) => Cancellation.fromJson(cancellation))
              .toList() ??
          [],
      totalCancelled:
          int.tryParse(json['total_cancelled']?.toString() ?? '0') ?? 0,
      userType: json['user_type'] ?? '',
      clientId: json['client_id']?.toString() ?? '',
      requestParams: RequestParams.fromJson(json['request_params'] ?? {}),
    );
  }
}

class Pagination {
  final int totalRecords;
  final int totalPages;
  final int currentPage;
  final int limit;

  Pagination({
    required this.totalRecords,
    required this.totalPages,
    required this.currentPage,
    required this.limit,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      totalRecords: int.tryParse(json['total_records']?.toString() ?? '0') ?? 0,
      totalPages: json['total_pages'] ?? 0,
      currentPage: json['current_page'] ?? 0,
      limit: json['limit'] ?? 0,
    );
  }
}

class Cancellation {
  final String bookingId;
  final String bookingCode;
  final String clientId;
  final String pickupLocation;
  final String dropoffLocation;
  final String estimatedPrice;
  final String createdAt;
  final String cancelledAt;
  final String cancelledBy;
  final String cancellationReason;
  final String catgName;
  final String catgImage;

  Cancellation({
    required this.bookingId,
    required this.bookingCode,
    required this.clientId,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.estimatedPrice,
    required this.createdAt,
    required this.cancelledAt,
    required this.cancelledBy,
    required this.cancellationReason,
    required this.catgName,
    required this.catgImage,
  });

  factory Cancellation.fromJson(Map<String, dynamic> json) {
    return Cancellation(
      bookingId: json['booking_id'] ?? '',
      bookingCode: json['booking_code'] ?? '',
      clientId: json['client_id'] ?? '',
      pickupLocation: json['pickup_location'] ?? '',
      dropoffLocation: json['dropoff_location'] ?? '',
      estimatedPrice: json['estimated_price'] ?? '',
      createdAt: json['created_at'] ?? '',
      cancelledAt: json['cancelled_at'] ?? '',
      cancelledBy: json['cancelled_by'] ?? '',
      cancellationReason: json['cancellation_reason'] ?? '',
      catgName: json['catg_name'] ?? '',
      catgImage: json['catg_image'] ?? '',
    );
  }

  // Helper method to format date
  String get formattedCreatedAt {
    try {
      final date = DateTime.parse(createdAt);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return createdAt;
    }
  }

  // Helper method to format cancellation date
  String get formattedCancelledAt {
    try {
      final date = DateTime.parse(cancelledAt);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return cancelledAt;
    }
  }

  // Get image URL with base URL
  String get imageUrl {
    if (catgImage.isEmpty) return '';
    return 'http://move.itecsoft.site/images/categories/$catgImage';
  }
}

class RequestParams {
  final int page;
  final int limit;

  RequestParams({
    required this.page,
    required this.limit,
  });

  factory RequestParams.fromJson(Map<String, dynamic> json) {
    return RequestParams(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
    );
  }
}
