class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type; // 'booking', 'promo', 'alert'
  bool read;
  final DateTime createdAt;
  final String? actionUrl;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.read = false,
    required this.createdAt,
    this.actionUrl,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final rawCreatedAt =
        json['createdAt'] ?? json['created_at'] ?? json['timestamp'];
    DateTime createdAt;
    if (rawCreatedAt is DateTime) {
      createdAt = rawCreatedAt;
    } else if (rawCreatedAt is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(rawCreatedAt);
    } else if (rawCreatedAt is String) {
      createdAt = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    return NotificationModel(
      id: (json['id'] ?? '').toString(),
      userId: (json['userId'] ?? json['user_id'] ?? '').toString(),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'info',
      read: json['read'] ?? false,
      createdAt: createdAt,
      actionUrl: json['actionUrl'] ?? json['action_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'read': read,
      'createdAt': createdAt.toIso8601String(),
      'actionUrl': actionUrl,
    };
  }
}
