import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/lounge_booking_models.dart';
import '../../models/user_model.dart';
import '../../services/lounge_booking_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_style.dart';
import 'lounge_booking_confirmation_screen.dart';

/// Lounge booking screen when booking AFTER a bus trip is booked
/// Key differences from standalone booking:
/// - Date/Time is FIXED (from bus trip) - not editable
/// - Pre-trip: Uses bus departure time
/// - Post-trip: Uses bus arrival time
/// - Shows "times are negotiable" banner
class LoungeBookingWithBusScreen extends StatefulWidget {
  final Lounge lounge;
  final List<LoungeProduct> products;

  /// Bus booking ID for linking
  final String? busBookingId;

  /// Bus booking reference for display
  final String busBookingReference;

  /// Type: 'pre_trip' or 'post_trip'
  final String bookingType;

  /// Bus departure time (for pre_trip lounge booking)
  final DateTime busDepartureTime;

  /// Bus arrival time (for post_trip lounge booking)
  final DateTime busArrivalTime;

  /// Route name for display
  final String? routeName;

  /// Boarding stop name
  final String? boardingStopName;

  /// Alighting stop name
  final String? alightingStopName;

  const LoungeBookingWithBusScreen({
    super.key,
    required this.lounge,
    this.products = const [],
    this.busBookingId,
    required this.busBookingReference,
    required this.bookingType,
    required this.busDepartureTime,
    required this.busArrivalTime,
    this.routeName,
    this.boardingStopName,
    this.alightingStopName,
  });

  @override
  State<LoungeBookingWithBusScreen> createState() =>
      _LoungeBookingWithBusScreenState();
}

