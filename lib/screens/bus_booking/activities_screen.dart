import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../models/unified_booking.dart';
import '../../services/combined_bookings_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_style.dart';
import 'booking_detail_screen.dart';
import '../lounge/lounge_booking_detail_screen.dart';
import '../../widgets/blue_header.dart';

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

  // Pagination state
  static const int _pageSize = 20;

  final ScrollController _upcomingController = ScrollController();
  final ScrollController _completedController = ScrollController();
  final ScrollController _cancelledController = ScrollController();

  int _upcomingBusPage = 1;
  int _upcomingLoungePage = 1;
  bool _hasMoreUpcomingBus = true;
  bool _hasMoreUpcomingLounge = true;

  int _completedBusPage = 1;
  int _completedLoungePage = 1;
  bool _hasMoreCompletedBus = true;
  bool _hasMoreCompletedLounge = true;

  int _cancelledBusPage = 1;
  int _cancelledLoungePage = 1;
  bool _hasMoreCancelledBus = true;
  bool _hasMoreCancelledLounge = true;

  List<UnifiedBooking> _upcomingBookings = [];
  List<UnifiedBooking> _completedBookings = [];
  List<UnifiedBooking> _cancelledBookings = [];

  bool _isLoadingUpcoming = true;
  bool _isLoadingCompleted = false;
  bool _isLoadingCancelled = false;

  bool _isLoadingUpcomingMore = false;
  bool _isLoadingCompletedMore = false;
  bool _isLoadingCancelledMore = false;

  String? _errorUpcoming;
  String? _errorCompleted;
  String? _errorCancelled;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _upcomingController.addListener(_onUpcomingScroll);
    _completedController.addListener(_onCompletedScroll);
    _cancelledController.addListener(_onCancelledScroll);
    _loadUpcomingBookings();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _upcomingController.removeListener(_onUpcomingScroll);
    _completedController.removeListener(_onCompletedScroll);
    _cancelledController.removeListener(_onCancelledScroll);
    _upcomingController.dispose();
    _completedController.dispose();
    _cancelledController.dispose();
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

  bool _canLoadMoreUpcoming() =>
      (_hasMoreUpcomingBus || _hasMoreUpcomingLounge) &&
      !_isLoadingUpcomingMore &&
      !_isLoadingUpcoming;

  bool _canLoadMoreCompleted() =>
      (_hasMoreCompletedBus || _hasMoreCompletedLounge) &&
      !_isLoadingCompletedMore &&
      !_isLoadingCompleted;

  bool _canLoadMoreCancelled() =>
      (_hasMoreCancelledBus || _hasMoreCancelledLounge) &&
      !_isLoadingCancelledMore &&
      !_isLoadingCancelled;

  void _onUpcomingScroll() {
    if (_upcomingController.position.pixels >=
            _upcomingController.position.maxScrollExtent -
                200 &&
        _canLoadMoreUpcoming()) {
      _loadUpcomingBookings(loadMore: true);
    }
  }

  void _onCompletedScroll() {
    if (_completedController.position.pixels >=
            _completedController.position.maxScrollExtent -
                200 &&
        _canLoadMoreCompleted()) {
      _loadCompletedBookings(loadMore: true);
    }
  }

  void _onCancelledScroll() {
    if (_cancelledController.position.pixels >=
            _cancelledController.position.maxScrollExtent -
                200 &&
        _canLoadMoreCancelled()) {
      _loadCancelledBookings(loadMore: true);
    }
  }

  Future<void> _loadUpcomingBookings({bool loadMore = false}) async {
    if (loadMore && !_canLoadMoreUpcoming()) return;

    if (!loadMore) {
      _upcomingBusPage = 1;
      _upcomingLoungePage = 1;
      _hasMoreUpcomingBus = true;
      _hasMoreUpcomingLounge = true;
      _upcomingBookings = [];
    }

    setState(() {
      if (loadMore) {
        _isLoadingUpcomingMore = true;
      } else {
        _isLoadingUpcoming = true;
        _errorUpcoming = null;
      }
    });

    try {
      final result = await _bookingsService.getPagedBookings(
        status: 'upcoming',
        busPage: _upcomingBusPage,
        loungePage: _upcomingLoungePage,
        limit: _pageSize,
      );

      final merged = [
        ..._upcomingBookings,
        ...result.bookings,
      ];
      _sortBookings(merged, 'upcoming');

      setState(() {
        _upcomingBookings = merged;
        _isLoadingUpcoming = false;
        _isLoadingUpcomingMore = false;
        _hasMoreUpcomingBus = result.hasMoreBus;
        _hasMoreUpcomingLounge = result.hasMoreLounge;
        if (result.hasMoreBus) _upcomingBusPage += 1;
        if (result.hasMoreLounge) _upcomingLoungePage += 1;
      });
      _logger.i(
        'Loaded ${result.bookings.length} upcoming bookings (total ${merged.length})',
      );
    } catch (e) {
      _logger.e('Failed to load upcoming bookings: $e');
      setState(() {
        _errorUpcoming = e.toString().replaceAll('Exception: ', '');
        _isLoadingUpcoming = false;
        _isLoadingUpcomingMore = false;
      });
    }
  }

  Future<void> _loadCompletedBookings({bool loadMore = false}) async {
    if (loadMore && !_canLoadMoreCompleted()) return;

    if (!loadMore) {
      _completedBusPage = 1;
      _completedLoungePage = 1;
      _hasMoreCompletedBus = true;
      _hasMoreCompletedLounge = true;
      _completedBookings = [];
    }

    setState(() {
      if (loadMore) {
        _isLoadingCompletedMore = true;
      } else {
        _isLoadingCompleted = true;
        _errorCompleted = null;
      }
    });

    try {
      final result = await _bookingsService.getPagedBookings(
        status: 'completed',
        busPage: _completedBusPage,
        loungePage: _completedLoungePage,
        limit: _pageSize,
      );

      final merged = [
        ..._completedBookings,
        ...result.bookings,
      ];
      _sortBookings(merged, 'completed');

      setState(() {
        _completedBookings = merged;
        _isLoadingCompleted = false;
        _isLoadingCompletedMore = false;
        _hasMoreCompletedBus = result.hasMoreBus;
        _hasMoreCompletedLounge = result.hasMoreLounge;
        if (result.hasMoreBus) _completedBusPage += 1;
        if (result.hasMoreLounge) _completedLoungePage += 1;
      });
      _logger.i(
        'Loaded ${result.bookings.length} completed bookings (total ${merged.length})',
      );
    } catch (e) {
      _logger.e('Failed to load completed bookings: $e');
      setState(() {
        _errorCompleted = e.toString().replaceAll('Exception: ', '');
        _isLoadingCompleted = false;
        _isLoadingCompletedMore = false;
      });
    }
  }

  Future<void> _loadCancelledBookings({bool loadMore = false}) async {
    if (loadMore && !_canLoadMoreCancelled()) return;

    if (!loadMore) {
      _cancelledBusPage = 1;
      _cancelledLoungePage = 1;
      _hasMoreCancelledBus = true;
      _hasMoreCancelledLounge = true;
      _cancelledBookings = [];
    }

    setState(() {
      if (loadMore) {
        _isLoadingCancelledMore = true;
      } else {
        _isLoadingCancelled = true;
        _errorCancelled = null;
      }
    });

    try {
      final result = await _bookingsService.getPagedBookings(
        status: 'cancelled',
        busPage: _cancelledBusPage,
        loungePage: _cancelledLoungePage,
        limit: _pageSize,
      );

      final merged = [
        ..._cancelledBookings,
        ...result.bookings,
      ];
      _sortBookings(merged, 'cancelled');

      setState(() {
        _cancelledBookings = merged;
        _isLoadingCancelled = false;
        _isLoadingCancelledMore = false;
        _hasMoreCancelledBus = result.hasMoreBus;
        _hasMoreCancelledLounge = result.hasMoreLounge;
        if (result.hasMoreBus) _cancelledBusPage += 1;
        if (result.hasMoreLounge) _cancelledLoungePage += 1;
      });
      _logger.i(
        'Loaded ${result.bookings.length} cancelled bookings (total ${merged.length})',
      );
    } catch (e) {
      _logger.e('Failed to load cancelled bookings: $e');
      setState(() {
        _errorCancelled = e.toString().replaceAll('Exception: ', '');
        _isLoadingCancelled = false;
        _isLoadingCancelledMore = false;
      });
    }
  }

  void _sortBookings(List<UnifiedBooking> bookings, String status) {
    if (status == 'upcoming') {
      bookings.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    } else if (status == 'completed') {
      bookings.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    } else {
      bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BlueHeader(
              padding: EdgeInsets.fromLTRB(20, topInset + 18, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Bookings',
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.textLight,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track your trips and lounge visits',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textLight.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 29),
                      indicator: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorPadding: const EdgeInsets.all(4),
                      labelColor: AppColors.primary,
                      unselectedLabelColor:
                          AppColors.textLight.withOpacity(0.85),
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.schedule, size: 14),
                              SizedBox(width: 3),
                              Text('Upcoming'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline, size: 14),
                              SizedBox(width: 3),
                              Text('Completed'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cancel_outlined, size: 14),
                              SizedBox(width: 3),
                              Text('Cancelled'),
                            ],
                          ),
                        ),
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
                      isLoadingMore: _isLoadingUpcomingMore,
                      error: _errorUpcoming,
                      onRefresh: _loadUpcomingBookings,
                      emptyTitle: 'No upcoming trips',
                      emptySubtitle: 'Book a bus or lounge to see it here',
                      emptyIcon: Icons.calendar_today_outlined,
                      controller: _upcomingController,
                      canLoadMore:
                          _hasMoreUpcomingBus || _hasMoreUpcomingLounge,
                    ),
                    _buildBookingsList(
                      bookings: _completedBookings,
                      isLoading: _isLoadingCompleted,
                      isLoadingMore: _isLoadingCompletedMore,
                      error: _errorCompleted,
                      onRefresh: _loadCompletedBookings,
                      emptyTitle: 'No completed trips',
                      emptySubtitle: 'Your travel history will appear here',
                      emptyIcon: Icons.history,
                      controller: _completedController,
                      canLoadMore:
                          _hasMoreCompletedBus || _hasMoreCompletedLounge,
                    ),
                    _buildBookingsList(
                      bookings: _cancelledBookings,
                      isLoading: _isLoadingCancelled,
                      isLoadingMore: _isLoadingCancelledMore,
                      error: _errorCancelled,
                      onRefresh: _loadCancelledBookings,
                      emptyTitle: 'No cancelled bookings',
                      emptySubtitle: 'Cancelled trips will appear here',
                      emptyIcon: Icons.cancel_outlined,
                      controller: _cancelledController,
                      canLoadMore:
                          _hasMoreCancelledBus || _hasMoreCancelledLounge,
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
    required bool isLoadingMore,
    required String? error,
    required VoidCallback onRefresh,
    required String emptyTitle,
    required String emptySubtitle,
    required IconData emptyIcon,
    required ScrollController controller,
    required bool canLoadMore,
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
        controller: controller,
        itemCount: bookings.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= bookings.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: canLoadMore
                    ? const CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 3,
                      )
                    : const SizedBox.shrink(),
              ),
            );
          }
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
