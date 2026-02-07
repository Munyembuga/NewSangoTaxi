class BookingType {
  final String bookingTypeId;
  final String typeName;
  final String description;
  final String sts;

  BookingType({
    required this.bookingTypeId,
    required this.typeName,
    required this.description,
    required this.sts,
  });

  factory BookingType.fromJson(Map<String, dynamic> json) {
    return BookingType(
      bookingTypeId: json['booking_type_id'] ?? '',
      typeName: json['type_name'] ?? '',
      description: json['description'] ?? '',
      sts: json['sts'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'booking_type_id': bookingTypeId,
      'type_name': typeName,
      'description': description,
      'sts': sts,
    };
  }

  bool get isActive => sts == '1';
}

// New model for category with booking type support
class CategoryWithBookingType {
  final String catgId;
  final String catgName;
  final String description;
  final String catgImage;
  final String dueDate;
  final String sts;
  final BookingType bookingType;
  final dynamic pricing;
  final String? availableVehicles;

  CategoryWithBookingType({
    required this.catgId,
    required this.catgName,
    required this.description,
    required this.catgImage,
    required this.dueDate,
    required this.sts,
    required this.bookingType,
    required this.pricing,
    required this.availableVehicles,
  });

  factory CategoryWithBookingType.fromJson(Map<String, dynamic> json) {
    return CategoryWithBookingType(
      catgId: json['catg_id'].toString(),
      catgName: json['catg_name'] ?? '',
      description: json['description'] ?? '',
      catgImage: json['catg_image'] ?? '',
      dueDate: json['due_date'] ?? '',
      sts: json['sts'].toString(),
      bookingType: BookingType.fromJson(json['booking_type'] ?? {}),
      pricing: json['pricing'],
      availableVehicles: json['available_vehicles'] ?? '',
    );
  }

  bool get isActive => sts == '1';

  String get displayPrice {
    if (pricing == null) return 'Price on request';

    if (pricing is Map<String, dynamic>) {
      final pricingMap = pricing as Map<String, dynamic>;

      if (pricingMap['type'] == 'ride') {
        // Booking type 1: Standard ride pricing
        final base_fee = pricingMap['base_fee'] ?? '0';
        final base_km = pricingMap['base_km'] ?? '0';
        final perKmRate = pricingMap['per_km_rate'] ?? '0';

        final baseFareInt = (double.tryParse(base_fee) ?? 0);
        final perKmRateInt = (double.tryParse(perKmRate) ?? 0);

        return '$baseFareInt FCFA(${base_km} Km) + $perKmRateInt FCFA/km';
      } else if (pricingMap['type'] == 'rental') {
        // Booking type 2: Car rental without driver
        final details = pricingMap['details'];
        if (details is List && details.isNotEmpty) {
          try {
            final dayPrices = details
                .where((detail) => detail['price_type_name'] == 'day')
                .toList();

            if (dayPrices.isNotEmpty) {
              final dayPrice = dayPrices.first;
              final priceValue = dayPrice['car_rent_price'].toString();
              final price = (double.tryParse(priceValue) ?? 0);
              return '$price FCFA/day';
            } else {
              // No day price, show first available price
              final firstPrice = details.first;
              final priceValue = firstPrice['car_rent_price'].toString();
              final price = (double.tryParse(priceValue) ?? 0);
              return '$price FCFA/${firstPrice['price_type_name']}';
            }
          } catch (e) {
            print('Error parsing rental pricing: $e');
            return 'Price varies';
          }
        }
      } else if (pricingMap['type'] == 'rental_with_driver') {
        // Booking type 3: Car rental with driver
        final details = pricingMap['details'];
        if (details is List && details.isNotEmpty) {
          try {
            final dayPrices = details
                .where((detail) => detail['price_type_name'] == 'day')
                .toList();

            if (dayPrices.isNotEmpty) {
              final dayPrice = dayPrices.first;
              final priceValue = dayPrice['total_price'].toString();
              final price = (double.tryParse(priceValue) ?? 0);
              return '$price FCFA/day (with driver)';
            } else {
              // No day price, show first available price
              final firstPrice = details.first;
              final priceValue = firstPrice['total_price'].toString();
              final price = (double.tryParse(priceValue) ?? 0);
              return '$price FCFA/${firstPrice['price_type_name']} (with driver)';
            }
          } catch (e) {
            print('Error parsing rental with driver pricing: $e');
            return 'Price varies';
          }
        }
      }
    }
    return 'Price varies';
  }

  // Get detailed pricing information for display
  String get detailedPricing {
    if (pricing == null) return 'Price on request';

    if (pricing is Map<String, dynamic>) {
      final pricingMap = pricing as Map<String, dynamic>;

      if (pricingMap['type'] == 'ride') {
        final baseFare = (double.tryParse(pricingMap['base_fare'] ?? '0') ?? 0);
        final perKmRate =
            (double.tryParse(pricingMap['per_km_rate'] ?? '0') ?? 0);

        final perMinuteRate =
            (double.tryParse(pricingMap['per_minute_rate'] ?? '0') ?? 0);

        return 'Base: $baseFare FCFA\nPer km: $perKmRate FCFA\nPer minute: $perMinuteRate FCFA';
      } else if (pricingMap['type'] == 'rental' ||
          pricingMap['type'] == 'rental_with_driver') {
        final details = pricingMap['details'];
        if (details is List && details.isNotEmpty) {
          final StringBuffer pricing = StringBuffer();

          for (var detail in details) {
            final priceTypeName = detail['price_type_name'];
            String priceValue;

            if (pricingMap['type'] == 'rental_with_driver') {
              priceValue =
                  (double.tryParse(detail['total_price'].toString()) ?? 0)
                      .toString();
            } else {
              priceValue =
                  (double.tryParse(detail['car_rent_price'].toString()) ?? 0)
                      .toString();
            }

            if (pricing.isNotEmpty) pricing.write('\n');
            pricing.write(
                '${priceTypeName.toString().toUpperCase()}: $priceValue FCFA');
          }

          return pricing.toString();
        }
      }
    }
    return 'Price varies';
  }

  // Get rental pricing options for display in dropdown
  List<Map<String, dynamic>> get rentalPricingOptions {
    if (pricing == null ||
        (pricing['type'] != 'rental_with_driver' &&
            pricing['type'] != 'rental')) {
      return [];
    }

    final details = pricing['details'];
    if (details is List) {
      return details.cast<Map<String, dynamic>>();
    }

    return [];
  }

  // Add comparison methods for dropdown_search
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryWithBookingType && other.catgId == catgId;
  }

  @override
  int get hashCode => catgId.hashCode;

  @override
  String toString() => catgName;
}
