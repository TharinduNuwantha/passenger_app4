import 'package:flutter/material.dart';
import 'booking_conform.dart';

// 🎨 App Colors
class AppColors {
  static const Color primary = Color(0xFF031A4B);
  static const Color secondary = Color(0xFFE0F7FA);
  static const Color white = Colors.white;
}

// 🧾 App Text Styles (defined as constants)
class AppTextStyles {
  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );
  static const TextStyle h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
  );
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.primary,
  );
}

// 💺 Seat Color Config
class SeatColors {
  static const Color available = Color(0xFF4CAF50); // Green
  static const Color selected = Color(0xFFFFC300); // Yellow
  static Color booked = AppColors.primary.withOpacity(0.5); // Faded Blue
}

// --------------------------------------------------------------------------

class SeatBookingScreen extends StatefulWidget {
  final String busNumber;
  final double price;

  const SeatBookingScreen({
    super.key,
    required this.busNumber,
    required this.price,
  });

  @override
  State<SeatBookingScreen> createState() => _SeatBookingScreenState();
}

class _SeatBookingScreenState extends State<SeatBookingScreen> {
  final List<String> seatRows = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
  ];

  final Map<String, bool?> initialSeats = {
    'A1': null,
    'B1': null,
    'C1': null,
    'D1': true,
    'E1': true,
    'F1': null,
    'G1': true,
    'H1': null,
    'I1': null,
    'J1': null,
    'K1': true,
    'A2': true,
    'B2': true,
    'C2': true,
    'D2': null,
    'E2': true,
    'F2': true,
    'G2': true,
    'H2': null,
    'I2': null,
    'J2': true,
    'K2': null,
    'A3': true,
    'A4': null,
    'B3': null,
    'B4': true,
    'C3': null,
    'C4': true,
    'D3': true,
    'D4': null,
    'E3': true,
    'E4': true,
    'F3': true,
    'F4': true,
    'G3': true,
    'G4': true,
    'H3': null,
    'H4': null,
    'I3': null,
    'I4': true,
    'J3': true,
    'J4': null,
    'K3': null,
  };

  Set<String> _selectedSeats = {};

  void _toggleSeatSelection(String seatNo) {
    if (initialSeats[seatNo] == null) return; // already booked
    setState(() {
      if (_selectedSeats.contains(seatNo)) {
        _selectedSeats.remove(seatNo);
      } else {
        _selectedSeats.add(seatNo);
      }
    });
  }

  Color _getSeatColor(String seatNo) {
    if (initialSeats[seatNo] == null) return SeatColors.booked;
    if (_selectedSeats.contains(seatNo)) return SeatColors.selected;
    return SeatColors.available;
  }

  IconData _getSeatIcon(String seatNo) {
    if (initialSeats[seatNo] == null) {
      return Icons.notifications_off; // 🔕 booked
    }
    if (_selectedSeats.contains(seatNo)) {
      return Icons.notifications_active; // 🔔 selected
    }
    return Icons.notifications; // 🔔 available
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Seat Booking',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        centerTitle: true,
      ),

      body: SafeArea(
        child: Column(
          children: [
            _buildLegend(),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 10),
                decoration: const BoxDecoration(
                  color: AppColors.white,
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

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
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
          children: const [
            Icon(
              Icons.notifications_active,
              color: SeatColors.selected,
              size: 16,
            ),
            SizedBox(width: 5),
            Text(
              'Selected',
              style: TextStyle(fontSize: 14, color: AppColors.primary),
            ),
            SizedBox(width: 20),
            Icon(Icons.notifications, color: SeatColors.available, size: 16),
            SizedBox(width: 5),
            Text(
              'Available',
              style: TextStyle(fontSize: 14, color: AppColors.primary),
            ),
            SizedBox(width: 20),
            Icon(Icons.notifications_off, color: AppColors.primary, size: 16),
            SizedBox(width: 5),
            Text(
              'Booked',
              style: TextStyle(fontSize: 14, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeatLayout() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          // 🟡 Dynamic selected count
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedSeats.length.toString(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(flex: 3),
                const Icon(Icons.drive_eta, size: 40, color: AppColors.primary),
              ],
            ),
          ),

          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: seatRows.map((r) => _buildRowLabel(r)).toList(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    children: seatRows.map((r) => _buildSeatRow(r)).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRowLabel(String row) {
    return Container(
      height: 30,
      alignment: Alignment.centerRight,
      child: Text(
        row,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSeatOrPlaceholder(String? seatNo) {
    if (seatNo == null) return const Spacer(flex: 2);
    if (initialSeats.containsKey(seatNo)) {
      return Expanded(flex: 1, child: _buildSeat(seatNo));
    }
    return const Expanded(flex: 1, child: SizedBox.shrink());
  }

  Widget _buildSeatRow(String row) {
    final List<String?> seatOrder = [
      '${row}1',
      '${row}2',
      null,
      '${row}3',
      '${row}4',
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: SizedBox(
        height: 30,
        child: Row(
          children: seatOrder.map((s) => _buildSeatOrPlaceholder(s)).toList(),
        ),
      ),
    );
  }

  Widget _buildSeat(String seatNo) {
    return GestureDetector(
      onTap: initialSeats[seatNo] == null
          ? null
          : () => _toggleSeatSelection(seatNo),
      child: Icon(_getSeatIcon(seatNo), color: _getSeatColor(seatNo), size: 26),
    );
  }

  Widget _buildConfirmButton() {
    final seatCount = _selectedSeats.length;
    final totalPrice = seatCount * widget.price;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      child: ElevatedButton(
        onPressed: seatCount == 0
            ? null
            : () {
                final selectedSeatsString = _selectedSeats.join(', ');
                const mockReferenceNo = 'AAC00126';
                const mockRoute = 'Colombo to Galle';
                const mockDateTime = '12 Sept, 10:45 AM';
                const mockBusType = 'AC Luxury';
                const mockNumberPlate = 'GL - 2984';

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingConfirmedScreen(
                      referenceNo: mockReferenceNo,
                      route: mockRoute,
                      dateTime: mockDateTime,
                      busType: mockBusType,
                      numberPlate: mockNumberPlate,
                      seatNo: selectedSeatsString,
                      price: 'LKR ${totalPrice.toStringAsFixed(0)}',
                    ),
                  ),
                );
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: SeatColors.selected,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          disabledBackgroundColor: Colors.grey,
        ),
        child: Text(
          seatCount > 0
              ? 'Confirm (${seatCount} Seats - Rs.${totalPrice.toStringAsFixed(2)})'
              : 'Select Seats to Confirm',
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
