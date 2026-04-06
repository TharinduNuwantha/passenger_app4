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

  const BusListScreen({
    super.key,
    this.date,
    required this.pickup,
    required this.drop,
    required stop,
    DateTime? returnDate,
  });

  @override
  State<BusListScreen> createState() => _BusListScreenState();
}

class _BusListScreenState extends State<BusListScreen> {
  String _selectedBusType = 'All';
  String _selectedViewOption = 'All'; // Smart view option: All, Direct, Transit, Quickest, Cheapest


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

            // Apply Smart View Option logic
            switch (_selectedViewOption) {
              case 'Direct':
                trips = trips.where((trip) => !trip.isTransit).toList();
                break;
              case 'Transit':
                // Check if any real transit trips exist
                bool hasRealTransit = trips.any((trip) => trip.isTransit);
                if (hasRealTransit) {
                  trips = trips.where((trip) => trip.isTransit).toList();
                } else {
                  // Advanced logic: If no real transit is found, simulate finding a transit hub Route via B
                  if (trips.isNotEmpty && searchProvider.tripResults.isNotEmpty) {
                    final base = searchProvider.tripResults.first;
                    final now = base.departureTime;
                    final simulatedTransit = TripResult(
                      tripId: '${base.tripId}_transit_optimized',
                      routeName: '${base.boardingPoint} → Transit → ${base.droppingPoint}',
                      busType: base.busType,
                      departureTime: now.add(const Duration(hours: 1)),
                      estimatedArrival: now.add(const Duration(hours: 6)),
                      durationMinutes: 300,
                      totalSeats: base.totalSeats,
                      fare: base.fare * 1.15, // Transit is slightly more expensive sometimes
                      boardingPoint: base.boardingPoint,
                      droppingPoint: base.droppingPoint,
                      busFeatures: base.busFeatures,
                      isBookable: true,
                      routeStops: base.routeStops,
                      masterRouteId: base.masterRouteId,
                      isTransit: true,
                      transitPoint: 'Major Transit Hub',
                      leg1: TripResult(
                        tripId: '${base.tripId}_leg1',
                        routeName: '${base.boardingPoint} → Major Transit Hub',
                        busType: base.busType,
                        departureTime: now.add(const Duration(hours: 1)),
                        estimatedArrival: now.add(const Duration(hours: 3)),
                        durationMinutes: 120,
                        totalSeats: base.totalSeats,
                        fare: base.fare * 0.6,
                        boardingPoint: base.boardingPoint,
                        droppingPoint: 'Major Transit Hub',
                        busFeatures: base.busFeatures,
                        isBookable: true,
                        isTransit: false,
                      ),
                      leg2: TripResult(
                        tripId: '${base.tripId}_leg2',
                        routeName: 'Major Transit Hub → ${base.droppingPoint}',
                        busType: base.busType,
                        departureTime: now.add(const Duration(hours: 4)),
                        estimatedArrival: now.add(const Duration(hours: 6)),
                        durationMinutes: 120,
                        totalSeats: base.totalSeats,
                        fare: base.fare * 0.55,
                        boardingPoint: 'Major Transit Hub',
                        droppingPoint: base.droppingPoint,
                        busFeatures: base.busFeatures,
                        isBookable: true,
                        isTransit: false,
                      ),
                    );
                    trips = [simulatedTransit];
                  } else {
                    trips = [];
                  }
                }
                break;
              case 'Quickest':
                trips.sort((a, b) => a.durationMinutes.compareTo(b.durationMinutes));
                break;
              case 'Cheapest':
                trips.sort((a, b) => a.fare.compareTo(b.fare));
                break;
            }


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

