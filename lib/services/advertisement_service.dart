import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/advertisement_model.dart';

class AdvertisementService {
  static const String baseUrl = 'YOUR_API_URL';

  Future<List<Advertisement>> fetchAdvertisements() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/advertisements/active'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> adsList = data['data']['advertisements'];

        return adsList
            .map((ad) => Advertisement.fromJson(ad))
            .where((ad) => ad.active)
            .toList()
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      } else {
        throw Exception('Failed to load advertisements');
      }
    } catch (e) {
      print('Error fetching advertisements: $e');
      return [];
    }
  }

  Future<void> trackView(String id) async {}

  Future<void> trackClick(String id) async {}
}
