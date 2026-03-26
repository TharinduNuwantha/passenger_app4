// Models for Booking Orchestration (Intent → Payment → Confirm)
// Matches backend API response structure

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/// Safely parse a value that might be num, String, or null to double
double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

/// Safely parse a value that might be num, String, or null to int
int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

// ============================================================================
// ENUMS
// ============================================================================

/// Intent status enum matching backend
enum BookingIntentStatus {
  held,
  paymentPending,
  confirming,
  confirmed,
  expired,
  cancelled;

  String toJson() {
    switch (this) {
      case BookingIntentStatus.held:
        return 'held';
      case BookingIntentStatus.paymentPending:
        return 'payment_pending';
      case BookingIntentStatus.confirming:
        return 'confirming';
      case BookingIntentStatus.confirmed:
        return 'confirmed';
      case BookingIntentStatus.expired:
        return 'expired';
      case BookingIntentStatus.cancelled:
        return 'cancelled';
    }
  }

  static BookingIntentStatus fromJson(String? value) {
    switch (value) {
      case 'held':
        return BookingIntentStatus.held;
      case 'payment_pending':
        return BookingIntentStatus.paymentPending;
      case 'confirming':
        return BookingIntentStatus.confirming;
      case 'confirmed':
        return BookingIntentStatus.confirmed;
      case 'expired':
        return BookingIntentStatus.expired;
      case 'cancelled':
        return BookingIntentStatus.cancelled;
      default:
        return BookingIntentStatus.held;
    }
  }

