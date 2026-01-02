import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/notification_model.dart';
import '../config/api_config.dart';
import 'storage_service.dart';

class NotificationService {
  final StorageService _storage = StorageService();

  // Get authorization headers with token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.getAccessToken();
    return {
      'Authorization': 'Bearer ${token ?? ''}',
      'Content-Type': 'application/json',
    };
  }

  /// Fetch all notifications for a user
  Future<List<NotificationModel>> fetchNotifications(String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/notifications'),
        headers: headers,
      ).timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Handle different response structures
        List<dynamic> notifList;
        if (data is List) {
          notifList = data;
        } else if (data['data'] != null) {
          if (data['data'] is List) {
            notifList = data['data'];
          } else if (data['data']['notifications'] != null) {
            notifList = data['data']['notifications'];
          } else {
            notifList = [];
          }
        } else if (data['notifications'] != null) {
          notifList = data['notifications'];
        } else {
          notifList = [];
        }

        return notifList
            .map((notif) => NotificationModel.fromJson(notif))
            .toList();
      } else if (response.statusCode == 401) {
        print('Unauthorized: Token may be expired');
        throw Exception('Unauthorized');
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      // Return mock data for development/testing
      return _getMockNotifications();
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/notifications/$notificationId/read'),
        headers: headers,
      ).timeout(ApiConfig.sendTimeout);

      if (response.statusCode != 200) {
        print('Failed to mark notification as read: ${response.statusCode}');
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/notifications/read-all'),
        headers: headers,
      ).timeout(ApiConfig.sendTimeout);

      if (response.statusCode != 200) {
        print('Failed to mark all notifications as read: ${response.statusCode}');
      }
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  /// Get count of unread notifications
  Future<int> getUnreadCount(String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/notifications/unread-count'),
        headers: headers,
      ).timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Handle different response structures
        if (data is Map) {
          return data['count'] ?? 
                 data['unreadCount'] ?? 
                 data['data']?['count'] ?? 
                 data['data']?['unreadCount'] ?? 
                 0;
        }
        return 0;
      }
      return 0;
    } catch (e) {
      print('Error fetching unread count: $e');
      // Return mock count for development
      return 3;
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/notifications/$notificationId'),
        headers: headers,
      ).timeout(ApiConfig.sendTimeout);

      if (response.statusCode != 200) {
        print('Failed to delete notification: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  /// Get mock notifications for development/testing
  List<NotificationModel> _getMockNotifications() {
    final now = DateTime.now();
    return [
      NotificationModel(
        id: '1',
        userId: 'user123',
        title: 'Booking Confirmed',
        message: 'Your bus booking for Route 245 has been confirmed. Departure at 10:30 AM.',
        type: 'booking',
        read: false,
        createdAt: now.subtract(const Duration(minutes: 30)),
        actionUrl: '/bookings/1',
      ),
      NotificationModel(
        id: '2',
        userId: 'user123',
        title: 'Special Offer: 20% Off',
        message: 'Book your next trip and get 20% off! Limited time offer.',
        type: 'promo',
        read: false,
        createdAt: now.subtract(const Duration(hours: 2)),
        actionUrl: '/offers',
      ),
      NotificationModel(
        id: '3',
        userId: 'user123',
        title: 'Trip Reminder',
        message: 'Your trip to Colombo is scheduled for tomorrow at 8:00 AM. Don\'t forget to check in!',
        type: 'alert',
        read: true,
        createdAt: now.subtract(const Duration(days: 1)),
        actionUrl: '/bookings/2',
      ),
      NotificationModel(
        id: '4',
        userId: 'user123',
        title: 'Payment Successful',
        message: 'Your payment of LKR 1,500 has been processed successfully.',
        type: 'booking',
        read: true,
        createdAt: now.subtract(const Duration(days: 2)),
        actionUrl: '/payments/1',
      ),
      NotificationModel(
        id: '5',
        userId: 'user123',
        title: 'New Route Available',
        message: 'Check out our new express route to Kandy! Faster and more comfortable.',
        type: 'promo',
        read: true,
        createdAt: now.subtract(const Duration(days: 3)),
        actionUrl: '/routes/kandy-express',
      ),
    ];
  }
}
