import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../models/booking_models.dart';
import '../../models/search_models.dart';
import '../../services/booking_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import 'booking_confirm_screen.dart';
import 'booking_intent_flow_screen.dart';

/// Enhanced seat booking screen that fetches real seat data from API
class SeatBookingScreenV2 extends StatefulWidget {
  /// Trip data from search results
  final TripResult trip;

  /// Boarding point name (from search)
  final String boardingPoint;

  /// Alighting point name (from search)
  final String alightingPoint;

  /// Boarding stop ID (from search details)
  final String? boardingStopId;

  /// Alighting stop ID (from search details)
  final String? alightingStopId;

  /// Master route ID (for lounge lookup)
  final String? masterRouteId;

  /// Use new intent-based booking flow (with TTL seat holding)
  final bool useIntentFlow;

  final String? originCity;
  final String? destinationCity;

  /// User GPS coords from the original search request, used for
  /// proximity-based lounge sorting in the Add Lounge screen.
  final double? fromLat;
  final double? fromLng;
  final double? toLat;
  final double? toLng;

  const SeatBookingScreenV2({
    super.key,
    required this.trip,
    required this.boardingPoint,
    required this.alightingPoint,
    this.boardingStopId,
    this.alightingStopId,
    this.masterRouteId,
    this.useIntentFlow = true, // Default to new flow
    this.originCity,
    this.destinationCity,
    this.fromLat,
    this.fromLng,
    this.toLat,
    this.toLng,
  });

  @override
  State<SeatBookingScreenV2> createState() => _SeatBookingScreenV2State();
}

class _SeatBookingScreenV2State extends State<SeatBookingScreenV2> {
  final BookingService _bookingService = BookingService();
  final AuthService _authService = AuthService();
  final Logger _logger = Logger();

  bool _isLoading = true;
  String? _errorMessage;
  List<TripSeat> _seats = [];
  final Set<String> _selectedSeatIds = {};

  // Existing bookings for this trip
  List<BookingListItem> _existingBookings = [];
  bool _hasExistingBooking = false;

  @override
  void initState() {
    super.initState();
    _loadSeats();
    _checkExistingBookings();
  }

  /// Check if user has existing bookings on this trip
  Future<void> _checkExistingBookings() async {
    try {
      final isAuthenticated = await _authService.isAuthenticated();
      if (!isAuthenticated) return;

      final bookings = await _bookingService.getUpcomingBookings(limit: 50);

      // Filter for bookings on this specific trip
      final tripBookings = bookings.where((b) {
        if (b.departureDatetime != null) {
          final sameDay =
              b.departureDatetime!.year == widget.trip.departureTime.year &&
              b.departureDatetime!.month == widget.trip.departureTime.month &&
              b.departureDatetime!.day == widget.trip.departureTime.day;
          final sameRoute =
              b.routeName?.toLowerCase() == widget.trip.routeName.toLowerCase();
          return sameDay && sameRoute == true;
        }
        return false;
      }).toList();

      if (tripBookings.isNotEmpty && mounted) {
        setState(() {
          _existingBookings = tripBookings;
          _hasExistingBooking = true;
        });
        _logger.i(
          'Found ${tripBookings.length} existing booking(s) on this trip',
        );
      }
    } catch (e) {
      _logger.e('Failed to check existing bookings: $e');
    }
  }

