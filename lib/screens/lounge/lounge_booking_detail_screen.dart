import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/lounge_booking_models.dart';
import '../../services/lounge_booking_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_style.dart';

final _logger = Logger();

/// Detailed view of a single lounge booking
class LoungeBookingDetailScreen extends StatefulWidget {
  final LoungeBooking booking;

  const LoungeBookingDetailScreen({
    super.key,
    required this.booking,
  });

  @override
  State<LoungeBookingDetailScreen> createState() =>
      _LoungeBookingDetailScreenState();
}

class _LoungeBookingDetailScreenState extends State<LoungeBookingDetailScreen> {
  final LoungeBookingService _loungeService = LoungeBookingService();

  late LoungeBooking _booking;
  List<LoungeOrder> _orders = [];
  bool _isLoadingOrders = true;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final orders = await _loungeService.getBookingOrders(_booking.id);
      setState(() {
        _orders = orders;
        _isLoadingOrders = false;
      });
    } catch (e) {
      // Silently fail - lounge-only bookings may not have orders endpoint
      _logger.d('Could not load orders (expected for lounge-only bookings): $e');
      setState(() {
        _orders = [];
        _isLoadingOrders = false;
      });
    }
  }

  bool get _canCancel {
    return _booking.status == LoungeBookingStatus.pending ||
        _booking.status == LoungeBookingStatus.confirmed;
  }

  bool get _canOrder {
    return _booking.status == LoungeBookingStatus.checkedIn;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_canCancel && !_isCancelling)
            IconButton(
              onPressed: _showCancelDialog,
              icon: const Icon(Icons.cancel_outlined),
              tooltip: 'Cancel Booking',
            )
          else if (_isCancelling)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshBooking,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Status Banner
              _buildStatusBanner(),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // QR Code Card
                    _buildQRCard(),
                    const SizedBox(height: 16),

                    // Booking Details Card
                    _buildDetailsCard(),
                    const SizedBox(height: 16),

                    // Guests Card
                    if (_booking.guests.isNotEmpty) ...[
                      _buildGuestsCard(),
                      const SizedBox(height: 16),
                    ],

                    // Pre-Orders Card
                    if (_booking.preOrders.isNotEmpty) ...[
                      _buildPreOrdersCard(),
                      const SizedBox(height: 16),
                    ],

                    // In-Lounge Orders Card
                    if (_orders.isNotEmpty || _canOrder) ...[
                      _buildOrdersCard(),
                      const SizedBox(height: 16),
                    ],

                    // Payment Card
                    _buildPaymentCard(),
                    const SizedBox(height: 24),

                    // Action Buttons
                    if (_canOrder) _buildOrderButton(),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    final statusColor = _getStatusColor(_booking.status);
    final statusIcon = _getStatusIcon(_booking.status);
    final paymentColor = _getPaymentStatusColor(_booking.paymentStatus);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: statusColor.withOpacity(0.1),
      child: Column(
        children: [
          // Booking Status
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(statusIcon, color: statusColor, size: 24),
              const SizedBox(width: 12),
              Text(
                _booking.status.displayName.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          // Payment Status Badge
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: paymentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: paymentColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _booking.paymentStatus == LoungePaymentStatus.paid
                      ? Icons.check_circle
                      : Icons.pending,
                  size: 16,
                  color: paymentColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'Payment: ${_booking.paymentStatus.displayName}',
                  style: TextStyle(
                    color: paymentColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Booking Reference
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Booking Reference: ',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(
                      ClipboardData(text: _booking.bookingReference),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reference copied')),
                    );
                  },
                  child: Row(
                    children: [
                      Text(
                        _booking.bookingReference,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.copy, size: 16, color: AppColors.primary),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // QR Code
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: QrImageView(
                data: _booking.qrCodeData,
                version: QrVersions.auto,
                size: 180,
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Present this QR code at the lounge',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking Details',
              style: AppTextStyles.h3.copyWith(color: AppColors.primary),
            ),
            const Divider(height: 24),

            _buildDetailRow(
              Icons.airline_seat_individual_suite_outlined,
              'Lounge',
              _booking.loungeName ?? 'Lounge',
            ),
            const SizedBox(height: 16),

            _buildDetailRow(
              Icons.calendar_today,
              'Scheduled Arrival',
              _booking.formattedScheduledArrival,
            ),
            const SizedBox(height: 16),

            _buildDetailRow(
              Icons.timer,
              'Duration',
              _booking.pricingType.displayName,
            ),

            const SizedBox(height: 16),
            _buildDetailRow(
              Icons.login,
              'Check-In Time',
              _formatDateTime(_booking.checkInTime),
            ),

            if (_booking.actualCheckOutTime != null) ...[
              const SizedBox(height: 16),
              _buildDetailRow(
                Icons.logout,
                'Checked Out At',
                _formatDateTime(_booking.actualCheckOutTime!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGuestsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Guests (${_booking.guests.length})',
                  style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                ),
              ],
            ),
            const Divider(height: 24),
            ..._booking.guests.map((guest) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.secondary,
                      child: Text(
                        guest.guestName[0].toUpperCase(),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            guest.guestName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (guest.guestPhone != null)
                            Text(
                              guest.guestPhone!,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: guest.checkedIn
                            ? Colors.green.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            guest.checkedIn
                                ? Icons.check_circle
                                : Icons.schedule,
                            size: 14,
                            color:
                                guest.checkedIn ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            guest.checkedIn ? 'Checked In' : 'Pending',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  guest.checkedIn ? Colors.green : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPreOrdersCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.restaurant_menu, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Pre-Orders',
                  style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                ),
              ],
            ),
            const Divider(height: 24),
            ..._booking.preOrders.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
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
                          item.productName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'LKR ${item.unitPrice.toStringAsFixed(0)} each',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'LKR ${item.totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'In-Lounge Orders',
                  style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                ),
              ],
            ),
            const Divider(height: 24),

            if (_isLoadingOrders)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_orders.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_outlined,
                        size: 48,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No orders yet',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._orders.map((order) => _buildOrderItem(order)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(LoungeOrder order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Order #${order.orderNumber}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getOrderStatusColor(order.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  order.status.displayName,
                  style: TextStyle(
                    color: _getOrderStatusColor(order.status),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...order.items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Text('${item.quantity}x'),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item.productName)),
                  Text('LKR ${item.totalPrice.toStringAsFixed(0)}'),
                ],
              ),
            );
          }),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Total: LKR ${order.totalAmount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Payment',
                  style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                ),
              ],
            ),
            const Divider(height: 24),

            // Payment status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Status'),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getPaymentStatusColor(_booking.paymentStatus)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _booking.paymentStatus.displayName,
                    style: TextStyle(
                      color: _getPaymentStatusColor(_booking.paymentStatus),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Amount breakdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Lounge Fee', style: TextStyle(color: Colors.grey[600])),
                Text(
                  'LKR ${(_booking.totalAmount - _booking.preOrderTotal).toStringAsFixed(2)}',
                ),
              ],
            ),
            if (_booking.preOrderTotal > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Pre-Orders', style: TextStyle(color: Colors.grey[600])),
                  Text('LKR ${_booking.preOrderTotal.toStringAsFixed(2)}'),
                ],
              ),
            ],
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'LKR ${_booking.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          // TODO: Navigate to in-lounge ordering screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('In-lounge ordering coming soon!')),
          );
        },
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Order Food & Drinks'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
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
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _refreshBooking() async {
    try {
      final booking = await _loungeService.getBookingById(_booking.id);
      setState(() {
        _booking = booking;
      });
      await _loadOrders();
    } catch (e) {
      // Keep existing data
    }
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text(
          'Are you sure you want to cancel this booking? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No, Keep It'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelBooking();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelBooking() async {
    setState(() {
      _isCancelling = true;
    });

    try {
      await _loungeService.cancelBooking(_booking.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(LoungeBookingStatus status) {
    switch (status) {
      case LoungeBookingStatus.pending:
        return Colors.orange;
      case LoungeBookingStatus.confirmed:
        return Colors.blue;
      case LoungeBookingStatus.checkedIn:
        return Colors.green;
      case LoungeBookingStatus.completed:
        return Colors.grey;
      case LoungeBookingStatus.cancelled:
        return Colors.red;
      case LoungeBookingStatus.noShow:
        return Colors.red.shade300;
    }
  }

  IconData _getStatusIcon(LoungeBookingStatus status) {
    switch (status) {
      case LoungeBookingStatus.pending:
        return Icons.schedule;
      case LoungeBookingStatus.confirmed:
        return Icons.check_circle_outline;
      case LoungeBookingStatus.checkedIn:
        return Icons.login;
      case LoungeBookingStatus.completed:
        return Icons.done_all;
      case LoungeBookingStatus.cancelled:
        return Icons.cancel_outlined;
      case LoungeBookingStatus.noShow:
        return Icons.person_off;
    }
  }

  Color _getPaymentStatusColor(LoungePaymentStatus status) {
    switch (status) {
      case LoungePaymentStatus.pending:
        return Colors.orange;
      case LoungePaymentStatus.partial:
        return Colors.blue;
      case LoungePaymentStatus.paid:
        return Colors.green;
      case LoungePaymentStatus.refunded:
        return Colors.purple;
    }
  }

  Color _getOrderStatusColor(LoungeOrderStatus status) {
    switch (status) {
      case LoungeOrderStatus.pending:
        return Colors.orange;
      case LoungeOrderStatus.preparing:
        return Colors.blue;
      case LoungeOrderStatus.ready:
        return Colors.green;
      case LoungeOrderStatus.delivered:
        return Colors.grey;
      case LoungeOrderStatus.cancelled:
        return Colors.red;
    }
  }
}
