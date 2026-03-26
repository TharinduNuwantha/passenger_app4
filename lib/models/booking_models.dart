// Models for App Booking functionality
// Matches backend API response structure

// ============================================================================
// ENUMS / STATUS TYPES
// ============================================================================

enum BookingType {
  busOnly,
  loungeOnly,
  busWithLounge;

  String toJson() {
    switch (this) {
      case BookingType.busOnly:
        return 'bus_only';
      case BookingType.loungeOnly:
        return 'lounge_only';
      case BookingType.busWithLounge:
        return 'bus_with_lounge';
    }
  }

  static BookingType fromJson(String? value) {
    switch (value) {
      case 'bus_only':
        return BookingType.busOnly;
      case 'lounge_only':
        return BookingType.loungeOnly;
      case 'bus_with_lounge':
        return BookingType.busWithLounge;
      default:
        return BookingType.busOnly;
    }
  }
}

enum MasterPaymentStatus {
  pending,
  partial,
  paid,
  collectOnBus,
  free,
  failed,
  refunded,
  partialRefund;

  String toJson() {
    switch (this) {
      case MasterPaymentStatus.pending:
        return 'pending';
      case MasterPaymentStatus.partial:
        return 'partial';
      case MasterPaymentStatus.paid:
        return 'paid';
      case MasterPaymentStatus.collectOnBus:
        return 'collect_on_bus';
      case MasterPaymentStatus.free:
        return 'free';
      case MasterPaymentStatus.failed:
        return 'failed';
      case MasterPaymentStatus.refunded:
        return 'refunded';
      case MasterPaymentStatus.partialRefund:
        return 'partial_refund';
    }
  }

  static MasterPaymentStatus fromJson(String? value) {
    switch (value) {
      case 'pending':
        return MasterPaymentStatus.pending;
      case 'partial':
        return MasterPaymentStatus.partial;
      case 'paid':
        return MasterPaymentStatus.paid;
      case 'collect_on_bus':
        return MasterPaymentStatus.collectOnBus;
      case 'free':
        return MasterPaymentStatus.free;
      case 'failed':
        return MasterPaymentStatus.failed;
      case 'refunded':
        return MasterPaymentStatus.refunded;
      case 'partial_refund':
        return MasterPaymentStatus.partialRefund;
      default:
        return MasterPaymentStatus.pending;
    }
  }
}

enum MasterBookingStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
  partialCancel;

  String toJson() {
    switch (this) {
      case MasterBookingStatus.pending:
        return 'pending';
      case MasterBookingStatus.confirmed:
        return 'confirmed';
      case MasterBookingStatus.inProgress:
        return 'in_progress';
      case MasterBookingStatus.completed:
        return 'completed';
      case MasterBookingStatus.cancelled:
        return 'cancelled';
      case MasterBookingStatus.partialCancel:
        return 'partial_cancel';
    }
  }

  static MasterBookingStatus fromJson(String? value) {
    switch (value) {
      case 'pending':
        return MasterBookingStatus.pending;
      case 'confirmed':
        return MasterBookingStatus.confirmed;
      case 'in_progress':
        return MasterBookingStatus.inProgress;
      case 'completed':
        return MasterBookingStatus.completed;
      case 'cancelled':
        return MasterBookingStatus.cancelled;
      case 'partial_cancel':
        return MasterBookingStatus.partialCancel;
      default:
        return MasterBookingStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case MasterBookingStatus.pending:
        return 'Pending';
      case MasterBookingStatus.confirmed:
        return 'Confirmed';
      case MasterBookingStatus.inProgress:
        return 'In Progress';
      case MasterBookingStatus.completed:
        return 'Completed';
      case MasterBookingStatus.cancelled:
        return 'Cancelled';
      case MasterBookingStatus.partialCancel:
        return 'Partially Cancelled';
    }
  }
}

enum BusBookingStatus {
  pending,
  confirmed,
  checkedIn,
  boarded,
  inTransit,
  completed,
  cancelled,
  noShow;

  String toJson() {
    switch (this) {
      case BusBookingStatus.pending:
        return 'pending';
      case BusBookingStatus.confirmed:
        return 'confirmed';
      case BusBookingStatus.checkedIn:
        return 'checked_in';
      case BusBookingStatus.boarded:
        return 'boarded';
      case BusBookingStatus.inTransit:
        return 'in_transit';
      case BusBookingStatus.completed:
        return 'completed';
      case BusBookingStatus.cancelled:
        return 'cancelled';
      case BusBookingStatus.noShow:
        return 'no_show';
    }
  }

