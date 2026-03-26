import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import '../../models/booking_intent_models.dart';
import '../../models/booking_models.dart';
import '../../models/lounge_booking_models.dart';
import '../../models/search_models.dart';
import '../../services/lounge_booking_service.dart';
import '../../theme/app_colors.dart';

/// Data class to hold selected lounge information for combined booking
class SelectedLoungeData {
  final Lounge lounge;
  final String pricingType;
  final double pricePerGuest;
  final List<LoungeGuestRequest> guests;
  final List<PreOrderItemData> preOrders;
  final double basePrice;
  final double preOrderTotal;
  final double totalPrice;
  final DateTime tripDate; // Date from the trip
  final String
  checkInTime; // Check-in time (e.g., trip departure time for pre-trip)
  final String? transportType; // van, car, or tuktuk
  final String? pickupLocation; // Selected pickup location
  final double transportCost; // Cost for transport

  SelectedLoungeData({
    required this.lounge,
    required this.pricingType,
    required this.pricePerGuest,
    required this.guests,
    this.preOrders = const [],
    required this.basePrice,
    required this.preOrderTotal,
    required this.totalPrice,
    required this.tripDate,
    required this.checkInTime,
    this.transportType,
    this.pickupLocation,
    this.transportCost = 0.0,
  });

  LoungeIntentRequest toIntentRequest() {
    return LoungeIntentRequest(
      loungeId: lounge.id,
      loungeName: lounge.loungeName,
      loungeAddress: lounge.address,
      pricingType: pricingType,
      date: DateFormat('yyyy-MM-dd').format(tripDate),
      checkInTime: checkInTime,
      guests: guests,
      preOrders: preOrders
          .map(
            (p) => PreOrderItem(
              productId: p.productId,
              productName: p.productName,
              productType: 'product',
              imageUrl: p.imageUrl,
              quantity: p.quantity,
              unitPrice: p.unitPrice,
              totalPrice: p.totalPrice,
            ),
          )
          .toList(),
      pricePerGuest: pricePerGuest,
      basePrice: basePrice,
      preOrderTotal: preOrderTotal,
      totalPrice: totalPrice,
    );
  }
}

/// Pre-order item with product details for display
class PreOrderItemData {
  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final String? imageUrl;

  PreOrderItemData({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    this.imageUrl,
  });

  double get totalPrice => unitPrice * quantity;
}

/// Screen to add lounges (pre-trip and/or post-trip) to a bus booking
/// This appears after seat selection and passenger details, before payment
class AddLoungeScreen extends StatefulWidget {
  final TripResult trip;
  final List<TripSeat> selectedSeats;
  final String boardingPoint;
  final String alightingPoint;
  final String? boardingStopId;
  final String? alightingStopId;
  final String? masterRouteId;
  final double busFare;
  final String passengerName;
  final String passengerPhone;
  final String? passengerEmail;

  /// The origin city the user typed in the search (e.g. "Colombo").
  /// Used to filter boarding lounges via master_routes.origin_city.
  /// Falls back to route-based or stop-based queries when null.
  final String? originCity;

  const AddLoungeScreen({
    super.key,
    required this.trip,
    required this.selectedSeats,
    required this.boardingPoint,
    required this.alightingPoint,
    this.boardingStopId,
    this.alightingStopId,
    this.masterRouteId,
    required this.busFare,
    required this.passengerName,
    required this.passengerPhone,
    this.passengerEmail,
    this.originCity,
  });

  @override
  State<AddLoungeScreen> createState() => _AddLoungeScreenState();
}

