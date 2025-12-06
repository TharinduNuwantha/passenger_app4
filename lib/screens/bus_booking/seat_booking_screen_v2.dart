import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../models/booking_models.dart';
import '../../models/search_models.dart';
import '../../services/booking_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import 'booking_confirm_screen.dart';

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

  const SeatBookingScreenV2({
    super.key,
    required this.trip,
    required this.boardingPoint,
    required this.alightingPoint,
    this.boardingStopId,
    this.alightingStopId,
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

  @override
  void initState() {
    super.initState();
    _loadSeats();
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
        // Limit number of seats
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
      return const Color(0xFFFFC300); // Selected - Yellow
    }
    if (seat.isBooked || seat.isBlocked) {
      return AppColors.primary.withOpacity(0.5); // Booked - Faded Blue
    }
    if (seat.canBeSelected) {
      return const Color(0xFF4CAF50); // Available - Green
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

    // Get current user info
    final user = await _authService.getCurrentUser();

    if (!mounted) return;

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
          totalPrice: _totalPrice,
          userName: user?.fullName ?? '',
          userPhone: user?.phoneNumber ?? '',
          userEmail: user?.email,
        ),
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

  Widget _buildTripInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
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
                  color: AppColors.primary,
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
            _buildLegendItem(
              Icons.event_seat,
              const Color(0xFFFFC300),
              'Selected',
            ),
            const SizedBox(width: 16),
            _buildLegendItem(
              Icons.event_seat_outlined,
              const Color(0xFF4CAF50),
              'Available',
            ),
            const SizedBox(width: 16),
            _buildLegendItem(
              Icons.event_seat,
              AppColors.primary.withOpacity(0.5),
              'Booked',
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
            fontSize: 12,
            color: AppColors.primary.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  /// Build dynamic seat layout based on seat row/column data
  Widget _buildSeatLayout() {
    if (_seats.isEmpty) {
      return const Center(
        child: Text(
          'No seats available',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    // Group seats by row
    final Map<int, List<TripSeat>> seatsByRow = {};
    int maxColumn = 0;

    for (final seat in _seats) {
      seatsByRow.putIfAbsent(seat.seatRow, () => []);
      seatsByRow[seat.seatRow]!.add(seat);
      if (seat.seatColumn > maxColumn) {
        maxColumn = seat.seatColumn;
      }
    }

    // Sort rows
    final sortedRows = seatsByRow.keys.toList()..sort();

    // Determine bus layout type based on columns
    // Typical layouts: 4 columns (2+2), 5 columns (2+3 or 3+2)
    final int aislePosition = maxColumn <= 4
        ? 2
        : 3; // After which column is aisle

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F7FA),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          // Header with seat count and driver icon
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
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
                const Icon(Icons.drive_eta, size: 40, color: AppColors.primary),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: sortedRows.map((rowNum) {
                  final rowSeats = seatsByRow[rowNum]!;
                  // Sort by column
                  rowSeats.sort((a, b) => a.seatColumn.compareTo(b.seatColumn));
                  return _buildDynamicSeatRow(
                    rowNum,
                    rowSeats,
                    maxColumn,
                    aislePosition,
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicSeatRow(
    int rowNum,
    List<TripSeat> rowSeats,
    int maxColumn,
    int aislePosition,
  ) {
    // Create a map for quick seat lookup by column
    final Map<int, TripSeat> seatMap = {
      for (var seat in rowSeats) seat.seatColumn: seat,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          // Row label
          SizedBox(
            width: 30,
            child: Text(
              '$rowNum',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Seats
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(maxColumn, (index) {
                final colNum = index + 1;

                // Add aisle spacer after aislePosition
                if (index == aislePosition) {
                  return const SizedBox(width: 20); // Aisle gap
                }

                final adjustedCol = index < aislePosition ? colNum : colNum;
                final seat = seatMap[adjustedCol];

                if (seat == null) {
                  // Empty seat placeholder
                  return const SizedBox(width: 40, height: 36);
                }

                return _buildSeatWidget(seat);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatWidget(TripSeat seat) {
    final isSelectable = seat.canBeSelected;
    final isSelected = _selectedSeatIds.contains(seat.id);

    return GestureDetector(
      onTap: isSelectable ? () => _toggleSeatSelection(seat) : null,
      child: Container(
        width: 40,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        child: Tooltip(
          message:
              '${seat.seatNumber} - LKR ${seat.currentPrice.toStringAsFixed(0)}',
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_getSeatIcon(seat), color: _getSeatColor(seat), size: 24),
              Text(
                seat.seatNumber,
                style: TextStyle(
                  fontSize: 9,
                  color: isSelected
                      ? const Color(0xFFFFC300)
                      : Colors.grey.shade600,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
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
                backgroundColor: const Color(0xFFFFC300),
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
                  color: seatCount > 0 ? AppColors.primary : Colors.grey,
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
