import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/search_models.dart';
import '../../models/booking_models.dart';
import '../../screens/bus_booking/add_lounge_screen.dart';
import '../../theme/app_colors.dart';

/// Journey Summary Screen for Transit Trips (A → B → C)
///
/// Shows a complete journey breakdown before final booking confirmation, including:
/// - Boarding lounge (if selected)
/// - Leg 1 bus details (A → B)
/// - Transit lounge details (mandatory)
/// - Leg 2 bus details (B → C)
/// - Destination lounge (if selected)
/// - Itemised cost breakdown
/// - Confirm Booking button
class TransitJourneySummaryScreen extends StatelessWidget {
  final TripResult transitTrip;
  final String boardingPoint;
  final String alightingPoint;
  final List<TripSeat> seatsLeg1;
  final List<TripSeat> seatsLeg2;

  final SelectedLoungeData? boardingLounge;
  final SelectedLoungeData transitLounge; // mandatory
  final SelectedLoungeData? destinationLounge;

  final double leg1Fare;
  final double leg2Fare;

  final VoidCallback onConfirmBooking;

  const TransitJourneySummaryScreen({
    super.key,
    required this.transitTrip,
    required this.boardingPoint,
    required this.alightingPoint,
    required this.seatsLeg1,
    required this.seatsLeg2,
    this.boardingLounge,
    required this.transitLounge,
    this.destinationLounge,
    required this.leg1Fare,
    required this.leg2Fare,
    required this.onConfirmBooking,
  });

  TripResult get _leg1 => transitTrip.leg1!;
  TripResult get _leg2 => transitTrip.leg2!;

  double get _totalLoungeCost {
    double total = transitLounge.totalPrice;
    if (boardingLounge != null) total += boardingLounge!.totalPrice;
    if (destinationLounge != null) total += destinationLounge!.totalPrice;
    return total;
  }

  double get _totalTransportCost {
    double total = transitLounge.transportCost;
    if (boardingLounge != null) total += boardingLounge!.transportCost;
    if (destinationLounge != null) total += destinationLounge!.transportCost;
    return total;
  }

  double get _grandTotal => leg1Fare + leg2Fare + _totalLoungeCost + _totalTransportCost;

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
          'Journey Summary',
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
            // Transit header badge
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.compare_arrows, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$boardingPoint → ${transitTrip.transitPoint ?? 'Transit'} → $alightingPoint',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8F00),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'TRANSIT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── 1. Boarding Lounge (optional) ──────────────────
                      if (boardingLounge != null) ...[
                        _buildSectionTitle('Boarding Lounge', Icons.weekend, Colors.teal),
                        _buildLoungeCard(boardingLounge!, isTransit: false, isMandatory: false),
                        _buildConnector(color: Colors.teal),
                      ],

                      // ── 2. Leg 1 Bus ───────────────────────────────────
                      _buildSectionTitle('Leg 1 — ${_leg1.boardingPoint} → ${_leg1.droppingPoint}', Icons.directions_bus, AppColors.primary),
                      _buildLegCard(
                        leg: _leg1,
                        seats: seatsLeg1,
                        fare: leg1Fare,
                        color: AppColors.primary,
                      ),
                      _buildConnector(color: const Color(0xFFFF8F00), label: transitTrip.formattedTransitWaitTime),

                      // ── 3. Transit Lounge (mandatory) ──────────────────
                      _buildSectionTitle('Transit Lounge (Required)', Icons.lock, const Color(0xFFE53935)),
                      _buildLoungeCard(transitLounge, isTransit: true, isMandatory: true),
                      _buildConnector(color: const Color(0xFF7B1FA2)),

                      // ── 4. Leg 2 Bus ───────────────────────────────────
                      _buildSectionTitle('Leg 2 — ${_leg2.boardingPoint} → ${_leg2.droppingPoint}', Icons.directions_bus, const Color(0xFF7B1FA2)),
                      _buildLegCard(
                        leg: _leg2,
                        seats: seatsLeg2,
                        fare: leg2Fare,
                        color: const Color(0xFF7B1FA2),
                      ),

                      // ── 5. Destination Lounge (optional) ──────────────
                      if (destinationLounge != null) ...[
                        _buildConnector(color: Colors.deepOrange),
                        _buildSectionTitle('Destination Lounge', Icons.local_hotel, Colors.deepOrange),
                        _buildLoungeCard(destinationLounge!, isTransit: false, isMandatory: false),
                      ],

                      const SizedBox(height: 24),