class _AddLoungeScreenState extends State<AddLoungeScreen>
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

  // Selected lounges with full booking data
  SelectedLoungeData? _selectedPreTripLounge;
  SelectedLoungeData? _selectedPostTripLounge;

  // Transport selection for Pre-Trip
  String? _preTripTransportType;
  String? _preTripPickupLocation;

  // Transport selection for Post-Trip
  String? _postTripTransportType;
  String? _postTripPickupLocation;

  // Transport locations (5 popular areas)
  final List<Map<String, String>> _transportLocations = [
    {'id': '1', 'name': 'City Center', 'icon': '🏙️'},
    {'id': '2', 'name': 'Airport', 'icon': '✈️'},
    {'id': '3', 'name': 'Railway Station', 'icon': '🚂'},
    {'id': '4', 'name': 'Hotel District', 'icon': '🏨'},
    {'id': '5', 'name': 'Shopping Mall', 'icon': '🛍️'},
  ];

  // Transport pricing
  final Map<String, double> _transportPricing = {
    'van': 2500.0,
    'car': 1800.0,
    'tuktuk': 800.0,
  };

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
    _logger.i('=== LOUNGE SEARCH FOR COMBINED BOOKING ===');
    _logger.i('masterRouteId: ${widget.masterRouteId}');
    _logger.i('boardingStopId: ${widget.boardingStopId}');
    _logger.i('alightingStopId: ${widget.alightingStopId}');
    _logger.i('originCity: ${widget.originCity}');

    // ── Boarding (pre-trip) lounges ─────────────────────────────────────────
    // Priority 1: lounges near the exact boarding stop (most precise)
    if (widget.masterRouteId != null &&
        widget.masterRouteId!.isNotEmpty &&
        widget.boardingStopId != null &&
        widget.boardingStopId!.isNotEmpty) {
      _loadDepartureLoungesNearStop();
    }
    // Priority 2: city-based filter using master_routes.origin_city
    else if (widget.masterRouteId != null &&
        widget.masterRouteId!.isNotEmpty &&
        widget.originCity != null &&
        widget.originCity!.isNotEmpty) {
      _loadDepartureLoungesByOriginCity();
    }
    // Priority 3: all lounges on this route (broadest fallback)
    else if (widget.masterRouteId != null &&
        widget.masterRouteId!.isNotEmpty) {
      _loadDepartureLoungesByRoute();
    } else {
      setState(() {
        _isLoadingDeparture = false;
        _departureError = 'No route information available';
      });
    }

    // ── Arrival (post-trip) lounges ─────────────────────────────────────────
    if (widget.masterRouteId != null &&
        widget.masterRouteId!.isNotEmpty &&
        widget.alightingStopId != null &&
        widget.alightingStopId!.isNotEmpty) {
      _loadArrivalLoungesNearStop();
    } else if (widget.masterRouteId != null &&
        widget.masterRouteId!.isNotEmpty) {
      _loadArrivalLoungesByRoute();
    } else {
      setState(() {
        _isLoadingArrival = false;
        _arrivalError = 'No route information available';
      });
    }
  }

  Future<void> _loadDepartureLoungesNearStop() async {
    try {
      _logger.i(
        'Loading departure lounges near stop: ${widget.boardingStopId}',
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
      _logger.e('Failed to load departure lounges: $e');
      setState(() {
        _departureError = 'Failed to load lounges';
        _isLoadingDeparture = false;
      });
    }
  }

  Future<void> _loadArrivalLoungesNearStop() async {
    try {
      _logger.i('Loading arrival lounges near stop: ${widget.alightingStopId}');
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
      _logger.e('Failed to load arrival lounges: $e');
      setState(() {
        _arrivalError = 'Failed to load lounges';
        _isLoadingArrival = false;
      });
    }
  }

  Future<void> _loadDepartureLoungesByRoute() async {
    try {
      final lounges = await _loungeService.getLoungesByRoute(
        widget.masterRouteId!,
      );
      setState(() {
        _departureLounges = lounges;
        _isLoadingDeparture = false;
      });
    } catch (e) {
      setState(() {
        _departureError = 'No lounges available';
        _isLoadingDeparture = false;
      });
    }
  }

  /// Load boarding lounges filtered by the origin city of this route.
  /// The backend resolves origin_city from master_routes using [masterRouteId]
  /// and returns lounges joined via lounge_routes, sorted by rating & price.
  Future<void> _loadDepartureLoungesByOriginCity() async {
    try {
      _logger.i(
        'Loading boarding lounges by origin city '
        '(route: ${widget.masterRouteId}, city hint: ${widget.originCity})',
      );

      // Prefer the city string passed from search; server also has the route
      // so it can derive the canonical origin_city on its own if needed.
      List<Lounge> lounges;
      if (widget.originCity != null && widget.originCity!.isNotEmpty) {
        lounges = await _loungeService.getLoungesByOriginCity(
          widget.originCity!,
        );
      } else {
        lounges = await _loungeService.getBoardingLoungesByRouteOrigin(
          widget.masterRouteId!,
        );
      }

      _logger.i(
        'Found ${lounges.length} boarding lounges for origin city',
      );

      if (lounges.isEmpty && widget.masterRouteId != null) {
        // Soft fallback: try the full route list so we never show an empty
        // boarding-lounge tab when there ARE lounges on this route.
        _logger.w(
          'No city-filtered lounges found; falling back to route-wide list',
        );
        final fallback =
            await _loungeService.getLoungesByRoute(widget.masterRouteId!);
        setState(() {
          _departureLounges = fallback;
          _isLoadingDeparture = false;
        });
      } else {
        setState(() {
          _departureLounges = lounges;
          _isLoadingDeparture = false;
        });
      }
    } catch (e) {
      _logger.e('Failed to load departure lounges by origin city: $e');
      setState(() {
        _departureError = 'No lounges available near your departure city';
        _isLoadingDeparture = false;
      });
    }
  }

  Future<void> _loadArrivalLoungesByRoute() async {
    try {
      final lounges = await _loungeService.getLoungesByRoute(
        widget.masterRouteId!,
      );
      setState(() {
        _arrivalLounges = lounges;
        _isLoadingArrival = false;
      });
    } catch (e) {
      setState(() {
        _arrivalError = 'No lounges available';
        _isLoadingArrival = false;
      });
    }
  }

  /// Open lounge configuration bottom sheet
  Future<void> _configureLoungeBooking(Lounge lounge, bool isPreTrip) async {
    final result = await showModalBottomSheet<SelectedLoungeData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LoungeConfigurationSheet(
        lounge: lounge,
        isPreTrip: isPreTrip,
        busDepartureTime: widget.trip.departureTime,
        busArrivalTime: widget.trip.estimatedArrival,
        passengerName: widget.passengerName,
        passengerPhone: widget.passengerPhone,
      ),
    );

    if (result != null) {
      setState(() {
        if (isPreTrip) {
          _selectedPreTripLounge = result;
        } else {
          _selectedPostTripLounge = result;
        }
      });
    }
  }

  /// Remove selected lounge
  void _removeLounge(bool isPreTrip) {
    setState(() {
      if (isPreTrip) {
        _selectedPreTripLounge = null;
      } else {
        _selectedPostTripLounge = null;
      }
    });
  }

  /// Calculate total including lounges
  double get _totalWithLounges {
    double total = widget.busFare;
    if (_selectedPreTripLounge != null) {
      total += _selectedPreTripLounge!.totalPrice;
    }
    if (_selectedPostTripLounge != null) {
      total += _selectedPostTripLounge!.totalPrice;
    }
    return total;
  }

  /// Skip lounges and proceed
  void _skipLounges() {
    Navigator.pop(
      context,
      AddLoungeResult(preTripLounge: null, postTripLounge: null),
    );
  }

  /// Continue with selected lounges
  void _continueWithLounges() {
    Navigator.pop(
      context,
      AddLoungeResult(
        preTripLounge: _selectedPreTripLounge,
        postTripLounge: _selectedPostTripLounge,
      ),
    );
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
          'Add Lounge',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 238, 239, 239),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Bus booking summary
            _buildBusSummary(),

            // Selected lounges summary (if any)
            if (_selectedPreTripLounge != null ||
                _selectedPostTripLounge != null)
              _buildSelectedLoungesSummary(),

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
                  color:  AppColors.primarySurface,
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
                        const Flexible(
                          child: Text(
                            'Boarding Lounge',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_selectedPreTripLounge != null)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.green,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Flexible(
                          child: Text(
                            'Destination Lounge',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_selectedPostTripLounge != null)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.green,
                            ),
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
                    _buildLoungeList(
                      isLoading: _isLoadingDeparture,
                      error: _departureError,
                      lounges: _departureLounges,
                      selectedLounge: _selectedPreTripLounge,
                      isPreTrip: true,
                      stopName: widget.boardingPoint,
                    ),
                    _buildLoungeList(
                      isLoading: _isLoadingArrival,
                      error: _arrivalError,
                      lounges: _arrivalLounges,
                      selectedLounge: _selectedPostTripLounge,
                      isPreTrip: false,
                      stopName: widget.alightingPoint,
                    ),
                  ],
                ),
              ),
            ),

            // Bottom actions
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildBusSummary() {
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
                color: AppColors.primarySurface,
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
                    widget.trip.routeName,
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
                    '${widget.boardingPoint} → ${widget.alightingPoint}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${DateFormat('dd MMM, hh:mm a').format(widget.trip.departureTime)} • ${widget.selectedSeats.length} seat(s)',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  'LKR ${widget.busFare.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color:AppColors.primarySurface,
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

  Widget _buildSelectedLoungesSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primarySurface),
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
          const Row(
            children: [
              Icon(Icons.weekend, color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text(
                'Selected Lounges',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_selectedPreTripLounge != null)
            _buildSelectedLoungeChip(_selectedPreTripLounge!, true),
          if (_selectedPostTripLounge != null)
            _buildSelectedLoungeChip(_selectedPostTripLounge!, false),
        ],
      ),
    );
  }

  Widget _buildSelectedLoungeChip(SelectedLoungeData data, bool isPreTrip) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(
            isPreTrip ? Icons.weekend : Icons.hotel,
            color: AppColors.primary,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.lounge.loungeName,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${data.guests.length} guest(s) • ${_formatPricingType(data.pricingType)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                ),
              ],
            ),
          ),
          Text(
            'LKR ${data.totalPrice.toStringAsFixed(0)}',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _removeLounge(isPreTrip),
            child: Icon(Icons.close, color: Colors.red.shade400, size: 18),
          ),
        ],
      ),
    );
  }

  String _formatPricingType(String type) {
    switch (type) {
      case '1_hour':
        return '1 Hour';
      case '2_hours':
        return '2 Hours';
      case '3_hours':
        return '3 Hours';
      case 'until_bus':
        return 'Until Bus';
      default:
        return type;
    }
  }

  Widget _buildLoungeList({
    required bool isLoading,
    required String? error,
    required List<Lounge> lounges,
    required SelectedLoungeData? selectedLounge,
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
                style: TextStyle(color: Colors.grey.shade600),
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
              final isSelected = selectedLounge?.lounge.id == lounge.id;

              return _buildLoungeCard(
                lounge: lounge,
                isSelected: isSelected,
                isPreTrip: isPreTrip,
                onTap: () => _configureLoungeBooking(lounge, isPreTrip),
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
    required bool isPreTrip,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primarySurface : const Color.fromARGB(255, 76, 149, 246),
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
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: lounge.images.isNotEmpty
                  ? Image.network(
                      lounge.images.first,
                      height: 100,
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
                            color: const Color.fromARGB(255, 236, 235, 234).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                size: 14,
                                color:AppColors.primarySurface,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                lounge.averageRating!.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 238, 237, 234),
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
                      ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected
                              ? Colors.green
                              : AppColors.primary,
                          foregroundColor: isSelected
                              ? Colors.white
                              : AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          isSelected ? 'Selected ✓' : 'Add',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.white,
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
      height: 100,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.weekend, size: 32, color: Colors.grey.shade400),
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
    final hasSelections =
        _selectedPreTripLounge != null || _selectedPostTripLounge != null;

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Total display
            if (hasSelections)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total (Bus + Lounge)',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      'LKR ${_totalWithLounges.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Color(0xFFFFC300),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _skipLounges,
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
                        color: Color.fromARGB(179, 255, 255, 255),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _continueWithLounges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 238, 238, 237),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      hasSelections ? 'Continue with Lounge' : 'Continue',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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
  }
}

