import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_style.dart';
import '../../providers/search_provider.dart';
import '../../models/search_models.dart';
import 'seat_booking_screen_v2.dart';
import '../../core/theme/app_theme.dart';


class BusListScreen extends StatefulWidget {
  final DateTime? date;
  final String pickup;
  final String drop;
  final double? fromLat;
  final double? fromLng;
  final double? toLat;
  final double? toLng;

  const BusListScreen({
    super.key,
    this.date,
    required this.pickup,
    required this.drop,
    this.fromLat,
    this.fromLng,
    this.toLat,
    this.toLng,
    required stop,
    DateTime? returnDate,
  });

  @override
  State<BusListScreen> createState() => _BusListScreenState();
}

class _BusListScreenState extends State<BusListScreen> {
  String _selectedBusType = 'All';
  String _selectedViewOption =
      'Direct'; // Smart view option: Direct, Transit, Quickest, Cheapest
  final Set<String> _expandedCards =
      {}; // Track which cards are expanded for route info

  @override
  void initState() {
    super.initState();
    // Perform search when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performSearch();
    });
  }

  Future<void> _performSearch({double? radiusLimit = 3000.0}) async {
    final searchProvider = context.read<SearchProvider>();
    await searchProvider.searchTrips(
      from: widget.pickup,
      to: widget.drop,
      datetime: widget.date,
      limit: 50,
      fromLat: widget.fromLat,
      fromLng: widget.fromLng,
      toLat: widget.toLat,
      toLng: widget.toLng,
      radiusLimit: radiusLimit,
    );

    if (radiusLimit == 3000.0 &&
        searchProvider.errorMessage == null &&
        searchProvider.tripResults.isEmpty &&
        mounted) {
      _showExpandSearchDialog();
    }
  }

  void _showExpandSearchDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          backgroundColor: context.colors.dialogBackground,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.travel_explore_rounded,
                    color: AppColors.primary,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Expand Search Radius?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'No direct routes or lounges were found within a 3km radius of your locations. Would you like to expand the search radius to 15km to search a wider area?',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: context.colors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: context.colors.cardBorder),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: context.colors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _performSearch(radiusLimit: 15000.0);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Expand',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = widget.date != null
        ? "${widget.date!.day} ${_getMonthName(widget.date!.month)}"
        : "Select Date";

    return Scaffold(
      backgroundColor: context.colors.scaffoldBackground,
      body: Consumer<SearchProvider>(
        builder: (context, searchProvider, child) {
          List<TripResult> trips = searchProvider.tripResults;

          // Find nearest lounges among all direct trips
          String? nearestFromLounge;
          double minFromDist = double.infinity;
          String? nearestToLounge;
          double minToDist = double.infinity;

          for (final t in trips) {
            if (!t.isTransit) {
              if (t.fromLounge != null && t.fromLoungeDistKm < minFromDist) {
                minFromDist = t.fromLoungeDistKm;
                nearestFromLounge = t.fromLounge;
              }
              if (t.toLounge != null && t.toLoungeDistKm < minToDist) {
                minToDist = t.toLoungeDistKm;
                nearestToLounge = t.toLounge;
              }
            }
          }

          if (_selectedViewOption == 'Direct') {
            trips = trips.where((t) => !t.isTransit).toList();
            // Filter to show only trips associated with the nearest lounge
            trips = trips.where((t) {
              bool keep = true;
              if (nearestFromLounge != null &&
                  t.fromLounge != null &&
                  t.fromLounge != nearestFromLounge) {
                keep = false;
              }
              if (nearestToLounge != null &&
                  t.toLounge != null &&
                  t.toLounge != nearestToLounge) {
                keep = false;
              }
              return keep;
            }).toList();
          } else if (_selectedViewOption == 'Transit') {
            trips = trips.where((t) => t.isTransit).toList();
          }

          if (_selectedBusType != 'All') {
            trips = trips
                .where((trip) => trip.busType == _selectedBusType)
                .toList();
          }

          // Sort by departure time or specific criteria
          if (_selectedViewOption == 'Quickest') {
            trips.sort(
              (a, b) => a.durationMinutes.compareTo(b.durationMinutes),
            );
          } else if (_selectedViewOption == 'Cheapest') {
            trips.sort((a, b) => a.fare.compareTo(b.fare));
          } else {
            trips.sort((a, b) => a.departureTime.compareTo(b.departureTime));
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Premium Custom App Bar
              _buildModernAppBar(context, searchProvider),

              // 2. Body Content
              SliverToBoxAdapter(
                child: searchProvider.isSearching
                    ? _buildLoadingState()
                    : searchProvider.errorMessage != null
                    ? _buildErrorState(searchProvider)
                    : trips.isEmpty
                    ? _buildEmptyState(searchProvider)
                    : _buildResultsHeader(trips.length),
              ),

              if (!searchProvider.isSearching &&
                  searchProvider.errorMessage == null &&
                  trips.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildTripCard(context, trips[index]),
                      ),
                      childCount: trips.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModernAppBar(
    BuildContext context,
    SearchProvider searchProvider,
  ) {
    return SliverAppBar(
      expandedHeight: 260,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primary,
      centerTitle: true,
      title: LayoutBuilder(
        builder: (context, constraints) {
          final top = constraints.biggest.height;
          final isCollapsed =
              top <= (MediaQuery.of(context).padding.top + kToolbarHeight + 10);

          return AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isCollapsed ? 1.0 : 0.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      _cleanLocation(widget.pickup),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.0),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white70,
                      size: 12,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      _cleanLocation(widget.drop),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primary.withBlue(160)],
            ),
          ),
          child: Stack(
            children: [
              // Premium abstract shapes for depth
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 65, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Route Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Origin',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _cleanLocation(widget.pickup),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.swap_horiz_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Destination',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _cleanLocation(widget.drop),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Date & Passenger Summary
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.date != null
                                ? DateFormat(
                                    'EEEE, MMMM d',
                                  ).format(widget.date!)
                                : 'Select Date',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 1,
                            height: 14,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.person_outline_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '1 Adult',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
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
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          height: 70,
          padding: const EdgeInsets.only(top: 15),
          decoration: BoxDecoration(
            color: context.colors.scaffoldBackground,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(35),
              topRight: Radius.circular(35),
            ),
            boxShadow: [
              BoxShadow(
                color: context.colors.shadowColor.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: _buildQuickFilters(),
        ),
      ),
    );
  }

  Widget _buildQuickFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildModernFilterChip('Direct', Icons.bolt_rounded),
          _buildModernFilterChip('Transit', Icons.alt_route_rounded),
          _buildModernFilterChip('Quickest', Icons.timer_rounded),
          _buildModernFilterChip('Cheapest', Icons.payments_rounded),
        ],
      ),
    );
  }

  Widget _buildModernFilterChip(String label, IconData icon) {
    final bool isSelected = _selectedViewOption == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedViewOption = label),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : context.colors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.3)
                  : context.colors.shadowColor.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : context.colors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$count Buses Available',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: context.colors.textPrimary,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: context.colors.cardBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.colors.cardBorder),
            ),
            child: Row(
              children: [
                Text(
                  'Sort',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: context.colors.iconPrimary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(strokeWidth: 3),
            const SizedBox(height: 20),
            Text(
              'Finding your perfect ride...',
              style: TextStyle(fontWeight: FontWeight.w600, color: context.colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(SearchProvider provider) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 80,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 20),
          Text(
            'Oops! Something went wrong',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.colors.textPrimary),
          ),
          const SizedBox(height: 10),
          Text(
            provider.errorMessage ?? 'Unknown error',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.colors.textSecondary),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => _performSearch(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(SearchProvider provider) {
    final response = provider.searchResponse;
    final bool hasRouteOnlyDiscovery = response?.hasRouteOnlyDiscovery ?? false;
    final bool hasPartialCoverage = response?.hasPartialCoverage ?? false;
    final String message = hasPartialCoverage
        ? 'A route exists, but only partial coverage is available. A remaining gap of ${response?.remainingGapKm.toStringAsFixed(1) ?? '0.0'} km remains.'
        : hasRouteOnlyDiscovery
        ? 'A route is available, but no buses are scheduled for this date. Try a different date or check back soon.'
        : 'We couldn\'t find any buses for your search criteria on this date.';

    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            hasRouteOnlyDiscovery || hasPartialCoverage
                ? Icons.info_outline
                : Icons.directions_bus_filled_outlined,
            size: 80,
            color: hasRouteOnlyDiscovery || hasPartialCoverage
                ? AppColors.primary
                : context.colors.iconInactive,
          ),
          const SizedBox(height: 20),
          Text(
            'No Buses Found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.colors.textPrimary),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.colors.textSecondary),
          ),
          const SizedBox(height: 30),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Modify Search'),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(BuildContext context, TripResult trip) {
    // Check if the trip is today
    final now = DateTime.now();
    final tripDate = trip.departureTime;
    final isToday =
        tripDate.year == now.year &&
        tripDate.month == now.month &&
        tripDate.day == now.day;
    final isTomorrow =
        tripDate.year == now.year &&
        tripDate.month == now.month &&
        tripDate.day == now.day + 1;

    final bool isRouteOnly = trip.isRouteOnly;
    final bool isPartialCoverage = trip.isPartialCoverage;

    // Format the date display
    String dateLabel;
    if (isRouteOnly) {
      dateLabel = 'Selected Route Info';
    } else if (isToday) {
      dateLabel = 'Today';
    } else if (isTomorrow) {
      dateLabel = 'Tomorrow';
    } else {
      dateLabel = DateFormat('EEE, MMM d').format(tripDate);
    }

    final bool isExpanded = _expandedCards.contains(trip.tripId);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.colors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: context.colors.shadowColor.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isExpanded
              ? AppColors.primary.withOpacity(0.15)
              : context.colors.cardBorder,
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedCards.remove(trip.tripId);
                    } else {
                      _expandedCards.add(trip.tripId);
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- 1. OPERATOR & RATING ROW ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.business,
                                    size: 20,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isRouteOnly
                                            ? (trip.displayRouteName == 'Colombo - Kandy' ? 'colombo express' : trip.displayRouteName)
                                            : trip.scheduleName ??
                                                  trip.busOwnerName ??
                                                  (trip.displayRouteName == 'Colombo - Kandy' ? 'colombo express' : trip.displayRouteName),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: context.colors.textPrimary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (trip.mainRouteOrigin != null &&
                                          trip.mainRouteDestination != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4.0,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.route_outlined,
                                                size: 14,
                                                color: AppColors.primary
                                                    .withOpacity(0.7),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${trip.mainRouteOrigin} ↔ ${trip.mainRouteDestination}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.primary
                                                      .withOpacity(0.8),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (trip.busOwnerName != null &&
                                          trip.routeName.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4.0,
                                            bottom: 4.0,
                                          ),
                                          child: Text(
                                            trip.routeName == 'Colombo - Kandy' 
                                                ? 'colombo express' 
                                                : trip.routeName,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: context.colors.textSecondary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildHeaderTag(
                            trip.isTransit
                                ? 'TRANSIT'
                                : isPartialCoverage
                                ? 'PARTIAL'
                                : trip.busType.toUpperCase(),
                            trip.isTransit
                                ? AppColors.secondary
                                : isPartialCoverage
                                ? AppColors.secondary
                                : AppColors.primary,
                            trip.isTransit
                                ? Icons.alt_route_rounded
                                : Icons.directions_bus_filled,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // --- 2. TIMES SECTION ---
                      if (!isRouteOnly) _buildTimeAndDurationSection(trip),

                      const SizedBox(height: 16),

                      // --- 3. AMENITIES & BADGES ---
                      Row(
                        children: [
                          Expanded(child: _buildFeaturesRow(trip)),
                          if (trip.totalSeats < 10)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'FAST FILLING',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (isRouteOnly || isPartialCoverage)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isRouteOnly
                                  ? AppColors.primary.withOpacity(0.08)
                                  : AppColors.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              isRouteOnly
                                  ? 'Route available but no bus schedule is available on this date.'
                                  : 'Partial coverage: ${trip.remainingGapKm.toStringAsFixed(1)} km gap remains for complete journey.',
                              style: TextStyle(
                                fontSize: 13,
                                color: isRouteOnly
                                    ? AppColors.primary
                                    : AppColors.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isExpanded ? 'Hide Details' : 'View Lounges & Details',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          Icon(
                            isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // --- 4. EXPANDABLE ROUTE SECTION ---
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                decoration: BoxDecoration(
                  color: context.colors.scaffoldBackground,
                  border: Border(top: BorderSide(color: context.colors.dividerColor)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'JOURNEY DETAILS',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildLocationTimeline(trip),
                    const SizedBox(height: 24),
                    const Text(
                      'ROUTE STOPS & SCHEDULE',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRoutePreview(trip),
                  ],
                ),
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),

            // --- 5. FOOTER: PRICE & BOOK ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: context.colors.cardBackground,
                border: Border(top: BorderSide(color: context.colors.dividerColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL FARE',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1,
                            fontWeight: FontWeight.bold,
                            color: context.colors.textSecondary,
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              trip.formattedFare,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                            if (trip.isTransit &&
                                trip.leg1 != null &&
                                trip.leg2 != null) ...[
                              const SizedBox(width: 4),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  '(LKR ${trip.leg1!.fare.toStringAsFixed(0)} + ${trip.leg2!.fare.toStringAsFixed(0)})',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.secondary.withOpacity(0.8),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 140,
                    child: ElevatedButton(
                      onPressed: trip.isBookable
                          ? () => _handleBookingPress(context, trip)
                          : () => _showRouteOnlyUnavailableMessage(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: trip.isBookable
                            ? AppColors.primary
                            : Colors.grey.shade400,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        trip.isBookable ? 'Book Now' : 'Not Bookable',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderTag(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeAndDurationSection(TripResult trip) {
    final fromName = (trip.fromLounge ?? trip.boardingPoint).replaceAll(" (Nearest Join Point)", "");
    final toName = (trip.toLounge ?? trip.droppingPoint).replaceAll(" (Nearest Join Point)", "");

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Departure
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('hh:mm').format(trip.departureTime),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: context.colors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                DateFormat('a').format(trip.departureTime),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                fromName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // Duration Visual
        Expanded(
          flex: 4,
          child: Column(
            children: [
              Text(
                trip.formattedDuration,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.1),
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: context.colors.cardBackground,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.directions_bus_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                trip.isTransit ? '1 STOP' : 'DIRECT',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: trip.isTransit
                      ? AppColors.secondary
                      : AppColors.primary.withOpacity(0.6),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        // Arrival
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('hh:mm').format(trip.estimatedArrival),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: context.colors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                DateFormat('a').format(trip.estimatedArrival),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                toName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                ),
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationTimeline(TripResult trip) {
    final fromName = (trip.fromLounge ?? trip.boardingPoint).replaceAll(
      " (Nearest Join Point)",
      "",
    );
    final toName = (trip.toLounge ?? trip.droppingPoint).replaceAll(
      " (Nearest Join Point)",
      "",
    );

    // Build contextual subtitles that clearly communicate this is proximity-based
    final fromSubtitle = trip.fromLounge != null
        ? 'Nearest Lounge · Departure'
        : 'Boarding Point';
    final toSubtitle = trip.toLounge != null
        ? 'Nearest Lounge · Arrival Point'
        : 'Alighting Point';

    return Column(
      children: [
        _buildLocationRow(
          title: fromName,
          subtitle: fromSubtitle,
          color: AppColors.success,
          isStart: true,
          distKm: trip.fromLoungeDistKm,
          targetName: _cleanLocation(widget.pickup),
        ),
        if (trip.isTransit) ...[
          _buildTimelineConnector(),
          _buildLocationRow(
            title: trip.transitPoint ?? 'Transit Hub',
            subtitle: trip.formattedTransitWaitTime.isNotEmpty
                ? 'Transit Lounge • ${trip.formattedTransitWaitTime}'
                : 'Transit Hub (Change Bus)',
            color: AppColors.secondary,
            isStart: false,
            distKm: 0,
            targetName: trip.transitPoint ?? 'Transit Hub',
            icon: Icons.transfer_within_a_station_rounded,
          ),
        ],
        _buildTimelineConnector(),
        _buildLocationRow(
          title: toName,
          subtitle: toSubtitle,
          color: AppColors.error,
          isStart: false,
          distKm: trip.toLoungeDistKm,
          targetName: _cleanLocation(widget.drop),
        ),
      ],
    );
  }

  Widget _buildTimelineConnector() {
    return Padding(
      padding: const EdgeInsets.only(left: 11),
      child: Column(
        children: List.generate(
          3,
          (index) => Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            width: 2,
            height: 4,
            color: Colors.grey[300],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationRow({
    required String title,
    required String subtitle,
    required Color color,
    required bool isStart,
    double distKm = 0.0,
    String? targetName,
    IconData? icon,
  }) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Icon(
              icon ?? Icons.circle,
              size: icon != null ? 14 : 8,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 6,
                children: [
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: context.colors.textSecondary,
                    ),
                  ),
                  if (distKm > 0 && targetName != null)
                    _buildDistancePill(distKm, isStart, targetName),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDistancePill(double distKm, bool isStart, String targetName) {
    // Dynamic coloring based on proximity
    final Color accentColor = distKm < 1.0
        ? AppColors.success
        : distKm < 3.0
        ? AppColors.primary
        : const Color(0xFF607D8B);

    final IconData icon = isStart
        ? Icons.man_rounded
        : Icons.location_on_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: accentColor.withOpacity(0.15), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: accentColor),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${distKm.toStringAsFixed(1)} km ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: accentColor,
                      fontFamily: 'Inter',
                    ),
                  ),
                  TextSpan(
                    text: 'to $targetName',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textSecondary.withOpacity(0.8),
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_rounded, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'No scheduled trips currently available for this route. Please try another date.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Color(0xFF1976D2),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesRow(TripResult trip) {
    final features = trip.busFeatures;
    if (!features.hasAnyFeatures) return const SizedBox.shrink();

    return Row(
      children: [
        if (features.hasAc) _buildSmallFeatureIcon(Icons.ac_unit_rounded, 'AC'),
        if (features.hasWifi)
          _buildSmallFeatureIcon(Icons.wifi_rounded, 'WiFi'),
        if (features.hasChargingPorts)
          _buildSmallFeatureIcon(Icons.usb_rounded, 'USB'),
        if (features.hasEntertainment)
          _buildSmallFeatureIcon(Icons.tv_rounded, 'TV'),
        if (features.hasRefreshments)
          _buildSmallFeatureIcon(Icons.local_cafe_rounded, 'Food'),
        const Spacer(),
        // Small route indicator
        Text(
          '#${trip.routeNumber ?? trip.routeName.split(" ").first}',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: context.colors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSmallFeatureIcon(IconData icon, String tooltip) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Tooltip(
        message: tooltip,
        child: Icon(icon, size: 16, color: context.colors.iconSecondary),
      ),
    );
  }

  Widget _buildRoutePreview(TripResult trip) {
    if (trip.routeStops.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route_outlined, size: 14, color: context.colors.iconSecondary),
              const SizedBox(width: 6),
              Text(
                'Route Stops (${trip.routeStops.length})',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: trip.routeStops.length,
              itemBuilder: (context, index) {
                final stop = trip.routeStops[index];
                final bool isFirst = index == 0;
                final bool isLast = index == trip.routeStops.length - 1;
                final bool isMajor = stop.isMajorStop;

                return SizedBox(
                  width: 90,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 2,
                              color: isFirst
                                  ? Colors.transparent
                                  : AppColors.primary.withOpacity(0.2),
                            ),
                          ),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: isMajor ? AppColors.primary : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary,
                                width: isMajor ? 0 : 2,
                              ),
                              boxShadow: isMajor
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(
                                          0.3,
                                        ),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: isMajor
                                ? const Center(
                                    child: Icon(
                                      Icons.star,
                                      size: 8,
                                      color: Colors.white,
                                    ),
                                  )
                                : null,
                          ),
                          Expanded(
                            child: Container(
                              height: 2,
                              color: isLast
                                  ? Colors.transparent
                                  : AppColors.primary.withOpacity(0.2),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          stop.stopName,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isMajor
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isMajor
                                ? AppColors.primary
                                : context.colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatsDisplay(TripResult trip) {
    return Row(
      children: [
        Icon(Icons.event_seat, size: 18, color: context.colors.iconSecondary),
        const SizedBox(width: 8),
        Text(
          trip.seatsDisplay,
          style: TextStyle(
            color: context.colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _handleBookingPress(BuildContext context, TripResult trip) {
    if (trip.isTransit) {
      _navigateToSeatBooking(
        context,
        trip,
        trip.leg1?.routeStops.firstOrNull?.id,
        trip.boardingPoint,
        trip.leg2?.routeStops.lastOrNull?.id,
        trip.droppingPoint,
      );
    } else {
      _showStopSelectionSheet(context, trip);
    }
  }

  void _showRouteOnlyUnavailableMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'This route is available, but booking is not possible yet for the selected date.',
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showStopSelectionSheet(BuildContext context, TripResult trip) {
    final searchProvider = context.read<SearchProvider>();
    final searchDetails = searchProvider.searchResponse?.searchDetails;

    if (trip.routeStops.isEmpty) {
      _navigateToSeatBooking(
        context,
        trip,
        null,
        trip.boardingPoint,
        null,
        trip.droppingPoint,
      );
      return;
    }

    RouteStop? selectedBoarding;
    RouteStop? selectedAlighting;

    if (searchDetails?.fromStop.id != null) {
      selectedBoarding = trip.routeStops.cast<RouteStop?>().firstWhere(
        (s) => s?.id == searchDetails?.fromStop.id,
        orElse: () => trip.routeStops.first,
      );
    } else {
      selectedBoarding = trip.routeStops.first;
    }

    if (searchDetails?.toStop.id != null) {
      selectedAlighting = trip.routeStops.cast<RouteStop?>().firstWhere(
        (s) => s?.id == searchDetails?.toStop.id,
        orElse: () => trip.routeStops.last,
      );
    } else {
      selectedAlighting = trip.routeStops.last;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.bottomSheetBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final validAlightingStops = trip.routeStops
                .where(
                  (s) =>
                      selectedBoarding == null ||
                      s.stopOrder > selectedBoarding!.stopOrder,
                )
                .toList();

            return Container(
              padding: const EdgeInsets.all(20),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Stops',
                        style: AppTextStyles.h2.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    trip.routeName,
                    style: AppTextStyles.body.copyWith(color: context.colors.textSecondary),
                  ),
                  const Divider(height: 24),
                  Text(
                    'Boarding Point',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: context.colors.cardBorder),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<RouteStop>(
                        value: selectedBoarding,
                        isExpanded: true,
                        dropdownColor: context.colors.cardBackground,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        borderRadius: BorderRadius.circular(12),
                        items: trip.routeStops
                            .where(
                              (s) =>
                                  selectedAlighting == null ||
                                  s.stopOrder < selectedAlighting!.stopOrder,
                            )
                            .map((stop) {
                              return DropdownMenuItem<RouteStop>(
                                value: stop,
                                child: Row(
                                  children: [
                                    Icon(
                                      stop.isMajorStop
                                          ? Icons.location_city
                                          : Icons.location_on_outlined,
                                      size: 18,
                                      color: stop.isMajorStop
                                          ? AppColors.primary
                                          : context.colors.iconSecondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        stop.stopName,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            })
                            .toList(),
                        onChanged: (value) {
                          setSheetState(() {
                            selectedBoarding = value;
                            if (selectedAlighting != null &&
                                selectedAlighting!.stopOrder <=
                                    value!.stopOrder) {
                              selectedAlighting = validAlightingStops.isNotEmpty
                                  ? validAlightingStops.first
                                  : null;
                            }
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Alighting Point',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: context.colors.cardBorder),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<RouteStop>(
                        value: selectedAlighting,
                        isExpanded: true,
                        dropdownColor: context.colors.cardBackground,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        borderRadius: BorderRadius.circular(12),
                        items: validAlightingStops.map((stop) {
                          return DropdownMenuItem<RouteStop>(
                            value: stop,
                            child: Row(
                              children: [
                                Icon(
                                  stop.isMajorStop
                                      ? Icons.location_city
                                      : Icons.location_on_outlined,
                                  size: 18,
                                  color: stop.isMajorStop
                                      ? AppColors.primary
                                      : context.colors.iconSecondary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    stop.stopName,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setSheetState(() {
                            selectedAlighting = value;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          selectedBoarding != null && selectedAlighting != null
                          ? () {
                              Navigator.pop(context);
                              _navigateToSeatBooking(
                                context,
                                trip,
                                selectedBoarding!.id,
                                selectedBoarding!.stopName,
                                selectedAlighting!.id,
                                selectedAlighting!.stopName,
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Continue to Seat Selection',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _navigateToSeatBooking(
    BuildContext context,
    TripResult trip,
    String? boardingStopId,
    String boardingPoint,
    String? alightingStopId,
    String alightingPoint,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SeatBookingScreenV2(
          trip: trip,
          boardingPoint: boardingPoint,
          alightingPoint: alightingPoint,
          boardingStopId: boardingStopId,
          alightingStopId: alightingStopId,
          masterRouteId: trip.masterRouteId,
          // Pass the raw "From" city the user typed in the search box so that
          originCity: _cleanLocation(widget.pickup),
          destinationCity: _cleanLocation(widget.drop),
        ),
      ),
    );
  }

  String _cleanLocation(String location) {
    if (location.isEmpty) return '';
    
    // Split the location by commas to get individual address components
    final components = location.split(',');
    
    for (var component in components) {
      final trimmedComponent = component.trim();
      if (trimmedComponent.isEmpty) continue;
      
      // Split the component by space to check for plus codes (e.g., "7523+P54" or "7523+P54 Colombo")
      final words = trimmedComponent.split(' ');
      final cleanWords = words.where((word) => !word.contains('+')).toList();
      
      // If we have words left after removing any plus codes, join them and return
      if (cleanWords.isNotEmpty) {
        final result = cleanWords.join(' ').trim();
        if (result.isNotEmpty) {
          return result;
        }
      }
    }
    
    // Fallback if everything had a plus code or was empty
    return location.split(',').first.trim();
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}
