import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/booking_models.dart';
import '../../services/booking_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/booking_countdown_timer.dart';
import '../payment/payment_method_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Screen to display detailed booking information with QR code
class BookingDetailScreen extends StatefulWidget {
  final String bookingId;

  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final BookingService _bookingService = BookingService();
  final Logger _logger = Logger();

  BookingResponse? _bookingResponse;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isCancelling = false;

  List<Map<String, dynamic>> _transportDetails = [];
  bool _isLoadingTransportDetails = false;

  final PageController _qrPageController = PageController();
  final ScrollController _scrollController = ScrollController();
  int _currentQrPage = 0;

  @override
  void initState() {
    super.initState();
    _loadBookingDetails();
  }

  @override
  void dispose() {
    _qrPageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTransportDetails(List<TransportBooking> transports) async {
    setState(() {
      _isLoadingTransportDetails = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final bookingId = widget.bookingId;

      List<Map<String, dynamic>> updatedDetails = [];

      for (var tb in transports) {
        Map<String, dynamic> tbData = {'transport': tb};

        try {
          // Find driver details conditionally
          final loungeBookingsRes = await supabase
              .from('lounge_bookings')
              .select('id')
              .eq('master_booking_id', bookingId);

          if (loungeBookingsRes != null) {
            for (var lb in (loungeBookingsRes as List)) {
              final loungeBookingId = lb['id'];

              final assignmentRes = await supabase
                  .from('lounge_booking_driver_assignments')
                  .select('''
                    driver_contact,
                    driver_id,
                    lounge_drivers (
                      name,
                      vehicle_no,
                      vehicle_type
                    )
                  ''')
                  .eq('lounge_booking_id', loungeBookingId)
                  .maybeSingle();

              if (assignmentRes != null) {
                tbData['driver_assignment'] = assignmentRes;
                break; // Stop looking once we find the driver assignment
              }
            }
          }
        } catch (e) {
          _logger.w('Failed to load driver details for transport: $e');
        }

        updatedDetails.add(tbData);
      }

      if (mounted) {
        setState(() {
          _transportDetails = updatedDetails;
          _isLoadingTransportDetails = false;
        });
      }
    } catch (e) {
      _logger.e('Failed to load transport details: $e');
      if (mounted) {
        setState(() {
          _isLoadingTransportDetails = false;
        });
      }
    }
  }

  Future<void> _loadBookingDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _bookingService.getBookingById(widget.bookingId);
      setState(() {
        _bookingResponse = response;
        _isLoading = false;
      });

      // Fetch transport bookings directly from Supabase
      try {
        final supabase = Supabase.instance.client;
        final transportRes = await supabase
            .from('transport_bookings')
            .select('''
              *,
              lounge_transport_locations (
                location
              ),
              lounges (
                lounge_name
              )
            ''')
            .eq('booking_id', widget.bookingId);

        List<TransportBooking> fetchedTransports = [];
        for (var t in transportRes) {
          if (t['lounge_transport_locations'] != null) {
            t['pickup_location_name'] = t['lounge_transport_locations']['location'];
          }
          if (t['lounges'] != null) {
            t['lounge_name'] = t['lounges']['lounge_name'];
          }
          fetchedTransports.add(TransportBooking.fromJson(t));
        }

        // Load driver details if transport exists
        await _loadTransportDetails(fetchedTransports.isNotEmpty ? fetchedTransports : response.booking.transportBookings);
      } catch (e) {
        _logger.e('Failed to fetch transport bookings directly: $e');
        await _loadTransportDetails(response.booking.transportBookings);
      }
      
      _logger.i('Loaded booking: ${response.booking.bookingReference}');
    } catch (e) {
      _logger.e('Failed to load booking: $e');
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelBooking() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text(
          'Are you sure you want to cancel this booking? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, Keep it'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCancelling = true);

    try {
      await _bookingService.cancelBooking(widget.bookingId);
      await _loadBookingDetails();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _logger.e('Failed to cancel booking: $e');
      setState(() => _isCancelling = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelTransportBooking(String transportId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Transport Booking'),
        content: const Text(
          'Are you sure you want to cancel this transport booking?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, Keep it'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCancelling = true);

    try {
      await _bookingService.cancelTransportBooking(transportId);
      await _loadBookingDetails();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transport booking cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _logger.e('Failed to cancel transport booking: $e');
      setState(() => _isCancelling = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildTransportCard(Map<String, dynamic> transportData) {
    final transport = transportData['transport'] as TransportBooking;
    final status = transport.status;
    final vehicleType = transport.vehicleType;
    final locationName = transport.pickupLocationName ?? 'N/A';
    final transportTime = transport.transportTime;
    final isCompleted = status == 'completed';
    final transportId = transport.id;

    final assignment = transportData['driver_assignment'];
    final bool hasDriver = assignment != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_taxi, color: Color(0xFFE65100)),
                  const SizedBox(width: 8),
                  Text(
                    vehicleType,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE65100).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE65100),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.location_on, 'Pickup Location', locationName),
          const SizedBox(height: 8),
          _buildDetailRow(
            Icons.access_time,
            'Pickup Time',
            transportTime != null ? _formatTime(transportTime) : 'N/A',
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            Icons.person,
            'Driver Status',
            hasDriver ? 'Driver Assigned' : 'Pending Driver',
          ),

          if (hasDriver) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(),
            ),
            const Text(
              'Assigned Driver',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.badge,
              'Driver Name',
              assignment['lounge_drivers']?['name'] ?? 'N/A',
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.phone,
              'Driver Contact',
              assignment['driver_contact'] ?? 'N/A',
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.directions_car,
              'Vehicle No',
              assignment['lounge_drivers']?['vehicle_no'] ?? 'N/A',
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.local_taxi,
              'Vehicle Type',
              assignment['lounge_drivers']?['vehicle_type'] ?? 'N/A',
            ),
          ],

          if (!isCompleted) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isCancelling
                    ? null
                    : () => _cancelTransportBooking(transportId),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isCancelling
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.red,
                        ),
                      )
                    : const Text('Cancel Transport'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary, // Themed background for top
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Booking Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_bookingResponse != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadBookingDetails,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _errorMessage != null
          ? _buildErrorView()
          : _buildContent(),
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
              onPressed: _loadBookingDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.primary,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final booking = _bookingResponse!.booking;
    final busBooking = _bookingResponse!.busBooking;
    final seats = _bookingResponse!.seats;
    final preLounge = _bookingResponse!.preLoungeBooking;
    final postLounge = _bookingResponse!.postLoungeBooking;
    final qrCode = _bookingResponse!.qrCode ?? busBooking?.qrCodeData ?? '';

    // Collect all active QR cards
    final List<Widget> qrCards = [];
    if (qrCode.isNotEmpty &&
        booking.bookingStatus != MasterBookingStatus.cancelled) {
      qrCards.add(_buildBusQRCodeCard(busBooking, booking, qrCode, seats));
    }

    if ((preLounge != null || postLounge != null) &&
        booking.bookingStatus != MasterBookingStatus.cancelled) {
      if (preLounge != null) {
        qrCards.add(
          _buildLoungeQRCodeCard(
            title: booking.bookingType == BookingType.loungeOnly
                ? 'Lounge Booking'
                : 'Boarding Lounge',
            qrData: preLounge.qrCode ?? preLounge.reference,
            subtitle: 'Show at lounge entry',
            icon: Icons.weekend,
            color: const Color(0xFF2196F3),
          ),
        );
      }
      if (postLounge != null) {
        qrCards.add(
          _buildLoungeQRCodeCard(
            title: 'Destination Lounge',
            qrData: postLounge.qrCode ?? postLounge.reference,
            subtitle: 'Show at lounge entry',
            icon: Icons.hotel,
            color: const Color(0xFF9C27B0),
          ),
        );
      }
    }

    final activeTransportBookings = _transportDetails
        .where(
          (t) => (t['transport'] as TransportBooking).status != 'cancelled',
        )
        .toList();

    final showTimer =
        busBooking != null &&
        booking.bookingStatus == MasterBookingStatus.confirmed &&
        busBooking.departureDatetime.isAfter(DateTime.now());
    final double pageViewHeight = showTimer ? 490 : 430;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Reference and Status Bar Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.receipt_long,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Booking Reference',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      booking.bookingReference,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () {
                                      Clipboard.setData(
                                        ClipboardData(
                                          text: booking.bookingReference,
                                        ),
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Reference copied'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                    child: Icon(
                                      Icons.copy,
                                      size: 14,
                                      color: AppColors.primary.withOpacity(0.6),
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
                  const SizedBox(width: 8),
                  _buildStatusChip(booking.bookingStatus),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // QR Cards Carousel
            if (qrCards.isNotEmpty) ...[
              if (qrCards.length == 1)
                qrCards[0]
              else ...[
                SizedBox(
                  height: pageViewHeight,
                  child: PageView.builder(
                    controller: _qrPageController,
                    itemCount: qrCards.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentQrPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: qrCards[index],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(qrCards.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 6,
                      width: _currentQrPage == index ? 16 : 6,
                      decoration: BoxDecoration(
                        color: _currentQrPage == index
                            ? AppColors.primary
                            : AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ],
              const SizedBox(height: 20),
            ],

            // Trip Details
            if (busBooking != null) ...[
              _buildSectionHeader('Trip Details', Icons.route_outlined),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: _sectionCardDecoration(),
                child: Column(
                  children: [
                    _buildDetailRow(Icons.route, 'Route', busBooking.routeName),
                    const Divider(height: 1),
                    _buildDetailRow(
                      Icons.location_on_outlined,
                      'From',
                      booking.searchFromLounge != null &&
                              booking.searchFromLounge!.isNotEmpty
                          ? booking.searchFromLounge!
                          : busBooking.boardingStopName,
                    ),
                    const Divider(height: 1),
                    _buildDetailRow(
                      Icons.location_on,
                      'To',
                      booking.searchToLounge != null &&
                              booking.searchToLounge!.isNotEmpty
                          ? booking.searchToLounge!
                          : busBooking.alightingStopName,
                    ),
                    const Divider(height: 1),
                    _buildDetailRow(
                      Icons.calendar_today,
                      'Date & Time',
                      _formatDateTime(busBooking.departureDatetime),
                    ),
                    if (busBooking.busType != null) ...[
                      const Divider(height: 1),
                      _buildDetailRow(
                        Icons.directions_bus,
                        'Bus Type',
                        busBooking.busTypeDisplay,
                      ),
                    ],
                    if (busBooking.busNumber != null) ...[
                      const Divider(height: 1),
                      _buildDetailRow(
                        Icons.confirmation_number,
                        'Bus Number',
                        busBooking.busNumber!,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Seat Details
            _buildSectionHeader('Seat Details', Icons.event_seat_outlined),
            if (seats.isNotEmpty)
              ...seats.map((seat) => _buildSeatCard(seat))
            else if (busBooking != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _sectionCardDecoration(),
                child: Row(
                  children: [
                    const Icon(Icons.event_seat, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      '${busBooking.numberOfSeats} seat(s)',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            if (_isLoadingTransportDetails) ...[
              _buildSectionHeader(
                'Transport Details',
                Icons.local_taxi_outlined,
              ),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 20),
            ] else if (activeTransportBookings.isNotEmpty) ...[
              _buildSectionHeader(
                'Transport Details',
                Icons.local_taxi_outlined,
              ),
              ...activeTransportBookings.map(
                (transport) => _buildTransportCard(transport),
              ),
              const SizedBox(height: 20),
            ] else if (booking.canBeCancelled) ...[
              _buildSectionHeader(
                'Transport Details',
                Icons.local_taxi_outlined,
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Action not required currently
                  },
                  icon: const Icon(Icons.local_taxi),
                  label: const Text(
                    'Book Transport',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Passenger Info
            _buildSectionHeader('Passenger Information', Icons.person_outline),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: _sectionCardDecoration(),
              child: Column(
                children: [
                  _buildDetailRow(Icons.person, 'Name', booking.passengerName),
                  const Divider(height: 1),
                  _buildDetailRow(Icons.phone, 'Phone', booking.passengerPhone),
                  if (booking.passengerEmail != null) ...[
                    const Divider(height: 1),
                    _buildDetailRow(
                      Icons.email,
                      'Email',
                      booking.passengerEmail!,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Payment Summary
            _buildSectionHeader('Payment Summary', Icons.payment_outlined),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _sectionCardDecoration(),
              child: Column(
                children: [
                  _buildPriceRow('Subtotal', booking.subtotal),
                  if (booking.discountAmount > 0)
                    _buildPriceRow(
                      'Discount',
                      -booking.discountAmount,
                      isDiscount: true,
                    ),
                  if (booking.taxAmount > 0)
                    _buildPriceRow('Tax', booking.taxAmount),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        booking.formattedTotal,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Payment Status',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      _buildPaymentStatusChip(booking.paymentStatus),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            if (booking.canBeCancelled) ...[
              if (booking.paymentStatus == MasterPaymentStatus.pending) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaymentMethodScreen(
                            bookingPrice: booking.totalAmount.toStringAsFixed(
                              2,
                            ),
                            referenceNo: booking.bookingReference,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Pay Now',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isCancelling ? null : _cancelBooking,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isCancelling
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.red,
                          ),
                        )
                      : const Text(
                          'Cancel Booking',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  BoxDecoration _sectionCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary.withOpacity(0.8)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatCard(BusBookingSeat seat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: _sectionCardDecoration(),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                seat.seatNumber,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  seat.passengerName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (seat.passengerPhone != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    seat.passengerPhone!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            seat.formattedPrice,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoungeQRCodeCard({
    required String title,
    required String qrData,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(color: color),
                child: Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: Colors.white.withOpacity(0.95),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // QR Code
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 110,
                  backgroundColor: Colors.white,
                ),
              ),

              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Show this QR code at entry',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _getCityName(String stopName) {
    if (stopName.isEmpty) return 'N/A';
    final parts = stopName.split(' ');
    if (parts.isNotEmpty) {
      return parts[0];
    }
    return stopName;
  }

  Widget _buildBusQRCodeCard(
    BusBooking? busBooking,
    MasterBooking booking,
    String qrCode,
    List<BusBookingSeat> seats,
  ) {
    final seatNumbers = seats.isNotEmpty
        ? seats.map((s) => s.seatNumber).join(', ')
        : (busBooking?.numberOfSeats != null
              ? '${busBooking!.numberOfSeats} Seats'
              : 'N/A');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            children: [
              // Ticket Header
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 20,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.directions_bus,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'BOARDING PASS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: Colors.white.withOpacity(0.95),
                      ),
                    ),
                  ],
                ),
              ),

              // Journey route summary on ticket
              if (busBooking != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getCityName(
                                booking.searchFromLounge ??
                                    busBooking.boardingStopName,
                              ),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              booking.searchFromLounge ??
                                  busBooking.boardingStopName,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(
                              width: 40,
                              child: Divider(
                                color: AppColors.primary.withOpacity(0.5),
                                thickness: 1.5,
                              ),
                            ),
                            const Icon(
                              Icons.directions_bus,
                              color: AppColors.primary,
                              size: 16,
                            ),
                            SizedBox(
                              width: 40,
                              child: Divider(
                                color: AppColors.primary.withOpacity(0.5),
                                thickness: 1.5,
                              ),
                            ),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.primary,
                                  width: 1.5,
                                ),
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _getCityName(
                                booking.searchToLounge ??
                                    busBooking.alightingStopName,
                              ),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              booking.searchToLounge ??
                                  busBooking.alightingStopName,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Dashed Ticket Divider inside the card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  height: 24,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Dashed line
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return Flex(
                            direction: Axis.horizontal,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(
                              (constraints.constrainWidth() / 8).floor(),
                              (index) => SizedBox(
                                width: 4,
                                height: 1,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      // Left cutout (colored white to mask container background)
                      Positioned(
                        left: -28,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: AppColors
                                .background, // Match screen background color
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      // Right cutout
                      Positioned(
                        right: -28,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: AppColors.background,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // QR Code and Boarding Instructions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: qrCode,
                        version: QrVersions.auto,
                        size: 140,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Ready for Boarding',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Scan this QR code with the conductor',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Dotted divider before metadata details
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  height: 24,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Flex(
                        direction: Axis.horizontal,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          (constraints.constrainWidth() / 8).floor(),
                          (index) => SizedBox(
                            width: 4,
                            height: 1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Metadata grid (Passenger, Seat, Departure)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PASSENGER',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            booking.passengerName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'SEAT',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            seatNumbers,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'DEPARTURE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            busBooking != null
                                ? _formatTime(busBooking.departureDatetime)
                                : 'N/A',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Countdown Timer Section
              if (busBooking != null &&
                  booking.bookingStatus == MasterBookingStatus.confirmed &&
                  busBooking.departureDatetime.isAfter(DateTime.now())) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.04),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'TIME UNTIL DEPARTURE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: AppColors.primary.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      BookingCountdownTimer(
                        targetDateTime: busBooking.departureDatetime,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    double amount, {
    bool isDiscount = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            isDiscount
                ? '-LKR ${amount.abs().toStringAsFixed(2)}'
                : 'LKR ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDiscount ? Colors.red : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(MasterBookingStatus status) {
    Color bgColor;
    Color textColor;
    String text;

    switch (status) {
      case MasterBookingStatus.confirmed:
        bgColor = const Color(0xFF4CAF50).withOpacity(0.12);
        textColor = const Color(0xFF4CAF50);
        text = 'Confirmed';
        break;
      case MasterBookingStatus.pending:
        bgColor = Colors.orange.withOpacity(0.12);
        textColor = Colors.orange.shade800;
        text = 'Pending';
        break;
      case MasterBookingStatus.completed:
        bgColor = Colors.blue.withOpacity(0.12);
        textColor = Colors.blue.shade700;
        text = 'Completed';
        break;
      case MasterBookingStatus.cancelled:
        bgColor = Colors.red.withOpacity(0.12);
        textColor = Colors.red;
        text = 'Cancelled';
        break;
      default:
        bgColor = Colors.grey.withOpacity(0.12);
        textColor = Colors.grey.shade700;
        text = status.displayName;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPaymentStatusChip(MasterPaymentStatus status) {
    Color bgColor;
    Color textColor;
    String text;
    IconData icon;

    switch (status) {
      case MasterPaymentStatus.paid:
        bgColor = const Color(0xFF4CAF50).withOpacity(0.1);
        textColor = const Color(0xFF4CAF50);
        text = 'Paid';
        icon = Icons.check_circle;
        break;
      case MasterPaymentStatus.pending:
        bgColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        text = 'Payment Pending';
        icon = Icons.schedule;
        break;
      case MasterPaymentStatus.collectOnBus:
        bgColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
        text = 'Pay on Bus';
        icon = Icons.directions_bus;
        break;
      case MasterPaymentStatus.free:
        bgColor = const Color(0xFF4CAF50).withOpacity(0.1);
        textColor = const Color(0xFF4CAF50);
        text = 'Free';
        icon = Icons.card_giftcard;
        break;
      default:
        bgColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
        text = status.toJson();
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, ${hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $period';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $period';
  }
}
