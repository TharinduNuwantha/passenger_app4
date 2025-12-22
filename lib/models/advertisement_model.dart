class Advertisement {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String? targetUrl;
  final int displayOrder;
  final int priority;
  final bool active;
  final DateTime startDate;
  final DateTime endDate;

  Advertisement({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.targetUrl,
    required this.displayOrder,
    required this.active,
    required this.startDate,
    required this.endDate,
    required this.priority,
  });

  factory Advertisement.fromJson(Map<String, dynamic> json) {
    return Advertisement(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      targetUrl: json['targetUrl'],
      displayOrder: json['displayOrder'],
      active: json['active'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      priority: json['priority'] ?? 0,
    );
  }
}
