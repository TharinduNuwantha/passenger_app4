import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../models/lounge_booking_models.dart';
import '../../services/lounge_booking_service.dart';
import '../../theme/app_colors.dart';
import 'lounge_booking_with_bus_screen.dart';

/// Screen to select lounges when booking a bus trip
/// Shows lounges available at departure (pre-trip) and arrival (post-trip) stops
class LoungeSelectionScreen extends StatefulWidget {
  /// Bus booking reference for linking lounge bookings
  final String busBookingReference;

  /// Bus booking ID for linking
  final String? busBookingId;

  /// Bus departure time (for pre-trip scheduling)
  final DateTime busDepartureTime;

  /// Bus arrival time (for post-trip scheduling)
  final DateTime busArrivalTime;

  /// Boarding stop ID
  final String? boardingStopId;

  /// Alighting stop ID
  final String? alightingStopId;

  /// Master route ID (for fallback lounge search)
  final String? masterRouteId;

  /// Boarding stop name (for display)
  final String boardingStopName;

  /// Alighting stop name (for display)
  final String alightingStopName;

  /// Route name (for display)
  final String routeName;

  /// Total bus fare (for combined pricing display)
  final double busFare;

  /// Selected seats (for display)
  final String selectedSeats;

  const LoungeSelectionScreen({
    super.key,
    required this.busBookingReference,
    this.busBookingId,
    required this.busDepartureTime,
    required this.busArrivalTime,
    this.boardingStopId,
    this.alightingStopId,
    this.masterRouteId,
    required this.boardingStopName,
    required this.alightingStopName,
    required this.routeName,
    required this.busFare,
    required this.selectedSeats,
  });

  @override
  State<LoungeSelectionScreen> createState() => _LoungeSelectionScreenState();
}

