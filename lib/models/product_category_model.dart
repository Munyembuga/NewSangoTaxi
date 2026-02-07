class ProductCategory {
  final String categoryId;
  final String categoryName;
  final String description;
  final String imageUrl;
  final bool isActive;

  ProductCategory({
    required this.categoryId,
    required this.categoryName,
    required this.description,
    required this.imageUrl,
    required this.isActive,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      categoryId: json['category_id']?.toString() ?? '',
      categoryName: json['category_name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? '',
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'category_name': categoryName,
      'description': description,
      'image_url': imageUrl,
      'is_active': isActive,
    };
  }
}