class _LoungeBookingWithBusScreenState
    extends State<LoungeBookingWithBusScreen> {
  final LoungeBookingService _loungeService = LoungeBookingService();
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  // Booking details
  LoungePricingType? _selectedPricingType;

  // FIXED date/time from bus trip - NOT editable
  late DateTime _fixedDateTime;

  // Guests
  final List<GuestEntry> _guests = [];
  final TextEditingController _guestNameController = TextEditingController();
  final TextEditingController _guestNicController = TextEditingController();

  // Pre-orders
  final Map<String, CartItem> _cart = {};

  // State
  bool _isLoading = false;
  int _currentStep = 0;
  UserModel? _currentUser;

  bool get _isPreTrip => widget.bookingType == 'pre_trip';

  double get _totalGuestPrice {
    if (_selectedPricingType == null) return 0;
    final guestCount = _guests.length + 1; // +1 for the main passenger
    return _getPriceForType(_selectedPricingType!) * guestCount;
  }

  double get _totalPreOrderPrice {
    return _cart.values.fold(
      0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );
  }

  double get _grandTotal => _totalGuestPrice + _totalPreOrderPrice;

  double _getPriceForType(LoungePricingType type) {
    switch (type) {
      case LoungePricingType.oneHour:
        return widget.lounge.price1Hour ?? 0;
      case LoungePricingType.twoHours:
        return widget.lounge.price2Hours ?? 0;
      case LoungePricingType.threeHours:
        return widget.lounge.price3Hours ?? 0;
      case LoungePricingType.untilBus:
        return widget.lounge.priceUntilBus ?? 0;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();

    // Set FIXED date/time based on booking type
    // Pre-trip: Bus departure time (passenger waits at lounge before bus leaves)
    // Post-trip: Bus arrival time (passenger uses lounge after arriving)
    _fixedDateTime = _isPreTrip
        ? widget.busDepartureTime
        : widget.busArrivalTime;
  }

  Future<void> _loadCurrentUser() async {
    final user = await _authService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  @override
  void dispose() {
    _guestNameController.dispose();
    _guestNicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isPreTrip ? 'Boarding Lounge' : 'Destination Lounge'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Bus trip info banner with FIXED time
          _buildBusTripBanner(),

          // Progress indicator (3 steps - no date/time step)
          _buildProgressIndicator(),

          // Content
          Expanded(
            child: Form(key: _formKey, child: _buildCurrentStep()),
          ),

          // Bottom buttons
          _buildBottomButtons(),
        ],
      ),
    );
  }

  /// Banner showing bus trip info and FIXED lounge time
  Widget _buildBusTripBanner() {
    final formattedDate = DateFormat('EEE, d MMM yyyy').format(_fixedDateTime);
    final formattedTime = DateFormat('h:mm a').format(_fixedDateTime);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isPreTrip ? Icons.weekend : Icons.hotel,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isPreTrip
                            ? 'Before Your Bus Departs'
                            : 'After Your Bus Arrives',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.lounge.loungeName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.confirmation_number_outlined,
                            color: Colors.white70,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Bus: ${widget.busBookingReference}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
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

          // Fixed date/time display (NOT editable)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            formattedTime,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFC300),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _isPreTrip ? 'DEPARTS' : 'ARRIVES',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // "Times are negotiable" banner
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC300).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFFFC300).withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: const Color(0xFFFFC300),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Don't worry about exact times - they're negotiable with the lounge!",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    // Only 3 steps (no date/time step - it's fixed)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.secondary.withOpacity(0.3),
      child: Row(
        children: [
          _buildStepIndicator(0, 'Duration'),
          _buildStepConnector(0),
          _buildStepIndicator(1, 'Guests'),
          _buildStepConnector(1),
          _buildStepIndicator(2, 'Pre-Order'),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? AppColors.primary : Colors.grey[300],
              border: isCurrent
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null,
            ),
            child: Center(
              child: isActive && !isCurrent
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : Text(
                      '${step + 1}',
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? AppColors.primary : Colors.grey[600],
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector(int step) {
    final isActive = _currentStep > step;
    return Container(
      height: 2,
      width: 30,
      color: isActive ? AppColors.primary : Colors.grey[300],
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildDurationStep();
      case 1:
        return _buildGuestsStep();
      case 2:
        return _buildPreOrderStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // Step 1: Duration Selection
  Widget _buildDurationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Duration',
            style: AppTextStyles.h2.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            _isPreTrip
                ? 'How long before your bus departs?'
                : 'How long after arriving at destination?',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // "Until Bus" is highlighted for pre-trip
          if (widget.lounge.priceUntilBus != null && _isPreTrip)
            _buildPricingOption(
              LoungePricingType.untilBus,
              'Until Bus Departs',
              Icons.directions_bus,
              widget.lounge.priceUntilBus!,
              isHighlighted: true,
              subtitle: 'Relax until your bus is ready to board',
            ),

          if (widget.lounge.price1Hour != null)
            _buildPricingOption(
              LoungePricingType.oneHour,
              '1 Hour',
              Icons.timer,
              widget.lounge.price1Hour!,
            ),
          if (widget.lounge.price2Hours != null)
            _buildPricingOption(
              LoungePricingType.twoHours,
              '2 Hours',
              Icons.timer,
              widget.lounge.price2Hours!,
            ),
          if (widget.lounge.price3Hours != null)
            _buildPricingOption(
              LoungePricingType.threeHours,
              '3 Hours',
              Icons.timer,
              widget.lounge.price3Hours!,
            ),

          // "Until Bus" for post-trip (less relevant but still available)
          if (widget.lounge.priceUntilBus != null && !_isPreTrip)
            _buildPricingOption(
              LoungePricingType.untilBus,
              'Flexible Duration',
              Icons.schedule,
              widget.lounge.priceUntilBus!,
              subtitle: 'Stay as long as you need',
            ),
        ],
      ),
    );
  }

  Widget _buildPricingOption(
    LoungePricingType type,
    String label,
    IconData icon,
    double price, {
    bool isHighlighted = false,
    String? subtitle,
  }) {
    final isSelected = _selectedPricingType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPricingType = type;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : isHighlighted
              ? const Color(0xFFFFC300).withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : isHighlighted
                ? const Color(0xFFFFC300)
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.2)
                    : isHighlighted
                    ? const Color(0xFFFFC300).withOpacity(0.2)
                    : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? AppColors.primary
                    : isHighlighted
                    ? Colors.amber[700]
                    : Colors.grey[600],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isSelected
                              ? AppColors.primary
                              : Colors.black87,
                        ),
                      ),
                      if (isHighlighted) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFC300),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Recommended',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'LKR ${price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isSelected ? AppColors.primary : Colors.black87,
                  ),
                ),
                Text(
                  'per person',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(Icons.check_circle, color: AppColors.primary),
              ),
          ],
        ),
      ),
    );
  }

  // Step 2: Guests
  Widget _buildGuestsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Additional Guests',
            style: AppTextStyles.h2.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            'Add companions to your lounge booking (optional)',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Existing guests
          if (_guests.isNotEmpty) ...[
            ...List.generate(_guests.length, (index) {
              final guest = _guests[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.secondary,
                      child: Text(
                        guest.guestName[0].toUpperCase(),
                        style: TextStyle(color: AppColors.primary),
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
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _guests.removeAt(index);
                        });
                      },
                      icon: const Icon(Icons.close, color: Colors.red),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
          ],

          // Add guest form
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add Guest',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _guestNameController,
                  decoration: InputDecoration(
                    labelText: 'Guest Name *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _guestNicController,
                  decoration: InputDecoration(
                    labelText: 'NIC/Passport (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.badge),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _addGuest,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Guest'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Pricing summary
          if (_selectedPricingType != null)
            Container(
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
                      const Text('You'),
                      Text(
                        'LKR ${_getPriceForType(_selectedPricingType!).toStringAsFixed(0)}',
                      ),
                    ],
                  ),
                  if (_guests.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${_guests.length} Guest(s)'),
                        Text(
                          'LKR ${(_getPriceForType(_selectedPricingType!) * _guests.length).toStringAsFixed(0)}',
                        ),
                      ],
                    ),
                  ],
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Lounge Total',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'LKR ${_totalGuestPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _addGuest() {
    if (_guestNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter guest name')));
      return;
    }

    setState(() {
      _guests.add(
        GuestEntry(
          guestName: _guestNameController.text.trim(),
          guestPhone: _guestNicController.text.trim().isNotEmpty
              ? _guestNicController.text.trim()
              : null,
        ),
      );
      _guestNameController.clear();
      _guestNicController.clear();
    });
  }

  // Step 3: Pre-order
  Widget _buildPreOrderStep() {
    final categories = <String, List<LoungeProduct>>{};
    for (final product in widget.products) {
      final category = product.categoryName ?? 'Other';
      categories.putIfAbsent(category, () => []).add(product);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pre-Order (Optional)',
            style: AppTextStyles.h2.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            'Have food & drinks ready when you arrive',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          if (widget.products.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No menu items available',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You can order when you arrive',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          else
            ...categories.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...entry.value.map((product) => _buildProductItem(product)),
                  const SizedBox(height: 16),
                ],
              );
            }),

          const SizedBox(height: 24),

          // Order summary
          if (_cart.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pre-Order Summary',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ..._cart.values.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text('${item.quantity}x'),
                          const SizedBox(width: 8),
                          Expanded(child: Text(item.product.name)),
                          Text(
                            'LKR ${(item.product.price * item.quantity).toStringAsFixed(0)}',
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pre-Order Total',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'LKR ${_totalPreOrderPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Grand total
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Lounge Access'),
                    Text('LKR ${_totalGuestPrice.toStringAsFixed(0)}'),
                  ],
                ),
                if (_totalPreOrderPrice > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Pre-Orders'),
                      Text('LKR ${_totalPreOrderPrice.toStringAsFixed(0)}'),
                    ],
                  ),
                ],
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'LKR ${_grandTotal.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(LoungeProduct product) {
    final cartItem = _cart[product.id];
    final quantity = cartItem?.quantity ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: product.imageUrl != null
                ? Image.network(
                    product.imageUrl!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _buildProductPlaceholder(product),
                  )
                : _buildProductPlaceholder(product),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (product.description != null)
                  Text(
                    product.description!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Text(
                  product.formattedPrice,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Quantity controls
          if (quantity == 0)
            IconButton(
              onPressed: product.isAvailable && !product.isOutOfStock
                  ? () => _updateCartItem(product, 1)
                  : null,
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: product.isAvailable && !product.isOutOfStock
                      ? AppColors.primary
                      : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            )
          else
            Row(
              children: [
                GestureDetector(
                  onTap: () => _updateCartItem(product, quantity - 1),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.remove, size: 16),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '$quantity',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _updateCartItem(product, quantity + 1),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildProductPlaceholder(LoungeProduct product) {
    return Container(
      width: 60,
      height: 60,
      color: Colors.grey[100],
      child: Icon(
        product.isService ? Icons.room_service : Icons.fastfood,
        color: Colors.grey[400],
      ),
    );
  }

  void _updateCartItem(LoungeProduct product, int quantity) {
    setState(() {
      if (quantity <= 0) {
        _cart.remove(product.id);
      } else {
        _cart[product.id] = CartItem(product: product, quantity: quantity);
      }
    });
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
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
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentStep--;
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC300),
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _currentStep == 2 ? 'Confirm Booking' : 'Next',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNext() {
    if (_currentStep == 0) {
      if (_selectedPricingType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a duration')),
        );
        return;
      }
    }

    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
    } else {
      _confirmBooking();
    }
  }

  Future<void> _confirmBooking() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare pre-orders
      final preOrders = _cart.values.map((item) {
        return PreOrderEntry(
          productId: item.product.id,
          quantity: item.quantity,
        );
      }).toList();

      // Get user info
      final userName = _currentUser?.name.isNotEmpty == true
          ? _currentUser!.name
          : 'Guest';
      final userPhone = _currentUser?.phoneNumber ?? '';

      // Create booking request with FIXED date/time from bus trip
      final request = CreateLoungeBookingRequest(
        loungeId: widget.lounge.id,
        bookingType: widget.bookingType, // 'pre_trip' or 'post_trip'
        pricingType: _selectedPricingType!,
        scheduledArrival: _fixedDateTime, // FIXED - from bus trip
        numberOfGuests: _guests.length + 1,
        primaryGuestName: userName,
        primaryGuestPhone: userPhone,
        busBookingId: widget.busBookingId,
        guests: _guests,
        preOrders: preOrders,
      );

      final booking = await _loungeService.createBooking(request);

      if (mounted) {
        // Navigate to confirmation screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoungeBookingConfirmationScreen(
              booking: booking,
              lounge: widget.lounge,
              busBookingReference: widget.busBookingReference,
              isLinkedToBus: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
