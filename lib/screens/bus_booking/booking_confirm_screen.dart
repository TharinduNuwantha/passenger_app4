import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';
import '../../models/booking_models.dart';
import '../../models/search_models.dart';
import '../../services/booking_service.dart';
import '../../theme/app_colors.dart';
import 'booking_conform.dart' hide AppColors, AppTextStyles;

/// Screen to confirm booking details and enter passenger information
class BookingConfirmScreen extends StatefulWidget {
  final TripResult trip;
  final List<TripSeat> selectedSeats;
  final String boardingPoint;
  final String alightingPoint;
  final String? boardingStopId;
  final String? alightingStopId;
  final String? masterRouteId;
  final double totalPrice;
  final String userName;
  final String userPhone;
  final String? userEmail;

  const BookingConfirmScreen({
    super.key,
    required this.trip,
    required this.selectedSeats,
    required this.boardingPoint,
    required this.alightingPoint,
    this.boardingStopId,
    this.alightingStopId,
    this.masterRouteId,
    required this.totalPrice,
    required this.userName,
    required this.userPhone,
    this.userEmail,
  });

  @override
  State<BookingConfirmScreen> createState() => _BookingConfirmScreenState();
}

class _BookingConfirmScreenState extends State<BookingConfirmScreen> {
  final BookingService _bookingService = BookingService();
  final Logger _logger = Logger();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  final TextEditingController _specialRequestsController =
      TextEditingController();

  // Gender selection for primary contact
  String? _selectedGender;

  // Passenger details for each seat
  late List<PassengerFormData> _passengerForms;

