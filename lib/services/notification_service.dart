import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import '../config/api_config.dart';
import 'storage_service.dart';

class NotificationService {
  final StorageService _storage = StorageService();
  
  // Local cache for deleted and read status to ensure persistence in mock/dev mode
  static const String _deletedKey = 'notifications_deleted_ids';
  static const String _readKey = 'notifications_read_ids';
  static const String _localCacheKey = 'notifications_local_cache_v1';
  static const int _localCacheLimit = 20;

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

      List<NotificationModel> notifications = [];

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

        notifications = notifList
            .map((notif) => NotificationModel.fromJson(notif))
            .toList();
      } else {
        print('Failed to load notifications (status: ${response.statusCode}), falling back to mock data');
        notifications = _getMockNotifications();
      }

      return await _filterAndSyncNotifications(
        notifications,
        userId: userId,
      );
    } catch (e) {
      print('Error fetching notifications: $e');
      // Return mock data for development/testing
      return await _filterAndSyncNotifications(
        _getMockNotifications(),
        userId: userId,
      );
    }
  }

  /// Filters out deleted notifications and applies local read status
  Future<List<NotificationModel>> _filterAndSyncNotifications(
      List<NotificationModel> notifications,
      {required String userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final deletedIds = prefs.getStringList(_deletedKey) ?? [];
    final readIds = prefs.getStringList(_readKey) ?? [];

    final filteredServer =
        notifications.where((n) => !deletedIds.contains(n.id)).toList();
    final merged = await _mergeWithLocalCache(
      filteredServer,
      deletedIds: deletedIds,
      userId: userId,
    );

    for (final notif in merged) {
      if (readIds.contains(notif.id)) {
        notif.read = true;
      }
    }

    merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return merged;
  }

  Future<List<NotificationModel>> _mergeWithLocalCache(
      List<NotificationModel> serverNotifications,
      {required List<String> deletedIds,
      required String userId}) async {
    final localNotifications = await _loadLocalNotifications();
    if (localNotifications.isEmpty) {
      return serverNotifications;
    }

    final serverIds = serverNotifications.map((n) => n.id).toSet();
    final serverActionKeys = serverNotifications
        .map((n) => '${n.type}:${n.actionUrl ?? ''}')
        .toSet();

    final now = DateTime.now();
    final threshold = now.subtract(const Duration(days: 7));
    final retainedLocal = <NotificationModel>[];

    for (final local in localNotifications) {
      if (local.userId.isNotEmpty &&
          userId.isNotEmpty &&
          local.userId != userId) {
        continue;
      }
      if (deletedIds.contains(local.id)) continue;
      if (serverIds.contains(local.id)) continue;
      if (serverActionKeys.contains('${local.type}:${local.actionUrl ?? ''}')) {
        // Server now has a matching notification; drop the local placeholder
        continue;
      }
      if (local.createdAt.isBefore(threshold)) continue;
      retainedLocal.add(local);
    }

    await _saveLocalNotifications(retainedLocal);

    return [...retainedLocal, ...serverNotifications];
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    // Optimistic local update
    final prefs = await SharedPreferences.getInstance();
    final readIds = prefs.getStringList(_readKey) ?? [];
    if (!readIds.contains(notificationId)) {
      readIds.add(notificationId);
      await prefs.setStringList(_readKey, readIds);
    }

    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/notifications/$notificationId/read'),
        headers: headers,
      ).timeout(ApiConfig.sendTimeout);

      if (response.statusCode != 200) {
        print('Failed to mark notification as read on server: ${response.statusCode}');
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      // Re-fetch current list to get all IDs
      final notifications = await fetchNotifications(userId);
      final prefs = await SharedPreferences.getInstance();
      final readIds = prefs.getStringList(_readKey) ?? [];
      
      for (var n in notifications) {
        if (!readIds.contains(n.id)) {
          readIds.add(n.id);
        }
      }
      await prefs.setStringList(_readKey, readIds);

      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/notifications/read-all'),
        headers: headers,
      ).timeout(ApiConfig.sendTimeout);

      if (response.statusCode != 200) {
        print('Failed to mark all notifications as read on server: ${response.statusCode}');
      }
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  /// Get count of unread notifications
  Future<int> getUnreadCount(String userId) async {
    try {
      // In dev mode, we better fetch all and count to respect local filters/read status
      final notifications = await fetchNotifications(userId);
      return notifications.where((n) => !n.read).length;
    } catch (e) {
      print('Error fetching unread count: $e');
      return 0;
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    // Sync locally first for immediate effect and persistence in dev/mock
    final prefs = await SharedPreferences.getInstance();
    final deletedIds = prefs.getStringList(_deletedKey) ?? [];
    if (!deletedIds.contains(notificationId)) {
      deletedIds.add(notificationId);
      await prefs.setStringList(_deletedKey, deletedIds);
    }
    await _removeLocalNotification(notificationId);

    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/notifications/$notificationId'),
        headers: headers,
      ).timeout(ApiConfig.sendTimeout);

      if (response.statusCode != 200) {
        print('Failed to delete notification on server: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  /// Create a local notification entry (used when backend sync is delayed)
  Future<void> addLocalNotification({
    required String title,
    required String message,
    String type = 'booking',
    String? actionUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    final localNotification = NotificationModel(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: title,
      message: message,
      type: type,
      read: false,
      createdAt: DateTime.now(),
      actionUrl: actionUrl,
    );

    final cached = await _loadLocalNotifications();
    cached.insert(0, localNotification);
    await _saveLocalNotifications(cached);
  }

  Future<List<NotificationModel>> _loadLocalNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localCacheKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = json.decode(raw);
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(NotificationModel.fromJson)
          .toList();
    } catch (e) {
      print('Error loading local notifications: $e');
      await prefs.remove(_localCacheKey);
      return [];
    }
  }

  Future<void> _saveLocalNotifications(
    List<NotificationModel> notifications,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final trimmed = notifications.length > _localCacheLimit
        ? notifications.sublist(0, _localCacheLimit)
        : notifications;
    final payload = trimmed.map((n) => n.toJson()).toList();
    await prefs.setString(_localCacheKey, json.encode(payload));
  }

  Future<void> _removeLocalNotification(String notificationId) async {
    final cached = await _loadLocalNotifications();
    final updated = cached.where((n) => n.id != notificationId).toList();
    if (updated.length == cached.length) {
      return;
    }
    await _saveLocalNotifications(updated);
  }

  /// Get mock notifications for development/testing
  List<NotificationModel> _getMockNotifications() {
    // Returning empty list to ensure only real/locally-triggered notifications are shown
    // as requested by the user to avoid stale mock data.
    return [];
  }
}