class _LoungeSelectionScreenState extends State<LoungeSelectionScreen>
    with SingleTickerProviderStateMixin {
  final LoungeBookingService _loungeService = LoungeBookingService();
  final Logger _logger = Logger();

  late TabController _tabController;

  bool _isLoadingDeparture = true;
  bool _isLoadingArrival = true;
  String? _departureError;
  String? _arrivalError;

  List<Lounge> _departureLounges = [];
  List<Lounge> _arrivalLounges = [];

  Lounge? _selectedDepartureLounge;
  Lounge? _selectedArrivalLounge;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLounges();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLounges() async {
    _logger.i('=== LOUNGE SEARCH DEBUG ===');
    _logger.i('masterRouteId: ${widget.masterRouteId}');
    _logger.i('boardingStopId: ${widget.boardingStopId}');
    _logger.i('alightingStopId: ${widget.alightingStopId}');

    // NEW LOGIC: Search for lounges within 2 stops of passenger's selected stops
    // Requires both route ID AND stop ID

    // Load departure lounges (near boarding stop)
    if (widget.masterRouteId != null &&
        widget.masterRouteId!.isNotEmpty &&
        widget.boardingStopId != null &&
        widget.boardingStopId!.isNotEmpty) {
      _loadDepartureLoungesNearStop();
    } else if (widget.masterRouteId != null &&
        widget.masterRouteId!.isNotEmpty) {
      // Fallback: Show all lounges on route
      _logger.w('No boarding stop ID, falling back to route-based search');
      _loadDepartureLoungesByRoute();
    } else {
      setState(() {
        _isLoadingDeparture = false;
        _departureError = 'No route information available';
      });
    }

    // Load arrival lounges (near alighting stop)
    if (widget.masterRouteId != null &&
        widget.masterRouteId!.isNotEmpty &&
        widget.alightingStopId != null &&
        widget.alightingStopId!.isNotEmpty) {
      _loadArrivalLoungesNearStop();
    } else if (widget.masterRouteId != null &&
        widget.masterRouteId!.isNotEmpty) {
      // Fallback: Show all lounges on route
      _logger.w('No alighting stop ID, falling back to route-based search');
      _loadArrivalLoungesByRoute();
    } else {
      setState(() {
        _isLoadingArrival = false;
        _arrivalError = 'No route information available';
      });
    }
  }

  /// Load lounges near the boarding stop (within 2 stops)
  Future<void> _loadDepartureLoungesNearStop() async {
    try {
      _logger.i(
        'Loading departure lounges near stop: ${widget.boardingStopId} on route: ${widget.masterRouteId}',
      );
      final lounges = await _loungeService.getLoungesNearStop(
        widget.masterRouteId!,
        widget.boardingStopId!,
      );
      setState(() {
        _departureLounges = lounges;
        _isLoadingDeparture = false;
      });
      _logger.i('Found ${lounges.length} lounges near boarding stop');
    } catch (e) {
      _logger.e('Failed to load departure lounges near stop: $e');
      setState(() {
        _departureError = 'Failed to load lounges';
        _isLoadingDeparture = false;
      });
    }
  }

  /// Load lounges near the alighting stop (within 2 stops)
  Future<void> _loadArrivalLoungesNearStop() async {
    try {
      _logger.i(
        'Loading arrival lounges near stop: ${widget.alightingStopId} on route: ${widget.masterRouteId}',
      );
      final lounges = await _loungeService.getLoungesNearStop(
        widget.masterRouteId!,
        widget.alightingStopId!,
      );
      setState(() {
        _arrivalLounges = lounges;
        _isLoadingArrival = false;
      });
      _logger.i('Found ${lounges.length} lounges near alighting stop');
    } catch (e) {
      _logger.e('Failed to load arrival lounges near stop: $e');
      setState(() {
        _arrivalError = 'Failed to load lounges';
        _isLoadingArrival = false;
      });
    }
  }

  Future<void> _loadDepartureLounges() async {
    try {
      final lounges = await _loungeService.getLoungesByStop(
        widget.boardingStopId!,
      );
      setState(() {
        _departureLounges = lounges;
        _isLoadingDeparture = false;
      });
      _logger.i('Found ${lounges.length} lounges at departure');
    } catch (e) {
      _logger.e('Failed to load departure lounges: $e');
      setState(() {
        _departureError = 'Failed to load lounges';
        _isLoadingDeparture = false;
      });
    }
  }

  Future<void> _loadArrivalLounges() async {
    try {
      final lounges = await _loungeService.getLoungesByStop(
        widget.alightingStopId!,
      );
      setState(() {
        _arrivalLounges = lounges;
        _isLoadingArrival = false;
      });
      _logger.i('Found ${lounges.length} lounges at arrival');
    } catch (e) {
      _logger.e('Failed to load arrival lounges: $e');
      setState(() {
        _arrivalError = 'Failed to load lounges';
        _isLoadingArrival = false;
      });
    }
  }

  /// Fallback: Load departure lounges by route when stop ID is not available
  Future<void> _loadDepartureLoungesByRoute() async {
    try {
      _logger.i('Loading departure lounges by route: ${widget.masterRouteId}');
      final lounges = await _loungeService.getLoungesByRoute(
        widget.masterRouteId!,
      );
      setState(() {
        _departureLounges = lounges;
        _isLoadingDeparture = false;
      });
      _logger.i('Found ${lounges.length} lounges on route (for departure)');
    } catch (e) {
      _logger.e('Failed to load departure lounges by route: $e');
      setState(() {
        _departureError = 'No lounges available on this route';
        _isLoadingDeparture = false;
      });
    }
  }

  /// Fallback: Load arrival lounges by route when stop ID is not available
  Future<void> _loadArrivalLoungesByRoute() async {
    try {
      _logger.i('Loading arrival lounges by route: ${widget.masterRouteId}');
      final lounges = await _loungeService.getLoungesByRoute(
        widget.masterRouteId!,
      );
      setState(() {
        _arrivalLounges = lounges;
        _isLoadingArrival = false;
      });
      _logger.i('Found ${lounges.length} lounges on route (for arrival)');
    } catch (e) {
      _logger.e('Failed to load arrival lounges by route: $e');
      setState(() {
        _arrivalError = 'No lounges available on this route';
        _isLoadingArrival = false;
      });
    }
  }

  void _selectDepartureLounge(Lounge? lounge) {
    setState(() {
      _selectedDepartureLounge = _selectedDepartureLounge?.id == lounge?.id
          ? null
          : lounge;
    });
  }

  void _selectArrivalLounge(Lounge? lounge) {
    setState(() {
      _selectedArrivalLounge = _selectedArrivalLounge?.id == lounge?.id
          ? null
          : lounge;
    });
  }

  void _proceedToBooking(Lounge lounge, bool isPreTrip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoungeBookingWithBusScreen(
          lounge: lounge,
          bookingType: isPreTrip ? 'pre_trip' : 'post_trip',
          busBookingId: widget.busBookingId,
          busDepartureTime: widget.busDepartureTime,
          busArrivalTime: widget.busArrivalTime,
          busBookingReference: widget.busBookingReference,
          routeName: widget.routeName,
          boardingStopName: widget.boardingStopName,
          alightingStopName: widget.alightingStopName,
        ),
      ),
    );
  }

  void _skipLoungeBooking() {
    // Navigate back or to success screen
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bus booking confirmed without lounge'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Lounge',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Bus booking summary
            _buildBookingSummary(),

            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: const Color(0xFFFFC300),
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorPadding: const EdgeInsets.all(4),
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            'Boarding Lounge',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_selectedDepartureLounge != null)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.check_circle, size: 16),
                          ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            'Destination Lounge',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_selectedArrivalLounge != null)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.check_circle, size: 16),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Content
            Expanded(
              child: Container(
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
                    // Pre-Trip (Departure) lounges
                    _buildLoungeList(
                      isLoading: _isLoadingDeparture,
                      error: _departureError,
                      lounges: _departureLounges,
                      selectedLounge: _selectedDepartureLounge,
                      onSelect: _selectDepartureLounge,
                      isPreTrip: true,
                      stopName: widget.boardingStopName,
                    ),

                    // Post-Trip (Arrival) lounges
                    _buildLoungeList(
                      isLoading: _isLoadingArrival,
                      error: _arrivalError,
                      lounges: _arrivalLounges,
                      selectedLounge: _selectedArrivalLounge,
                      onSelect: _selectArrivalLounge,
                      isPreTrip: false,
                      stopName: widget.alightingStopName,
                    ),
                  ],
                ),
              ),
            ),

            // Bottom action buttons
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingSummary() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFC300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.directions_bus,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.routeName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.boardingStopName} → ${widget.alightingStopName}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Seats: ${widget.selectedSeats} • Ref: ${widget.busBookingReference}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  'LKR ${widget.busFare.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Color(0xFFFFC300),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Bus Fare',
                  style: TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoungeList({
    required bool isLoading,
    required String? error,
    required List<Lounge> lounges,
    required Lounge? selectedLounge,
    required Function(Lounge?) onSelect,
    required bool isPreTrip,
    required String stopName,
  }) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                error,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (lounges.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.weekend_outlined,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'No Lounges Available',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'There are no partner lounges near\n$stopName at this time.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            children: [
              Icon(
                isPreTrip ? Icons.weekend : Icons.hotel,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPreTrip ? 'Lounges at Departure' : 'Lounges at Arrival',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Near $stopName',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${lounges.length} available',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Lounge list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: lounges.length,
            itemBuilder: (context, index) {
              final lounge = lounges[index];
              final isSelected = selectedLounge?.id == lounge.id;

              return _buildLoungeCard(
                lounge: lounge,
                isSelected: isSelected,
                onSelect: () => onSelect(lounge),
                onBook: () => _proceedToBooking(lounge, isPreTrip),
                isPreTrip: isPreTrip,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoungeCard({
    required Lounge lounge,
    required bool isSelected,
    required VoidCallback onSelect,
    required VoidCallback onBook,
    required bool isPreTrip,
  }) {
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFC300) : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image or placeholder
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: lounge.images.isNotEmpty
                  ? Image.network(
                      lounge.images.first,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                    )
                  : _buildImagePlaceholder(),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and rating
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lounge.loungeName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (lounge.averageRating != null &&
                          lounge.averageRating! > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                size: 14,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                lounge.averageRating!.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Address
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          lounge.address,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Amenities
                  if (lounge.amenities.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: lounge.amenities.take(4).map((amenity) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _formatAmenity(amenity),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 12),

                  // Pricing and action
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'From LKR ${(lounge.price1Hour ?? 0).toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              'per hour',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        ElevatedButton(
                          onPressed: onBook,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFC300),
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Book Now',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Select',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
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

  Widget _buildImagePlaceholder() {
    return Container(
      height: 120,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.weekend, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 4),
          Text(
            'Lounge',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Skip button
            Expanded(
              child: OutlinedButton(
                onPressed: _skipLoungeBooking,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white70),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Skip Lounge',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Continue button
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed:
                    (_selectedDepartureLounge != null ||
                        _selectedArrivalLounge != null)
                    ? () {
                        // If a lounge is selected, go to booking
                        final selectedLounge =
                            _selectedDepartureLounge ?? _selectedArrivalLounge;
                        final isPreTrip = _selectedDepartureLounge != null;
                        if (selectedLounge != null) {
                          _proceedToBooking(selectedLounge, isPreTrip);
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC300),
                  disabledBackgroundColor: Colors.grey.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _getButtonText(),
                  style: TextStyle(
                    color:
                        (_selectedDepartureLounge != null ||
                            _selectedArrivalLounge != null)
                        ? AppColors.primary
                        : Colors.grey.shade400,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getButtonText() {
    if (_selectedDepartureLounge != null && _selectedArrivalLounge != null) {
      return 'Book Both Lounges';
    } else if (_selectedDepartureLounge != null) {
      return 'Book Boarding Lounge';
    } else if (_selectedArrivalLounge != null) {
      return 'Book Destination Lounge';
    }
    return 'Select a Lounge';
  }

  String _formatAmenity(String amenity) {
    return amenity
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1)}'
              : '',
        )
        .join(' ');
  }
}
