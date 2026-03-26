import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class LoungeServiceDetailsScreen extends StatefulWidget {
  final String loungeName;
  final String location;
  final Map<String, dynamic>? loungeData;

  const LoungeServiceDetailsScreen({
    super.key,
    required this.loungeName,
    required this.location,
    this.loungeData,
  });

  @override
  State<LoungeServiceDetailsScreen> createState() =>
      _LoungeServiceDetailsScreenState();
}

class _LoungeServiceDetailsScreenState
    extends State<LoungeServiceDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Lounge Services & Updates',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Lounge Open Status Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B5E70), Color(0xFF2C7A8C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lounge Open',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Available until 10:30 PM',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.weekend,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Available Facilities Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Available Facilities',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  TextButton(onPressed: () {}, child: const Text('View All')),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // WiFi Access
            _buildFacilityCard(
              icon: Icons.wifi,
              iconColor: Colors.green,
              iconBgColor: Colors.green.shade50,
              title: 'WiFi Access',
              subtitle: 'Free high-speed internet',
              status: 'Active',
              statusColor: Colors.green,
              details: ['Network: Terminal_Lounge_5G', 'Password: ••••••••'],
            ),

            // Charging Stations
            _buildFacilityCard(
              icon: Icons.battery_charging_full,
              iconColor: Colors.blue,
              iconBgColor: Colors.blue.shade50,
              title: 'Charging Stations',
              subtitle: 'USB & wireless charging',
              status: '12 Available',
              statusColor: Colors.blue,
              details: [
                'USB-C: 18 ports',
                'Wireless: 12 pads',
                'AC Outlets: 6 available',
              ],
              showCount: true,
              counts: {'USB-C': 18, 'Wireless': 12, 'AC': 6},
            ),

            // Rest Area
            _buildFacilityCard(
              icon: Icons.airline_seat_recline_extra,
              iconColor: Colors.cyan,
              iconBgColor: Colors.cyan.shade50,
              title: 'Rest Area',
              subtitle: 'Comfortable seating',
              status: 'Available',
              statusColor: Colors.cyan,
              details: ['Seats Available: 24', 'Recliners: 8', 'Occupied: 16'],
            ),

            // Washrooms
            _buildFacilityCard(
              icon: Icons.wc,
              iconColor: Colors.purple,
              iconBgColor: Colors.purple.shade50,
              title: 'Washrooms',
              subtitle: 'Clean facilities available',
              status: 'Open',
              statusColor: Colors.green,
              details: [],
            ),

            // Food Court
            _buildFacilityCard(
              icon: Icons.restaurant,
              iconColor: Colors.red,
              iconBgColor: Colors.red.shade50,
              title: 'Food Court',
              subtitle: 'Snacks & beverages',
              status: '',
              statusColor: Colors.grey,
              details: [],
            ),

            // Reading Area
            _buildFacilityCard(
              icon: Icons.menu_book,
              iconColor: Colors.blue,
              iconBgColor: Colors.blue.shade50,
              title: 'Reading Area',
              subtitle: 'Magazines & quiet zone',
              status: '',
              statusColor: Colors.grey,
              details: [],
            ),

            const SizedBox(height: 16),

            // Booking Duration Section
            if (widget.loungeData != null &&
                widget.loungeData!['duration'] != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.blue.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.schedule,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Booking Duration',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.loungeData!['duration'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Active',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Marketplace Items Section
            if (widget.loungeData != null &&
                widget.loungeData!['marketplaceItems'] != null &&
                (widget.loungeData!['marketplaceItems'] as List)
                    .isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your Marketplace Orders',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${(widget.loungeData!['marketplaceItems'] as List).length} items',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...((widget.loungeData!['marketplaceItems'] as List).map((item) {
                return _buildMarketplaceItemCard(
                  name: item['name'] ?? 'Unknown Item',
                  category: item['category'] ?? 'General',
                  quantity: item['quantity'] ?? 1,
                  price: (item['price'] ?? 0).toDouble(),
                );
              }).toList()),
              const SizedBox(height: 16),
            ],

            // Additional Services Section
            if (widget.loungeData != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Text(
                  'Additional Services',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Transport Service
              if (widget.loungeData!['transportService'] == true)
                _buildAdditionalServiceCard(
                  icon: Icons.directions_car,
                  iconColor: Colors.orange,
                  iconBgColor: Colors.orange.shade50,
                  title: 'Transport Service',
                  subtitle:
                      'Vehicle: ${_getVehicleName(widget.loungeData!['selectedTransportType'])}${widget.loungeData!['selectedTransportLocation'] != null ? ' • ${widget.loungeData!['selectedTransportLocation']}' : ''}',
                  status: 'Confirmed',
                  statusColor: Colors.green,
                ),

              // Premium Meals
              if (widget.loungeData!['premiumMeals'] == true)
                _buildAdditionalServiceCard(
                  icon: Icons.restaurant_menu,
                  iconColor: Colors.deepOrange,
                  iconBgColor: Colors.deepOrange.shade50,
                  title: 'Premium Meals',
                  subtitle: 'Exclusive dining experience',
                  status: 'Included',
                  statusColor: Colors.green,
                ),

              // Express Laundry
              if (widget.loungeData!['expressLaundry'] == true)
                _buildAdditionalServiceCard(
                  icon: Icons.local_laundry_service,
                  iconColor: Colors.cyan,
                  iconBgColor: Colors.cyan.shade50,
                  title: 'Express Laundry',
                  subtitle: 'Quick laundry service',
                  status: 'Available',
                  statusColor: Colors.green,
                ),

              // Cargo Storage
              if (widget.loungeData!['cargoStorageCount'] != null &&
                  widget.loungeData!['cargoStorageCount'] > 0)
                _buildAdditionalServiceCard(
                  icon: Icons.luggage,
                  iconColor: Colors.brown,
                  iconBgColor: Colors.brown.shade50,
                  title: 'Cargo Storage',
                  subtitle:
                      '${widget.loungeData!['cargoStorageCount']} item(s)',
                  status: 'Reserved',
                  statusColor: Colors.green,
                ),

              // Personal Assistant
              if (widget.loungeData!['personalAssistant'] == true)
                _buildAdditionalServiceCard(
                  icon: Icons.support_agent,
                  iconColor: Colors.teal,
                  iconBgColor: Colors.teal.shade50,
                  title: 'Personal Assistant',
                  subtitle: 'Dedicated assistance available',
                  status: 'Available',
                  statusColor: Colors.green,
                ),

              // Spa Services
              if (widget.loungeData!['spaServices'] == true)
                _buildAdditionalServiceCard(
                  icon: Icons.spa,
                  iconColor: Colors.pink,
                  iconBgColor: Colors.pink.shade50,
                  title: 'Spa Services',
                  subtitle: 'Relaxation and wellness',
                  status: 'Available',
                  statusColor: Colors.green,
                ),

              // Airport Transfer
              if (widget.loungeData!['airportTransfer'] == true)
                _buildAdditionalServiceCard(
                  icon: Icons.airport_shuttle,
                  iconColor: Colors.indigo,
                  iconBgColor: Colors.indigo.shade50,
                  title: 'Airport Transfer',
                  subtitle: 'Shuttle service to terminal',
                  status: 'Confirmed',
                  statusColor: Colors.green,
                ),

              // Meeting Room (from booking selection)
              if (widget.loungeData!['meetingRoom'] == true)
                _buildAdditionalServiceCard(
                  icon: Icons.meeting_room,
                  iconColor: Colors.purple,
                  iconBgColor: Colors.purple.shade50,
                  title: 'Meeting Room Access',
                  subtitle: 'Private space for business meetings',
                  status: 'Reserved',
                  statusColor: Colors.green,
                ),

              // Tuk Tuk Service (legacy support)
              if (widget.loungeData!['tukTukService'] == true)
                _buildAdditionalServiceCard(
                  icon: Icons.local_taxi,
                  iconColor: Colors.amber,
                  iconBgColor: Colors.amber.shade50,
                  title: 'Tuk Tuk Service',
                  subtitle: 'Local transport arranged',
                  status: 'Confirmed',
                  statusColor: Colors.green,
                ),

              // Food Service (legacy support)
              if (widget.loungeData!['foodService'] == true)
                _buildAdditionalServiceCard(
                  icon: Icons.restaurant_menu,
                  iconColor: Colors.red,
                  iconBgColor: Colors.red.shade50,
                  title: 'Food Service',
                  subtitle: 'Complimentary meals included',
                  status: 'Available',
                  statusColor: Colors.green,
                ),

              // Shower Service (legacy support)
              if (widget.loungeData!['showerService'] == true)
                _buildAdditionalServiceCard(
                  icon: Icons.shower,
                  iconColor: Colors.blue,
                  iconBgColor: Colors.blue.shade50,
                  title: 'Shower Facilities',
                  subtitle: 'Private shower available',
                  status: 'Available',
                  statusColor: Colors.green,
                ),

              const SizedBox(height: 16),
            ],

            // Announcements Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Announcements',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  TextButton(onPressed: () {}, child: const Text('View All')),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Announcements
            _buildAnnouncementCard(
              icon: Icons.warning_amber,
              iconColor: Colors.orange,
              title: 'Service Delay',
              time: '5 min ago',
              message:
                  'Bus to Terminal 5 will be delayed by 10 minutes due to traffic conditions. Next departure at 5:45 PM.',
            ),

            _buildAnnouncementCard(
              icon: Icons.local_offer,
              iconColor: Colors.green,
              title: 'Special Offer',
              time: '1 hour ago',
              message:
                  'Get 20% off on your next booking! Use code: LOUNGE20. Valid until end of month.',
            ),

            _buildAnnouncementCard(
              icon: Icons.build,
              iconColor: Colors.blue,
              title: 'Maintenance Notice',
              time: '3 hours ago',
              message:
                  'WiFi will be temporarily unavailable from 11 PM to 12 AM for system maintenance.',
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFacilityCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required String status,
    required Color statusColor,
    required List<String> details,
    bool showCount = false,
    Map<String, int>? counts,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              if (status.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
            ],
          ),
          if (showCount && counts != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: counts.entries.map((entry) {
                return Column(
                  children: [
                    Text(
                      '${entry.value}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.key,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
          if (details.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            ...details.map(
              (detail) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      detail,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String time,
    required String message,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketplaceItemCard({
    required String name,
    required String category,
    required int quantity,
    required double price,
  }) {
    IconData categoryIcon;
    Color categoryColor;

    switch (category.toLowerCase()) {
      case 'food':
      case 'beverages':
        categoryIcon = Icons.fastfood;
        categoryColor = Colors.orange;
        break;
      case 'snacks':
        categoryIcon = Icons.cookie;
        categoryColor = Colors.brown;
        break;
      case 'drinks':
        categoryIcon = Icons.local_drink;
        categoryColor = Colors.blue;
        break;
      default:
        categoryIcon = Icons.shopping_bag;
        categoryColor = Colors.purple;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(categoryIcon, color: categoryColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.clear, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      'Qty: $quantity',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'LKR ${price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 12,
                      color: Colors.green.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Ordered',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalServiceCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 14, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getVehicleName(dynamic transportType) {
    if (transportType == null) return 'Standard';
    switch (transportType.toString().toLowerCase()) {
      case 'car':
        return 'Car';
      case 'van':
        return 'Van';
      case 'tuktuk':
      case 'tuk tuk':
        return 'Tuk Tuk';
      default:
        return 'Standard';
    }
  }
}
