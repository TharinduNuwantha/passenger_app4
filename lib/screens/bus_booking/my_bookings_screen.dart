import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../models/booking_models.dart';
import '../../services/booking_service.dart';
import '../../theme/app_colors.dart';
import 'booking_detail_screen.dart';

/// Screen to display user's bookings (upcoming, past, cancelled)
class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  final BookingService _bookingService = BookingService();
  final Logger _logger = Logger();
  late TabController _tabController;

  List<BookingListItem> _upcomingBookings = [];
  List<BookingListItem> _pastBookings = [];
  List<BookingListItem> _cancelledBookings = [];

  bool _isLoadingUpcoming = true;
  bool _isLoadingPast = false;
  bool _isLoadingCancelled = false;

  String? _errorUpcoming;
  String? _errorPast;
  String? _errorCancelled;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadUpcomingBookings();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      switch (_tabController.index) {
        case 0:
          if (_upcomingBookings.isEmpty && !_isLoadingUpcoming) {
            _loadUpcomingBookings();
          }
          break;
        case 1:
          if (_pastBookings.isEmpty && !_isLoadingPast) {
            _loadPastBookings();
          }
          break;
        case 2:
          if (_cancelledBookings.isEmpty && !_isLoadingCancelled) {
            _loadCancelledBookings();
          }
          break;
      }
    }
  }

  Future<void> _loadUpcomingBookings() async {
    setState(() {
      _isLoadingUpcoming = true;
      _errorUpcoming = null;
    });

    try {
      final bookings = await _bookingService.getUpcomingBookings(limit: 20);
      setState(() {
        _upcomingBookings = bookings;
        _isLoadingUpcoming = false;
      });
      _logger.i('Loaded ${bookings.length} upcoming bookings');
    } catch (e) {
      _logger.e('Failed to load upcoming bookings: $e');
      setState(() {
        _errorUpcoming = e.toString().replaceAll('Exception: ', '');
        _isLoadingUpcoming = false;
      });
    }
  }

  Future<void> _loadPastBookings() async {
    setState(() {
      _isLoadingPast = true;
      _errorPast = null;
    });

    try {
      final bookings = await _bookingService.getMyBookings(
        status: 'completed',
        limit: 50,
      );
      setState(() {
        _pastBookings = bookings;
        _isLoadingPast = false;
      });
      _logger.i('Loaded ${bookings.length} past bookings');
    } catch (e) {
      _logger.e('Failed to load past bookings: $e');
      setState(() {
        _errorPast = e.toString().replaceAll('Exception: ', '');
        _isLoadingPast = false;
      });
    }
  }

  Future<void> _loadCancelledBookings() async {
    setState(() {
      _isLoadingCancelled = true;
      _errorCancelled = null;
    });

    try {
      final bookings = await _bookingService.getMyBookings(
        status: 'cancelled',
        limit: 50,
      );
      setState(() {
        _cancelledBookings = bookings;
        _isLoadingCancelled = false;
      });
      _logger.i('Loaded ${bookings.length} cancelled bookings');
    } catch (e) {
      _logger.e('Failed to load cancelled bookings: $e');
      setState(() {
        _errorCancelled = e.toString().replaceAll('Exception: ', '');
        _isLoadingCancelled = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Bookings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.secondary,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildBookingsList(
              bookings: _upcomingBookings,
              isLoading: _isLoadingUpcoming,
              error: _errorUpcoming,
              onRefresh: _loadUpcomingBookings,
              emptyMessage: 'No upcoming bookings',
              emptyIcon: Icons.calendar_today_outlined,
            ),
            _buildBookingsList(
              bookings: _pastBookings,
              isLoading: _isLoadingPast,
              error: _errorPast,
              onRefresh: _loadPastBookings,
              emptyMessage: 'No past trips',
              emptyIcon: Icons.history,
            ),
            _buildBookingsList(
              bookings: _cancelledBookings,
              isLoading: _isLoadingCancelled,
              error: _errorCancelled,
              onRefresh: _loadCancelledBookings,
              emptyMessage: 'No cancelled bookings',
              emptyIcon: Icons.cancel_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsList({
    required List<BookingListItem> bookings,
    required bool isLoading,
    required String? error,
    required VoidCallback onRefresh,
    required String emptyMessage,
    required IconData emptyIcon,
  }) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                error,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRefresh,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (bookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(emptyIcon, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your bookings will appear here',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          return _buildBookingCard(bookings[index]);
        },
      ),
    );
  }

  Widget _buildBookingCard(BookingListItem booking) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookingDetailScreen(bookingId: booking.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      booking.routeName ?? 'Unknown Route',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusChip(booking.bookingStatus),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.confirmation_number_outlined,
                    size: 16,
                    color: AppColors.primary.withOpacity(0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    booking.bookingReference,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (booking.departureDatetime != null)
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppColors.primary.withOpacity(0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDateTime(booking.departureDatetime!),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.event_seat,
                    size: 16,
                    color: AppColors.primary.withOpacity(0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${booking.numberOfSeats ?? 1} seat(s)',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary.withOpacity(0.7),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    booking.formattedTotal,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildPaymentStatusChip(booking.paymentStatus),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(MasterBookingStatus status) {
    Color bgColor;
    Color textColor;
    String text;

    switch (status) {
      case MasterBookingStatus.confirmed:
        bgColor = const Color(0xFF4CAF50).withOpacity(0.1);
        textColor = const Color(0xFF4CAF50);
        text = 'Confirmed';
        break;
      case MasterBookingStatus.pending:
        bgColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        text = 'Pending';
        break;
      case MasterBookingStatus.completed:
        bgColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
        text = 'Completed';
        break;
      case MasterBookingStatus.cancelled:
        bgColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        text = 'Cancelled';
        break;
      case MasterBookingStatus.inProgress:
        bgColor = Colors.purple.withOpacity(0.1);
        textColor = Colors.purple;
        text = 'In Progress';
        break;
      default:
        bgColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
        text = status.displayName;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPaymentStatusChip(MasterPaymentStatus status) {
    Color textColor;
    String text;
    IconData icon;

    switch (status) {
      case MasterPaymentStatus.paid:
        textColor = const Color(0xFF4CAF50);
        text = 'Paid';
        icon = Icons.check_circle_outline;
        break;
      case MasterPaymentStatus.pending:
        textColor = Colors.orange;
        text = 'Payment Pending';
        icon = Icons.schedule;
        break;
      case MasterPaymentStatus.collectOnBus:
        textColor = Colors.blue;
        text = 'Pay on Bus';
        icon = Icons.directions_bus_outlined;
        break;
      case MasterPaymentStatus.free:
        textColor = const Color(0xFF4CAF50);
        text = 'Free';
        icon = Icons.card_giftcard;
        break;
      default:
        textColor = Colors.grey;
        text = status.toJson();
        icon = Icons.info_outline;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: textColor),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${months[dt.month - 1]}, ${hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $period';
  }
}
