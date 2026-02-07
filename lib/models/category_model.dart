class Category {
  final String catgId;
  final String catgName;
  final int availableVehicles;

  final String description;
  final String image;
  final String dueDate;
  final String status;
  final Pricing? pricing;

  Category({
    required this.catgId,
    required this.catgName,
    required this.availableVehicles,
    required this.description,
    required this.image,
    required this.dueDate,
    required this.status,
    this.pricing,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    // Handle pricing which can be either an empty list or an object
    Pricing? pricingData;
    if (json['pricing'] != null && json['pricing'] is Map) {
      pricingData = Pricing.fromJson(json['pricing']);
    }

    return Category(
      catgId: json['catg_id'] ?? '',
      catgName: json['catg_name'] ?? '',
      description: json['description'] ?? '',
      image: json['catg_image'] ?? '',
      dueDate: json['due_date'] ?? '',
      status: json['sts'] ?? '',
      pricing: pricingData,
      availableVehicles: json['available_vehicles'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'catg_id': catgId,
      'catg_name': catgName,
      'description': description,
      'catg_image': image,
      'due_date': dueDate,
      'sts': status,
      'pricing': pricing?.toJson(),
      'available_vehicles': availableVehicles,
    };
  }
}

class Pricing {
  final String priceId;
  final String baseFare;
  final String perKmRate;
  final String perMinuteRate;
  final String lastUpdated;

  Pricing({
    required this.priceId,
    required this.baseFare,
    required this.perKmRate,
    required this.perMinuteRate,
    required this.lastUpdated,
  });

  factory Pricing.fromJson(Map<String, dynamic> json) {
    return Pricing(
      priceId: json['price_id'] ?? '',
      baseFare: json['base_fare'] ?? '',
      perKmRate: json['per_km_rate'] ?? '',
      perMinuteRate: json['per_minute_rate'] ?? '',
      lastUpdated: json['last_updated'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'price_id': priceId,
      'base_fee': baseFare,
      'per_km_rate': perKmRate,
      'per_minute_rate': perMinuteRate,
      'last_updated': lastUpdated,
    };
  }

  // Helper method to get formatted price per km
  String getFormattedPerKmRate() {
    try {
      final rate = double.parse(perKmRate);
      return '${rate.toStringAsFixed(0)} per km';
    } catch (e) {
      return '$perKmRate per km';
    }
  }

  // Helper method to get formatted base fare
  String getFormattedBaseFare() {
    try {
      final fare = double.parse(baseFare);
      return '${fare.toStringAsFixed(0)}';
    } catch (e) {
      return '$baseFare';
    }
  }
}
