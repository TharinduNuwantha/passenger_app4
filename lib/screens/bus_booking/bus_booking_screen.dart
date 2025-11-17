import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_style.dart';
import '../../providers/search_provider.dart';
import '../../models/search_models.dart';
import 'seat_booking_screen.dart' hide AppColors, AppTextStyles;

class BusListScreen extends StatefulWidget {
  final DateTime? date;
  final String pickup;
  final String drop;

  const BusListScreen({
    super.key,
    this.date,
    required this.pickup,
    required this.drop,
  });

  @override
  State<BusListScreen> createState() => _BusListScreenState();
}

class _BusListScreenState extends State<BusListScreen> {
  String _selectedBusType = 'All';

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
        backgroundColor: AppColors.primary,
        body: Consumer<SearchProvider>(
          builder: (context, searchProvider, child) {
            // Get filtered trips based on bus type
            List<TripResult> trips = searchProvider.tripResults;
            if (_selectedBusType != 'All') {
              trips = trips
                  .where((trip) => trip.busType == _selectedBusType)
                  .toList();
            }

            return Column(
              children: [
                _buildHeaderAndFilters(
                  context,
                  formattedDate,
                  trips.length,
                  searchProvider.isSearching,
                ),
                Expanded(
                  child: _buildBody(searchProvider, trips),
                ),
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
              style: TextStyle(color: Colors.white, fontSize: 16),
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
                color: AppColors.secondary,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Search Failed',
                style: AppTextStyles.h2.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                searchProvider.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.white70),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _performSearch(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.primary,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Empty state
    if (trips.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.search_off,
                color: AppColors.white70,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'No Trips Found',
                style: AppTextStyles.h2.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'No buses available for this route on the selected date.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.white70),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.primary,
                ),
                child: const Text('Change Search'),
              ),
            ],
          ),
        ),
      );
    }

    // Success state - display trips
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

            // Time & duration
            Row(
              children: [
                const Icon(Icons.access_time, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  DateFormat('h:mm a').format(trip.departureTime),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('—', style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 8),
                Text(
                  DateFormat('h:mm a').format(trip.estimatedArrival),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  trip.formattedDuration,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Features row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (trip.busFeatures.hasAc)
                  _buildFeatureChip(Icons.ac_unit, 'AC'),
                if (trip.busFeatures.hasWifi)
                  _buildFeatureChip(Icons.wifi, 'WiFi'),
                if (trip.busFeatures.hasChargingPorts)
                  _buildFeatureChip(Icons.charging_station, 'Charging'),
                if (trip.busFeatures.hasEntertainment)
                  _buildFeatureChip(Icons.tv, 'Entertainment'),
                if (trip.busFeatures.hasRefreshments)
                  _buildFeatureChip(Icons.local_cafe, 'Refreshments'),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            // Seats & Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
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
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: trip.isBookable
                          ? () {
                              // Navigate to seat selection
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SeatBookingScreen(
                                    busNumber: trip.routeNumber ?? trip.routeName,
                                    price: trip.fare,
                                  ),
                                ),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: AppColors.primary,
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
              color: isSelected ? AppColors.primary : AppColors.white,
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
        color: Color(0xFF5A9DB6),
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
          if (!isLoading && filterOptions.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: filterOptions.length,
                itemBuilder: (context, index) {
                  final type = filterOptions[index];
                  return _buildFilterChip(type);
                },
              ),
            ),
          ],
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
      'December'
    ];
    return months[month - 1];
  }
}
