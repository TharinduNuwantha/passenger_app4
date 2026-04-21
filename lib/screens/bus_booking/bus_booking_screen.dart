import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_style.dart';
import '../../providers/search_provider.dart';
import '../../models/search_models.dart';
import 'seat_booking_screen_v2.dart';

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
  String _selectedViewOption = 'All'; // Smart view option: All, Direct, Transit, Quickest, Cheapest
  final Set<String> _expandedCards = {}; // Track which cards are expanded for route info


  @override
  void initState() {
    super.initState();
    // Perform search when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performSearch();
    });
  }

  Future<void> _performSearch() async {
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = widget.date != null
        ? "${widget.date!.day} ${_getMonthName(widget.date!.month)} ${widget.date!.year}"
        : "No Date Selected";

    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: AppColors.background,
        body: Consumer<SearchProvider>(
          builder: (context, searchProvider, child) {
            // Get filtered trips based on bus type
            List<TripResult> trips = searchProvider.tripResults;
            if (_selectedBusType != 'All') {
              trips = trips
                  .where((trip) => trip.busType == _selectedBusType)
                  .toList();
            }

            // Simplified: All results are now Lounge-to-Lounge Direct Routes
            trips.sort((a, b) => a.departureTime.compareTo(b.departureTime));


            return Column(
              children: [
                _buildHeaderAndFilters(
                  context,
                  formattedDate,
                  trips.length,
                  searchProvider.isSearching,
                ),
                Expanded(child: _buildBody(searchProvider, trips)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(SearchProvider searchProvider, List<TripResult> trips) {
    // Loading state
    if (searchProvider.isSearching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.secondary),
            SizedBox(height: 16),
            Text(
              'Searching for trips...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Error state
    if (searchProvider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.warning,
                size: 64,
              ),
              const SizedBox(height: 10),
              Text(
                'Search Failed',
                style: AppTextStyles.h2.merge(
                  TextStyle(color: AppColors.warning),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                searchProvider.errorMessage!,
                textAlign: TextAlign.center,
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _performSearch(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.primary,
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Color.fromARGB(255, 227, 230, 232)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Empty state
    if (trips.isEmpty) {
      // Get search details for more context
      final searchDetails = searchProvider.searchResponse?.searchDetails;
      final message =
          searchProvider.searchResponse?.message ??
          'No buses available for this route on the selected date.';

      final fromMatched = searchDetails?.fromStop.matched ?? false;
      final toMatched = searchDetails?.toStop.matched ?? false;
      final fromName = searchDetails?.fromStop.name ?? widget.pickup;
      final toName = searchDetails?.toStop.name ?? widget.drop;

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                fromMatched && toMatched
                    ? Icons.event_busy
                    : Icons.location_off,
                color: AppColors.primaryLight,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                fromMatched && toMatched
                    ? 'No Scheduled Trips'
                    : 'Route Not Found',
                style: AppTextStyles.h2,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 12),
              // Show matched stops
              if (fromMatched || toMatched) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            fromMatched ? Icons.check_circle : Icons.error,
                            color: fromMatched ? Colors.green : Colors.orange,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'From: $fromName',
                              style: TextStyle(
                                color: fromMatched
                                    ? Colors.black87
                                    : Colors.orange,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            toMatched ? Icons.check_circle : Icons.error,
                            color: toMatched ? Colors.green : Colors.orange,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'To: $toName',
                              style: TextStyle(
                                color: toMatched
                                    ? Colors.black87
                                    : Colors.orange,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: const Color.fromARGB(255, 250, 250, 250),
                ),
                child: const Text('Change Search'),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: trips.length,
        itemBuilder: (context, index) {
          final trip = trips[index];
          return _buildTripCard(context, trip);
        },
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

    // Route-only preview flag: true if no schedule is found but route exists
    final bool isRouteOnly = !trip.isBookable && trip.busType == "Unknown";

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
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 20, left: 4, right: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
        border: Border.all(
          color: isExpanded ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
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
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- 1. OPERATOR & RATING ROW ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.business, size: 20, color: AppColors.primary),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    trip.routeName.split(" ").first + " Express",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, size: 14, color: Color(0xFFFFB300)),
                                      const SizedBox(width: 4),
                                      Text(
                                        "4.8 (124 reviews)",
                                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          _buildHeaderTag(
                            trip.busType.toUpperCase(),
                            AppColors.secondary,
                            Icons.directions_bus_filled,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // --- 2. TIMES SECTION ---
                      if (!isRouteOnly) _buildTimeAndDurationSection(trip),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Divider(height: 1, color: AppColors.divider),
                      ),

                      // --- 3. JOURNEY TIMELINE ---
                      _buildLocationTimeline(trip),

                      const SizedBox(height: 20),
                      
                      // --- 3.5 AMENITIES & BADGES ---
                      Row(
                        children: [
                          Expanded(child: _buildFeaturesRow(trip)),
                          if (trip.totalSeats < 10)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                decoration: BoxDecoration(
                  color: Colors.grey[50]!.withOpacity(0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 32),
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
              crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),

            // --- 5. FOOTER: PRICE & BOOK ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.03),
                border: const Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
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
                            color: Colors.grey[500],
                          ),
                        ),
                        Text(
                          trip.formattedFare,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _handleBookingPress(context, trip),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: AppColors.primary.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: const Row(
                      children: [
                        Text(
                          'Book Now',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Departure
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('hh:mm').format(trip.departureTime),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                DateFormat('a').format(trip.departureTime),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        // Duration Visual
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Text(
                trip.formattedDuration,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[500],
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
                    decoration: const BoxDecoration(
                      color: Colors.white,
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
                'DIRECT',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary.withOpacity(0.6),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        // Arrival
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('hh:mm').format(trip.estimatedArrival),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                DateFormat('a').format(trip.estimatedArrival),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationTimeline(TripResult trip) {
    final fromName = (trip.fromLounge ?? trip.boardingPoint).replaceAll(" (Nearest Join Point)", "");
    final toName = (trip.toLounge ?? trip.droppingPoint).replaceAll(" (Nearest Join Point)", "");

    return Column(
      children: [
        _buildLocationRow(
          fromName,
          trip.fromLounge != null ? 'Lounge Departure' : 'Boarding Point',
          AppColors.success,
          true,
        ),
        const SizedBox(height: 4),
        Padding(
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
        ),
        const SizedBox(height: 4),
        _buildLocationRow(
          toName,
          trip.toLounge != null ? 'Lounge Arrival' : 'Alighting Point',
          AppColors.error,
          false,
        ),
      ],
    );
  }

  Widget _buildLocationRow(String title, String subtitle, Color color, bool isStart) {
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
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
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
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ],
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
        if (features.hasWifi) _buildSmallFeatureIcon(Icons.wifi_rounded, 'WiFi'),
        if (features.hasChargingPorts) _buildSmallFeatureIcon(Icons.usb_rounded, 'USB'),
        if (features.hasEntertainment) _buildSmallFeatureIcon(Icons.tv_rounded, 'TV'),
        if (features.hasRefreshments) _buildSmallFeatureIcon(Icons.local_cafe_rounded, 'Food'),
        const Spacer(),
        // Small route indicator
        Text(
          '#${trip.routeNumber ?? trip.routeName.split(" ").first}',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey[400],
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
        child: Icon(
          icon,
          size: 16,
          color: Colors.grey[400],
        ),
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
              Icon(Icons.route_outlined, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                'Route Stops (${trip.routeStops.length})',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
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
                                        color: AppColors.primary.withOpacity(0.3),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      )
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
                            fontWeight: isMajor ? FontWeight.bold : FontWeight.normal,
                            color: isMajor ? AppColors.primary : Colors.grey[700],
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
        const Icon(Icons.event_seat, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          trip.seatsDisplay,
          style: const TextStyle(
            color: Colors.grey,
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
      backgroundColor: Colors.white,
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
                    style: AppTextStyles.body.copyWith(color: Colors.grey[600]),
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
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<RouteStop>(
                        value: selectedBoarding,
                        isExpanded: true,
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
                                          : Colors.grey,
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
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<RouteStop>(
                        value: selectedAlighting,
                        isExpanded: true,
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
                                      : Colors.grey,
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

  Widget _buildSmartOptionChip(String label, IconData icon) {
    final bool isSelected = _selectedViewOption == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedViewOption = label;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primary : Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String type) {
    final bool isSelected = _selectedBusType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBusType = type;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.secondary : AppColors.white70,
          ),
        ),
        child: Center(
          child: Text(
            type,
            style: TextStyle(
              color: isSelected
                  ? const Color.fromARGB(255, 242, 243, 244)
                  : AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Container _buildHeaderAndFilters(
    BuildContext context,
    String formattedDate,
    int busCount,
    bool isLoading,
  ) {
    // Get unique bus types from search results
    final searchProvider = context.watch<SearchProvider>();
    final uniqueBusTypes = searchProvider.tripResults
        .map((trip) => trip.busType)
        .toSet()
        .toList();
    final List<String> filterOptions = ['All', ...uniqueBusTypes];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '${_cleanLocation(widget.pickup)} → ${_cleanLocation(widget.drop)}',
              style: AppTextStyles.h2.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              formattedDate,
              style: AppTextStyles.body.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isLoading ? 'Searching...' : '$busCount trips found',
            style: AppTextStyles.body.copyWith(color: AppColors.white70),
          ),
          if (!isLoading) ...[
            const SizedBox(height: 12),
            // Smart View Options Row
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildSmartOptionChip('All', Icons.list),
                  _buildSmartOptionChip('Direct', Icons.arrow_forward),
                  _buildSmartOptionChip('Transit', Icons.compare_arrows),
                  _buildSmartOptionChip('Quickest', Icons.flash_on),
                  _buildSmartOptionChip('Cheapest', Icons.monetization_on),
                ],
              ),
            ),
            if (filterOptions.isNotEmpty && filterOptions.length > 1) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 32,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: filterOptions.length,
                  itemBuilder: (context, index) {
                    final type = filterOptions[index];
                    return _buildFilterChip(type);
                  },
                ),
              ),
            ],
          ]
        ],
      ),
    );
  }

  String _cleanLocation(String location) {
    // Remove country/region info if present (e.g., "Colombo, Sri Lanka" → "Colombo")
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
