import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../models/unified_booking.dart';
import '../../services/combined_bookings_service.dart';
import '../../theme/app_colors.dart';
import 'booking_detail_screen.dart';
import '../lounge/lounge_booking_detail_screen.dart';

/// Redesigned Activities/Bookings screen with tabs for Upcoming, Completed, Cancelled
class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen>
    with SingleTickerProviderStateMixin {
  final CombinedBookingsService _bookingsService = CombinedBookingsService();
  final Logger _logger = Logger();
  late TabController _tabController;

  List<UnifiedBooking> _upcomingBookings = [];
  List<UnifiedBooking> _completedBookings = [];
  List<UnifiedBooking> _cancelledBookings = [];

  bool _isLoadingUpcoming = true;
  bool _isLoadingCompleted = false;
  bool _isLoadingCancelled = false;

  String? _errorUpcoming;
  String? _errorCompleted;
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
          if (_upcomingBookings.isEmpty &&
              !_isLoadingUpcoming &&
              _errorUpcoming == null) {
            _loadUpcomingBookings();
          }
          break;
        case 1:
          if (_completedBookings.isEmpty &&
              !_isLoadingCompleted &&
              _errorCompleted == null) {
            _loadCompletedBookings();
          }
          break;
        case 2:
          if (_cancelledBookings.isEmpty &&
              !_isLoadingCancelled &&
              _errorCancelled == null) {
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
      final bookings = await _bookingsService.getUpcomingBookings();
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

  Future<void> _loadCompletedBookings() async {
    setState(() {
      _isLoadingCompleted = true;
      _errorCompleted = null;
    });

    try {
      final bookings = await _bookingsService.getCompletedBookings();
      setState(() {
        _completedBookings = bookings;
        _isLoadingCompleted = false;
      });
      _logger.i('Loaded ${bookings.length} completed bookings');
    } catch (e) {
      _logger.e('Failed to load completed bookings: $e');
      setState(() {
        _errorCompleted = e.toString().replaceAll('Exception: ', '');
        _isLoadingCompleted = false;
      });
    }
  }

  Future<void> _loadCancelledBookings() async {
    setState(() {
      _isLoadingCancelled = true;
      _errorCancelled = null;
    });

    try {
      final bookings = await _bookingsService.getCancelledBookings();
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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My Bookings',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track your trips and lounge visits',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.all(4),
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.white.withOpacity(0.8),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.schedule, size: 16),
                        const SizedBox(width: 6),
                        const Text('Upcoming'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline, size: 16),
                        const SizedBox(width: 6),
                        const Text('Completed'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cancel_outlined, size: 16),
                        const SizedBox(width: 6),
                        const Text('Cancelled'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tab Content
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
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
                      emptyTitle: 'No upcoming trips',
                      emptySubtitle: 'Book a bus or lounge to see it here',
                      emptyIcon: Icons.calendar_today_outlined,
                    ),
                    _buildBookingsList(
                      bookings: _completedBookings,
                      isLoading: _isLoadingCompleted,
                      error: _errorCompleted,
                      onRefresh: _loadCompletedBookings,
                      emptyTitle: 'No completed trips',
                      emptySubtitle: 'Your travel history will appear here',
                      emptyIcon: Icons.history,
                    ),
                    _buildBookingsList(
                      bookings: _cancelledBookings,
                      isLoading: _isLoadingCancelled,
                      error: _errorCancelled,
                      onRefresh: _loadCancelledBookings,
                      emptyTitle: 'No cancelled bookings',
                      emptySubtitle: 'Cancelled trips will appear here',
                      emptyIcon: Icons.cancel_outlined,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsList({
    required List<UnifiedBooking> bookings,
    required bool isLoading,
    required String? error,
    required VoidCallback onRefresh,
    required String emptyTitle,
    required String emptySubtitle,
    required IconData emptyIcon,
  }) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading bookings...',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red.shade400,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Something went wrong',
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (bookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  emptyIcon,
                  size: 56,
                  color: AppColors.primary.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                emptyTitle,
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                emptySubtitle,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                textAlign: TextAlign.center,
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          return _buildBookingCard(bookings[index]);
        },
      ),
    );
  }

  Widget _buildBookingCard(UnifiedBooking booking) {
    final isBus = booking.type == UnifiedBookingType.bus;
    final isLounge = booking.type == UnifiedBookingType.lounge;

    // Color theming based on type
    final Color typeColor = isBus ? AppColors.primary : const Color(0xFF7C3AED);
    final Color typeBgColor = isBus
        ? AppColors.primary.withOpacity(0.1)
        : const Color(0xFF7C3AED).withOpacity(0.1);
    final IconData typeIcon = isBus ? Icons.directions_bus : Icons.weekend;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.1),
        child: InkWell(
          onTap: () => _navigateToDetail(booking),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Type badge + Status + Arrow
                Row(
                  children: [
                    // Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: typeBgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(typeIcon, size: 14, color: typeColor),
                          const SizedBox(width: 4),
                          Text(
                            isBus ? 'Bus' : 'Lounge',
                            style: TextStyle(
                              color: typeColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    _buildStatusBadge(booking.status),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right, color: Colors.grey.shade400),
                  ],
                ),

                const SizedBox(height: 14),

                // Title
                Text(
                  booking.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // Reference
                Row(
                  children: [
                    Icon(
                      Icons.confirmation_number_outlined,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      booking.bookingReference,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Date/Time and Amount row
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      // Date & Time
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.access_time,
                                size: 18,
                                color: typeColor,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking.formattedDate,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                                Text(
                                  booking.formattedTime,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Divider
                      Container(
                        width: 1,
                        height: 36,
                        color: Colors.grey.shade300,
                      ),

                      // Amount
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  booking.formattedTotal,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                                Text(
                                  booking.subtitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(UnifiedBookingStatus status) {
    Color bgColor;
    Color textColor;
    String text;

    switch (status) {
      case UnifiedBookingStatus.upcoming:
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF166534);
        text = 'Upcoming';
        break;
      case UnifiedBookingStatus.inProgress:
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFF92400E);
        text = 'In Progress';
        break;
      case UnifiedBookingStatus.completed:
        bgColor = const Color(0xFFDBEAFE);
        textColor = const Color(0xFF1E40AF);
        text = 'Completed';
        break;
      case UnifiedBookingStatus.cancelled:
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFF991B1B);
        text = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
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

  void _navigateToDetail(UnifiedBooking booking) {
    if (booking.type == UnifiedBookingType.bus && booking.busBooking != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookingDetailScreen(bookingId: booking.id),
        ),
      );
    } else if (booking.type == UnifiedBookingType.lounge &&
        booking.loungeBooking != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              LoungeBookingDetailScreen(booking: booking.loungeBooking!),
        ),
      );
    }
  }
}
