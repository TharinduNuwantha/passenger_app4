import 'package:flutter/material.dart';
import '../../models/lounge_booking_models.dart';
import '../../services/lounge_booking_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_style.dart';
import 'lounge_booking_detail_screen.dart';

/// Screen showing all lounge bookings for the current user
class MyLoungeBookingsScreen extends StatefulWidget {
  const MyLoungeBookingsScreen({super.key});

  @override
  State<MyLoungeBookingsScreen> createState() => _MyLoungeBookingsScreenState();
}

class _MyLoungeBookingsScreenState extends State<MyLoungeBookingsScreen>
    with SingleTickerProviderStateMixin {
  final LoungeBookingService _loungeService = LoungeBookingService();
  late TabController _tabController;

  List<LoungeBooking> _upcomingBookings = [];
  List<LoungeBooking> _allBookings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _loungeService.getUpcomingBookings(),
        _loungeService.getMyBookings(),
      ]);

      setState(() {
        _upcomingBookings = results[0];
        _allBookings = results[1];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Lounge Bookings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.upcoming, size: 18),
                  const SizedBox(width: 8),
                  const Text('Upcoming'),
                  if (_upcomingBookings.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_upcomingBookings.length}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 18),
                  SizedBox(width: 8),
                  Text('All'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadBookings,
        color: AppColors.primary,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildBookingsList(_upcomingBookings, isUpcoming: true),
            _buildBookingsList(_allBookings, isUpcoming: false),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsList(List<LoungeBooking> bookings,
      {required bool isUpcoming}) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Failed to load bookings',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadBookings,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUpcoming ? Icons.calendar_today : Icons.history,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              isUpcoming
                  ? 'No upcoming bookings'
                  : 'No booking history',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isUpcoming
                  ? 'Book a lounge and it will appear here'
                  : 'Your past bookings will appear here',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        return _BookingCard(
          booking: bookings[index],
          onTap: () => _navigateToDetail(bookings[index]),
        );
      },
    );
  }

  void _navigateToDetail(LoungeBooking booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoungeBookingDetailScreen(booking: booking),
      ),
    ).then((_) => _loadBookings()); // Refresh on return
  }
}

class _BookingCard extends StatelessWidget {
  final LoungeBooking booking;
  final VoidCallback onTap;

  const _BookingCard({
    required this.booking,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Header with status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _getStatusColor(booking.status).withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(booking.status),
                    size: 20,
                    color: _getStatusColor(booking.status),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    booking.status.displayName,
                    style: TextStyle(
                      color: _getStatusColor(booking.status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    booking.bookingReference,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lounge name
                  Row(
                    children: [
                      Icon(
                        Icons.airline_seat_individual_suite_outlined,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          booking.loungeName ?? 'Lounge',
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Date and time
                  Row(
                    children: [
                      _buildInfoItem(
                        Icons.calendar_today,
                        booking.formattedScheduledArrival,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Duration
                  Row(
                    children: [
                      _buildInfoItem(
                        Icons.timer,
                        booking.pricingType.displayName,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Divider
                  Divider(color: Colors.grey[200]),
                  const SizedBox(height: 8),

                  // Bottom row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Guests count
                      if (booking.guests.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.people,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${booking.guests.length + 1} guests',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        )
                      else
                        const SizedBox.shrink(),

                      // Total amount
                      Text(
                        'LKR ${booking.totalAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(LoungeBookingStatus status) {
    switch (status) {
      case LoungeBookingStatus.pending:
        return Colors.orange;
      case LoungeBookingStatus.confirmed:
        return Colors.blue;
      case LoungeBookingStatus.checkedIn:
        return Colors.green;
      case LoungeBookingStatus.completed:
        return Colors.grey;
      case LoungeBookingStatus.cancelled:
        return Colors.red;
      case LoungeBookingStatus.noShow:
        return Colors.red.shade300;
    }
  }

  IconData _getStatusIcon(LoungeBookingStatus status) {
    switch (status) {
      case LoungeBookingStatus.pending:
        return Icons.schedule;
      case LoungeBookingStatus.confirmed:
        return Icons.check_circle_outline;
      case LoungeBookingStatus.checkedIn:
        return Icons.login;
      case LoungeBookingStatus.completed:
        return Icons.done_all;
      case LoungeBookingStatus.cancelled:
        return Icons.cancel_outlined;
      case LoungeBookingStatus.noShow:
        return Icons.person_off;
    }
  }
}
