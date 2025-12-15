import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/booking_intent_models.dart';
import '../../models/booking_models.dart';
import '../../models/search_models.dart';
import '../../providers/booking_intent_provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../payment/payment_webview_screen.dart';
import 'booking_intent_success_screen.dart';

/// Booking Intent Flow Screen - Uses the new Intent → Payment → Confirm flow
///
/// This screen:
/// 1. Creates a booking intent (holds seats for 10 minutes)
/// 2. Shows countdown timer
/// 3. Collects passenger details
/// 4. Initiates payment
/// 5. Confirms booking after payment
class BookingIntentFlowScreen extends StatefulWidget {
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

  const BookingIntentFlowScreen({
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
  State<BookingIntentFlowScreen> createState() =>
      _BookingIntentFlowScreenState();
}

class _BookingIntentFlowScreenState extends State<BookingIntentFlowScreen> {
  final Logger _logger = Logger();
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  // Passenger details
  late List<PassengerInfo> _passengers;
  bool _sameForAllPassengers = true;
  String? _selectedGender;

  // State
  bool _isCreatingIntent = false;
  bool _intentCreated = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userName);
    _phoneController = TextEditingController(text: widget.userPhone);
    _emailController = TextEditingController(text: widget.userEmail ?? '');

    // Initialize passenger list
    _passengers = widget.selectedSeats.map((seat) {
      return PassengerInfo(
        seatNumber: seat.seatNumber,
        tripSeatId: seat.id,
        seatPrice: seat.currentPrice,
        nameController: TextEditingController(),
        nicController: TextEditingController(),
        phoneController: TextEditingController(),
      );
    }).toList();

    // Create intent after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _createBookingIntent();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    for (var p in _passengers) {
      p.nameController.dispose();
      p.nicController.dispose();
      p.phoneController.dispose();
    }
    super.dispose();
  }

  /// Create booking intent to hold seats
  Future<void> _createBookingIntent() async {
    // Check authentication first
    final isAuthenticated = await _authService.isAuthenticated();
    if (!isAuthenticated) {
      if (!mounted) return;
      _showErrorSnackBar('Session expired. Please login again.');
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      return;
    }

    final provider = context.read<BookingIntentProvider>();

    setState(() => _isCreatingIntent = true);

    try {
      // Use phone number as fallback if userName is empty
      final seatPassengerName = widget.userName.trim().isNotEmpty 
          ? widget.userName 
          : 'Passenger';

      // Build seat requests
      final seats = _passengers.map((p) {
        return IntentSeatRequest(
          tripSeatId: p.tripSeatId,
          passengerName: seatPassengerName,
          passengerPhone: widget.userPhone,
          passengerGender: _selectedGender,
        );
      }).toList();

      // Use phone number as fallback if userName is empty
      final effectiveName = widget.userName.trim().isNotEmpty 
          ? widget.userName 
          : 'Passenger ${widget.userPhone}';

      final success = await provider.createBusIntent(
        scheduledTripId: widget.trip.tripId,
        seats: seats,
        boardingStopId: widget.boardingStopId ?? '',
        alightingStopId: widget.alightingStopId ?? '',
        boardingStopName: widget.boardingPoint,
        alightingStopName: widget.alightingPoint,
        passengerName: effectiveName,
        passengerPhone: widget.userPhone,
        passengerEmail: widget.userEmail,
      );

      if (success) {
        setState(() {
          _intentCreated = true;
          _isCreatingIntent = false;
        });
        _logger.i('Intent created successfully');
      } else {
        // Handle partial availability
        if (provider.hasPartialAvailability) {
          _showPartialAvailabilityDialog(provider.partialAvailabilityError!);
        } else {
          _showErrorSnackBar(provider.errorMessage ?? 'Failed to hold seats');
        }
        setState(() => _isCreatingIntent = false);
      }
    } catch (e) {
      _logger.e('Error creating intent: $e');
      setState(() => _isCreatingIntent = false);
      _showErrorSnackBar('Failed to hold seats: $e');
    }
  }

  /// Show dialog for partial availability
  void _showPartialAvailabilityDialog(PartialAvailabilityError error) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('Some Seats Unavailable'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(error.displayMessage),
            if (error.unavailable.bus?.takenSeats != null &&
                error.unavailable.bus!.takenSeats!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Unavailable seats:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              ...error.unavailable.bus!.takenSeats!.map((seat) => Padding(
                    padding: const EdgeInsets.only(left: 8, top: 2),
                    child: Text('• Seat $seat'),
                  )),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to seat selection
            },
            child: const Text('Select Different Seats'),
          ),
        ],
      ),
    );
  }

  /// Proceed to payment
  Future<void> _proceedToPayment() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<BookingIntentProvider>();

    if (provider.isExpired) {
      _showExpiredDialog();
      return;
    }

    // Initiate payment
    final success = await provider.initiatePayment();

    if (success && mounted) {
      final paymentInfo = provider.paymentInfo!;

      // Check if we have a payment URL
      if (paymentInfo.paymentUrl == null || paymentInfo.paymentUrl!.isEmpty) {
        _showErrorSnackBar('Payment URL not available');
        return;
      }

      // Navigate to payment webview
      final paymentResult = await Navigator.push<PaymentResult>(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentWebViewScreen(
            paymentUrl: paymentInfo.paymentUrl!,
            paymentReference: paymentInfo.paymentReference,
            amount: paymentInfo.amount,
            intentId: provider.currentIntent!.intentId,
          ),
        ),
      );

      // Handle payment result
      if (paymentResult != null && paymentResult.success) {
        await _confirmBooking(paymentResult.paymentReference);
      } else if (paymentResult != null && !paymentResult.success) {
        _showErrorSnackBar(
            paymentResult.errorMessage ?? 'Payment was not completed');
      }
    } else if (provider.hasError) {
      _showErrorSnackBar(provider.errorMessage ?? 'Failed to initiate payment');
    }
  }

  /// Confirm booking after successful payment
  Future<void> _confirmBooking(String paymentReference) async {
    final provider = context.read<BookingIntentProvider>();

    final success = await provider.confirmBooking(paymentReference);

    if (success && mounted) {
      final confirmedBooking = provider.confirmedBooking!;

      // Navigate to success screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BookingSuccessScreen(
            masterReference: confirmedBooking.masterReference,
            busReference: confirmedBooking.busBooking?.reference,
            totalAmount: confirmedBooking.busBooking?.totalAmount ?? 0,
            trip: widget.trip,
            boardingPoint: widget.boardingPoint,
            alightingPoint: widget.alightingPoint,
            seatNumbers:
                widget.selectedSeats.map((s) => s.seatNumber).join(', '),
          ),
        ),
      );
    } else if (provider.hasError) {
      _showErrorSnackBar(
          provider.errorMessage ?? 'Failed to confirm booking');
    }
  }

  /// Show expired dialog
  void _showExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.timer_off, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('Session Expired'),
          ],
        ),
        content: const Text(
          'Your seat reservation has expired. Please go back and select your seats again.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  /// Cancel intent and go back
  Future<void> _cancelAndGoBack() async {
    final provider = context.read<BookingIntentProvider>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: const Text(
          'This will release your held seats. Are you sure you want to cancel?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, Keep My Seats'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await provider.cancelIntent();
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _cancelAndGoBack();
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.primary,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _cancelAndGoBack,
          ),
          title: const Text(
            'Confirm & Pay',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: _isCreatingIntent
              ? _buildLoadingView()
              : Column(
                  children: [
                    _buildCountdownTimer(),
                    Expanded(
                      child: Container(
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
                                const SizedBox(height: 20),
                                _buildPassengerSection(),
                                const SizedBox(height: 20),
                                _buildPriceSummary(),
                                const SizedBox(height: 100),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    _buildPaymentButton(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 20),
          const Text(
            'Holding your seats...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we reserve your selection',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownTimer() {
    return Consumer<BookingIntentProvider>(
      builder: (context, provider, _) {
        final remaining = provider.remainingSeconds;
        final minutes = remaining ~/ 60;
        final seconds = remaining % 60;
        final isLow = remaining <= 120; // Less than 2 minutes

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isLow
                ? Colors.red.withOpacity(0.2)
                : Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isLow ? Colors.red : Colors.white.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isLow ? Icons.timer_off : Icons.timer,
                color: isLow ? Colors.red : Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seats held for',
                      style: TextStyle(
                        color: isLow
                            ? Colors.red.shade100
                            : Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '$minutes:${seconds.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: isLow ? Colors.red : Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (isLow)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'HURRY!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'HELD',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          _buildInfoRow(Icons.location_on_outlined, 'From', widget.boardingPoint),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.location_on, 'To', widget.alightingPoint),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.access_time,
            'Departure',
            DateFormat('dd MMM, hh:mm a').format(widget.trip.departureTime),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.event_seat,
            'Seats',
            widget.selectedSeats.map((s) => s.seatNumber).join(', '),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
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

  Widget _buildPassengerSection() {
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
        // Primary contact
        _buildTextField(
          controller: _nameController,
          label: 'Full Name',
          icon: Icons.person_outline,
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Please enter your name' : null,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _phoneController,
          label: 'Phone Number',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Please enter phone';
            if (v.trim().length < 9) return 'Invalid phone number';
            return null;
          },
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _emailController,
          label: 'Email (Optional)',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),

        if (widget.selectedSeats.length > 1) ...[
          const SizedBox(height: 16),
          _buildPassengerToggle(),
          if (!_sameForAllPassengers) ...[
            const SizedBox(height: 16),
            _buildIndividualPassengerForms(),
          ],
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
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
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
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
            onChanged: (v) => setState(() => _sameForAllPassengers = v),
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildIndividualPassengerForms() {
    return Column(
      children: _passengers.asMap().entries.map((entry) {
        final index = entry.key;
        final passenger = entry.value;

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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Seat ${passenger.seatNumber}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  if (index == 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: passenger.nameController,
                decoration: InputDecoration(
                  labelText: index == 0
                      ? 'Name (uses contact if empty)'
                      : 'Passenger Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: index == 0
                    ? null
                    : (v) => !_sameForAllPassengers &&
                            (v == null || v.trim().isEmpty)
                        ? 'Enter name'
                        : null,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPriceSummary() {
    return Consumer<BookingIntentProvider>(
      builder: (context, provider, _) {
        final pricing = provider.currentIntent?.pricing;

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
                    'Bus Fare (${widget.selectedSeats.length} seats)',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primary.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    pricing?.formattedBusFare ??
                        'LKR ${widget.totalPrice.toStringAsFixed(2)}',
                    style:
                        const TextStyle(fontSize: 14, color: AppColors.primary),
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
                    pricing?.formattedTotal ??
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
      },
    );
  }

  Widget _buildPaymentButton() {
    return Consumer<BookingIntentProvider>(
      builder: (context, provider, _) {
        final isLoading =
            provider.isInitiatingPayment || provider.isConfirmingBooking;
        final isExpired = provider.isExpired;

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
              onPressed: isLoading || isExpired ? null : _proceedToPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isExpired ? Colors.grey : const Color(0xFFFFC300),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : Text(
                      isExpired ? 'Session Expired' : 'Proceed to Payment',
                      style: TextStyle(
                        color: isExpired ? Colors.grey : AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}

/// Helper class for passenger info
class PassengerInfo {
  final String seatNumber;
  final String tripSeatId;
  final double seatPrice;
  final TextEditingController nameController;
  final TextEditingController nicController;
  final TextEditingController phoneController;

  PassengerInfo({
    required this.seatNumber,
    required this.tripSeatId,
    required this.seatPrice,
    required this.nameController,
    required this.nicController,
    required this.phoneController,
  });
}

/// Payment result from webview
class PaymentResult {
  final bool success;
  final String paymentReference;
  final String? errorMessage;

  PaymentResult({
    required this.success,
    required this.paymentReference,
    this.errorMessage,
  });
}
