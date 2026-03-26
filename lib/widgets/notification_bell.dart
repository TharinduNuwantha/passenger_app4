import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';

class NotificationBell extends StatefulWidget {
  final String userId;
  final VoidCallback onTap;
  final int? initialCount;

  const NotificationBell({
    Key? key,
    required this.userId,
    required this.onTap,
    this.initialCount,
  }) : super(key: key);

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  late NotificationService _notificationService;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService();
    _unreadCount = widget.initialCount ?? 0;
    if (widget.initialCount == null) {
      _loadUnreadCount();
    }
  }

  @override
  void didUpdateWidget(NotificationBell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCount != oldWidget.initialCount && widget.initialCount != null) {
      setState(() {
        _unreadCount = widget.initialCount!;
      });
    }
  }

  Future<void> _loadUnreadCount() async {
    if (widget.userId.isEmpty) return;
    final count = await _notificationService.getUnreadCount(widget.userId);
    if (mounted) {
      setState(() {
        _unreadCount = count;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Badge(
          isLabelVisible: _unreadCount > 0,
          label: Text(
            _unreadCount > 9 ? '9+' : '$_unreadCount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xFFFF4B4B),
          largeSize: 18,
          child: Icon(
            Icons.notifications_none_rounded,
            color: AppColors.primary,
            size: 24,
          ),
        ),
      ),
    );
  }
}
