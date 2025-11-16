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
    return NotificationModel(
      id: json['id'],
      userId: json['userId'],
      title: json['title'],
      message: json['message'],
      type: json['type'],
      read: json['read'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      actionUrl: json['actionUrl'],
    );
  }
}
