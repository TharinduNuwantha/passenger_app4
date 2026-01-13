import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/booking_intent_models.dart';
import '../../models/search_models.dart';
import '../../theme/app_colors.dart';

/// Success screen after booking is confirmed via intent flow
/// Supports combined bus + lounge bookings with multiple QR codes
class BookingSuccessScreen extends StatelessWidget {
  final String masterReference;
  final String? busReference;
  final double totalAmount;
  final TripResult trip;
  final String boardingPoint;
  final String alightingPoint;
  final String seatNumbers;

  // Lounge booking info (for combined bookings)
  final ConfirmedBookingInfo? preLoungeBooking;
  final ConfirmedBookingInfo? postLoungeBooking;

  const BookingSuccessScreen({
    super.key,
    required this.masterReference,
    this.busReference,
    required this.totalAmount,
    required this.trip,
    required this.boardingPoint,
    required this.alightingPoint,
    required this.seatNumbers,
    this.preLoungeBooking,
    this.postLoungeBooking,
  });

  /// Factory constructor from ConfirmBookingResponse
  factory BookingSuccessScreen.fromResponse({
    required ConfirmBookingResponse response,
    required TripResult trip,
    required String boardingPoint,
    required String alightingPoint,
    required String seatNumbers,
  }) {
    return BookingSuccessScreen(
      masterReference: response.masterReference,
      busReference: response.busBooking?.reference,
      totalAmount: response.effectiveTotalAmount,
      trip: trip,
      boardingPoint: boardingPoint,
      alightingPoint: alightingPoint,
      seatNumbers: seatNumbers,
      preLoungeBooking: response.preLoungeBooking,
      postLoungeBooking: response.postLoungeBooking,
    );
  }

  bool get hasLoungeBookings =>
      preLoungeBooking != null || postLoungeBooking != null;

  @override
  Widget build(BuildContext context) {
    print('🎉 BookingSuccessScreen build:');
    print('  Bus ref: $busReference');
    print(
      '  Pre-lounge: ${preLoungeBooking?.reference}, QR: ${preLoungeBooking?.qrCode}',
    );
    print(
      '  Post-lounge: ${postLoungeBooking?.reference}, QR: ${postLoungeBooking?.qrCode}',
    );
    print('  hasLoungeBookings: $hasLoungeBookings');

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Success Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(Icons.check, color: Color.fromARGB(255, 19, 143, 244), size: 50),
              ),
              const SizedBox(height: 20),

              // Success Message
              const Text(
                'Payment Successful!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Reference: $masterReference',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                hasLoungeBookings
                    ? 'Your bus + lounge booking is confirmed!\nSafe travels & enjoy your journey!'
                    : 'Your booking is confirmed!\nSafe travels & enjoy your journey!',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),

              // QR Code Cards (swipeable if multiple)
              _buildQRCodeSection(),

              const SizedBox(height: 20),

              // Trip Details Card
              _buildTripDetailsCard(),

              const SizedBox(height: 20),

              // Copy Reference Button
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: masterReference));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reference copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy Reference'),
              ),

              const SizedBox(height: 30),

              // Back to Home Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 224, 12, 12),
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color.fromARGB(255, 252, 250, 250)),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: () {
                  // TODO: Navigate to My Bookings screen
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text(
                  'View My Bookings',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQRCodeSection() {
    // Build list of QR cards
    final qrCards = <Widget>[];

    // Bus QR is always first (if exists)
    if (busReference != null && busReference!.isNotEmpty) {
      qrCards.add(
        _buildQRCard(
          title: 'Bus Boarding Pass',
          subtitle: 'Show to conductor',
          qrData: busReference!,
          icon: Icons.directions_bus,
          color: AppColors.primary,
        ),
      );
    }

    // Pre-trip lounge QR
    if (preLoungeBooking != null) {
      qrCards.add(
        _buildQRCard(
          title: 'Boarding Lounge',
          subtitle: 'Show at lounge entry',
          qrData: preLoungeBooking!.qrCode ?? preLoungeBooking!.reference,
          icon: Icons.weekend,
          color: const Color(0xFF2196F3),
          reference: preLoungeBooking!.reference,
        ),
      );
    }

    // Destination lounge QR
    if (postLoungeBooking != null) {
      qrCards.add(
        _buildQRCard(
          title: 'Destination Lounge',
          subtitle: 'Show at lounge entry',
          qrData: postLoungeBooking!.qrCode ?? postLoungeBooking!.reference,
          icon: Icons.hotel,
          color: const Color(0xFF9C27B0),
          reference: postLoungeBooking!.reference,
        ),
      );
    }

    // Fallback if no specific QRs (use master reference)
    if (qrCards.isEmpty) {
      qrCards.add(
        _buildQRCard(
          title: 'Your Boarding Pass',
          subtitle: 'Show to conductor',
          qrData: masterReference,
          icon: Icons.confirmation_number,
          color: AppColors.primary,
        ),
      );
    }

    // If only one QR, show it directly
    if (qrCards.length == 1) {
      return qrCards.first;
    }

    // Multiple QRs - show in a PageView with indicators
    return _MultiQRView(qrCards: qrCards);
  }

  Widget _buildQRCard({
    required String title,
    required String subtitle,
    required String qrData,
    required IconData icon,
    required Color color,
    String? reference,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 180,
              backgroundColor: Colors.white,
              errorStateBuilder: (context, error) {
                return Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'QR Code\nGenerating...',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: color.withOpacity(0.7)),
          ),
          if (reference != null) ...[
            const SizedBox(height: 4),
            Text(
              'Ref: $reference',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTripDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trip Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const Divider(height: 20),
          _buildDetailRow('Route', trip.routeName),
          _buildDetailRow('From', boardingPoint),
          _buildDetailRow('To', alightingPoint),
          _buildDetailRow(
            'Date & Time',
            DateFormat('dd MMM yyyy, hh:mm a').format(trip.departureTime),
          ),
          _buildDetailRow('Bus Type', trip.busTypeDisplay),
          _buildDetailRow('Seats', seatNumbers),

          // Show lounge info if applicable
          if (preLoungeBooking != null) ...[
            const SizedBox(height: 8),
            _buildDetailRow('Boarding Lounge', 'Booked ✓', highlight: true),
          ],
          if (postLoungeBooking != null) ...[
            const SizedBox(height: 4),
            _buildDetailRow('Destination Lounge', 'Booked ✓', highlight: true),
          ],

          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Paid',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'LKR ${totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '✓ Paid',
              style: TextStyle(
                color: Color(0xFF4CAF50),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: highlight
                    ? const Color(0xFF4CAF50)
                    : AppColors.primary.withOpacity(0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
                color: highlight ? const Color(0xFF4CAF50) : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget for displaying multiple QR codes with PageView
class _MultiQRView extends StatefulWidget {
  final List<Widget> qrCards;

  const _MultiQRView({required this.qrCards});

  @override
  State<_MultiQRView> createState() => _MultiQRViewState();
}

class _MultiQRViewState extends State<_MultiQRView> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Page indicator text
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Swipe to see ${widget.qrCards.length} QR codes',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
        // PageView for QR cards
        SizedBox(
          height: 320,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.qrCards.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: widget.qrCards[index],
              );
            },
          ),
        ),
        // Page indicators
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.qrCards.length, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentIndex == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentIndex == index
                    ? const Color(0xFFFFC300)
                    : Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}