/// Result from AddLoungeScreen
class AddLoungeResult {
  final SelectedLoungeData? preTripLounge;
  final SelectedLoungeData? postTripLounge;

  AddLoungeResult({this.preTripLounge, this.postTripLounge});

  bool get hasLounges => preTripLounge != null || postTripLounge != null;
}

// ============================================================================
// LOUNGE CONFIGURATION SHEET
// ============================================================================

class _LoungeConfigurationSheet extends StatefulWidget {
  final Lounge lounge;
  final bool isPreTrip;
  final DateTime busDepartureTime;
  final DateTime? busArrivalTime;
  final String passengerName;
  final String passengerPhone;

  const _LoungeConfigurationSheet({
    required this.lounge,
    required this.isPreTrip,
    required this.busDepartureTime,
    this.busArrivalTime,
    required this.passengerName,
    required this.passengerPhone,
  });

  @override
  State<_LoungeConfigurationSheet> createState() =>
      _LoungeConfigurationSheetState();
}

class _LoungeConfigurationSheetState extends State<_LoungeConfigurationSheet> {
  final LoungeBookingService _loungeService = LoungeBookingService();

  String? _selectedPricingType;
  final List<LoungeGuestRequest> _guests = [];
  final Map<String, PreOrderItemData> _cart = {};