  /// Show bottom sheet with existing bookings
  void _showExistingBookingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color.fromARGB(0, 42, 123, 210),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.bookmark,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: const Text(
                        'Your Bookings on This Trip',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _existingBookings.length,
                  itemBuilder: (context, index) {
                    final booking = _existingBookings[index];
                    return _buildExistingBookingCard(booking);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExistingBookingCard(BookingListItem booking) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Ref: ${booking.bookingReference}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(booking.bookingStatus),
              ],
            ),
            const SizedBox(height: 8),
            if (booking.numberOfSeats != null)
              Text(
                '${booking.numberOfSeats} seat(s) • ${booking.formattedTotal}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            if (booking.departureDatetime != null)
              Text(
                'Departure: ${_formatDateTime(booking.departureDatetime!)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(MasterBookingStatus status) {
    Color bgColor;
    Color textColor;
    String text;

    switch (status) {
      case MasterBookingStatus.confirmed:
        bgColor = const Color(0xFF4CAF50).withOpacity(0.1);
        textColor = const Color(0xFF4CAF50);
        text = 'Confirmed';
        break;
      case MasterBookingStatus.pending:
        bgColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        text = 'Pending';
        break;
      default:
        bgColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
        text = status.displayName;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day}/${dt.month}/${dt.year} ${hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _loadSeats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _bookingService.getTripSeats(widget.trip.tripId);
      setState(() {
        _seats = response.seats;
        _isLoading = false;
      });
      _logger.i('Loaded ${_seats.length} seats');
    } catch (e) {
      _logger.e('Failed to load seats: $e');
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _toggleSeatSelection(TripSeat seat) {
    if (!seat.canBeSelected) return;

    setState(() {
      if (_selectedSeatIds.contains(seat.id)) {
        _selectedSeatIds.remove(seat.id);
      } else {
        if (_selectedSeatIds.length >= 10) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Maximum 10 seats can be selected'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        _selectedSeatIds.add(seat.id);
      }
    });
  }

  Color _getSeatColor(TripSeat seat) {
    if (_selectedSeatIds.contains(seat.id)) {
      return AppColors.secondary;
    }
    
    if (seat.isBooked) {
      // Gender-based colors for booked seats
      final gender = seat.passengerGender?.toLowerCase();
      if (gender == 'male') {
        return Colors.blue.shade600;
      } else if (gender == 'female') {
        return Colors.pink.shade300;
      }
      // Fallback for booked seats with no gender info
      return const Color.fromARGB(255, 215, 8, 8).withOpacity(0.5);
    }
    
    if (seat.isBlocked) {
      return Colors.grey.shade400;
    }
    
    if (seat.canBeSelected) {
      return const Color(0xFF4CAF50);
    }
    return Colors.grey.shade300;
  }

  IconData _getSeatIcon(TripSeat seat) {
    if (_selectedSeatIds.contains(seat.id)) {
      return Icons.event_seat;
    }
    if (seat.isBooked || seat.isBlocked) {
      return Icons.event_seat;
    }
    return Icons.event_seat_outlined;
  }

  List<TripSeat> get _selectedSeats {
    return _seats.where((s) => _selectedSeatIds.contains(s.id)).toList();
  }

  double get _totalPrice {
    return _selectedSeats.fold(0.0, (sum, seat) => sum + seat.currentPrice);
  }

  void _proceedToConfirm() async {
    if (_selectedSeats.isEmpty) return;

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

    if (widget.useIntentFlow) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookingIntentFlowScreen(
            trip: widget.trip,
            selectedSeats: _selectedSeats,
            boardingPoint: widget.boardingPoint,
            alightingPoint: widget.alightingPoint,
            boardingStopId: widget.boardingStopId,
            alightingStopId: widget.alightingStopId,
            masterRouteId: widget.masterRouteId ?? widget.trip.masterRouteId,
            totalPrice: _totalPrice,
            userName: user?.fullName ?? '',
            userPhone: user?.phoneNumber ?? '',
            userEmail: user?.email,
            originCity: widget.originCity,
            destinationCity: widget.destinationCity,
            fromLat: widget.fromLat,
            fromLng: widget.fromLng,
            toLat: widget.toLat,
            toLng: widget.toLng,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookingConfirmScreen(
            trip: widget.trip,
            selectedSeats: _selectedSeats,
            boardingPoint: widget.boardingPoint,
            alightingPoint: widget.alightingPoint,
            boardingStopId: widget.boardingStopId,
            alightingStopId: widget.alightingStopId,
            masterRouteId: widget.masterRouteId ?? widget.trip.masterRouteId,
            totalPrice: _totalPrice,
            userName: user?.fullName ?? '',
            userPhone: user?.phoneNumber ?? '',
            userEmail: user?.email,
          ),
        ),
      );
    }
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
          'Select Seats',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _errorMessage != null
            ? _buildErrorView()
            : Column(
                children: [
                  _buildTripInfo(),
                  if (_hasExistingBooking) _buildExistingBookingsBanner(),
                  _buildLegend(),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: _buildSeatLayout(),
                            ),
                          ),
                          _buildConfirmButton(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.white70),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Something went wrong',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadSeats,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExistingBookingsBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: GestureDetector(
        onTap: _showExistingBookingsSheet,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 82, 156, 222),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Color.fromARGB(255, 241, 242, 243),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You have ${_existingBookings.length} booking(s) on this trip',
                  style: const TextStyle(
                    color: Color.fromARGB(255, 243, 244, 246),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color.fromARGB(255, 210, 211, 213),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 82, 156, 222),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.trip.routeName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
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
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFC300),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.trip.busTypeDisplay,
                style: const TextStyle(
                  color: Color.fromARGB(255, 12, 12, 12),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLegendItem(Icons.event_seat, AppColors.secondary, 'Selected'),
            const SizedBox(width: 12),
            _buildLegendItem(
              Icons.event_seat_outlined,
              const Color(0xFF4CAF50),
              'Available',
            ),
            const SizedBox(width: 12),
            _buildLegendItem(
              Icons.male,
              Colors.blue.shade600,
              'Male',
            ),
            const SizedBox(width: 12),
            _buildLegendItem(
              Icons.female,
              Colors.pink.shade300,
              'Female',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.primary.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Fallback: original dynamic layout (used when total seats != 56)
  // ---------------------------------------------------------------------------

  /// Dynamic layout — matches the reference image exactly.
  /// Uses a Left Column and a Right Column aligned at the top,
  /// sorting seats sequentially to automatically create the staggered
  /// layout (right side extending further down/front).
  Widget _buildSeatLayout() {
    if (_seats.isEmpty) {
      return const Center(
        child: Text(
          'No seats available',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    // 1. Sort all seats by numerical seat number
    final List<TripSeat> sortedSeats = List.from(_seats);
    sortedSeats.sort((a, b) {
      final numA = int.tryParse(a.seatNumber.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final numB = int.tryParse(b.seatNumber.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      if (numA != numB) return numA.compareTo(numB);
      return a.seatNumber.compareTo(b.seatNumber);
    });

    // 2. Extract rear seats (assume 5 seats at the very end)
    final int rearSeatCount = 5;
    List<TripSeat> rearSeats = [];
    List<TripSeat> standardSeats = [];
    
    if (sortedSeats.length > rearSeatCount) {
      rearSeats = sortedSeats.sublist(sortedSeats.length - rearSeatCount);
      standardSeats = sortedSeats.sublist(0, sortedSeats.length - rearSeatCount);
    } else {
      rearSeats = sortedSeats;
    }

    // Optional: specifically reorder rear seats if exactly 5 to match image [51, 52, 55, 54, 53]
    if (rearSeats.length == 5) {
      rearSeats = [
        rearSeats[0], // 51
        rearSeats[1], // 52
        rearSeats[4], // 55
        rearSeats[3], // 54
        rearSeats[2], // 53
      ];
    }

    // 3. Group standard seats into rows of 4 (2 for left, 2 for right)
    // Handle the front row gap (remainder seats) first so they stay at the bottom/front
    final List<List<TripSeat>> leftColumnPairs = [];
    final List<List<TripSeat>> rightColumnPairs = [];
    
    final int remainder = standardSeats.length % 4;
    int startIndex = 0;
    
    if (remainder > 0) {
      final frontSeats = standardSeats.sublist(0, remainder);
      List<TripSeat> leftPair = [];
      List<TripSeat> rightPair = [];
      
      // Real buses have the door on the front-left, so right side fills first
      if (remainder == 1) {
        rightPair = [frontSeats[0]];
      } else if (remainder == 2) {
        rightPair = [frontSeats[0], frontSeats[1]];
      } else if (remainder == 3) {
        leftPair = [frontSeats[0]];
        rightPair = [frontSeats[1], frontSeats[2]];
      }
      
      leftColumnPairs.add(leftPair);
      rightColumnPairs.add(rightPair);
      startIndex = remainder;
    }
    
    for (int i = startIndex; i < standardSeats.length; i += 4) {
      List<TripSeat> leftPair = [];
      List<TripSeat> rightPair = [];
      
      if (i < standardSeats.length) leftPair.add(standardSeats[i]);
      if (i + 1 < standardSeats.length) leftPair.add(standardSeats[i + 1]);
      
      if (i + 2 < standardSeats.length) rightPair.add(standardSeats[i + 2]);
      if (i + 3 < standardSeats.length) rightPair.add(standardSeats[i + 3]);
      
      leftColumnPairs.add(leftPair);
      rightColumnPairs.add(rightPair);
    }

    // 5. Reverse the columns so the highest numbers (rear) are at the top
    final leftReversed = leftColumnPairs.reversed.toList();
    final rightReversed = rightColumnPairs.reversed.toList();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F7FA),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          // Stats header
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_selectedSeats.length} selected • ${_seats.length} total',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(Icons.directions_bus, size: 40, color: AppColors.primary),
              ],
            ),
          ),

          // "Rear" label at top
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.blueGrey.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blueGrey.withOpacity(0.3)),
            ),
            child: const Text(
              'Rear',
              style: TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.w600),
            ),
          ),

          // Seat grid
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Rear row at top (full width)
                  if (rearSeats.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: rearSeats.map((s) => _buildSeatWidget(s)).toList(),
                    ),
                    const SizedBox(height: 6),
                  ],

                  // Standard rows: Left and Right blocks aligned at the top
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start, // Crucial for stagger effect
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Left block
                      Column(
                        children: leftReversed.map((pair) => _buildPairWidget(pair)).toList(),
                      ),
                      
                      // Wider Walkway (48px aligns perfectly with rear middle seat)
                      const SizedBox(width: 48),
                      
                      // Right block
                      Column(
                        children: rightReversed.map((pair) => _buildPairWidget(pair)).toList(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  
                  // Gender Legend (Inline)
                  _buildGenderLayoutLegend(),
                  
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderLayoutLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildGenderLegendBox(Colors.blue.shade600, 'Male'),
          const SizedBox(width: 32),
          _buildGenderLegendBox(Colors.pink.shade300, 'Female'),
        ],
      ),
    );
  }

  Widget _buildGenderLegendBox(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  /// Helper to render a pair of seats in a column
  Widget _buildPairWidget(List<TripSeat> pair) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSeatCell(pair.isNotEmpty ? pair[0] : null),
          _buildSeatCell(pair.length > 1 ? pair[1] : null),
        ],
      ),
    );
  }

  /// Helper to render an individual cell (seat or empty space)
  Widget _buildSeatCell(TripSeat? seat) {
    if (seat == null) return const SizedBox(width: 48, height: 40);
    return _buildSeatWidget(seat);
  }

  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // Sri Lankan Bus Layout — only used when _seats.length == 56
  // 10 standard rows × 5 seats (2 left | aisle | 3 right) + 1 back row of 6
  // ---------------------------------------------------------------------------

  /// Assigns the 56 API seats into the fixed Sri Lankan layout.
  ///
  /// Mapping rule:
  ///   • Sort all seats by (seatRow ASC, seatColumn ASC).
  ///   • The last seatRow becomes the back row (6 seats).
  ///   • Each of the 10 standard rows: first 2 seats → left side,
  ///     next 3 seats → right side.  The actual [TripSeat] objects (with their
  ///     original IDs, prices, statuses) are used unchanged — only the visual
  ///     position changes.
  Widget _buildSriLankanBusLayout() {
    // ── Canonical grid assignment ────────────────────────────────────────────
    //
    // The API's seatRow / seatColumn values are arbitrary and cannot be trusted
    // for layout purposes (they may be 11/12/13, use W-suffixes, etc.).
    //
    // Strategy: sort the entire 56-seat list by (seatRow ASC, seatColumn ASC)
    // to get the natural booking order, then map them onto the fixed grid:
    //
    //   Flat index 0–49  → Grid rows 1–10, columns [L1,L2 | aisle | R1,R2,R3]
    //   Flat index 50–55 → Grid row 11 (back row), columns [B1–B6]
    //
    // The TripSeat objects (id, price, status) are used AS-IS — only their
    // visual position is determined by this mapping.

    // 1. Sort all seats by API row then column (preserves the operator's
    //    intended natural ordering).
    final sorted = List<TripSeat>.from(_seats)
      ..sort((a, b) {
        final rowCmp = a.seatRow.compareTo(b.seatRow);
        return rowCmp != 0 ? rowCmp : a.seatColumn.compareTo(b.seatColumn);
      });

    // 2. Split into the two sections.
    //    - Standard: first 50 seats  → 10 rows × 5 seats
    //    - Back row: last  6 seats   → 1 row  × 6 seats
    final standardSeats = sorted.sublist(0, 50); // indices 0-49
    final backRowSeats  = sorted.sublist(50);     // indices 50-55

    // 3. Slice standard seats into 10 rows of 5.
    final List<List<TripSeat>> standardRows = List.generate(
      10,
      (rowIdx) => standardSeats.sublist(rowIdx * 5, rowIdx * 5 + 5),
    );

    // ── Build UI ─────────────────────────────────────────────────────────────
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F7FA),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          // ── Stats + bus icon ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_selectedSeats.length} selected • ${_seats.length} total',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(
                  Icons.directions_bus,
                  size: 40,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),

          // ── Front landmark bar: [Door] ──── FRONT ──── [Driver] ──────────
          _buildFrontSection(),

          const SizedBox(height: 8),

          // ── Column header: L1  L2  _  R1  R2  R3 ────────────────────────
          _buildColumnHeaders(),

          const SizedBox(height: 4),

          // ── Scrollable seat grid ──────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Rows 1–10: display number is always 1-based index + 1
                  ...List.generate(10, (i) {
                    return _buildStandardRow(i + 1, standardRows[i]);
                  }),

                  const SizedBox(height: 6),

                  // Divider between row 10 and back row
                  Divider(
                    color: AppColors.primary.withOpacity(0.3),
                    thickness: 1.5,
                    indent: 10,
                    endIndent: 10,
                  ),

                  const SizedBox(height: 4),

                  // Row 11 — back row, 6 seats, no aisle
                  _buildBackRow(backRowSeats),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Front of bus: entrance door on the left, steering wheel on the right.
  Widget _buildFrontSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Left: entrance door (front-left of Sri Lankan bus)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFC300).withOpacity(0.25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFC300), width: 1.2),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.door_front_door,
                  size: 20,
                  color: Color(0xFFFFC300),
                ),
                SizedBox(height: 2),
                Text(
                  'Entry',
                  style: TextStyle(
                    fontSize: 9,
                    color: Color(0xFFFFC300),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Centre label
          const Expanded(
            child: Text(
              '— FRONT —',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ),

          // Right: driver / steering wheel
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.settings_backup_restore,
              size: 22,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// Column header row: L1 L2 | aisle | R1 R2 R3
  Widget _buildColumnHeaders() {
    const style = TextStyle(
      fontSize: 10,
      color: AppColors.primary,
      fontWeight: FontWeight.w600,
    );
    return Row(
      children: [
        const SizedBox(width: 30), // aligns with row-number label
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _headerCell('L1', style),
              _headerCell('L2', style),
              const SizedBox(width: 24), // aisle gap
              _headerCell('R1', style),
              _headerCell('R2', style),
              _headerCell('R3', style),
            ],
          ),
        ),
      ],
    );
  }

  Widget _headerCell(String text, TextStyle style) {
    return SizedBox(
      width: 40,
      child: Center(child: Text(text, style: style)),
    );
  }

  /// Renders one standard row (grid rows 1–10).
  ///
  /// [displayRowNum] is the 1-based label shown to the user (always 1–10).
  /// [rowSeats] is exactly 5 seats already in column order:
  ///   index 0,1 → L1, L2 (left side)
  ///   index 2,3,4 → R1, R2, R3 (right side)
  ///
  /// No column-value logic here — positions are purely by list index.
  Widget _buildStandardRow(int displayRowNum, List<TripSeat> rowSeats) {
    final l1 = rowSeats[0];
    final l2 = rowSeats[1];
    final r1 = rowSeats[2];
    final r2 = rowSeats[3];
    final r3 = rowSeats[4];

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          // Row label (1–10)
          SizedBox(
            width: 28,
            child: Text(
              '$displayRowNum',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // L1, L2
                _buildSeatWidget(l1),
                _buildSeatWidget(l2),
                // Centre aisle
                const SizedBox(width: 24),
                // R1, R2, R3
                _buildSeatWidget(r1),
                _buildSeatWidget(r2),
                _buildSeatWidget(r3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Back row: all 6 seats in a single horizontal line (no aisle split).
  Widget _buildBackRow(List<TripSeat> seats) {
    return Column(
      children: [
        const Text(
          'BACK ROW',
          style: TextStyle(
            fontSize: 10,
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: seats.map(_buildSeatWidget).toList(),
        ),
      ],
    );
  }

  Widget _buildEmptySeatPlaceholder() {
    return const SizedBox(width: 40, height: 40);
  }

  Widget _buildSeatWidget(TripSeat seat) {
    final isSelectable = seat.canBeSelected;
    final isSelected = _selectedSeatIds.contains(seat.id);
    final color = _getSeatColor(seat);

    return GestureDetector(
      onTap: isSelectable ? () => _toggleSeatSelection(seat) : null,
      child: Container(
        width: 44,
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Seat Number
            Text(
              seat.seatNumber.padLeft(2, '0'),
              style: TextStyle(
                fontSize: 11,
                color: (seat.isBlocked || !seat.canBeSelected)
                    ? Colors.black54
                    : Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.bold,
              ),
            ),
            
            // Gender Icon (Subtle overlay)
            if (seat.isBooked)
              Positioned(
                top: 2,
                right: 2,
                child: Icon(
                  seat.passengerGender?.toLowerCase() == 'male'
                      ? Icons.male
                      : seat.passengerGender?.toLowerCase() == 'female'
                          ? Icons.female
                          : null,
                  size: 14,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    final seatCount = _selectedSeats.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
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
        children: [
          if (seatCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Selected: ${_selectedSeats.map((s) => s.seatNumber).join(', ')}',
                    style: TextStyle(
                      color: AppColors.primary.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'LKR ${_totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: seatCount == 0 ? null : _proceedToConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: Text(
                seatCount > 0
                    ? 'Continue ($seatCount ${seatCount == 1 ? 'Seat' : 'Seats'})'
                    : 'Select Seats to Continue',
                style: TextStyle(
                  color: seatCount > 0
                      ? const Color.fromARGB(255, 236, 237, 238)
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
}