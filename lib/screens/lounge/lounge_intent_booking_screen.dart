import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import '../../models/booking_intent_models.dart';
import '../../models/lounge_booking_models.dart';
import '../../models/user_model.dart';
import '../../providers/booking_intent_provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../payment/payment_webview_screen.dart';
import '../bus_booking/booking_intent_flow_screen.dart' show PaymentResult;
import 'lounge_intent_success_screen.dart';

/// Lounge-only booking using Intent → Payment → Confirm flow
class LoungeIntentBookingScreen extends StatefulWidget {
  final Lounge lounge;
  final List<LoungeProduct> products;

  const LoungeIntentBookingScreen({
    super.key,
    required this.lounge,
    this.products = const [],
  });

  @override
  State<LoungeIntentBookingScreen> createState() =>
      _LoungeIntentBookingScreenState();
}

class _LoungeIntentBookingScreenState
    extends State<LoungeIntentBookingScreen> {
  final Logger _logger = Logger();
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  // Booking details
  LoungePricingType? _selectedPricingType;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  final List<LoungeGuestEntry> _guests = [];
  final Map<String, CartItem> _cart = {};
  int _currentStep = 0;

  // State
  bool _isLoading = false;
  bool _isCreatingIntent = false;
  bool _intentCreated = false;
  UserModel? _currentUser;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null && mounted) {
        setState(() {
          _currentUser = user;
          _nameController.text = user.name;
          _phoneController.text = user.phoneNumber;
          _emailController.text = user.email ?? '';
        });
      }
    } catch (e) {
      _logger.e('Error loading user data: $e');
    }
  }

  void _addGuest() {
    setState(() {
      _guests.add(LoungeGuestEntry(
        nameController: TextEditingController(),
        phoneController: TextEditingController(),
      ));
    });
  }

  void _removeGuest(int index) {
    setState(() {
      _guests[index].nameController.dispose();
      _guests[index].phoneController.dispose();
      _guests.removeAt(index);
    });
  }

  void _updateCart(LoungeProduct product, int quantity) {
    setState(() {
      if (quantity > 0) {
        _cart[product.id] = CartItem(product: product, quantity: quantity);
      } else {
        _cart.remove(product.id);
      }
    });
  }

  double get _preOrderTotal {
    return _cart.values
        .fold(0.0, (sum, item) => sum + (item.product.price * item.quantity));
  }

  double get _basePrice {
    if (_selectedPricingType == null) return 0.0;
    final pricePerGuest = _getPriceForType(_selectedPricingType!);
    final totalGuests = _guests.length + 1; // +1 for primary guest
    return pricePerGuest * totalGuests;
  }

  double get _totalAmount {
    return _basePrice + _preOrderTotal;
  }

  double _getPriceForType(LoungePricingType type) {
    switch (type) {
      case LoungePricingType.oneHour:
        return widget.lounge.price1Hour ?? 0.0;
      case LoungePricingType.twoHours:
        return widget.lounge.price2Hours ?? 0.0;
      case LoungePricingType.threeHours:
        return widget.lounge.price3Hours ?? 0.0;
      case LoungePricingType.untilBus:
        return widget.lounge.priceUntilBus ?? 0.0;
    }
  }

  Future<void> _createLoungeIntent() async {
    // Validate form
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPricingType == null) {
      _showErrorSnackBar('Please select a pricing option');
      return;
    }

    // Check authentication
    final isAuthenticated = await _authService.isAuthenticated();
    if (!isAuthenticated) {
      if (!mounted) return;
      _showErrorSnackBar('Session expired. Please login again.');
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      return;
    }

    setState(() => _isCreatingIntent = true);

    try {
      final provider = context.read<BookingIntentProvider>();

      // Combine date and time
      final checkInDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Build guest list
      final guestRequests = [
        LoungeGuestRequest(
          guestName: _nameController.text.trim(),
          guestPhone: _phoneController.text.trim(),
          isPrimary: true,
        ),
        ..._guests.map((g) => LoungeGuestRequest(
              guestName: g.nameController.text.trim(),
              guestPhone: g.phoneController.text.trim().isNotEmpty
                  ? g.phoneController.text.trim()
                  : null,
            ))
      ];

      // Build pre-orders
      final preOrders = _cart.isNotEmpty
          ? _cart.values.map((item) {
              return PreOrderItem(
                productId: item.product.id,
                productName: item.product.name,
                quantity: item.quantity,
                unitPrice: item.product.price,
                totalPrice: item.product.price * item.quantity,
              );
            }).toList()
          : null;

      // Create lounge intent request
      final loungeIntent = LoungeIntentRequest(
        loungeId: widget.lounge.id,
        loungeName: widget.lounge.loungeName,
        loungeAddress: widget.lounge.address,
        pricingType: _selectedPricingType!.toJson(),
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        checkInTime: '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
        guests: guestRequests,
        preOrders: preOrders,
        pricePerGuest: _getPriceForType(_selectedPricingType!),
        basePrice: _basePrice,
        preOrderTotal: _preOrderTotal,
        totalPrice: _totalAmount,
      );

      // Create lounge-only intent
      _logger.i('Creating lounge-only intent');
      final success = await provider.createLoungeOnlyIntent(
        loungeIntent: loungeIntent,
      );

      if (success) {
        setState(() {
          _intentCreated = true;
          _isCreatingIntent = false;
        });
        _logger.i('Lounge intent created: ${provider.currentIntent?.intentId}');
      } else {
        _showErrorSnackBar(provider.errorMessage ?? 'Failed to create intent');
        setState(() => _isCreatingIntent = false);
      }
    } catch (e) {
      _logger.e('Error creating lounge intent: $e');
      setState(() => _isCreatingIntent = false);
      _showErrorSnackBar('Failed to create intent: $e');
    }
  }

  Future<void> _proceedToPayment() async {
    final provider = context.read<BookingIntentProvider>();

    setState(() => _isLoading = true);

    try {
      // Initiate payment
      final success = await provider.initiatePayment();

      if (success && provider.paymentInfo?.paymentUrl != null) {
        if (!mounted) return;

        // Navigate to payment webview
        final paymentResult = await Navigator.push<PaymentResult>(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentWebViewScreen(
              paymentUrl: provider.paymentInfo!.paymentUrl!,
              paymentReference: provider.paymentInfo!.paymentReference,
              amount: provider.paymentInfo!.amount,
              intentId: provider.currentIntent!.intentId,
            ),
          ),
        );

        if (paymentResult != null && paymentResult.success) {
          // Confirm booking with payment reference
          final confirmed = await provider.confirmBooking(
            paymentResult.paymentReference,
          );

          if (confirmed && provider.confirmedBooking != null) {
            if (!mounted) return;
            // Navigate to success screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => LoungeIntentSuccessScreen(
                  bookingResponse: provider.confirmedBooking!,
                ),
              ),
            );
          } else {
            _showErrorSnackBar('Failed to confirm booking');
          }
        }
      } else {
        _showErrorSnackBar(provider.errorMessage ?? 'Failed to initiate payment');
      }
    } catch (e) {
      _logger.e('Error in payment flow: $e');
      _showErrorSnackBar('Payment failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
    return Consumer<BookingIntentProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Book ${widget.lounge.loungeName}'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          body: _isCreatingIntent
              ? const Center(child: CircularProgressIndicator())
              : _intentCreated
                  ? _buildIntentCreatedView(provider)
                  : _buildBookingForm(),
        );
      },
    );
  }

  Widget _buildBookingForm() {
    return Stepper(
      currentStep: _currentStep,
      onStepContinue: _onStepContinue,
      onStepCancel: _onStepCancel,
      controlsBuilder: (context, details) {
        return Row(
          children: [
            ElevatedButton(
              onPressed: details.onStepContinue,
              child: Text(_currentStep == 3 ? 'Create Booking' : 'Continue'),
            ),
            if (_currentStep > 0) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: details.onStepCancel,
                child: const Text('Back'),
              ),
            ],
          ],
        );
      },
      steps: [
        Step(
          title: const Text('Select Pricing'),
          content: _buildPricingStep(),
          isActive: _currentStep >= 0,
        ),
        Step(
          title: const Text('Date & Time'),
          content: _buildDateTimeStep(),
          isActive: _currentStep >= 1,
        ),
        Step(
          title: const Text('Guest Details'),
          content: _buildGuestDetailsStep(),
          isActive: _currentStep >= 2,
        ),
        Step(
          title: const Text('Pre-Orders (Optional)'),
          content: _buildPreOrdersStep(),
          isActive: _currentStep >= 3,
        ),
      ],
    );
  }

  List<_PricingOption> _buildPricingOptions() {
    final options = <_PricingOption>[];
    
    if (widget.lounge.price1Hour != null) {
      options.add(_PricingOption(LoungePricingType.oneHour, widget.lounge.price1Hour!, '1 Hour'));
    }
    if (widget.lounge.price2Hours != null) {
      options.add(_PricingOption(LoungePricingType.twoHours, widget.lounge.price2Hours!, '2 Hours'));
    }
    if (widget.lounge.price3Hours != null) {
      options.add(_PricingOption(LoungePricingType.threeHours, widget.lounge.price3Hours!, '3 Hours'));
    }
    if (widget.lounge.priceUntilBus != null) {
      options.add(_PricingOption(LoungePricingType.untilBus, widget.lounge.priceUntilBus!, 'Until Bus Arrives'));
    }
    
    return options;
  }

  Widget _buildPricingStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select your lounge session duration:',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 16),
        ..._buildPricingOptions().map((option) {
          return RadioListTile<LoungePricingType>(
            title: Text(option.displayName),
            subtitle: Text('LKR ${option.price.toStringAsFixed(2)} per guest'),
            value: option.type,
            groupValue: _selectedPricingType,
            onChanged: (value) {
              setState(() => _selectedPricingType = value);
            },
          );
        }),
      ],
    );
  }

  Widget _buildDateTimeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: const Text('Date'),
          subtitle: Text(DateFormat('MMMM d, yyyy').format(_selectedDate)),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 90)),
            );
            if (date != null) {
              setState(() => _selectedDate = date);
            }
          },
        ),
        ListTile(
          title: const Text('Check-in Time'),
          subtitle: Text(_selectedTime.format(context)),
          trailing: const Icon(Icons.access_time),
          onTap: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: _selectedTime,
            );
            if (time != null) {
              setState(() => _selectedTime = time);
            }
          },
        ),
      ],
    );
  }

  Widget _buildGuestDetailsStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Primary Guest', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Please enter name' : null,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) =>
                value?.isEmpty ?? true ? 'Please enter phone' : null,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email (Optional)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Additional Guests (${_guests.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _addGuest,
                icon: const Icon(Icons.add),
                label: const Text('Add Guest'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._guests.asMap().entries.map((entry) {
            final index = entry.key;
            final guest = entry.value;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: guest.nameController,
                            decoration: InputDecoration(
                              labelText: 'Guest ${index + 2} Name',
                              border: const OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _removeGuest(index),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: guest.phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPreOrdersStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pre-order items for your lounge visit:',
            style: TextStyle(fontSize: 16)),
        const SizedBox(height: 16),
        if (widget.products.isEmpty)
          const Text('No products available for pre-order')
        else
          ...widget.products.map((product) {
            final cartItem = _cart[product.id];
            final quantity = cartItem?.quantity ?? 0;
            return Card(
              child: ListTile(
                title: Text(product.name),
                subtitle: Text('LKR ${product.price.toStringAsFixed(2)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: quantity > 0
                          ? () => _updateCart(product, quantity - 1)
                          : null,
                    ),
                    Text('$quantity'),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _updateCart(product, quantity + 1),
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 16),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Pre-order Total:'),
            Text('LKR ${_preOrderTotal.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildIntentCreatedView(BookingIntentProvider provider) {
    final intent = provider.currentIntent!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timer card
          Card(
            color: AppColors.primary.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.timer, size: 48, color: AppColors.primary),
                  const SizedBox(height: 8),
                  const Text(
                    'Lounge Reserved',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder(
                    stream: Stream.periodic(const Duration(seconds: 1)),
                    builder: (context, snapshot) {
                      final remaining = intent.expiresAt.difference(DateTime.now());
                      if (remaining.isNegative) {
                        return const Text(
                          'EXPIRED',
                          style: TextStyle(color: Colors.red, fontSize: 24),
                        );
                      }
                      final minutes = remaining.inMinutes;
                      final seconds = remaining.inSeconds % 60;
                      return Text(
                        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      );
                    },
                  ),
                  const Text('Complete payment to confirm booking'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Booking summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Booking Summary',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(),
                  _buildSummaryRow('Lounge', widget.lounge.loungeName),
                  _buildSummaryRow('Date', DateFormat('MMM d, yyyy').format(_selectedDate)),
                  _buildSummaryRow('Time', _selectedTime.format(context)),
                  _buildSummaryRow('Duration', _selectedPricingType!.displayName),
                  _buildSummaryRow('Guests', '${_guests.length + 1}'),
                  const Divider(),
                  _buildSummaryRow('Base Price', 'LKR ${_basePrice.toStringAsFixed(2)}'),
                  if (_preOrderTotal > 0)
                    _buildSummaryRow('Pre-Orders', 'LKR ${_preOrderTotal.toStringAsFixed(2)}'),
                  const Divider(),
                  _buildSummaryRow(
                    'Total Amount',
                    'LKR ${_totalAmount.toStringAsFixed(2)}',
                    isBold: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Payment button
          ElevatedButton(
            onPressed: _isLoading ? null : _proceedToPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.all(16),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Proceed to Payment',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: isBold ? const TextStyle(fontWeight: FontWeight.bold) : null),
          Text(value, style: isBold ? const TextStyle(fontWeight: FontWeight.bold) : null),
        ],
      ),
    );
  }

  void _onStepContinue() {
    if (_currentStep == 0 && _selectedPricingType == null) {
      _showErrorSnackBar('Please select a pricing option');
      return;
    }

    if (_currentStep == 2) {
      // Validate guest details before proceeding
      if (!_formKey.currentState!.validate()) {
        return;
      }
    }

    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      // Create intent
      _createLoungeIntent();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }
}

// Helper classes
class LoungeGuestEntry {
  final TextEditingController nameController;
  final TextEditingController phoneController;

  LoungeGuestEntry({
    required this.nameController,
    required this.phoneController,
  });
}

class CartItem {
  final LoungeProduct product;
  final int quantity;

  CartItem({required this.product, required this.quantity});
}

class _PricingOption {
  final LoungePricingType type;
  final double price;
  final String displayName;

  _PricingOption(this.type, this.price, this.displayName);
}