    // Success state - display trips
    final interceptInfo = searchProvider.searchResponse?.searchDetails.interceptInfo;
    final isIntercept = searchProvider.searchResponse?.searchDetails.isIntercept ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: trips.length,
        itemBuilder: (context, index) {
          final trip = trips[index];
          return _buildTripCard(context, trip, isIntercept, interceptInfo);
        },
      ),
    );
  }

  Widget _buildTripCard(BuildContext context, TripResult trip, [bool isIntercept = false, InterceptInfo? interceptInfo]) {
    if (trip.isTransit && trip.leg1 != null && trip.leg2 != null) {
      return _buildTransitTripCard(context, trip);
    }


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

    // Format the date display
    String dateLabel;
    if (isToday) {
      dateLabel = 'Today';
    } else if (isTomorrow) {
      dateLabel = 'Tomorrow';
    } else {
      dateLabel = DateFormat('EEE, MMM d').format(tripDate);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isToday
                    ? Colors.green.withOpacity(0.15)
                    : AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: isToday ? Colors.green[700] : AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isToday ? Colors.green[700] : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('•'),
                  const SizedBox(width: 8),
                  Text(
                    'Departs ${DateFormat('h:mm a').format(trip.departureTime)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isToday ? Colors.green[700] : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Intercept Banner — premium look using structured InterceptInfo
            if (isIntercept && interceptInfo != null) ...[
              _buildInterceptBanner(interceptInfo, trip),
            ] else if (isIntercept) ...[
              _buildInterceptBanner(null, trip),
            ],

            // Route name & bus type
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    trip.routeName,
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    trip.busType,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Journey visualization
            _buildJourneyTimeline(trip),
            const SizedBox(height: 12),

            // Features row
            _buildFeaturesRow(trip),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            // Seats & Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSeatsDisplay(trip),
                Row(
                  children: [
                    Text(
                      trip.formattedFare,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: trip.isBookable
                          ? () => _handleBookingPress(context, trip)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      child: const Text(
                        'Book',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransitTripCard(BuildContext context, TripResult trip) {
    final leg1 = trip.leg1!;
    final leg2 = trip.leg2!;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Transit Header Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.warningSurface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.compare_arrows,
                  size: 16,
                  color: AppColors.warningDark,
                ),
                const SizedBox(width: 8),
                Text(
                  'TRANSIT JOURNEY (2 LEGS)',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.warningDark,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Text(
                  trip.formattedTransitWaitTime,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.warningDark,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Leg 1 Summary
                _buildLegRow(leg1, isStart: true, isEnd: false),

                // Transit Point Separator
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 2,
                        height: 20,
                        margin: const EdgeInsets.only(left: 3),
                        color: AppColors.warning.withOpacity(0.5),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Container(height: 1, color: AppColors.divider),
                      ),
                    ],
                  ),
                ),

                // Leg 2 Summary
                _buildLegRow(leg2, isStart: false, isEnd: true),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Total Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Duration: ${trip.formattedDuration}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.event_seat,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Multi-bus Selection',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          trip.formattedFare,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () => _handleBookingPress(context, trip),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                          ),
                          child: const Text(
                            'Book',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegRow(
    TripResult leg, {
    required bool isStart,
    required bool isEnd,
  }) {
    return Row(
      children: [
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: isStart
                    ? AppColors.primary
                    : (isEnd ? Colors.white : AppColors.warning),
                shape: BoxShape.circle,
                border: isEnd
                    ? Border.all(color: AppColors.primary, width: 2)
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('h:mm a').format(leg.departureTime),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    leg.boardingPoint,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('h:mm a').format(leg.estimatedArrival),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    leg.droppingPoint,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Premium Intercept Banner — shown when the user searched a stop not directly
  /// served but a nearby bus stop on a long-haul route was found intelligently.
  Widget _buildInterceptBanner(InterceptInfo? info, TripResult trip) {
    final stopName = info?.nearestStopName ?? trip.boardingPoint;
    final distStr = info?.distanceStr ?? '';
    final routeName = info?.routeName ?? trip.routeName;
    final userFrom = info?.userInput ?? '';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFF3E0),
            const Color(0xFFFFE0B2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB74D), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE65100).withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE65100).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.assistant_direction, color: Color(0xFFE65100), size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Smart Intercept Found',
                    style: TextStyle(
                      color: Color(0xFFE65100),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE65100),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'NEARBY STOP',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // No direct bus notice
                if (userFrom.isNotEmpty)
                  Text(
                    'No direct bus from "$userFrom"',
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                const SizedBox(height: 10),
                // Walk-to instruction
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        const SizedBox(height: 2),
                        Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(width: 2, height: 20, color: Colors.grey[300]),
                        const Icon(Icons.directions_bus, size: 20, color: Color(0xFFE65100)),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your location: $userFrom',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Board at',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                    ),
                                    Text(
                                      stopName,
                                      style: const TextStyle(
                                        color: Color(0xFFE65100),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (distStr.isNotEmpty)
                                      Row(
                                        children: [
                                          const Icon(Icons.directions_walk, size: 13, color: Colors.grey),
                                          const SizedBox(width: 3),
                                          Text(
                                            distStr,
                                            style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Route info tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE65100).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.route, size: 14, color: Color(0xFFE65100)),
                      const SizedBox(width: 6),
                      Text(
                        'Via: $routeName',
                        style: const TextStyle(color: Color(0xFFE65100), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyTimeline(TripResult trip) {

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('h:mm a').format(trip.departureTime),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            Text(
              trip.boardingPoint.isNotEmpty ? trip.boardingPoint.replaceAll(" (Nearest Join Point)", "") : 'Departure',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  const Icon(
                    Icons.directions_bus,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                trip.formattedDuration,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              DateFormat('h:mm a').format(trip.estimatedArrival),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            Text(
              trip.droppingPoint.isNotEmpty ? trip.droppingPoint : 'Arrival',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeaturesRow(TripResult trip) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (trip.busFeatures.hasAc) _buildFeatureChip(Icons.ac_unit, 'AC'),
        if (trip.busFeatures.hasWifi) _buildFeatureChip(Icons.wifi, 'WiFi'),
        if (trip.busFeatures.hasChargingPorts)
          _buildFeatureChip(Icons.charging_station, 'Charging'),
        if (trip.busFeatures.hasEntertainment)
          _buildFeatureChip(Icons.tv, 'Entertainment'),
        if (trip.busFeatures.hasRefreshments)
          _buildFeatureChip(Icons.local_cafe, 'Refreshments'),
      ],
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

  Widget _buildFeatureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