                      // ── Cost Breakdown ─────────────────────────────────
                      _buildCostBreakdown(),

                      const SizedBox(height: 24),

                      // ── Confirm Button ────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onConfirmBooking,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                          child: const Text(
                            'Confirm Booking',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegCard({
    required TripResult leg,
    required List<TripSeat> seats,
    required double fare,
    required Color color,
  }) {
    final dep = DateFormat('h:mm a').format(leg.departureTime);
    final arr = DateFormat('h:mm a').format(leg.estimatedArrival);
    final seatNumbers = seats.map((s) => s.seatNumber).join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dep,
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    leg.boardingPoint,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              Column(
                children: [
                  Row(
                    children: [
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      Container(width: 40, height: 2, color: color.withOpacity(0.4)),
                      Icon(Icons.directions_bus, size: 16, color: color),
                      Container(width: 40, height: 2, color: color.withOpacity(0.4)),
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: color, width: 2))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    leg.formattedDuration,
                    style: TextStyle(color: color.withOpacity(0.7), fontSize: 11),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    arr,
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    leg.droppingPoint,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.event_seat, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    seats.isEmpty ? 'No seats selected' : seatNumbers,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              Text(
                'LKR ${fare.toStringAsFixed(2)}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoungeCard(
    SelectedLoungeData lounge, {
    required bool isTransit,
    required bool isMandatory,
  }) {
    final borderColor = isTransit
        ? const Color(0xFFE53935)
        : Colors.teal;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMandatory
              ? const Color(0xFFE53935).withOpacity(0.4)
              : Colors.teal.withOpacity(0.2),
          width: isMandatory ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  lounge.lounge.loungeName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (isMandatory)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, size: 10, color: Color(0xFFE53935)),
                      SizedBox(width: 3),
                      Text(
                        'Required',
                        style: TextStyle(
                          color: Color(0xFFE53935),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            lounge.lounge.address,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _formatPricingType(lounge.pricingType),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              Text(
                'LKR ${lounge.totalPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  color: isMandatory ? const Color(0xFFE53935) : Colors.teal,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if (lounge.transportCost > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.directions_car, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Transport (${lounge.transportType ?? 'van'})',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                Text(
                  '+ LKR ${lounge.transportCost.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConnector({required Color color, String? label}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      child: Row(
        children: [
          Column(
            children: [
              Container(width: 2, height: 12, color: color.withOpacity(0.4)),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1.5),
                ),
              ),
              Container(width: 2, height: 12, color: color.withOpacity(0.4)),
            ],
          ),
          if (label != null && label.isNotEmpty) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCostBreakdown() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cost Breakdown',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildCostRow(
            'Leg 1 Bus Fare',
            'LKR ${leg1Fare.toStringAsFixed(2)}',
            icon: Icons.directions_bus,
            color: AppColors.primary,
          ),
          _buildCostRow(
            'Leg 2 Bus Fare',
            'LKR ${leg2Fare.toStringAsFixed(2)}',
            icon: Icons.directions_bus,
            color: const Color(0xFF7B1FA2),
          ),
          if (boardingLounge != null)
            _buildCostRow(
              'Boarding Lounge',
              'LKR ${boardingLounge!.totalPrice.toStringAsFixed(2)}',
              icon: Icons.weekend,
              color: Colors.teal,
            ),
          _buildCostRow(
            'Transit Lounge (Required)',
            'LKR ${transitLounge.totalPrice.toStringAsFixed(2)}',
            icon: Icons.lock,
            color: const Color(0xFFE53935),
          ),
          if (destinationLounge != null)
            _buildCostRow(
              'Destination Lounge',
              'LKR ${destinationLounge!.totalPrice.toStringAsFixed(2)}',
              icon: Icons.local_hotel,
              color: Colors.deepOrange,
            ),
          if (_totalTransportCost > 0)
            _buildCostRow(
              'Transport',
              'LKR ${_totalTransportCost.toStringAsFixed(2)}',
              icon: Icons.directions_car,
              color: Colors.grey,
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              Text(
                'LKR ${_grandTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCostRow(String label, String amount, {required IconData icon, required Color color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 13, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatPricingType(String type) {
    switch (type) {
      case '1_hour':
        return '1 Hour';
      case '2_hours':
        return '2 Hours';
      case '3_hours':
        return '3 Hours';
      case 'until_bus':
        return 'Until Bus Departs';
      default:
        return type.replaceAll('_', ' ');
    }
  }
}