  bool _isLoading = false;
  String? _errorMessage;
  bool _sameForAllPassengers = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userName);
    _phoneController = TextEditingController(text: widget.userPhone);
    _emailController = TextEditingController(text: widget.userEmail ?? '');

    // Initialize passenger forms
    _passengerForms = widget.selectedSeats.map((seat) {
      return PassengerFormData(
        seatNumber: seat.seatNumber,
        tripSeatId: seat.id,
        seatPrice: seat.currentPrice,
        nameController: TextEditingController(),
        phoneController: TextEditingController(),
      );
    }).toList();
  }

  // Gender options
  static const List<Map<String, String>> _genderOptions = [
    {'value': 'male', 'label': 'Male'},
    {'value': 'female', 'label': 'Female'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _specialRequestsController.dispose();
    for (var form in _passengerForms) {
      form.nameController.dispose();
      form.phoneController.dispose();
    }
    super.dispose();
  }

  Future<void> _createBooking() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Build seat selections
      final seats = <SeatSelection>[];
      for (int i = 0; i < _passengerForms.length; i++) {
        final form = _passengerForms[i];
        final seat = widget.selectedSeats[i];

        String passengerName;
        String? passengerPhone;
        String? passengerGender;

        if (_sameForAllPassengers) {
          // Use primary contact for all
          passengerName = _nameController.text.trim();
          passengerPhone = _phoneController.text.trim();
          passengerGender = _selectedGender;
        } else {
          // Use individual passenger details
          passengerName = form.nameController.text.trim().isNotEmpty
              ? form.nameController.text.trim()
              : _nameController.text.trim();
          passengerPhone = form.phoneController.text.trim().isNotEmpty
              ? form.phoneController.text.trim()
              : null;
          passengerGender = form.selectedGender ?? _selectedGender;
        }

        seats.add(
          SeatSelection(
            tripSeatId: seat.id,
            seatNumber: seat.seatNumber,
            seatType: seat.seatType,
            seatPrice: seat.currentPrice,
            passengerName: passengerName,
            passengerPhone: passengerPhone,
            passengerGender: passengerGender,
            isPrimary: i == 0, // First seat is primary
          ),
        );
      }

      final request = CreateBookingRequest(
        scheduledTripId: widget.trip.tripId,
        boardingStopId: widget.boardingStopId,
        boardingStopName: widget.boardingPoint,
        alightingStopId: widget.alightingStopId,
        alightingStopName: widget.alightingPoint,
        seats: seats,
        passengerName: _nameController.text.trim(),
        passengerPhone: _phoneController.text.trim(),
        passengerEmail: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        specialRequests: _specialRequestsController.text.trim().isNotEmpty
            ? _specialRequestsController.text.trim()
            : null,
      );

      _logger.i('Creating booking with ${seats.length} seats');

      final response = await _bookingService.createBooking(request);

      _logger.i('Booking created: ${response.booking.bookingReference}');

      if (mounted) {
        // Build seat numbers string
        final seatNumbers = response.seats.map((s) => s.seatNumber).join(', ');

        // Format date time
        final formattedDateTime = DateFormat(
          'dd MMM yyyy, hh:mm a',
        ).format(widget.trip.departureTime);

        // Navigate to BookingConfirmedScreen (Lounge or Pay choice)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BookingConfirmedScreen(
              referenceNo: response.booking.bookingReference,
              route: '${widget.boardingPoint} → ${widget.alightingPoint}',
              dateTime: formattedDateTime,
              busType: widget.trip.busType,
              numberPlate: widget.trip.routeNumber ?? 'N/A',
              seatNo: seatNumbers,
              price: response.booking.totalAmount.toStringAsFixed(0),
              pickup: widget.boardingPoint,
              drop: widget.alightingPoint,
              // Pass additional info for lounge selection
              busBookingId: response.booking.id,
              boardingStopId: widget.boardingStopId,
              alightingStopId: widget.alightingStopId,
              masterRouteId: widget.masterRouteId,
              busDepartureTime: widget.trip.departureTime,
              busArrivalTime: widget.trip.estimatedArrival,
            ),
          ),
        );
      }
    } catch (e) {
      _logger.e('Failed to create booking: $e');
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage ?? 'Failed to create booking'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          'Confirm Booking',
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTripSummary(),
                        const SizedBox(height: 24),
                        _buildPrimaryContactSection(),
                        const SizedBox(height: 24),
                        if (widget.selectedSeats.length > 1) ...[
                          _buildPassengerToggle(),
                          const SizedBox(height: 16),
                          if (!_sameForAllPassengers) _buildPassengerForms(),
                        ],
                        _buildSpecialRequests(),
                        const SizedBox(height: 24),
                        _buildPriceSummary(),
                        const SizedBox(height: 80), // Space for bottom button
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTripSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_bus, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.trip.routeName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          _buildDetailRow(
            Icons.location_on_outlined,
            'From',
            widget.boardingPoint,
          ),
          const SizedBox(height: 8),
          _buildDetailRow(Icons.location_on, 'To', widget.alightingPoint),
          const SizedBox(height: 8),
          _buildDetailRow(
            Icons.access_time,
            'Departure',
            _formatDateTime(widget.trip.departureTime),
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            Icons.event_seat,
            'Seats',
            widget.selectedSeats.map((s) => s.seatNumber).join(', '),
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            Icons.category,
            'Bus Type',
            widget.trip.busTypeDisplay,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary.withOpacity(0.6)),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.primary.withOpacity(0.6),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contact Information',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _nameController,
          decoration: _inputDecoration('Full Name', Icons.person_outline),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your name';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _phoneController,
          decoration: _inputDecoration('Phone Number', Icons.phone_outlined),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter phone number';
            }
            if (value.trim().length < 9) {
              return 'Please enter a valid phone number';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        // Gender dropdown
        DropdownButtonFormField<String>(
          value: _selectedGender,
          decoration: _inputDecoration('Gender', Icons.wc_outlined),
          items: _genderOptions.map((option) {
            return DropdownMenuItem<String>(
              value: option['value'],
              child: Text(option['label']!),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedGender = value;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select gender';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _emailController,
          decoration: _inputDecoration(
            'Email (Optional)',
            Icons.email_outlined,
          ),
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }

  Widget _buildPassengerToggle() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Same details for all ${widget.selectedSeats.length} passengers',
              style: const TextStyle(fontSize: 14, color: AppColors.primary),
            ),
          ),
          Switch(
            value: _sameForAllPassengers,
            onChanged: (value) {
              setState(() {
                _sameForAllPassengers = value;
              });
            },
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerForms() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Passenger Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(_passengerForms.length, (index) {
          final form = _passengerForms[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Seat ${form.seatNumber}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    if (index == 0)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFC300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Primary',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: form.nameController,
                  decoration: _inputDecoration(
                    index == 0 ? 'Name (uses contact info if empty)' : 'Name',
                    Icons.person_outline,
                  ),
                  validator: index == 0
                      ? null
                      : (value) {
                          if (!_sameForAllPassengers &&
                              (value == null || value.trim().isEmpty)) {
                            return 'Please enter passenger name';
                          }
                          return null;
                        },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: form.phoneController,
                  decoration: _inputDecoration(
                    'Phone (Optional)',
                    Icons.phone_outlined,
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSpecialRequests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Special Requests (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _specialRequestsController,
          decoration: _inputDecoration(
            'Any special requirements...',
            Icons.note_outlined,
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildPriceSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Seats (${widget.selectedSeats.length})',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.primary.withOpacity(0.7),
                ),
              ),
              Text(
                'LKR ${widget.totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 14, color: AppColors.primary),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'LKR ${widget.totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
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
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _createBooking,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFC300),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            disabledBackgroundColor: Colors.grey.shade300,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : const Text(
                  'Confirm Booking',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.primary.withOpacity(0.6)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${months[dt.month - 1]}, ${hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $period';
  }
}

/// Helper class to hold passenger form data
class PassengerFormData {
  final String seatNumber;
  final String tripSeatId;
  final double seatPrice;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  String? selectedGender;

  PassengerFormData({
    required this.seatNumber,
    required this.tripSeatId,
    required this.seatPrice,
    required this.nameController,
    required this.phoneController,
    this.selectedGender,
  });
}
