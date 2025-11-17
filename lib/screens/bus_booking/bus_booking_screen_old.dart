import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_style.dart';
import 'seat_booking_screen.dart' hide AppColors, AppTextStyles;

class BusListScreen extends StatefulWidget {
  final DateTime? date;
  final String pickup;
  final String drop;

  const BusListScreen({
    super.key,
    this.date,
    required this.pickup,
    required this.drop,
  });

  @override
  State<BusListScreen> createState() => _BusListScreenState();
}

class _BusListScreenState extends State<BusListScreen> {
  String _selectedBusType = 'All';

  final List<Map<String, dynamic>> allBuses = [
    {
      'route': 'Colombo - Galle',
      'type': 'Normal',
      'price': 400.00,
      'busNo': 'NC - 2345',
      'time': '9.30 AM — 1.00 PM',
      'seats': '18 Seats Available',
      'image': 'assets/images/bus1.png',
    },
    {
      'route': 'Colombo - Matara',
      'type': 'Semi-Sleeper',
      'price': 780.00,
      'busNo': 'NA - 7821',
      'time': '10.00 AM — 12.30 PM',
      'seats': '05 Seats Available',
      'image': 'assets/images/bus2.png',
    },
    {
      'route': 'Colombo - Tangalle',
      'type': 'AC Luxury',
      'price': 1500.00,
      'busNo': 'GL - 2984',
      'time': '10.45 AM — 1.00 AM',
      'seats': '20 Seats Available',
      'image': 'assets/images/bus3.png',
    },
    {
      'route': 'Colombo - Kandy',
      'type': 'Normal',
      'price': 550.00,
      'busNo': 'NB - 4567',
      'time': '11.00 AM — 2.00 PM',
      'seats': '12 Seats Available',
      'image': 'assets/images/bus1.png',
    },
  ];

  final List<String> busTypes = ['Normal', 'AC Luxury', 'Semi-Sleeper'];

  @override
  Widget build(BuildContext context) {
    final formattedDate = widget.date != null
        ? "${widget.date!.day} ${_getMonthName(widget.date!.month)} ${widget.date!.year}"
        : "No Date Selected";

    final filteredBuses = _selectedBusType == 'All'
        ? allBuses
        : allBuses.where((bus) => bus['type'] == _selectedBusType).toList();

    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: AppColors.primary,
        body: Column(
          children: [
            _buildHeaderAndFilters(
              context,
              formattedDate,
              filteredBuses.length,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: filteredBuses.length,
                  itemBuilder: (context, index) {
                    final bus = filteredBuses[index];
                    return _buildBusCard(context, bus);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String type) {
    final bool isSelected = _selectedBusType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBusType = type;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.secondary : AppColors.white70,
          ),
        ),
        child: Center(
          child: Text(
            type,
            style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Container _buildHeaderAndFilters(
    BuildContext context,
    String formattedDate,
    int busCount,
  ) {
    final List<String> filterOptions = ['All', ...busTypes];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF5A9DB6),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '${_cleanLocation(widget.pickup)} → ${_cleanLocation(widget.drop)}',
              style: AppTextStyles.h2.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              formattedDate,
              style: AppTextStyles.body.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '$busCount buses found',
            style: AppTextStyles.body.copyWith(color: AppColors.white70),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: filterOptions.length,
              itemBuilder: (context, index) {
                final type = filterOptions[index];
                return _buildFilterChip(type);
              },
            ),
          ),
        ],
      ),
    );
  }

  Container _buildBusCard(BuildContext context, Map<String, dynamic> bus) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                bus['image'],
                width: 80,
                height: 110,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 110,
                    color: Colors.grey[200],
                    child: const Icon(Icons.directions_bus, color: Colors.grey),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          bus['route'],
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Rs.${(bus['price'] as num).toStringAsFixed(2)}",
                        style: AppTextStyles.body.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    bus['type'],
                    style: AppTextStyles.body.copyWith(color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bus['busNo'],
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    bus['time'],
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        bus['seats'],
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SeatBookingScreen(
                                busNumber: bus['busNo'],
                                price: (bus['price'] as num).toDouble(),
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: const Text(
                          'Book Now',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
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
    );
  }

  String _getMonthName(int month) {
    const months = [
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
    return months[month - 1];
  }
}

// Clean up location strings for display (remove country name like 'Sri Lanka')
String _cleanLocation(String? loc) {
  if (loc == null) return '';
  var s = loc.trim();
  // Remove occurrences of ', Sri Lanka' or ' Sri Lanka' (case-insensitive)
  s = s.replaceAll(RegExp(r',?\s*Sri\s*Lanka', caseSensitive: false), '');
  // Trim again and return
  return s.trim();
}