  List<LoungeProduct> _products = [];
  bool _isLoadingProducts = false;

  final TextEditingController _guestNameController = TextEditingController();
  final TextEditingController _guestPhoneController = TextEditingController();

  // Transport selection
  String? _preTripTransportType;
  String? _preTripPickupLocation;
  String? _postTripTransportType;
  String? _postTripPickupLocation;

  // Transport locations (5 popular areas)
  final List<Map<String, String>> _transportLocations = [
    {'id': '1', 'name': 'City Center', 'icon': '🏙️'},
    {'id': '2', 'name': 'Airport', 'icon': '✈️'},
    {'id': '3', 'name': 'Railway Station', 'icon': '🚂'},
    {'id': '4', 'name': 'Hotel District', 'icon': '🏨'},
    {'id': '5', 'name': 'Shopping Mall', 'icon': '🛍️'},
  ];

  // Transport pricing
  final Map<String, double> _transportPricing = {
    'van': 2500.0,
    'car': 1800.0,
    'tuktuk': 800.0,
  };

  @override
  void initState() {
    super.initState();
    // Add primary guest automatically (from bus booking)
    _guests.add(
      LoungeGuestRequest(
        guestName: widget.passengerName,
        guestPhone: widget.passengerPhone,
        isPrimary: true,
      ),
    );
    _loadProducts();
  }

