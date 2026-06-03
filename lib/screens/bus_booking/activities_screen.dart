import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../models/unified_booking.dart';
import '../../services/combined_bookings_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_style.dart';
import '../../core/theme/app_theme.dart';
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
  final ScrollController _notCompletedController = ScrollController();
  final ScrollController _completedController = ScrollController();
  final ScrollController _cancelledController = ScrollController();

  int _upcomingBusPage = 1;
  int _upcomingLoungePage = 1;
  bool _hasMoreUpcomingBus = true;
  bool _hasMoreUpcomingLounge = true;

  int _notCompletedBusPage = 1;
  int _notCompletedLoungePage = 1;
  bool _hasMoreNotCompletedBus = true;
  bool _hasMoreNotCompletedLounge = true;

  int _completedBusPage = 1;
  int _completedLoungePage = 1;
  bool _hasMoreCompletedBus = true;
  bool _hasMoreCompletedLounge = true;

  int _cancelledBusPage = 1;
  int _cancelledLoungePage = 1;
  bool _hasMoreCancelledBus = true;
  bool _hasMoreCancelledLounge = true;

  List<UnifiedBooking> _upcomingBookings = [];
  List<UnifiedBooking> _notCompletedBookings = [];
  List<UnifiedBooking> _completedBookings = [];
  List<UnifiedBooking> _cancelledBookings = [];

  bool _isLoadingUpcoming = true;
  bool _isLoadingNotCompleted = false;
  bool _isLoadingCompleted = false;
  bool _isLoadingCancelled = false;

  bool _isLoadingUpcomingMore = false;
  bool _isLoadingNotCompletedMore = false;
  bool _isLoadingCompletedMore = false;
  bool _isLoadingCancelledMore = false;

  String? _errorUpcoming;
  String? _errorNotCompleted;
  String? _errorCompleted;
  String? _errorCancelled;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _upcomingController.addListener(_onUpcomingScroll);
    _notCompletedController.addListener(_onNotCompletedScroll);
    _completedController.addListener(_onCompletedScroll);
    _cancelledController.addListener(_onCancelledScroll);
    _loadUpcomingBookings();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _upcomingController.removeListener(_onUpcomingScroll);
    _notCompletedController.removeListener(_onNotCompletedScroll);
    _completedController.removeListener(_onCompletedScroll);
    _cancelledController.removeListener(_onCancelledScroll);
    _upcomingController.dispose();
    _notCompletedController.dispose();
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
          if (_notCompletedBookings.isEmpty &&
              !_isLoadingNotCompleted &&
              _errorNotCompleted == null) {
            _loadNotCompletedBookings();
          }
          break;
        case 2:
          if (_completedBookings.isEmpty &&
              !_isLoadingCompleted &&
              _errorCompleted == null) {
            _loadCompletedBookings();
          }
          break;
        case 3:
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

  bool _canLoadMoreNotCompleted() =>
      (_hasMoreNotCompletedBus || _hasMoreNotCompletedLounge) &&
      !_isLoadingNotCompletedMore &&
      !_isLoadingNotCompleted;

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

  void _onNotCompletedScroll() {
    if (_notCompletedController.position.pixels >=
            _notCompletedController.position.maxScrollExtent -
                200 &&
        _canLoadMoreNotCompleted()) {
      _loadNotCompletedBookings(loadMore: true);
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

  Future<void> _loadNotCompletedBookings({bool loadMore = false}) async {
    if (loadMore && !_canLoadMoreNotCompleted()) return;

    if (!loadMore) {
      _notCompletedBusPage = 1;
      _notCompletedLoungePage = 1;
      _hasMoreNotCompletedBus = true;
      _hasMoreNotCompletedLounge = true;
      _notCompletedBookings = [];
    }

    setState(() {
      if (loadMore) {
        _isLoadingNotCompletedMore = true;
      } else {
        _isLoadingNotCompleted = true;
        _errorNotCompleted = null;
      }
    });

    try {
      final result = await _bookingsService.getPagedBookings(
        status: 'not_completed',
        busPage: _notCompletedBusPage,
        loungePage: _notCompletedLoungePage,
        limit: _pageSize,
      );

      final merged = [
        ..._notCompletedBookings,
        ...result.bookings,
      ];
      _sortBookings(merged, 'not_completed');

      setState(() {
        _notCompletedBookings = merged;
        _isLoadingNotCompleted = false;
        _isLoadingNotCompletedMore = false;
        _hasMoreNotCompletedBus = result.hasMoreBus;
        _hasMoreNotCompletedLounge = result.hasMoreLounge;
        if (result.hasMoreBus) _notCompletedBusPage += 1;
        if (result.hasMoreLounge) _notCompletedLoungePage += 1;
      });
      _logger.i(
        'Loaded ${result.bookings.length} not completed bookings (total ${merged.length})',
      );
    } catch (e) {
      _logger.e('Failed to load not completed bookings: $e');
      setState(() {
        _errorNotCompleted = e.toString().replaceAll('Exception: ', '');
        _isLoadingNotCompleted = false;
        _isLoadingNotCompletedMore = false;
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

  String _formatLocationName(String location) {
    if (location.isEmpty || location == 'null') return 'Unknown';
    // Handle map coordinates gracefully
    final RegExp coordRegExp = RegExp(r'^-?\d{1,3}\.\d+\s*,\s*-?\d{1,3}\.\d+$');
    if (coordRegExp.hasMatch(location.trim())) {
      return 'Map Location';
    }
    
    // Clean up long addresses by taking the first significant part
    List<String> parts = location.split(',');
    if (parts.isNotEmpty) {
      String mainPart = parts[0].trim();
      mainPart = mainPart
          .replaceAll(RegExp(r'\s+(Railway|Bus|Train)\s+Station', caseSensitive: false), '')
          .replaceAll(RegExp(r'\s+Bus\s+Stand', caseSensitive: false), '')
          .replaceAll(RegExp(r'\s+Terminal', caseSensitive: false), '')
          .trim();
      if (mainPart.length > 2) {
        return mainPart;
      }
    }
    return location;
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: context.colors.scaffoldBackground,
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
                              Icon(Icons.warning_amber_rounded, size: 14),
                              SizedBox(width: 3),
                              Text('Not Completed'),
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
                decoration: BoxDecoration(
                  color: context.colors.scaffoldBackground,
                  borderRadius: const BorderRadius.only(
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
                      bookings: _notCompletedBookings,
                      isLoading: _isLoadingNotCompleted,
                      isLoadingMore: _isLoadingNotCompletedMore,
                      error: _errorNotCompleted,
                      onRefresh: _loadNotCompletedBookings,
                      emptyTitle: 'No pending trips',
                      emptySubtitle: 'Expired but incomplete trips appear here',
                      emptyIcon: Icons.warning_amber_rounded,
                      controller: _notCompletedController,
                      canLoadMore:
                          _hasMoreNotCompletedBus || _hasMoreNotCompletedLounge,
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
              style: TextStyle(color: context.colors.textSecondary, fontSize: 14),
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
                  color: Colors.red.shade50.withOpacity(context.isDarkMode ? 0.15 : 1),
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
                  color: context.colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: TextStyle(color: context.colors.textSecondary, fontSize: 14),
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
                  color: AppColors.primary.withOpacity(context.isDarkMode ? 0.15 : 0.1),
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
                  color: context.colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                emptySubtitle,
                style: TextStyle(color: context.colors.textTertiary, fontSize: 14),
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
    final isCombined = booking.type == UnifiedBookingType.combined;

    // Color theming based on type
    final Color typeColor = isCombined
        ? const Color(0xFF0D9488) // Teal
        : (isBus ? AppColors.primary : const Color(0xFF7C3AED));
    final Color typeBgColor = isCombined
        ? const Color(0xFF0D9488).withOpacity(0.1)
        : (isBus
            ? AppColors.primary.withOpacity(0.1)
            : const Color(0xFF7C3AED).withOpacity(0.1));
    final IconData typeIcon = isCombined
        ? Icons.commute
        : (isBus ? Icons.directions_bus : Icons.weekend);

    String fromLoc = 'Unknown';
    String toLoc = '';
    
    if (booking.type == UnifiedBookingType.bus || booking.type == UnifiedBookingType.combined) {
      if (booking.busBooking != null) {
        fromLoc = booking.busBooking!.searchFromLounge?.isNotEmpty == true 
            ? booking.busBooking!.searchFromLounge! 
            : '';
        toLoc = booking.busBooking!.searchToLounge?.isNotEmpty == true 
            ? booking.busBooking!.searchToLounge! 
            : '';
        
        if (fromLoc == 'Unknown' || fromLoc.isEmpty) {
           final parts = booking.title.split(' - ');
           if (parts.length >= 2) {
             fromLoc = parts[0];
             toLoc = parts[1];
           } else {
             fromLoc = booking.title;
           }
        }
      } else {
         final parts = booking.title.split(' - ');
         if (parts.length >= 2) {
           fromLoc = parts[0];
           toLoc = parts[1];
         } else {
           fromLoc = booking.title;
         }
      }
    } else {
      fromLoc = booking.title;
    }

    fromLoc = _formatLocationName(fromLoc);
    if (toLoc.isNotEmpty) toLoc = _formatLocationName(toLoc);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: context.colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        shadowColor: context.colors.shadowColor,
        child: InkWell(
          onTap: () => _navigateToDetail(booking),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.colors.cardBorder),
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
                            booking.type.displayName,
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
                    Icon(Icons.chevron_right, color: context.colors.iconInactive),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Big Eye-Catching Locations ──
                if (toLoc.isNotEmpty)
                  Row(
                    children: [
                      // FROM
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fromLoc,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: context.colors.textPrimary,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.circle, size: 6, color: typeColor),
                                const SizedBox(width: 4),
                                Text(
                                  booking.formattedTime,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: context.colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // ARROW
                      Expanded(
                        flex: 1,
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: context.colors.iconInactive.withOpacity(0.5),
                          size: 24,
                        ),
                      ),
                      
                      // TO
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              toLoc,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: context.colors.textPrimary,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(Icons.location_on, size: 10, color: context.colors.textTertiary),
                                const SizedBox(width: 4),
                                Text(
                                  'Drop-off',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: context.colors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  // Lounge Only case
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fromLoc,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: context.colors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.circle, size: 6, color: typeColor),
                          const SizedBox(width: 4),
                          Text(
                            booking.formattedTime,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: context.colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                const SizedBox(height: 16),

                // ── Date, Reference and Amount row ──
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: context.colors.inputBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.colors.dividerColor.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      // Date & Reference
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.formattedDate,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: context.colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.confirmation_number_outlined,
                                  size: 12,
                                  color: context.colors.textTertiary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Ref: ${booking.bookingReference}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.colors.textSecondary,
                                    fontWeight: FontWeight.w500,
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
                        height: 30,
                        color: context.colors.dividerColor,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                      ),

                      // Amount & Subtitle
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            booking.formattedTotal,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: context.colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            booking.subtitle,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: typeColor,
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
      case UnifiedBookingStatus.notCompleted:
        bgColor = const Color(0xFFFEF3C7); // Amber background (similar to inProgress/warning)
        textColor = const Color(0xFFB45309); // Dark amber text
        text = 'Not Completed';
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
    if ((booking.type == UnifiedBookingType.bus || booking.type == UnifiedBookingType.combined) && booking.busBooking != null) {
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
