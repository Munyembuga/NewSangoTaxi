class CarouselItem {
  final int id;
  final String imageUrl;
  final String title;
  final String subtitle;
  final int status;
  final String createdAt;

  CarouselItem({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.createdAt,
  });

  factory CarouselItem.fromJson(Map<String, dynamic> json) {
    return CarouselItem(
      id: json['id'] ?? 0,
      imageUrl: json['image_url'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      status: json['sts'] ?? 0,
      createdAt: json['created_at'] ?? '',
    );
  }
}
