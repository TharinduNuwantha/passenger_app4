import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../models/booking_models.dart';
import '../../models/search_models.dart';
import '../../services/booking_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import 'booking_intent_flow_screen.dart';

/// Transit Seat Booking Screen — Two-Step Seat Selection for A → B → C journeys
///
/// Step 1: Select seat on Leg 1 bus (A → B)
/// Step 2: Select seat on Leg 2 bus (B → C)
/// After both steps, proceeds to BookingIntentFlowScreen
class TransitSeatBookingScreen extends StatefulWidget {
  /// The combined transit trip (isTransit = true, has leg1 and leg2)
  final TripResult transit;

  /// Boarding point name for full journey (from A)
  final String boardingPoint;

  /// Alighting point name for full journey (to C)
  final String alightingPoint;

  /// Stop ID for A (boarding stop)
  final String? boardingStopId;

  /// Stop ID for C (final alighting stop)
  final String? alightingStopId;

  /// Master route ID for lounge lookup (can be null for transit)
  final String? masterRouteId;

  /// Origin city (from user search)
  final String? originCity;

  /// Destination city (from user search)
  final String? destinationCity;

  const TransitSeatBookingScreen({
    super.key,
    required this.transit,
    required this.boardingPoint,
    required this.alightingPoint,
    this.boardingStopId,
    this.alightingStopId,
    this.masterRouteId,
    this.originCity,
    this.destinationCity,
  });

  @override
  State<TransitSeatBookingScreen> createState() =>
      _TransitSeatBookingScreenState();
}