  @override
  void dispose() {
    _guestNameController.dispose();
    _guestPhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoadingProducts = true);
    try {
      final products = await _loungeService.getLoungeProducts(widget.lounge.id);
      setState(() {
        _products = products.where((p) => p.isPreOrderable).toList();
        _isLoadingProducts = false;
      });
    } catch (e) {
      setState(() => _isLoadingProducts = false);
    }
  }

  double _getPriceForType(String? type) {
    switch (type) {
      case '1_hour':
        return widget.lounge.price1Hour ?? 0;
      case '2_hours':
        return widget.lounge.price2Hours ?? 0;
      case '3_hours':
        return widget.lounge.price3Hours ?? 0;
      case 'until_bus':
        return widget.lounge.priceUntilBus ?? 0;
      default:
        return 0;
    }
  }

  double get _basePrice =>
      _getPriceForType(_selectedPricingType) * _guests.length;

  double get _preOrderTotal =>
      _cart.values.fold(0, (sum, item) => sum + item.totalPrice);

  double get _transportCost {
    if (widget.isPreTrip && _preTripTransportType != null) {
      return _transportPricing[_preTripTransportType] ?? 0.0;
    } else if (!widget.isPreTrip && _postTripTransportType != null) {
      return _transportPricing[_postTripTransportType] ?? 0.0;
    }
    return 0.0;
  }

  double get _totalPrice => _basePrice + _preOrderTotal + _transportCost;

  void _addGuest() {
    final name = _guestNameController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _guests.add(
        LoungeGuestRequest(
          guestName: name,
          guestPhone: _guestPhoneController.text.trim().isNotEmpty
              ? _guestPhoneController.text.trim()
              : null,
          isPrimary: false,
        ),
      );
      _guestNameController.clear();
      _guestPhoneController.clear();
    });
  }

  void _removeGuest(int index) {
    if (index == 0) return; // Can't remove primary guest
    setState(() => _guests.removeAt(index));
  }

  void _updateCartItem(LoungeProduct product, int quantity) {
    setState(() {
      if (quantity <= 0) {
        _cart.remove(product.id);
      } else {
        _cart[product.id] = PreOrderItemData(
          productId: product.id,
          productName: product.name,
          unitPrice: product.price,
          quantity: quantity,
          imageUrl: product.imageUrl,
        );
      }
    });
  }

  void _confirm() {
    if (_selectedPricingType == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a duration')));
      return;
    }

    // Calculate check-in time based on pre-trip or post-trip
    final DateTime tripDateTime = widget.isPreTrip
        ? widget.busDepartureTime
        : (widget.busArrivalTime ?? widget.busDepartureTime);

    // For pre-trip: check-in 1-2 hours before departure
    // For post-trip: check-in at arrival time
    final checkInTime = DateFormat('HH:mm').format(
      widget.isPreTrip
          ? tripDateTime.subtract(const Duration(hours: 1))
          : tripDateTime,
    );

    final result = SelectedLoungeData(
      lounge: widget.lounge,
      pricingType: _selectedPricingType!,
      pricePerGuest: _getPriceForType(_selectedPricingType),
      guests: _guests,
      preOrders: _cart.values.toList(),
      basePrice: _basePrice,
      preOrderTotal: _preOrderTotal,
      totalPrice: _totalPrice,
      tripDate: tripDateTime,
      checkInTime: checkInTime,
      transportType: widget.isPreTrip
          ? _preTripTransportType
          : _postTripTransportType,
      pickupLocation: widget.isPreTrip
          ? (_preTripPickupLocation != null
                ? _transportLocations.firstWhere(
                    (l) => l['id'] == _preTripPickupLocation,
                  )['name']
                : null)
          : (_postTripPickupLocation != null
                ? _transportLocations.firstWhere(
                    (l) => l['id'] == _postTripPickupLocation,
                  )['name']
                : null),
      transportCost: _transportCost,
    );

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.lounge.loungeName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            widget.isPreTrip
                                ? 'Boarding Lounge'
                                : 'Destination Lounge',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Duration selection
                      const Text(
                        'Select Duration',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDurationOptions(),

                      const SizedBox(height: 24),

                      // Transport selection
                      const Text(
                        'Add Transport (Optional)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Get picked up from your location to the lounge',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTransportSection(),

                      const SizedBox(height: 24),

                      // Guests
                      const Text(
                        'Guests',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildGuestsList(),

                      const SizedBox(height: 24),

                      // Pre-orders (optional)
                      if (_products.isNotEmpty) ...[
                        const Text(
                          'Pre-Order Food & Drinks (Optional)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildPreOrderSection(),
                      ],

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              // Bottom
              _buildBottomSection(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDurationOptions() {
    return Column(
      children: [
        if (widget.lounge.priceUntilBus != null && widget.isPreTrip)
          _buildDurationOption(
            'until_bus',
            'Until Bus Departs',
            widget.lounge.priceUntilBus!,
            isHighlighted: true,
          ),
        if (widget.lounge.price1Hour != null)
          _buildDurationOption('1_hour', '1 Hour', widget.lounge.price1Hour!),
        if (widget.lounge.price2Hours != null)
          _buildDurationOption(
            '2_hours',
            '2 Hours',
            widget.lounge.price2Hours!,
          ),
        if (widget.lounge.price3Hours != null)
          _buildDurationOption(
            '3_hours',
            '3 Hours',
            widget.lounge.price3Hours!,
          ),
        if (widget.lounge.priceUntilBus != null && !widget.isPreTrip)
          _buildDurationOption(
            'until_bus',
            'Flexible Duration',
            widget.lounge.priceUntilBus!,
          ),
      ],
    );
  }

  Widget _buildDurationOption(
    String type,
    String label,
    double price, {
    bool isHighlighted = false,
  }) {
    final isSelected = _selectedPricingType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedPricingType = type),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isHighlighted
                      ? const Color(0xFFFFC300)
                      : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: type,
              groupValue: _selectedPricingType,
              onChanged: (v) => setState(() => _selectedPricingType = v),
              activeColor: AppColors.primary,
            ),
            Expanded(
              child: Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isSelected ? AppColors.primary : Colors.black87,
                    ),
                  ),
                  if (isHighlighted) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 244, 243, 241),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Recommended',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              'LKR ${price.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : Colors.black87,
              ),
            ),
            const Text(
              '/person',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestsList() {
    return Column(
      children: [
        ...List.generate(_guests.length, (index) {
          final guest = _guests[index];
          final isPrimary = index == 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: isPrimary
                      ? AppColors.primary
                      : Colors.grey.shade200,
                  radius: 18,
                  child: Text(
                    guest.guestName[0].toUpperCase(),
                    style: TextStyle(
                      color: isPrimary ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            guest.guestName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          if (isPrimary) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFC300),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Primary',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (guest.guestPhone != null)
                        Text(
                          guest.guestPhone!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!isPrimary)
                  IconButton(
                    onPressed: () => _removeGuest(index),
                    icon: const Icon(Icons.close, color: Colors.red, size: 20),
                  ),
              ],
            ),
          );
        }),
        // Add guest form
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              TextField(
                controller: _guestNameController,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Guest Name',
                  labelStyle: const TextStyle(color: Colors.black87),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _guestPhoneController,
                style: const TextStyle(color: Colors.black),
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone (Optional)',
                  labelStyle: const TextStyle(color: Colors.black87),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _addGuest,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Guest'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreOrderSection() {
    if (_isLoadingProducts) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: _products.map((product) {
        final cartItem = _cart[product.id];
        final quantity = cartItem?.quantity ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? Image.network(
                        product.imageUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey.shade200,
                          child: Icon(
                            Icons.fastfood,
                            color: Colors.grey.shade400,
                            size: 28,
                          ),
                        ),
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey.shade200,
                        child: Icon(
                          Icons.fastfood,
                          color: Colors.grey.shade400,
                          size: 28,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'LKR ${product.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              // Quantity controls
              if (quantity == 0)
                IconButton(
                  onPressed: () => _updateCartItem(product, 1),
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 18),
                  ),
                )
              else
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _updateCartItem(product, quantity - 1),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.remove, size: 16),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '$quantity',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _updateCartItem(product, quantity + 1),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Price breakdown
          if (_selectedPricingType != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Lounge (${_guests.length} guests)',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                Text(
                  'LKR ${_basePrice.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
            if (_preOrderTotal > 0) ...[
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pre-orders',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  Text(
                    'LKR ${_preOrderTotal.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ],
            // Transport section
            if (widget.isPreTrip && _preTripTransportType != null) ...[
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transport (${_preTripTransportType!.toUpperCase()})',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  Text(
                    'LKR ${_transportPricing[_preTripTransportType]!.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ],
            if (!widget.isPreTrip && _postTripTransportType != null) ...[
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transport (${_postTripTransportType!.toUpperCase()})',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  Text(
                    'LKR ${_transportPricing[_postTripTransportType]!.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ],
            const Divider(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'LKR ${_totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          // Confirm button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedPricingType != null ? _confirm : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC300),
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Add ${widget.isPreTrip ? "Pre-Trip" : "Post-Trip"} Lounge',
                style: TextStyle(
                  color: _selectedPricingType != null
                      ? AppColors.primary
                      : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransportSection() {
    final selectedTransport = widget.isPreTrip
        ? _preTripTransportType
        : _postTripTransportType;
    final selectedLocation = widget.isPreTrip
        ? _preTripPickupLocation
        : _postTripPickupLocation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Vehicle selection
        Row(
          children: [
            _buildVehicleOption('van', '🚐', 'Van', 'Up to 8 people', 2500.0),
            const SizedBox(width: 12),
            _buildVehicleOption('car', '🚗', 'Car', 'Up to 4 people', 1800.0),
            const SizedBox(width: 12),
            _buildVehicleOption(
              'tuktuk',
              '🛺',
              'Tuk Tuk',
              'Up to 3 people',
              800.0,
            ),
          ],
        ),

        // Location selection (show only if transport is selected)
        if (selectedTransport != null) ...[
          const SizedBox(height: 16),
          const Text(
            'Pickup Location',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _transportLocations.map((location) {
              final isSelected = selectedLocation == location['id'];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (widget.isPreTrip) {
                      _preTripPickupLocation = location['id'];
                    } else {
                      _postTripPickupLocation = location['id'];
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFFC300)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFFFC300)
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        location['icon']!,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        location['name']!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? AppColors.primary
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Driver will contact you 30 minutes before pickup',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVehicleOption(
    String type,
    String emoji,
    String name,
    String capacity,
    double price,
  ) {
    final isSelected = widget.isPreTrip
        ? _preTripTransportType == type
        : _postTripTransportType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (widget.isPreTrip) {
              if (_preTripTransportType == type) {
                _preTripTransportType = null;
                _preTripPickupLocation = null;
              } else {
                _preTripTransportType = type;
              }
            } else {
              if (_postTripTransportType == type) {
                _postTripTransportType = null;
                _postTripPickupLocation = null;
              } else {
                _postTripTransportType = type;
              }
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFFC300).withOpacity(0.2)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFFC300)
                  : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFFFC300).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 4),
              Text(
                name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              Text(
                capacity,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