  String get displayName {
    switch (this) {
      case BookingIntentStatus.held:
        return 'Seats Held';
      case BookingIntentStatus.paymentPending:
        return 'Payment Pending';
      case BookingIntentStatus.confirming:
        return 'Confirming';
      case BookingIntentStatus.confirmed:
        return 'Confirmed';
      case BookingIntentStatus.expired:
        return 'Expired';
      case BookingIntentStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isActive =>
      this == BookingIntentStatus.held ||
      this == BookingIntentStatus.paymentPending ||
      this == BookingIntentStatus.confirming;

  bool get isPending =>
      this == BookingIntentStatus.held ||
      this == BookingIntentStatus.paymentPending;
}

/// Intent type enum
enum IntentType {
  busOnly,
  loungeOnly,
  busWithLounge,
  busWithPreLounge,
  busWithPostLounge,
  busWithBothLounges;

  /// Convert to JSON for API request
  /// Backend only accepts: bus_only, lounge_only, combined
  String toJson() {
    switch (this) {
      case IntentType.busOnly:
        return 'bus_only';
      case IntentType.loungeOnly:
        return 'lounge_only';
      // All bus+lounge variants map to 'combined' for the API
      case IntentType.busWithLounge:
      case IntentType.busWithPreLounge:
      case IntentType.busWithPostLounge:
      case IntentType.busWithBothLounges:
        return 'combined';
    }
  }

  /// Parse from API response
  /// Backend returns: bus_only, lounge_only, combined
  static IntentType fromJson(String? value) {
    switch (value) {
      case 'bus_only':
        return IntentType.busOnly;
      case 'lounge_only':
        return IntentType.loungeOnly;
      case 'combined':
      case 'bus_with_lounge':
      case 'bus_with_pre_lounge':
      case 'bus_with_post_lounge':
      case 'bus_with_both_lounges':
        // Backend returns 'combined' - we'll use busWithLounge as generic
        return IntentType.busWithLounge;
      default:
        return IntentType.busOnly;
    }
  }

  String get displayName {
    switch (this) {
      case IntentType.busOnly:
        return 'Bus Only';
      case IntentType.loungeOnly:
        return 'Lounge Only';
      case IntentType.busWithLounge:
        return 'Bus + Lounge';
      case IntentType.busWithPreLounge:
        return 'Bus + Boarding Lounge';
      case IntentType.busWithPostLounge:
        return 'Bus + Destination Lounge';
      case IntentType.busWithBothLounges:
        return 'Bus + Both Lounges';
    }
  }
}

// ============================================================================
// REQUEST MODELS
// ============================================================================

/// Main request to create a booking intent
class CreateBookingIntentRequest {
  final IntentType intentType;
  final BusIntentRequest? bus;
  final LoungeIntentRequest? preTripLounge;
  final LoungeIntentRequest? postTripLounge;
  final String? idempotencyKey;

  CreateBookingIntentRequest({
    required this.intentType,
    this.bus,
    this.preTripLounge,
    this.postTripLounge,
    this.idempotencyKey,
  });

  Map<String, dynamic> toJson() {
    return {
      'intent_type': intentType.toJson(),
      if (bus != null) 'bus': bus!.toJson(),
      if (preTripLounge != null) 'pre_trip_lounge': preTripLounge!.toJson(),
      if (postTripLounge != null) 'post_trip_lounge': postTripLounge!.toJson(),
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
    };
  }

  /// Factory for bus-only intent
  factory CreateBookingIntentRequest.busOnly({
    required BusIntentRequest bus,
    String? idempotencyKey,
  }) {
    return CreateBookingIntentRequest(
      intentType: IntentType.busOnly,
      bus: bus,
      idempotencyKey: idempotencyKey,
    );
  }

  /// Factory for bus with lounge(s)
  factory CreateBookingIntentRequest.busWithLounge({
    required BusIntentRequest bus,
    LoungeIntentRequest? preTripLounge,
    LoungeIntentRequest? postTripLounge,
    String? idempotencyKey,
  }) {
    return CreateBookingIntentRequest(
      intentType: IntentType.busWithLounge,
      bus: bus,
      preTripLounge: preTripLounge,
      postTripLounge: postTripLounge,
      idempotencyKey: idempotencyKey,
    );
  }

  /// Factory for lounge-only intent
  factory CreateBookingIntentRequest.loungeOnly({
    LoungeIntentRequest? preTripLounge,
    LoungeIntentRequest? postTripLounge,
    String? idempotencyKey,
  }) {
    return CreateBookingIntentRequest(
      intentType: IntentType.loungeOnly,
      preTripLounge: preTripLounge,
      postTripLounge: postTripLounge,
      idempotencyKey: idempotencyKey,
    );
  }
}

/// Bus booking intent request
class BusIntentRequest {
  final String scheduledTripId;
  final String? boardingStopId;
  final String? boardingStopName;
  final String? alightingStopId;
  final String? alightingStopName;
  final List<IntentSeatRequest> seats;
  final String passengerName;
  final String passengerPhone;
  final String? passengerEmail;
  final String? specialRequests;

  BusIntentRequest({
    required this.scheduledTripId,
    this.boardingStopId,
    this.boardingStopName,
    this.alightingStopId,
    this.alightingStopName,
    required this.seats,
    required this.passengerName,
    required this.passengerPhone,
    this.passengerEmail,
    this.specialRequests,
  });

  Map<String, dynamic> toJson() {
    return {
      'scheduled_trip_id': scheduledTripId,
      if (boardingStopId != null) 'boarding_stop_id': boardingStopId,
      if (boardingStopName != null) 'boarding_stop_name': boardingStopName,
      if (alightingStopId != null) 'alighting_stop_id': alightingStopId,
      if (alightingStopName != null) 'alighting_stop_name': alightingStopName,
      'seats': seats.map((s) => s.toJson()).toList(),
      'passenger_name': passengerName,
      'passenger_phone': passengerPhone,
      if (passengerEmail != null) 'passenger_email': passengerEmail,
      if (specialRequests != null) 'special_requests': specialRequests,
    };
  }
}

/// Seat request within intent
class IntentSeatRequest {
  final String tripSeatId;
  final String passengerName;
  final String? passengerPhone;
  final String? passengerGender;
  final bool isPrimary;

  IntentSeatRequest({
    required this.tripSeatId,
    required this.passengerName,
    this.passengerPhone,
    this.passengerGender,
    this.isPrimary = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'trip_seat_id': tripSeatId,
      'passenger_name': passengerName,
      if (passengerPhone != null) 'passenger_phone': passengerPhone,
      if (passengerGender != null) 'passenger_gender': passengerGender,
      'is_primary': isPrimary,
    };
  }
}

/// Lounge booking intent request
class LoungeIntentRequest {
  final String loungeId;
  final String loungeName;
  final String? loungeAddress;
  final String pricingType; // '1_hour', '2_hours', '3_hours', 'until_bus'
  final String date; // 'YYYY-MM-DD'
  final String checkInTime; // 'HH:mm'
  final String? checkOutTime;
  final List<LoungeGuestRequest> guests;
  final List<PreOrderItem>? preOrders;

  // Pricing info
  final double pricePerGuest;
  final double basePrice;
  final double preOrderTotal;
  final double totalPrice;

  LoungeIntentRequest({
    required this.loungeId,
    required this.loungeName,
    this.loungeAddress,
    required this.pricingType,
    required this.date,
    required this.checkInTime,
    this.checkOutTime,
    required this.guests,
    this.preOrders,
    required this.pricePerGuest,
    required this.basePrice,
    this.preOrderTotal = 0.0,
    required this.totalPrice,
  });

  int get guestCount => guests.length;

  Map<String, dynamic> toJson() {
    return {
      'lounge_id': loungeId,
      'lounge_name': loungeName,
      if (loungeAddress != null) 'lounge_address': loungeAddress,
      'pricing_type': pricingType,
      'date': date,
      'check_in_time': checkInTime,
      if (checkOutTime != null) 'check_out_time': checkOutTime,
      'guest_count': guestCount,
      'guests': guests.map((g) => g.toJson()).toList(),
      if (preOrders != null && preOrders!.isNotEmpty)
        'pre_orders': preOrders!.map((p) => p.toJson()).toList(),
      'price_per_guest': pricePerGuest,
      'base_price': basePrice,
      'pre_order_total': preOrderTotal,
      'total_price': totalPrice,
    };
  }
}

/// Guest info for lounge intent
class LoungeGuestRequest {
  final String guestName;
  final String? guestPhone;
  final bool isPrimary;

  LoungeGuestRequest({
    required this.guestName,
    this.guestPhone,
    this.isPrimary = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'guest_name': guestName,
      if (guestPhone != null) 'guest_phone': guestPhone,
      'is_primary': isPrimary,
    };
  }
}

/// Pre-order item for lounge
class PreOrderItem {
  final String productId;
  final String productName;
  final String? productType;
  final String? imageUrl;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? notes;

  PreOrderItem({
    required this.productId,
    required this.productName,
    this.productType,
    this.imageUrl,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      if (productType != null) 'product_type': productType,
      if (imageUrl != null) 'image_url': imageUrl,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      if (notes != null) 'notes': notes,
    };
  }
}

/// Request to confirm booking after payment
class ConfirmIntentRequest {
  final String intentId;
  final String paymentReference;

  ConfirmIntentRequest({
    required this.intentId,
    required this.paymentReference,
  });

  Map<String, dynamic> toJson() {
    return {'intent_id': intentId, 'payment_reference': paymentReference};
  }
}

// ============================================================================
// RESPONSE MODELS
// ============================================================================

/// Response after creating an intent
class BookingIntentResponse {
  final String intentId;
  final BookingIntentStatus status;
  final DateTime expiresAt;
  final IntentPricing pricing;
  final BusIntentSummary? bus;
  final LoungeIntentSummary? preTripLounge;
  final LoungeIntentSummary? postTripLounge;

  BookingIntentResponse({
    required this.intentId,
    required this.status,
    required this.expiresAt,
    required this.pricing,
    this.bus,
    this.preTripLounge,
    this.postTripLounge,
  });

  factory BookingIntentResponse.fromJson(Map<String, dynamic> json) {
    // Backend uses 'price_breakdown', Flutter model uses 'pricing'
    final pricingData = json['price_breakdown'] ?? json['pricing'];
    return BookingIntentResponse(
      intentId: json['intent_id'] as String? ?? '',
      status: BookingIntentStatus.fromJson(json['status'] as String?),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : DateTime.now().add(const Duration(minutes: 10)),
      pricing: pricingData != null
          ? IntentPricing.fromJson(pricingData as Map<String, dynamic>)
          : IntentPricing.empty(),
      bus: json['bus'] != null
          ? BusIntentSummary.fromJson(json['bus'] as Map<String, dynamic>)
          : null,
      preTripLounge: json['pre_trip_lounge'] != null
          ? LoungeIntentSummary.fromJson(
              json['pre_trip_lounge'] as Map<String, dynamic>,
            )
          : null,
      postTripLounge: json['post_trip_lounge'] != null
          ? LoungeIntentSummary.fromJson(
              json['post_trip_lounge'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  /// Calculate remaining time until expiry
  Duration get remainingTime {
    // expiresAt is in UTC, so compare with UTC now
    final now = DateTime.now().toUtc();
    if (expiresAt.isBefore(now)) return Duration.zero;
    return expiresAt.difference(now);
  }

  /// Check if intent is expired
  bool get isExpired => remainingTime == Duration.zero;

  /// Formatted remaining time (MM:SS)
  String get formattedRemainingTime {
    final remaining = remainingTime;
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Pricing breakdown for intent
class IntentPricing {
  final double busFare;
  final double preLoungeFare;
  final double postLoungeFare;
  final double totalAmount;
  final String currency;

  IntentPricing({
    required this.busFare,
    required this.preLoungeFare,
    required this.postLoungeFare,
    required this.totalAmount,
    required this.currency,
  });

  factory IntentPricing.fromJson(Map<String, dynamic> json) {
    // Use safe parser for all numeric values (may be string or num)
    return IntentPricing(
      busFare: _parseDouble(json['bus_fare']),
      preLoungeFare: _parseDouble(json['pre_lounge_fare']),
      postLoungeFare: _parseDouble(json['post_lounge_fare']),
      // Backend uses 'total', Flutter model uses 'totalAmount'
      totalAmount: _parseDouble(json['total'] ?? json['total_amount']),
      currency: json['currency'] as String? ?? 'LKR',
    );
  }

  /// Empty pricing for fallback
  factory IntentPricing.empty() {
    return IntentPricing(
      busFare: 0.0,
      preLoungeFare: 0.0,
      postLoungeFare: 0.0,
      totalAmount: 0.0,
      currency: 'LKR',
    );
  }

  String get formattedTotal => '$currency ${totalAmount.toStringAsFixed(2)}';
  String get formattedBusFare => '$currency ${busFare.toStringAsFixed(2)}';
}

/// Bus intent summary in response
class BusIntentSummary {
  final String scheduledTripId;
  final String? routeName;
  final DateTime? departureDatetime;
  final String? boardingStop;
  final String? alightingStop;
  final int seatCount;
  final List<IntentSeatSummary> seats;

  BusIntentSummary({
    required this.scheduledTripId,
    this.routeName,
    this.departureDatetime,
    this.boardingStop,
    this.alightingStop,
    required this.seatCount,
    required this.seats,
  });

  factory BusIntentSummary.fromJson(Map<String, dynamic> json) {
    return BusIntentSummary(
      scheduledTripId: json['scheduled_trip_id'] as String? ?? '',
      routeName: json['route_name'] as String?,
      departureDatetime: json['departure_datetime'] != null
          ? DateTime.parse(json['departure_datetime'] as String)
          : null,
      boardingStop: json['boarding_stop'] as String?,
      alightingStop: json['alighting_stop'] as String?,
      seatCount: _parseInt(json['seat_count']),
      seats:
          (json['seats'] as List<dynamic>?)
              ?.map(
                (e) => IntentSeatSummary.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  String get seatNumbers => seats.map((s) => s.seatNumber).join(', ');
}

/// Seat summary in intent response
class IntentSeatSummary {
  final String seatNumber;
  final String seatType;
  final double seatPrice;

  IntentSeatSummary({
    required this.seatNumber,
    required this.seatType,
    required this.seatPrice,
  });

  factory IntentSeatSummary.fromJson(Map<String, dynamic> json) {
    return IntentSeatSummary(
      seatNumber: json['seat_number'] as String? ?? '',
      seatType: json['seat_type'] as String? ?? 'regular',
      seatPrice: _parseDouble(json['seat_price']),
    );
  }
}

/// Lounge intent summary in response
class LoungeIntentSummary {
  final String loungeId;
  final String? loungeName;
  final int guestCount;
  final double basePrice;
  final double preOrderTotal;
  final double totalPrice;

  LoungeIntentSummary({
    required this.loungeId,
    this.loungeName,
    required this.guestCount,
    required this.basePrice,
    required this.preOrderTotal,
    required this.totalPrice,
  });

  factory LoungeIntentSummary.fromJson(Map<String, dynamic> json) {
    return LoungeIntentSummary(
      loungeId: json['lounge_id'] as String? ?? '',
      loungeName: json['lounge_name'] as String?,
      guestCount: _parseInt(json['guest_count']),
      basePrice: _parseDouble(json['base_price']),
      preOrderTotal: _parseDouble(json['pre_order_total']),
      totalPrice: _parseDouble(json['total_price']),
    );
  }
}

/// Response for initiate payment
class InitiatePaymentResponse {
  final String intentId;
  final String paymentReference;
  final String paymentGateway;
  final String? paymentUrl;
  final double amount;
  final String currency;
  final DateTime expiresAt;
  final String? uid; // PAYable unique transaction ID
  final String? statusIndicator; // PAYable status check token

  InitiatePaymentResponse({
    required this.intentId,
    required this.paymentReference,
    required this.paymentGateway,
    this.paymentUrl,
    required this.amount,
    required this.currency,
    required this.expiresAt,
    this.uid,
    this.statusIndicator,
  });

  factory InitiatePaymentResponse.fromJson(Map<String, dynamic> json) {
    // Handle amount which may be string or num from backend
    double parsedAmount = 0.0;
    final amountValue = json['amount'];
    if (amountValue is num) {
      parsedAmount = amountValue.toDouble();
    } else if (amountValue is String) {
      parsedAmount = double.tryParse(amountValue) ?? 0.0;
    }

    return InitiatePaymentResponse(
      // Backend may return 'intent_id' or it may not be present
      intentId: json['intent_id'] as String? ?? '',
      // Backend uses 'invoice_id', Flutter uses 'paymentReference'
      paymentReference:
          json['payment_reference'] as String? ??
          json['invoice_id'] as String? ??
          '',
      paymentGateway: json['payment_gateway'] as String? ?? 'PAYable',
      paymentUrl: json['payment_url'] as String?,
      amount: parsedAmount,
      currency: json['currency'] as String? ?? 'LKR',
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : DateTime.now().add(const Duration(minutes: 10)),
      uid: json['uid'] as String?,
      statusIndicator: json['status_indicator'] as String?,
    );
  }

  String get formattedAmount => '$currency ${amount.toStringAsFixed(2)}';
}

/// Response for intent status
class IntentStatusResponse {
  final String intentId;
  final BookingIntentStatus status;
  final DateTime expiresAt;
  final int timeRemainingSeconds;
  final IntentPricing pricing;
  final ConfirmedBookingInfo? busBooking;
  final ConfirmedBookingInfo? preLoungeBooking;
  final ConfirmedBookingInfo? postLoungeBooking;

  IntentStatusResponse({
    required this.intentId,
    required this.status,
    required this.expiresAt,
    required this.timeRemainingSeconds,
    required this.pricing,
    this.busBooking,
    this.preLoungeBooking,
    this.postLoungeBooking,
  });

  factory IntentStatusResponse.fromJson(Map<String, dynamic> json) {
    // Backend uses 'price_breakdown', Flutter model uses 'pricing'
    final pricingData = json['price_breakdown'] ?? json['pricing'];
    // Backend uses 'ttl_seconds', model uses 'time_remaining_seconds'
    final ttl = _parseInt(
      json['ttl_seconds'] ?? json['time_remaining_seconds'],
    );
    return IntentStatusResponse(
      intentId: json['intent_id'] as String? ?? '',
      status: BookingIntentStatus.fromJson(json['status'] as String?),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : DateTime.now().add(const Duration(minutes: 10)),
      timeRemainingSeconds: ttl,
      pricing: pricingData != null
          ? IntentPricing.fromJson(pricingData as Map<String, dynamic>)
          : IntentPricing.empty(),
      busBooking: json['bus_booking'] != null
          ? ConfirmedBookingInfo.fromJson(
              json['bus_booking'] as Map<String, dynamic>,
            )
          : null,
      preLoungeBooking: json['pre_lounge_booking'] != null
          ? ConfirmedBookingInfo.fromJson(
              json['pre_lounge_booking'] as Map<String, dynamic>,
            )
          : null,
      postLoungeBooking: json['post_lounge_booking'] != null
          ? ConfirmedBookingInfo.fromJson(
              json['post_lounge_booking'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Duration get remainingTime => Duration(seconds: timeRemainingSeconds);

  int get remainingSeconds => timeRemainingSeconds;

  bool get isExpired => timeRemainingSeconds <= 0;

  String get formattedRemainingTime {
    final minutes = remainingTime.inMinutes;
    final seconds = remainingTime.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Confirmed booking info in response
class ConfirmedBookingInfo {
  final String id;
  final String reference;
  final String? qrCode;
  final double totalAmount;

  ConfirmedBookingInfo({
    required this.id,
    required this.reference,
    this.qrCode,
    this.totalAmount = 0.0,
  });

  factory ConfirmedBookingInfo.fromJson(Map<String, dynamic> json) {
    return ConfirmedBookingInfo(
      id: json['id'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
      qrCode: json['qr_code'] as String?,
      totalAmount: _parseDouble(json['total_amount']),
    );
  }
}

/// Response after confirming booking
class ConfirmBookingResponse {
  final String message;
  final String intentId;
  final String masterReference;
  final double totalPaid;
  final String currency;
  final ConfirmedBookingInfo? busBooking;
  final ConfirmedBookingInfo? preLoungeBooking;
  final ConfirmedBookingInfo? postLoungeBooking;

  ConfirmBookingResponse({
    required this.message,
    required this.intentId,
    required this.masterReference,
    this.totalPaid = 0.0,
    this.currency = 'LKR',
    this.busBooking,
    this.preLoungeBooking,
    this.postLoungeBooking,
  });

  factory ConfirmBookingResponse.fromJson(Map<String, dynamic> json) {
    return ConfirmBookingResponse(
      message: json['message'] as String? ?? 'Booking confirmed',
      intentId: json['intent_id'] as String? ?? '',
      masterReference: json['master_reference'] as String? ?? '',
      totalPaid: _parseDouble(json['total_paid']),
      currency: json['currency'] as String? ?? 'LKR',
      busBooking: json['bus_booking'] != null
          ? ConfirmedBookingInfo.fromJson(
              json['bus_booking'] as Map<String, dynamic>,
            )
          : null,
      preLoungeBooking: json['pre_lounge_booking'] != null
          ? ConfirmedBookingInfo.fromJson(
              json['pre_lounge_booking'] as Map<String, dynamic>,
            )
          : null,
      postLoungeBooking: json['post_lounge_booking'] != null
          ? ConfirmedBookingInfo.fromJson(
              json['post_lounge_booking'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  /// Get the effective total amount (from busBooking or root level)
  double get effectiveTotalAmount {
    // Try busBooking.totalAmount first, fallback to root totalPaid
    if (busBooking != null && busBooking!.totalAmount > 0) {
      return busBooking!.totalAmount;
    }
    return totalPaid;
  }

  String get formattedTotal =>
      '$currency ${effectiveTotalAmount.toStringAsFixed(2)}';
}

// ============================================================================
// ERROR MODELS
// ============================================================================

/// Partial availability error
class PartialAvailabilityError {
  final String error;
  final String message;
  final AvailabilityStatus available;
  final UnavailableItems unavailable;

  PartialAvailabilityError({
    required this.error,
    required this.message,
    required this.available,
    required this.unavailable,
  });

  factory PartialAvailabilityError.fromJson(Map<String, dynamic> json) {
    return PartialAvailabilityError(
      error: json['error'] as String? ?? 'partial_availability',
      message: json['message'] as String? ?? 'Some items are unavailable',
      available: AvailabilityStatus.fromJson(
        json['available'] as Map<String, dynamic>?,
      ),
      unavailable: UnavailableItems.fromJson(
        json['unavailable'] as Map<String, dynamic>?,
      ),
    );
  }

  /// Get human-readable error message
  String get displayMessage {
    final parts = <String>[];
    if (unavailable.bus != null) {
      parts.add(unavailable.bus!.details ?? 'Some seats are unavailable');
    }
    if (unavailable.preLounge != null) {
      parts.add('Boarding lounge: ${unavailable.preLounge!.details}');
    }
    if (unavailable.postLounge != null) {
      parts.add('Destination lounge: ${unavailable.postLounge!.details}');
    }
    return parts.isNotEmpty ? parts.join('\n') : message;
  }
}

class AvailabilityStatus {
  final bool bus;
  final bool preLounge;
  final bool postLounge;

  AvailabilityStatus({
    this.bus = true,
    this.preLounge = true,
    this.postLounge = true,
  });

  factory AvailabilityStatus.fromJson(Map<String, dynamic>? json) {
    if (json == null) return AvailabilityStatus();
    return AvailabilityStatus(
      bus: json['bus'] as bool? ?? true,
      preLounge: json['pre_lounge'] as bool? ?? true,
      postLounge: json['post_lounge'] as bool? ?? true,
    );
  }
}

class UnavailableItems {
  final UnavailableReason? bus;
  final UnavailableReason? preLounge;
  final UnavailableReason? postLounge;

  UnavailableItems({this.bus, this.preLounge, this.postLounge});

  factory UnavailableItems.fromJson(Map<String, dynamic>? json) {
    if (json == null) return UnavailableItems();
    return UnavailableItems(
      bus: json['bus'] != null
          ? UnavailableReason.fromJson(json['bus'] as Map<String, dynamic>)
          : null,
      preLounge: json['pre_lounge'] != null
          ? UnavailableReason.fromJson(
              json['pre_lounge'] as Map<String, dynamic>,
            )
          : null,
      postLounge: json['post_lounge'] != null
          ? UnavailableReason.fromJson(
              json['post_lounge'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class UnavailableReason {
  final String reason;
  final String? details;
  final List<String>? takenSeats;

  UnavailableReason({required this.reason, this.details, this.takenSeats});

  factory UnavailableReason.fromJson(Map<String, dynamic> json) {
    return UnavailableReason(
      reason: json['reason'] as String? ?? 'unavailable',
      details: json['details'] as String?,
      takenSeats: (json['taken_seats'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }
}
