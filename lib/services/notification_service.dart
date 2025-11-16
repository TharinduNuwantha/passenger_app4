import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/notification_model.dart';

class NotificationService {
  static const String baseUrl = 'YOUR_API_URL';

  Future<List<NotificationModel>> fetchNotifications(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/notifications/$userId'),
        headers: {
          'Authorization': 'Bearer YOUR_TOKEN',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> notifList = data['data']['notifications'];

        return notifList
            .map((notif) => NotificationModel.fromJson(notif))
            .toList();
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await http.put(
        Uri.parse('$baseUrl/api/notifications/$notificationId/read'),
        headers: {
          'Authorization': 'Bearer YOUR_TOKEN',
          'Content-Type': 'application/json',
        },
      );
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/notifications/$userId/unread-count'),
        headers: {'Authorization': 'Bearer YOUR_TOKEN'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['unreadCount'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('Error fetching unread count: $e');
      return 0;
    }
  }
}