  static BusBookingStatus fromJson(String? value) {
    switch (value) {
      case 'pending':
        return BusBookingStatus.pending;
      case 'confirmed':
        return BusBookingStatus.confirmed;
      case 'checked_in':
        return BusBookingStatus.checkedIn;
      case 'boarded':
        return BusBookingStatus.boarded;
      case 'in_transit':
        return BusBookingStatus.inTransit;
      case 'completed':
        return BusBookingStatus.completed;
      case 'cancelled':
        return BusBookingStatus.cancelled;
      case 'no_show':
        return BusBookingStatus.noShow;
      default:
        return BusBookingStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case BusBookingStatus.pending:
        return 'Pending';
      case BusBookingStatus.confirmed:
        return 'Confirmed';
      case BusBookingStatus.checkedIn:
        return 'Checked In';
      case BusBookingStatus.boarded:
        return 'Boarded';
      case BusBookingStatus.inTransit:
        return 'In Transit';
      case BusBookingStatus.completed:
        return 'Completed';
      case BusBookingStatus.cancelled:
        return 'Cancelled';
      case BusBookingStatus.noShow:
        return 'No Show';
    }
  }
}

enum SeatBookingStatus {
  pending,
  booked,
  checkedIn,
  boarded,
  completed,
  cancelled,
  noShow;

  String toJson() {
    switch (this) {
      case SeatBookingStatus.pending:
        return 'pending';
      case SeatBookingStatus.booked:
        return 'booked';
      case SeatBookingStatus.checkedIn:
        return 'checked_in';
      case SeatBookingStatus.boarded:
        return 'boarded';
      case SeatBookingStatus.completed:
        return 'completed';
      case SeatBookingStatus.cancelled:
        return 'cancelled';
      case SeatBookingStatus.noShow:
        return 'no_show';
    }
  }

  static SeatBookingStatus fromJson(String? value) {
    switch (value) {
      case 'pending':
        return SeatBookingStatus.pending;
      case 'booked':
        return SeatBookingStatus.booked;
      case 'checked_in':
        return SeatBookingStatus.checkedIn;
      case 'boarded':
        return SeatBookingStatus.boarded;
      case 'completed':
        return SeatBookingStatus.completed;
      case 'cancelled':
        return SeatBookingStatus.cancelled;
      case 'no_show':
        return SeatBookingStatus.noShow;
      default:
        return SeatBookingStatus.pending;
    }
  }
}

// ============================================================================
// TRIP SEAT MODEL (for seat availability)
// ============================================================================

class TripSeat {
  final String id;
  final String scheduledTripId;
  final String? seatConfigId;
  final String seatNumber;
  final String seatType;
  final int seatRow;
  final int seatColumn;
  final String deckLevel;
  final double basePrice;
  final double currentPrice;
  final bool isAvailable;
  final bool isBooked;
  final bool isBlocked;
  final bool isSelected;
  final String? bookedByUserId;
  final String? bookingReference;
  final DateTime? bookedAt;
  final DateTime? reservedUntil;
  final DateTime createdAt;
  final DateTime updatedAt;