class _TransitSeatBookingScreenState extends State<TransitSeatBookingScreen>
    with SingleTickerProviderStateMixin {
  final BookingService _bookingService = BookingService();
  final AuthService _authService = AuthService();
  final Logger _logger = Logger();

  // Step tracking: 0 = Leg 1, 1 = Leg 2
  int _currentStep = 0;

  // Leg 1 seat state
  bool _isLoadingLeg1 = true;
  String? _errorLeg1;
  List<TripSeat> _seatsLeg1 = [];
  final Set<String> _selectedSeatIdsLeg1 = {};

  // Leg 2 seat state
  bool _isLoadingLeg2 = true;
  String? _errorLeg2;
  List<TripSeat> _seatsLeg2 = [];
  final Set<String> _selectedSeatIdsLeg2 = {};

  late AnimationController _stepAnimController;

  @override
  void initState() {
    super.initState();
    _stepAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _loadLeg1Seats();
    _loadLeg2Seats();
  }

  @override
  void dispose() {
    _stepAnimController.dispose();
    super.dispose();
  }

  TripResult get _leg1 => widget.transit.leg1!;
  TripResult get _leg2 => widget.transit.leg2!;

  Future<void> _loadLeg1Seats() async {
    setState(() {
      _isLoadingLeg1 = true;
      _errorLeg1 = null;
    });
    try {
      final response = await _bookingService.getTripSeats(_leg1.tripId);
      setState(() {
        _seatsLeg1 = response.seats;
        _isLoadingLeg1 = false;
      });
    } catch (e) {
      _logger.e('Failed to load Leg 1 seats: $e');
      setState(() {
        _errorLeg1 = e.toString().replaceAll('Exception: ', '');
        _isLoadingLeg1 = false;
      });
    }
  }

  Future<void> _loadLeg2Seats() async {
    setState(() {
      _isLoadingLeg2 = true;
      _errorLeg2 = null;
    });
    try {
      final response = await _bookingService.getTripSeats(_leg2.tripId);
      setState(() {
        _seatsLeg2 = response.seats;
        _isLoadingLeg2 = false;
      });
    } catch (e) {
      _logger.e('Failed to load Leg 2 seats: $e');
      setState(() {
        _errorLeg2 = e.toString().replaceAll('Exception: ', '');
        _isLoadingLeg2 = false;
      });
    }
  }

  void _toggleSeat(String id, bool isLeg1) {
    setState(() {
      final set = isLeg1 ? _selectedSeatIdsLeg1 : _selectedSeatIdsLeg2;
      if (set.contains(id)) {
        set.remove(id);
      } else {
        if (set.length >= 10) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Maximum 10 seats can be selected'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        set.add(id);
      }
    });
  }

  double get _totalPrice {
    final leg1Price = _seatsLeg1
        .where((s) => _selectedSeatIdsLeg1.contains(s.id))
        .fold(0.0, (sum, s) => sum + s.currentPrice);
    final leg2Price = _seatsLeg2
        .where((s) => _selectedSeatIdsLeg2.contains(s.id))
        .fold(0.0, (sum, s) => sum + s.currentPrice);
    return leg1Price + leg2Price;
  }

  void _advanceToLeg2() {
    if (_selectedSeatIdsLeg1.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one seat for Leg 1'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _currentStep = 1);
    _stepAnimController.forward(from: 0);
  }

  void _goBackToLeg1() {
    setState(() => _currentStep = 0);
    _stepAnimController.reverse(from: 1);
  }

  Future<void> _proceedToBooking() async {
    if (_selectedSeatIdsLeg2.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one seat for Leg 2'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final isAuthenticated = await _authService.isAuthenticated();
    if (!isAuthenticated) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to continue with booking'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      return;
    }

    final user = await _authService.getCurrentUser();
    if (!mounted) return;

    // Combine all selected seats from both legs for the main trip
    final allSelectedSeats = [
      ..._seatsLeg1.where((s) => _selectedSeatIdsLeg1.contains(s.id)),
      ..._seatsLeg2.where((s) => _selectedSeatIdsLeg2.contains(s.id)),
    ];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingIntentFlowScreen(
          trip: widget.transit,
          selectedSeats: allSelectedSeats,
          boardingPoint: widget.boardingPoint,
          alightingPoint: widget.alightingPoint,
          boardingStopId: widget.boardingStopId,
          alightingStopId: widget.alightingStopId,
          masterRouteId: widget.masterRouteId ?? widget.transit.masterRouteId,
          totalPrice: _totalPrice,
          userName: user?.fullName ?? '',
          userPhone: user?.phoneNumber ?? '',
          userEmail: user?.email,
          originCity: widget.originCity,
          destinationCity: widget.destinationCity,
          tripLeg1: _leg1,
          tripLeg2: _leg2,
          selectedSeatsLeg1: _selectedSeatIdsLeg1.toList(),
          selectedSeatsLeg2: _selectedSeatIdsLeg2.toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentStep == 1) {
          _goBackToLeg1();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.primary,
        appBar: _buildAppBar(),
        body: SafeArea(
          child: Column(
            children: [
              _buildStepIndicator(),
              _buildJourneyBanner(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(child: _buildCurrentStepContent()),
                      _buildBottomBar(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          if (_currentStep == 1) {
            _goBackToLeg1();
          } else {
            Navigator.pop(context);
          }
        },
      ),
      title: Text(
        _currentStep == 0 ? 'Select Seats — Leg 1' : 'Select Seats — Leg 2',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          _buildStepDot(step: 0, label: 'Leg 1\n${_leg1.boardingPoint.split(' ').first} → ${_leg1.droppingPoint.split(' ').first}'),
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _currentStep >= 1
                      ? [Colors.white, Colors.white]
                      : [Colors.white, Colors.white.withOpacity(0.3)],
                ),
              ),
            ),
          ),
          _buildStepDot(step: 1, label: 'Leg 2\n${_leg2.boardingPoint.split(' ').first} → ${_leg2.droppingPoint.split(' ').first}'),
        ],
      ),
    );
  }

  Widget _buildStepDot({required int step, required String label}) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isActive ? 36 : 28,
          height: isActive ? 36 : 28,
          decoration: BoxDecoration(
            color: isCompleted
                ? const Color(0xFF4CAF50)
                : (isActive ? Colors.white : Colors.white.withOpacity(0.3)),
            shape: BoxShape.circle,
            border: isActive
                ? Border.all(color: Colors.white, width: 3)
                : null,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? AppColors.primary : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isActive ? 16 : 13,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive
                ? Colors.white
                : Colors.white.withOpacity(0.6),
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildJourneyBanner() {
    final trip = _currentStep == 0 ? _leg1 : _leg2;
    final stepColor = _currentStep == 0
        ? const Color(0xFF1976D2)
        : const Color(0xFF7B1FA2);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.directions_bus,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.routeName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${trip.boardingPoint} → ${trip.droppingPoint}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Transit badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _currentStep == 0
                    ? const Color(0xFFFFF9C4)
                    : const Color(0xFFE8EAF6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _currentStep == 0 ? trip.busType.toUpperCase() : trip.busType.toUpperCase(),
                style: TextStyle(
                  color: stepColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    if (_currentStep == 0) {
      return _isLoadingLeg1
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorLeg1 != null
          ? _buildErrorView(_errorLeg1!, _loadLeg1Seats)
          : _buildSeatGrid(_seatsLeg1, _selectedSeatIdsLeg1, isLeg1: true);
    } else {
      return _isLoadingLeg2
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorLeg2 != null
          ? _buildErrorView(_errorLeg2!, _loadLeg2Seats)
          : _buildSeatGrid(_seatsLeg2, _selectedSeatIdsLeg2, isLeg1: false);
    }
  }

  Widget _buildErrorView(String message, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.grey, size: 56),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Try Again', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatGrid(
    List<TripSeat> seats,
    Set<String> selectedIds, {
    required bool isLeg1,
  }) {
    // Legend
    final legend = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendItem(Icons.event_seat, AppColors.secondary, 'Selected'),
          const SizedBox(width: 20),
          _legendItem(Icons.event_seat_outlined, const Color(0xFF4CAF50), 'Available'),
          const SizedBox(width: 20),
          _legendItem(Icons.event_seat, const Color(0xFFE57373), 'Booked'),
        ],
      ),
    );

    if (seats.isEmpty) {
      return Column(
        children: [
          legend,
          const Expanded(
            child: Center(
              child: Text(
                'No seats available',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          ),
        ],
      );
    }

    // Group by row
    final Map<int, List<TripSeat>> byRow = {};
    int maxCol = 0;
    for (final seat in seats) {
      byRow.putIfAbsent(seat.seatRow, () => []);
      byRow[seat.seatRow]!.add(seat);
      if (seat.seatColumn > maxCol) maxCol = seat.seatColumn;
    }
    final sortedRows = byRow.keys.toList()..sort();
    final aislePosition = maxCol <= 4 ? 2 : 3;

    final selectedSeats = seats.where((s) => selectedIds.contains(s.id)).toList();
    final selectedCount = selectedSeats.length;

    return Column(
      children: [
        legend,
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F7FA),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$selectedCount selected • ${seats.length} total',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.directions_bus,
                          size: 36,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: sortedRows.map((rowNum) {
                          final rowSeats = byRow[rowNum]!
                            ..sort((a, b) => a.seatColumn.compareTo(b.seatColumn));
                          return _buildSeatRow(
                            rowNum,
                            rowSeats,
                            maxCol,
                            aislePosition,
                            selectedIds,
                            isLeg1: isLeg1,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeatRow(
    int rowNum,
    List<TripSeat> rowSeats,
    int maxCol,
    int aislePosition,
    Set<String> selectedIds, {
    required bool isLeg1,
  }) {
    final seatMap = {for (var s in rowSeats) s.seatColumn: s};

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rowNum',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(maxCol, (idx) {
                final colNum = idx + 1;
                if (idx == aislePosition) return const SizedBox(width: 20);
                final seat = seatMap[idx < aislePosition ? colNum : colNum];
                if (seat == null) return const SizedBox(width: 40, height: 40);
                return _buildSeatWidget(seat, selectedIds, isLeg1: isLeg1);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatWidget(
    TripSeat seat,
    Set<String> selectedIds, {
    required bool isLeg1,
  }) {
    final isSelected = selectedIds.contains(seat.id);
    final isBooked = seat.isBooked || seat.isBlocked;
    final canSelect = seat.canBeSelected;

    Color color;
    IconData icon;

    if (isSelected) {
      color = AppColors.secondary;
      icon = Icons.event_seat;
    } else if (isBooked) {
      color = const Color(0xFFE57373).withOpacity(0.7);
      icon = Icons.event_seat;
    } else if (canSelect) {
      color = const Color(0xFF4CAF50);
      icon = Icons.event_seat_outlined;
    } else {
      color = Colors.grey.shade300;
      icon = Icons.event_seat_outlined;
    }

    return GestureDetector(
      onTap: canSelect ? () => _toggleSeat(seat.id, isLeg1) : null,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        child: Tooltip(
          message: '${seat.seatNumber} - LKR ${seat.currentPrice.toStringAsFixed(0)}',
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 1),
              Text(
                seat.seatNumber,
                style: TextStyle(
                  fontSize: 9,
                  color: isSelected ? AppColors.primary : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legendItem(IconData icon, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.primary.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final currentSelected = _currentStep == 0
        ? _seatsLeg1.where((s) => _selectedSeatIdsLeg1.contains(s.id)).toList()
        : _seatsLeg2.where((s) => _selectedSeatIdsLeg2.contains(s.id)).toList();

    final count = currentSelected.length;
    final stepPrice = currentSelected.fold(0.0, (sum, s) => sum + s.currentPrice);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (count > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Seats: ${currentSelected.map((s) => s.seatNumber).join(', ')}',
                      style: TextStyle(
                        color: AppColors.primary.withOpacity(0.7),
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'LKR ${stepPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: count == 0
                  ? null
                  : (_currentStep == 0 ? _advanceToLeg2 : _proceedToBooking),
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentStep == 0
                    ? AppColors.secondary
                    : const Color(0xFF7B1FA2),
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: Text(
                count > 0
                    ? (_currentStep == 0
                        ? 'Continue to Leg 2 ($count seat${count == 1 ? '' : 's'})'
                        : 'Proceed to Booking ($count seat${count == 1 ? '' : 's'})')
                    : (_currentStep == 0
                        ? 'Select Seats for Leg 1'
                        : 'Select Seats for Leg 2'),
                style: TextStyle(
                  color: count > 0 ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
