import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_style.dart';
import '../../widgets/blue_header.dart';

class NotificationsScreen extends StatefulWidget {
  final String userId;

  const NotificationsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late NotificationService _notificationService;
  late Future<List<NotificationModel>> _notificationsFuture;
  bool _showUnreadOnly = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService();
    _loadNotifications();
    
    // Auto-refresh notifications every 30 seconds while on this screen
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadNotifications();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _loadNotifications() {
    setState(() {
      _notificationsFuture = _notificationService.fetchNotifications(
        widget.userId,
      );
    });
  }

  void _markAllAsRead() async {
    await _notificationService.markAllAsRead(widget.userId);
    _loadNotifications();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('All notifications marked as read'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: FutureBuilder<List<NotificationModel>>(
              future: _notificationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (snapshot.hasError) {
                  return _buildErrorState();
                }

                List<NotificationModel> notifications = snapshot.data ?? [];
                if (_showUnreadOnly) {
                  notifications = notifications.where((n) => !n.read).toList();
                }

                if (notifications.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    _loadNotifications();
                    await _notificationsFuture;
                  },
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      return NotificationCard(
                        notification: notif,
                        onTap: () {
                          _notificationService.markAsRead(notif.id);
                          setState(() {
                            notif.read = true;
                          });
                        },
                        onDelete: () async {
                          final bool? confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Notification'),
                              content: const Text('Remove this notification permanently?'),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await _notificationService.deleteNotification(notif.id);
                            _loadNotifications();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Notification deleted'),
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return BlueHeader(
      bottomRadius: 0,
      padding: const EdgeInsets.fromLTRB(8, 60, 16, 18),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
        onPressed: () => Navigator.pop(context),
      ),
      title: 'Notifications',
      subtitle: _showUnreadOnly ? 'Showing unread only' : 'Your recent updates',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              _showUnreadOnly ? Icons.filter_list_off_rounded : Icons.filter_list_rounded,
              color: Colors.white,
            ),
            onPressed: () => setState(() => _showUnreadOnly = !_showUnreadOnly),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
            onSelected: (value) async {
              if (value == 'mark_all_read') _markAllAsRead();
              if (value == 'refresh') _loadNotifications();
              if (value == 'simulate') {
                await _notificationService.addLocalNotification(
                  title: 'Welcome!',
                  message: 'Your notification system is now minimal and modern.',
                  type: 'system',
                );
                _loadNotifications();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: ListTile(
                  leading: Icon(Icons.done_all_rounded, size: 20),
                  title: Text('Mark all read'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: ListTile(
                  leading: Icon(Icons.refresh_rounded, size: 20),
                  title: Text('Refresh'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'simulate',
                child: ListTile(
                  leading: Icon(Icons.add_alert_rounded, size: 20),
                  title: Text('Test Notification'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              _showUnreadOnly ? Icons.notifications_none_rounded : Icons.notifications_off_outlined,
              size: 64,
              color: AppColors.primary.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _showUnreadOnly ? 'No unread notifications' : 'No notifications yet',
            style: AppTextStyles.h3.copyWith(color: const Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          Text(
            _showUnreadOnly ? 'You\'re all caught up!' : 'We\'ll notify you when updates arrive',
            style: AppTextStyles.body.copyWith(color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text('Oops! Something went wrong', style: AppTextStyles.h3),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadNotifications,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NotificationCard({
    Key? key,
    required this.notification,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isUnread = !notification.read;
    final Color typeColor = _getTypeColor(notification.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isUnread ? 0.06 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isUnread 
            ? Border.all(color: AppColors.primary.withOpacity(0.1), width: 1)
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onDelete,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getTypeIcon(notification.type),
                      color: typeColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                                  fontSize: 15,
                                  color: isUnread ? const Color(0xFF0F172A) : const Color(0xFF475569),
                                ),
                              ),
                            ),
                            if (isUnread)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.message,
                          style: TextStyle(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatTime(notification.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'booking': return Icons.directions_car_rounded;
      case 'payment': return Icons.account_balance_wallet_rounded;
      case 'offer': return Icons.local_offer_rounded;
      case 'system': return Icons.settings_suggest_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'booking': return const Color(0xFF3B82F6);
      case 'payment': return const Color(0xFF10B981);
      case 'offer': return const Color(0xFFF59E0B);
      case 'system': return const Color(0xFF6366F1);
      default: return AppColors.primary;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${time.day}/${time.month}/${time.year}';
  }
}