  TripSeat({
    required this.id,
    required this.scheduledTripId,
    this.seatConfigId,
    required this.seatNumber,
    required this.seatType,
    required this.seatRow,
    required this.seatColumn,
    required this.deckLevel,
    required this.basePrice,
    required this.currentPrice,
    required this.isAvailable,
    required this.isBooked,
    required this.isBlocked,
    required this.isSelected,
    this.bookedByUserId,
    this.bookingReference,
    this.bookedAt,
    this.reservedUntil,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TripSeat.fromJson(Map<String, dynamic> json) {
    // Handle status -> isAvailable, isBooked, isBlocked
    final status = json['status'] as String? ?? 'available';
    final isAvailable = status == 'available';
    final isBooked = status == 'booked';
    final isBlocked = status == 'blocked';

    return TripSeat(
      id: json['id'] as String,
      scheduledTripId: json['scheduled_trip_id'] as String,
      seatConfigId: json['seat_config_id'] as String?,
      seatNumber: json['seat_number'] as String,
      seatType: json['seat_type'] as String? ?? 'regular',
      // Handle both API field names: row_number/seat_row and position/seat_column
      seatRow: json['row_number'] as int? ?? json['seat_row'] as int? ?? 1,
      seatColumn: json['position'] as int? ?? json['seat_column'] as int? ?? 1,
      deckLevel: json['deck_level'] as String? ?? 'lower',
      // Handle seat_price vs base_price/current_price
      basePrice:
          (json['base_price'] as num?)?.toDouble() ??
          (json['seat_price'] as num?)?.toDouble() ??
          0.0,
      currentPrice:
          (json['current_price'] as num?)?.toDouble() ??
          (json['seat_price'] as num?)?.toDouble() ??
          0.0,
      isAvailable: isAvailable,
      isBooked: isBooked,
      isBlocked: isBlocked,
      isSelected: json['is_selected'] as bool? ?? false,
      bookedByUserId: json['booked_by_user_id'] as String?,
      bookingReference: json['booking_reference'] as String?,
      bookedAt: json['booked_at'] != null
          ? DateTime.parse(json['booked_at'] as String)
          : null,
      reservedUntil: json['reserved_until'] != null
          ? DateTime.parse(json['reserved_until'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Checks if seat can be selected for booking
  bool get canBeSelected => isAvailable && !isBooked && !isBlocked;

  /// Display formatted price
  String get formattedPrice => 'LKR ${currentPrice.toStringAsFixed(2)}';
}

// ============================================================================
// MASTER BOOKING MODEL
// ============================================================================

class MasterBooking {
  final String id;
  final String bookingReference;
  final String userId;
  final BookingType bookingType;

  // Totals
  final double busTotal;
  final double loungeTotal;
  final double preOrderTotal;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;

  // Promo
  final String? promoCode;
  final String? promoDiscountType;
  final double promoDiscountValue;

  // Payment
  final MasterPaymentStatus paymentStatus;
  final String? paymentMethod;
  final String? paymentReference;
  final String? paymentGateway;
  final DateTime? paidAt;

  // Status
  final MasterBookingStatus bookingStatus;

  // Contact
  final String passengerName;
  final String passengerPhone;
  final String? passengerEmail;

  // Timestamps
  final DateTime? confirmedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final String? cancelledByUserId;
  final DateTime? completedAt;

  // Refund
  final double refundAmount;
  final String? refundReference;
  final DateTime? refundedAt;

  // Metadata
  final String bookingSource;
  final Map<String, dynamic>? deviceInfo;
  final String? notes;

  final DateTime createdAt;
  final DateTime updatedAt;

  // Related
  final BusBooking? busBooking;

  var totalPrice;

  MasterBooking({
    required this.id,
    required this.bookingReference,
    required this.userId,
    required this.bookingType,
    required this.busTotal,
    required this.loungeTotal,
    required this.preOrderTotal,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.totalAmount,
    this.promoCode,
    this.promoDiscountType,
    required this.promoDiscountValue,
    required this.paymentStatus,
    this.paymentMethod,
    this.paymentReference,
    this.paymentGateway,
    this.paidAt,
    required this.bookingStatus,
    required this.passengerName,
    required this.passengerPhone,
    this.passengerEmail,
    this.confirmedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.cancelledByUserId,
    this.completedAt,
    required this.refundAmount,
    this.refundReference,
    this.refundedAt,
    required this.bookingSource,
    this.deviceInfo,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.busBooking,
  });

  factory MasterBooking.fromJson(Map<String, dynamic> json) {
    return MasterBooking(
      id: json['id'] as String? ?? '',
      bookingReference: json['booking_reference'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      bookingType: BookingType.fromJson(json['booking_type'] as String?),
      busTotal: (json['bus_total'] as num?)?.toDouble() ?? 0.0,
      loungeTotal: (json['lounge_total'] as num?)?.toDouble() ?? 0.0,
      preOrderTotal: (json['pre_order_total'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      promoCode: json['promo_code'] as String?,
      promoDiscountType: json['promo_discount_type'] as String?,
      promoDiscountValue:
          (json['promo_discount_value'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: MasterPaymentStatus.fromJson(
        json['payment_status'] as String?,
      ),
      paymentMethod: json['payment_method'] as String?,
      paymentReference: json['payment_reference'] as String?,
      paymentGateway: json['payment_gateway'] as String?,
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
      bookingStatus: MasterBookingStatus.fromJson(
        json['booking_status'] as String?,
      ),
      passengerName: json['passenger_name'] as String? ?? '',
      passengerPhone: json['passenger_phone'] as String? ?? '',
      passengerEmail: json['passenger_email'] as String?,
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.parse(json['confirmed_at'] as String)
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
      cancellationReason: json['cancellation_reason'] as String?,
      cancelledByUserId: json['cancelled_by_user_id'] as String?,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      refundAmount: (json['refund_amount'] as num?)?.toDouble() ?? 0.0,
      refundReference: json['refund_reference'] as String?,
      refundedAt: json['refunded_at'] != null
          ? DateTime.parse(json['refunded_at'] as String)
          : null,
      bookingSource: json['booking_source'] as String? ?? 'app',
      deviceInfo: json['device_info'] as Map<String, dynamic>?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      busBooking: json['bus_booking'] != null
          ? BusBooking.fromJson(json['bus_booking'] as Map<String, dynamic>)
          : null,
    );
  }

  // Helper methods
  bool get canBeCancelled =>
      bookingStatus == MasterBookingStatus.pending ||
      bookingStatus == MasterBookingStatus.confirmed;

  bool get isPaid => paymentStatus == MasterPaymentStatus.paid;

  String get formattedTotal => 'LKR ${totalAmount.toStringAsFixed(2)}';
}

// ============================================================================
// BUS BOOKING MODEL
// ============================================================================

class BusBooking {
  final String id;
  final String bookingId;
  final String scheduledTripId;

  // Trip Snapshot
  final String routeName;
  final String? busNumber;
  final String? busType;
  final String? busOwnerId;

  // Stops
  final String? boardingStopId;
  final String boardingStopName;
  final int? boardingStopOrder;
  final String? alightingStopId;
  final String alightingStopName;
  final int? alightingStopOrder;

  // Timing
  final DateTime departureDatetime;
  final DateTime? estimatedArrivalDatetime;
  final DateTime? actualDepartureDatetime;
  final DateTime? actualArrivalDatetime;

  // Seats & Fare
  final int numberOfSeats;
  final double farePerSeat;
  final double totalFare;

  // Status
  final BusBookingStatus status;

  // Check-in/Boarding
  final DateTime? checkedInAt;
  final String? checkedInByUserId;
  final DateTime? boardedAt;
  final String? boardedByUserId;
  final DateTime? completedAt;

  // Cancellation
  final DateTime? cancelledAt;
  final String? cancellationReason;

  // QR Code
  final String? qrCodeData;
  final DateTime? qrGeneratedAt;

  final String? specialRequests;

  final DateTime createdAt;
  final DateTime updatedAt;

  // Related
  final List<BusBookingSeat> seats;

  BusBooking({
    required this.id,
    required this.bookingId,
    required this.scheduledTripId,
    required this.routeName,
    this.busNumber,
    this.busType,
    this.busOwnerId,
    this.boardingStopId,
    required this.boardingStopName,
    this.boardingStopOrder,
    this.alightingStopId,
    required this.alightingStopName,
    this.alightingStopOrder,
    required this.departureDatetime,
    this.estimatedArrivalDatetime,
    this.actualDepartureDatetime,
    this.actualArrivalDatetime,
    required this.numberOfSeats,
    required this.farePerSeat,
    required this.totalFare,
    required this.status,
    this.checkedInAt,
    this.checkedInByUserId,
    this.boardedAt,
    this.boardedByUserId,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.qrCodeData,
    this.qrGeneratedAt,
    this.specialRequests,
    required this.createdAt,
    required this.updatedAt,
    this.seats = const [],
  });

  factory BusBooking.fromJson(Map<String, dynamic> json) {
    return BusBooking(
      id: json['id'] as String? ?? '',
      bookingId: json['booking_id'] as String? ?? '',
      scheduledTripId: json['scheduled_trip_id'] as String? ?? '',
      routeName: json['route_name'] as String? ?? 'Unknown Route',
      busNumber: json['bus_number'] as String?,
      busType: json['bus_type'] as String?,
      busOwnerId: json['bus_owner_id'] as String?,
      boardingStopId: json['boarding_stop_id'] as String?,
      boardingStopName: json['boarding_stop_name'] as String? ?? '',
      boardingStopOrder: json['boarding_stop_order'] as int?,
      alightingStopId: json['alighting_stop_id'] as String?,
      alightingStopName: json['alighting_stop_name'] as String? ?? '',
      alightingStopOrder: json['alighting_stop_order'] as int?,
      departureDatetime: json['departure_datetime'] != null
          ? DateTime.parse(json['departure_datetime'] as String)
          : DateTime.now(),
      estimatedArrivalDatetime: json['estimated_arrival_datetime'] != null
          ? DateTime.parse(json['estimated_arrival_datetime'] as String)
          : null,
      actualDepartureDatetime: json['actual_departure_datetime'] != null
          ? DateTime.parse(json['actual_departure_datetime'] as String)
          : null,
      actualArrivalDatetime: json['actual_arrival_datetime'] != null
          ? DateTime.parse(json['actual_arrival_datetime'] as String)
          : null,
      numberOfSeats: json['number_of_seats'] as int? ?? 0,
      farePerSeat: (json['fare_per_seat'] as num?)?.toDouble() ?? 0.0,
      totalFare: (json['total_fare'] as num?)?.toDouble() ?? 0.0,
      status: BusBookingStatus.fromJson(json['status'] as String?),
      checkedInAt: json['checked_in_at'] != null
          ? DateTime.parse(json['checked_in_at'] as String)
          : null,
      checkedInByUserId: json['checked_in_by_user_id'] as String?,
      boardedAt: json['boarded_at'] != null
          ? DateTime.parse(json['boarded_at'] as String)
          : null,
      boardedByUserId: json['boarded_by_user_id'] as String?,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
      cancellationReason: json['cancellation_reason'] as String?,
      qrCodeData: json['qr_code_data'] as String?,
      qrGeneratedAt: json['qr_generated_at'] != null
          ? DateTime.parse(json['qr_generated_at'] as String)
          : null,
      specialRequests: json['special_requests'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      seats:
          (json['seats'] as List<dynamic>?)
              ?.map((e) => BusBookingSeat.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  // Helper methods
  bool get isCheckedIn => checkedInAt != null;
  bool get isBoarded => boardedAt != null;
  bool get isCompleted => completedAt != null;
  bool get isCancelled => status == BusBookingStatus.cancelled;

  String get formattedDeparture {
    return '${departureDatetime.day}/${departureDatetime.month}/${departureDatetime.year} ${departureDatetime.hour.toString().padLeft(2, '0')}:${departureDatetime.minute.toString().padLeft(2, '0')}';
  }

  String get seatNumbers => seats.map((s) => s.seatNumber).join(', ');

  String get busTypeDisplay {
    switch (busType?.toLowerCase()) {
      case 'luxury':
        return 'Luxury';
      case 'semi_luxury':
        return 'Semi Luxury';
      case 'super_luxury':
        return 'Super Luxury';
      case 'normal':
      default:
        return 'Normal';
    }
  }
}

// ============================================================================
// BUS BOOKING SEAT MODEL
// ============================================================================

class BusBookingSeat {
  final String id;
  final String busBookingId;
  final String scheduledTripId;
  final String? tripSeatId;

  // Seat Info
  final String seatNumber;
  final String seatType;
  final double seatPrice;

  // Passenger
  final String passengerName;
  final String? passengerPhone;
  final String? passengerEmail;
  final int? passengerAge;
  final String? passengerGender;
  final String? passengerNIC;
  final bool isPrimaryPassenger;

  // Status
  final SeatBookingStatus status;

  // Timestamps
  final DateTime? checkedInAt;
  final DateTime? boardedAt;
  final DateTime? cancelledAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  BusBookingSeat({
    required this.id,
    required this.busBookingId,
    required this.scheduledTripId,
    this.tripSeatId,
    required this.seatNumber,
    required this.seatType,
    required this.seatPrice,
    required this.passengerName,
    this.passengerPhone,
    this.passengerEmail,
    this.passengerAge,
    this.passengerGender,
    this.passengerNIC,
    required this.isPrimaryPassenger,
    required this.status,
    this.checkedInAt,
    this.boardedAt,
    this.cancelledAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BusBookingSeat.fromJson(Map<String, dynamic> json) {
    return BusBookingSeat(
      id: json['id'] as String? ?? '',
      busBookingId: json['bus_booking_id'] as String? ?? '',
      scheduledTripId: json['scheduled_trip_id'] as String? ?? '',
      tripSeatId: json['trip_seat_id'] as String?,
      seatNumber: json['seat_number'] as String? ?? '',
      seatType: json['seat_type'] as String? ?? 'regular',
      seatPrice: (json['seat_price'] as num?)?.toDouble() ?? 0.0,
      passengerName: json['passenger_name'] as String? ?? '',
      passengerPhone: json['passenger_phone'] as String?,
      passengerEmail: json['passenger_email'] as String?,
      passengerAge: json['passenger_age'] as int?,
      passengerGender: json['passenger_gender'] as String?,
      passengerNIC: json['passenger_nic'] as String?,
      isPrimaryPassenger: json['is_primary_passenger'] as bool? ?? false,
      status: SeatBookingStatus.fromJson(json['status'] as String?),
      checkedInAt: json['checked_in_at'] != null
          ? DateTime.parse(json['checked_in_at'] as String)
          : null,
      boardedAt: json['boarded_at'] != null
          ? DateTime.parse(json['boarded_at'] as String)
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  String get formattedPrice => 'LKR ${seatPrice.toStringAsFixed(2)}';
}

// ============================================================================
// REQUEST MODELS
// ============================================================================

/// Represents a seat selection with passenger details for booking
class SeatSelection {
  final String tripSeatId;
  final String seatNumber;
  final String seatType;
  final double seatPrice;
  final String passengerName;
  final String? passengerPhone;
  final String? passengerEmail;
  final int? passengerAge;
  final String? passengerGender;
  final String? passengerNIC;
  final bool isPrimary;

  SeatSelection({
    required this.tripSeatId,
    required this.seatNumber,
    this.seatType = 'regular',
    required this.seatPrice,
    required this.passengerName,
    this.passengerPhone,
    this.passengerEmail,
    this.passengerAge,
    this.passengerGender,
    this.passengerNIC,
    this.isPrimary = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'trip_seat_id': tripSeatId,
      'seat_number': seatNumber,
      'seat_type': seatType,
      'seat_price': seatPrice,
      'passenger_name': passengerName,
      if (passengerPhone != null) 'passenger_phone': passengerPhone,
      if (passengerEmail != null) 'passenger_email': passengerEmail,
      if (passengerAge != null) 'passenger_age': passengerAge,
      if (passengerGender != null) 'passenger_gender': passengerGender,
      if (passengerNIC != null) 'passenger_nic': passengerNIC,
      'is_primary': isPrimary,
    };
  }
}

/// Request to create a new booking
class CreateBookingRequest {
  final String scheduledTripId;
  final String? boardingStopId;
  final String boardingStopName;
  final String? alightingStopId;
  final String alightingStopName;
  final List<SeatSelection> seats;
  final String passengerName;
  final String passengerPhone;
  final String? passengerEmail;
  final String? paymentMethod;
  final String? promoCode;
  final String? specialRequests;
  final Map<String, dynamic>? deviceInfo;

  CreateBookingRequest({
    required this.scheduledTripId,
    this.boardingStopId,
    required this.boardingStopName,
    this.alightingStopId,
    required this.alightingStopName,
    required this.seats,
    required this.passengerName,
    required this.passengerPhone,
    this.passengerEmail,
    this.paymentMethod,
    this.promoCode,
    this.specialRequests,
    this.deviceInfo,
  });

  Map<String, dynamic> toJson() {
    return {
      'scheduled_trip_id': scheduledTripId,
      if (boardingStopId != null) 'boarding_stop_id': boardingStopId,
      'boarding_stop_name': boardingStopName,
      if (alightingStopId != null) 'alighting_stop_id': alightingStopId,
      'alighting_stop_name': alightingStopName,
      'seats': seats.map((s) => s.toJson()).toList(),
      'passenger_name': passengerName,
      'passenger_phone': passengerPhone,
      if (passengerEmail != null) 'passenger_email': passengerEmail,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (promoCode != null) 'promo_code': promoCode,
      if (specialRequests != null) 'special_requests': specialRequests,
      if (deviceInfo != null) 'device_info': deviceInfo,
    };
  }
}

/// Request to confirm payment
class ConfirmPaymentRequest {
  final String paymentMethod;
  final String paymentReference;
  final String? paymentGateway;

  ConfirmPaymentRequest({
    required this.paymentMethod,
    required this.paymentReference,
    this.paymentGateway,
  });

  Map<String, dynamic> toJson() {
    return {
      'payment_method': paymentMethod,
      'payment_reference': paymentReference,
      if (paymentGateway != null) 'payment_gateway': paymentGateway,
    };
  }
}

/// Request to cancel a booking
class CancelBookingRequest {
  final String? reason;

  CancelBookingRequest({this.reason});

  Map<String, dynamic> toJson() {
    return {if (reason != null) 'reason': reason};
  }
}

// ============================================================================
// RESPONSE MODELS
// ============================================================================

/// Response after creating a booking
class BookingResponse {
  final MasterBooking booking;
  final BusBooking? busBooking;
  final List<BusBookingSeat> seats;
  final String? qrCode;

  BookingResponse({
    required this.booking,
    this.busBooking,
    this.seats = const [],
    this.qrCode,
  });

  factory BookingResponse.fromJson(Map<String, dynamic> json) {
    // API may return booking directly OR wrapped in {"booking": ...}
    // Check if 'booking' key exists, otherwise treat entire json as MasterBooking
    final bookingJson = json.containsKey('booking') && json['booking'] != null
        ? json['booking'] as Map<String, dynamic>
        : json;

    return BookingResponse(
      booking: MasterBooking.fromJson(bookingJson),
      busBooking: json['bus_booking'] != null
          ? BusBooking.fromJson(json['bus_booking'] as Map<String, dynamic>)
          : null,
      seats:
          (json['seats'] as List<dynamic>?)
              ?.map((e) => BusBookingSeat.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      qrCode: json['qr_code'] as String?,
    );
  }
}

/// Summary item for booking list
class BookingListItem {
  final String id;
  final String bookingReference;
  final BookingType bookingType;
  final double totalAmount;
  final MasterPaymentStatus paymentStatus;
  final MasterBookingStatus bookingStatus;
  final String passengerName;
  final DateTime createdAt;

  // Bus details
  final String? routeName;
  final DateTime? departureDatetime;
  final int? numberOfSeats;
  final BusBookingStatus? busStatus;
  final String? qrCodeData;

  BookingListItem({
    required this.id,
    required this.bookingReference,
    required this.bookingType,
    required this.totalAmount,
    required this.paymentStatus,
    required this.bookingStatus,
    required this.passengerName,
    required this.createdAt,
    this.routeName,
    this.departureDatetime,
    this.numberOfSeats,
    this.busStatus,
    this.qrCodeData,
  });

  factory BookingListItem.fromJson(Map<String, dynamic> json) {
    return BookingListItem(
      id: json['id'] as String? ?? '',
      bookingReference: json['booking_reference'] as String? ?? '',
      bookingType: BookingType.fromJson(json['booking_type'] as String?),
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: MasterPaymentStatus.fromJson(
        json['payment_status'] as String?,
      ),
      bookingStatus: MasterBookingStatus.fromJson(
        json['booking_status'] as String?,
      ),
      passengerName: json['passenger_name'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      routeName: json['route_name'] as String?,
      departureDatetime: json['departure_datetime'] != null
          ? DateTime.parse(json['departure_datetime'] as String)
          : null,
      numberOfSeats: json['number_of_seats'] as int?,
      busStatus: json['bus_status'] != null
          ? BusBookingStatus.fromJson(json['bus_status'] as String?)
          : null,
      qrCodeData: json['qr_code_data'] as String?,
    );
  }

  String get formattedTotal => 'LKR ${totalAmount.toStringAsFixed(2)}';

  String get formattedDeparture {
    if (departureDatetime == null) return '';
    return '${departureDatetime!.day}/${departureDatetime!.month}/${departureDatetime!.year}';
  }
}

/// Response for trip seats
class TripSeatsResponse {
  final String tripId;
  final List<TripSeat> seats;
  final int totalSeats;
  final int availableSeats;
  final int bookedSeats;

  TripSeatsResponse({
    required this.tripId,
    required this.seats,
    required this.totalSeats,
    required this.availableSeats,
    required this.bookedSeats,
  });

  factory TripSeatsResponse.fromJson(Map<String, dynamic> json) {
    final seatsList =
        (json['seats'] as List<dynamic>?)
            ?.map((e) => TripSeat.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return TripSeatsResponse(
      tripId: json['trip_id'] as String? ?? '',
      seats: seatsList,
      totalSeats: json['total_seats'] as int? ?? seatsList.length,
      availableSeats:
          json['available_seats'] as int? ??
          seatsList.where((s) => s.canBeSelected).length,
      bookedSeats:
          json['booked_seats'] as int? ??
          seatsList.where((s) => s.isBooked).length,
    );
  }
}
