import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../models/booking_models.dart';
import '../../models/search_models.dart';
import '../../services/booking_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import 'booking_confirm_screen.dart';
import 'package:flutter/services.dart';
import 'booking_intent_flow_screen.dart';

// ── Design tokens ────────────────────────────────────────────────────────────
// Seat state colours
const _kAvailable  = Color(0xFF27AE60);   // Emerald green
const _kSelected   = Color(0xFF1976D2);   // Brand blue (= AppColors.primary)
const _kMale       = Color(0xFFE53935);   // Red – male booked
const _kFemale     = Color(0xFFE91E63);   // Pink – female booked
const _kBlocked    = Color(0xFFBDBDBD);   // Medium grey
const _kUnavail    = Color(0xFFEEEEEE);   // Light grey

// Surface / background
const _kBg         = Color(0xFFF4F6FB);   // Page background
const _kCard       = Colors.white;
const _kDivider    = Color(0xFFE8EBF0);
// ─────────────────────────────────────────────────────────────────────────────

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
      List<TripSeat> seats = response.seats;

      // ── Enrich booked seats with gender data from bookings API ──────────
      // The trip-seats endpoint may not include passenger_gender.
      // We fetch it from booking details (bus_booking_seats) and overlay it.
      seats = await _enrichSeatsWithGender(seats);

      // Sort seats to determine sequential order
      final List<TripSeat> sortedSeats = List.from(seats);
      sortedSeats.sort((a, b) {
        final numA =
            int.tryParse(a.seatNumber.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final numB =
            int.tryParse(b.seatNumber.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        if (numA != numB) return numA.compareTo(numB);
        return a.seatNumber.compareTo(b.seatNumber);
      });

      // Map each seat ID to its 1-based sequential display number
      final Map<String, String> displayNumbers = {};
      for (int i = 0; i < sortedSeats.length; i++) {
        displayNumbers[sortedSeats[i].id] = (i + 1).toString().padLeft(2, '0');
      }

      // Re-create the seats list with the displaySeatNumber assigned
      seats = seats.map((seat) {
        return seat.copyWith(
          displaySeatNumber: displayNumbers[seat.id],
        );
      }).toList();

      setState(() {
        _seats = seats;
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

  /// Enriches booked trip seats with passenger gender data.
  ///
  /// Strategy:
  ///   1. If the backend already provides `passenger_gender`, use it directly.
  ///   2. Fetch the current user's bookings and match them to this trip.
  ///      For matched bookings, pull seat-level gender from booking details.
  ///   3. Build a map of tripSeatId → gender and overlay onto the seats.
  Future<List<TripSeat>> _enrichSeatsWithGender(List<TripSeat> seats) async {
    // Quick check: if ALL booked seats already have gender, skip enrichment
    final bookedSeats = seats.where((s) => s.isBooked).toList();
    if (bookedSeats.isEmpty) return seats;

    final allHaveGender = bookedSeats.every(
      (s) => s.passengerGender != null && s.passengerGender!.isNotEmpty,
    );
    if (allHaveGender) return seats;

    // Don't attempt enrichment if user isn't authenticated
    final isAuthenticated = await _authService.isAuthenticated();
    if (!isAuthenticated) return seats;

    // Build a map: tripSeatId → passengerGender
    final Map<String, String> genderMap = {};

    try {
      // Fetch the current user's bookings
      final myBookings = await _bookingService.getMyBookings(limit: 50);

      // Pre-filter: only fetch details for bookings that could be on this trip
      // (matching departure date and route name)
      final candidateBookings = myBookings.where((b) {
        if (b.departureDatetime != null) {
          final sameDay =
              b.departureDatetime!.year == widget.trip.departureTime.year &&
              b.departureDatetime!.month == widget.trip.departureTime.month &&
              b.departureDatetime!.day == widget.trip.departureTime.day;
          return sameDay;
        }
        return false;
      }).toList();

      _logger.d(
        'Found ${candidateBookings.length} candidate bookings for gender enrichment',
      );

      for (final bookingItem in candidateBookings) {
        try {
          final bookingDetail = await _bookingService.getBookingById(
            bookingItem.id,
          );

          // Verify this booking is actually for our trip
          if (bookingDetail.busBooking?.scheduledTripId == widget.trip.tripId) {
            for (final bSeat in bookingDetail.seats) {
              if (bSeat.tripSeatId != null &&
                  bSeat.passengerGender != null &&
                  bSeat.passengerGender!.isNotEmpty) {
                genderMap[bSeat.tripSeatId!] = bSeat.passengerGender!;
              }
            }
          }
        } catch (e) {
          _logger.w('Could not fetch booking detail ${bookingItem.id}: $e');
        }
      }
    } catch (e) {
      _logger.w('Could not fetch user bookings for gender enrichment: $e');
    }

    // Apply the gender map to seats
    if (genderMap.isNotEmpty) {
      _logger.i('Enriching ${genderMap.length} seats with gender data');
      seats = seats.map((seat) {
        if (seat.isBooked &&
            (seat.passengerGender == null || seat.passengerGender!.isEmpty) &&
            genderMap.containsKey(seat.id)) {
          return seat.copyWith(passengerGender: genderMap[seat.id]);
        }
        return seat;
      }).toList();
    }

    return seats;
  }

  void _toggleSeatSelection(TripSeat seat) {
    if (!seat.canBeSelected) return;

    HapticFeedback.selectionClick();

    setState(() {
      if (_selectedSeatIds.contains(seat.id)) {
        _selectedSeatIds.remove(seat.id);
      } else {
        if (_selectedSeatIds.length >= 10) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Maximum 10 seats can be selected'),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
      return _kSelected;
    }

    if (seat.isBooked) {
      // Gender-based colors for booked seats
      final gender = seat.passengerGender?.toLowerCase();
      if (gender == 'male') {
        return _kMale; // Modern red for male booked
      } else if (gender == 'female') {
        return _kFemale; // Modern pink for female booked
      }
      // Fallback for booked seats with unknown gender
      return _kMale;
    }

    if (seat.isBlocked) {
      return _kBlocked; // Soft grey for blocked
    }

    if (seat.canBeSelected) {
      return _kAvailable; // Modern green for available
    }
    return _kUnavail; // Light grey for unavailable
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
        SnackBar(
          content: const Text('Please login to continue with booking'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      extendBodyBehindAppBar: false,
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingView()
          : _errorMessage != null
          ? _buildErrorView()
          : _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: Material(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ),
      title: const Text(
        'Select Seats',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: _buildTripInfoBar(),
      ),
    );
  }

  Widget _buildTripInfoBar() {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.trip.routeName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.my_location_rounded, color: Colors.white60, size: 12),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${widget.boardingPoint} → ${widget.alightingPoint}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.35)),
            ),
            child: Text(
              widget.trip.busTypeDisplay.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Loading / Error ────────────────────────────────────────────────────────

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            'Loading seats…',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Couldn\'t load seats',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Something went wrong. Please try again.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 160,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _loadSeats,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text(
                  'Try Again',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main Body ──────────────────────────────────────────────────────────────

  Widget _buildBody() {
    final bool panelVisible = _selectedSeatIds.isNotEmpty;
    return Stack(
      children: [
        // Scrollable content
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Existing bookings banner
            if (_hasExistingBooking)
              SliverToBoxAdapter(child: _buildExistingBookingsBanner()),

            // Legend row
            SliverToBoxAdapter(child: _buildLegend()),

            // Seat map card
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, panelVisible ? 160 : 24),
              sliver: SliverToBoxAdapter(child: _buildSeatMapCard()),
            ),
          ],
        ),

        // Bottom action panel — always present in layout, slides in/out via
        // AnimatedSlide so Flutter always sees a fully width-constrained widget.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            offset: panelVisible ? Offset.zero : const Offset(0, 1),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOut,
              opacity: panelVisible ? 1.0 : 0.0,
              // IgnorePointer when invisible so hidden panel doesn't eat taps
              child: IgnorePointer(
                ignoring: !panelVisible,
                child: _buildBottomPanel(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Existing Bookings Banner ───────────────────────────────────────────────

  Widget _buildExistingBookingsBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showExistingBookingsSheet,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.12),
                  AppColors.primaryLight.withOpacity(0.08),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.bookmarks_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'You have ${_existingBookings.length} booking(s) on this trip',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Tap to view details',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Legend & Summary ───────────────────────────────────────────────────────

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kDivider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            _legendPill(_kAvailable,  'Available',  filled: false),
            _legendPill(_kSelected,   'Selected',   filled: true),
            _legendPill(_kMale,       'Male',       filled: true),
            _legendPill(_kFemale,     'Female',     filled: true),
            _legendPill(_kBlocked,    'Blocked',    filled: true),
          ],
        ),
      ),
    );
  }

  Widget _legendPill(Color color, String label, {required bool filled}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: filled ? color : Colors.transparent,
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ── Seat Map ───────────────────────────────────────────────────────────────

  Widget _buildSeatMapCard() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kDivider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSeatMapHeader(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: _buildSeatLayout(),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatMapHeader() {
    final available = _seats.where((s) => s.canBeSelected).length;
    final booked = _seats.where((s) => s.isBooked).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _kBg,
        border: const Border(bottom: BorderSide(color: _kDivider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.directions_bus_rounded, color: AppColors.primary, size: 22),
          const SizedBox(width: 8),
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text(
              'Seat Map',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 6,
              runSpacing: 6,
              children: [
                _statChip('${_seats.length}', 'Total', AppColors.textSecondary),
                _statChip('$available', 'Free', _kAvailable),
                _statChip('$booked', 'Booked', _kMale),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatLayout() {
    if (_seats.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Text(
            'No seats available',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
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

    // Reverse the columns so the highest numbers (rear) are at the top
    final leftReversed = leftColumnPairs.reversed.toList();
    final rightReversed = rightColumnPairs.reversed.toList();

    return Column(
      children: [
        _buildDirectionChip('REAR', Icons.arrow_upward_rounded),
        const SizedBox(height: 24),

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
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Left block
            Column(
              children: leftReversed.map((pair) => _buildPairWidget(pair)).toList(),
            ),

            // Wider Walkway
            const SizedBox(width: 44),

            // Right block
            Column(
              children: rightReversed.map((pair) => _buildPairWidget(pair)).toList(),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Driver section
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 104, // Aligned with the left block columns (52 * 2)
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildDriverIcon(),
              ),
            ),
            const SizedBox(width: 44),
            const SizedBox(width: 104), // Space to maintain symmetry
          ],
        ),

        const SizedBox(height: 24),
        _buildDirectionChip('FRONT', Icons.arrow_downward_rounded),
        const SizedBox(height: 32),
        
        // Gender Legend Layout
        _buildGenderLayoutLegend(),
      ],
    );
  }

  Widget _buildGenderLayoutLegend() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kDivider),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 10,
        children: [
          _buildGenderLegendBox(_kMale, 'Male booked', Icons.male_rounded),
          _buildGenderLegendBox(_kFemale, 'Female booked', Icons.female_rounded),
        ],
      ),
    );
  }

  Widget _buildGenderLegendBox(Color color, String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPairWidget(List<TripSeat> pair) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSeatCell(pair.isNotEmpty ? pair[0] : null),
          _buildSeatCell(pair.length > 1 ? pair[1] : null),
        ],
      ),
    );
  }

  Widget _buildSeatCell(TripSeat? seat) {
    if (seat == null) return const SizedBox(width: 52, height: 50); // Space matching seat width
    return _buildSeatWidget(seat);
  }

  Widget _buildDirectionChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kDivider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverIcon() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kDivider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sports_motorsports_rounded, size: 18, color: AppColors.primary),
          SizedBox(width: 6),
          Text(
            'Driver',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatWidget(TripSeat seat) {
    final isSelectable = seat.canBeSelected;
    final isSelected = _selectedSeatIds.contains(seat.id);
    final color = _getSeatColor(seat);
    final gender = seat.passengerGender?.toLowerCase();
    
    final isUnavailable = !seat.isBooked && !seat.isBlocked && !seat.canBeSelected;

    return GestureDetector(
      onTap: isSelectable ? () => _toggleSeatSelection(seat) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: 44,
        height: 48,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? color : (isUnavailable ? _kUnavail : color.withOpacity(0.15)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : (isUnavailable ? Colors.transparent : color.withOpacity(0.4)),
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ] : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              seat.displaySeatNo,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? Colors.white : (isUnavailable ? Colors.grey.shade400 : color),
                fontWeight: FontWeight.w800,
              ),
            ),
            if (seat.isBooked && gender != null && gender.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  gender == 'male' ? Icons.male_rounded : Icons.female_rounded,
                  size: 12,
                  color: color,
                ),
              ),
          ],
        ),
      ),
    );
  }


  // ── Bottom Panel ───────────────────────────────────────────────────────────

  Widget _buildBottomPanel() {
    final seats = _selectedSeats;
    final seatCount = seats.length;
    final totalPrice = seats.fold(0.0, (sum, s) => sum + s.currentPrice);
    final seatLabel = seats.isEmpty ? '—' : seats.map((s) => s.displaySeatNo).join(', ');

    return LayoutBuilder(
      builder: (context, constraints) {
        final panelWidth = constraints.hasBoundedWidth ? constraints.maxWidth : MediaQuery.of(context).size.width;

        return Container(
          width: panelWidth,
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: panelWidth - 40,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SEATS SELECTED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.grey.shade400,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                seatLabel,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 110,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'TOTAL',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.grey.shade400,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'LKR ${totalPrice.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: seatCount == 0 ? null : _proceedToConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        disabledBackgroundColor: Colors.grey.shade200,
                        disabledForegroundColor: Colors.grey.shade400,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Flexible(
                            child: Text(
                              'Continue to Booking',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$seatCount',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
}
}
