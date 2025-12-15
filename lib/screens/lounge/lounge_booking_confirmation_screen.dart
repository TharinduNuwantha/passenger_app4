import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/lounge_booking_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_style.dart';

/// Confirmation screen shown after successful booking
class LoungeBookingConfirmationScreen extends StatelessWidget {
  final LoungeBooking booking;
  final Lounge lounge;

  /// Bus booking reference if linked to bus trip
  final String? busBookingReference;

  /// Whether this lounge booking is linked to a bus trip
  final bool isLinkedToBus;

  const LoungeBookingConfirmationScreen({
    super.key,
    required this.booking,
    required this.lounge,
    this.busBookingReference,
    this.isLinkedToBus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Success icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      'Booking Confirmed!',
                      style: AppTextStyles.h1.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your lounge booking has been confirmed',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Booking reference
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Booking Reference',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            booking.bookingReference,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // QR Code
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          QrImageView(
                            data: booking.qrCodeData,
                            version: QrVersions.auto,
                            size: 180,
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Show this QR code at the lounge',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Booking details
                    _buildDetailsCard(context),
                    const SizedBox(height: 16),

                    // Bus booking link (if linked)
                    if (isLinkedToBus && busBookingReference != null)
                      _buildBusLinkCard(),

                    // Guests
                    if (booking.guests.isNotEmpty) _buildGuestsCard(),

                    // Pre-orders
                    if (booking.preOrders.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildPreOrdersCard(),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom button
            _buildBottomButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            Icons.airline_seat_individual_suite_outlined,
            'Lounge',
            lounge.loungeName,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            Icons.location_on_outlined,
            'Location',
            lounge.address,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            Icons.calendar_today_outlined,
            'Date & Time',
            booking.formattedScheduledArrival,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            Icons.timer_outlined,
            'Duration',
            booking.pricingType.displayName,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            Icons.receipt_outlined,
            'Total Amount',
            'LKR ${booking.totalAmount.toStringAsFixed(2)}',
            isHighlighted: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    bool isHighlighted = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
                  fontSize: isHighlighted ? 16 : 14,
                  color: isHighlighted ? AppColors.primary : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGuestsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people_outline, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Guests',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...booking.guests.map((guest) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.secondary,
                    child: Text(
                      guest.guestName[0].toUpperCase(),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(guest.guestName)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: guest.checkedIn
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      guest.checkedIn ? 'Checked In' : 'Pending',
                      style: TextStyle(
                        fontSize: 12,
                        color: guest.checkedIn ? Colors.green : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBusLinkCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.link, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Linked to Bus Trip',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Bus Booking: $busBookingReference',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: Colors.green, size: 24),
        ],
      ),
    );
  }

  Widget _buildPreOrdersCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant_menu, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Pre-Orders',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...booking.preOrders.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${item.quantity}x',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(item.productName)),
                  Text(
                    'LKR ${item.subtotal.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            // Pop all screens and go back to home
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text(
            'Done',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
