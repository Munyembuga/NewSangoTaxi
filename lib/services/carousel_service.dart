import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sango/models/carousel_model.dart';

class CarouselService {
  static const String baseUrl = 'https://mis.sangotaxi.com/api';

  static Future<Map<String, dynamic>> getCarouselItems() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/booking/scr/carousel_api'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          print('Carousel items loaded successfully:$data');
          // Parse the carousel items from the response
          final List<dynamic> carouselData = data['data'] ?? [];
          final List<CarouselItem> carouselItems = carouselData
              .map((json) => CarouselItem.fromJson(json))
              .where((item) => item.status == 1) // Only active items
              .toList();

          return {
            'success': true,
            'data': carouselItems,
            'message':
                data['message'] ?? 'Carousel items retrieved successfully',
          };
        } else {
          return {
            'success': false,
            'data': <CarouselItem>[],
            'message': data['message'] ?? 'Failed to load carousel items',
          };
        }
      } else {
        return {
          'success': false,
          'data': <CarouselItem>[],
          'message': 'HTTP Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'data': <CarouselItem>[],
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
}
