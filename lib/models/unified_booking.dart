import 'booking_models.dart';
import 'lounge_booking_models.dart';

/// Enum to identify the type of booking item
enum UnifiedBookingType {
  bus,
  lounge,
  combined; // Bus + Lounge together

  String get displayName {
    switch (this) {
      case UnifiedBookingType.bus:
        return 'Bus';
      case UnifiedBookingType.lounge:
        return 'Lounge';
      case UnifiedBookingType.combined:
        return 'Bus + Lounge';
    }
  }

  String get iconName {
    switch (this) {
      case UnifiedBookingType.bus:
        return 'directions_bus';
      case UnifiedBookingType.lounge:
        return 'weekend';
      case UnifiedBookingType.combined:
        return 'connecting_airports';
    }
  }
}

/// Unified status that maps from both bus and lounge booking statuses
enum UnifiedBookingStatus {
  upcoming,
  inProgress,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case UnifiedBookingStatus.upcoming:
        return 'Upcoming';
      case UnifiedBookingStatus.inProgress:
        return 'In Progress';
      case UnifiedBookingStatus.completed:
        return 'Completed';
      case UnifiedBookingStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// Unified booking model that can represent both bus and lounge bookings
class UnifiedBooking {
  final String id;
  final String bookingReference;
  final UnifiedBookingType type;
  final UnifiedBookingStatus status;
  final DateTime dateTime; // For sorting - departure time or check-in time
  final double totalAmount;
  final String title; // Route name or lounge name
  final String subtitle; // Bus details or lounge location
  final String? qrCodeData;
  final DateTime createdAt;

  // Optional bus-specific data
  final BookingListItem? busBooking;

  // Optional lounge-specific data
  final LoungeBooking? loungeBooking;

  // For combined bookings
  final LoungeBooking? preLoungeBooking;
  final LoungeBooking? postLoungeBooking;

  UnifiedBooking({
    required this.id,
    required this.bookingReference,
    required this.type,
    required this.status,
    required this.dateTime,
    required this.totalAmount,
    required this.title,
    required this.subtitle,
    this.qrCodeData,
    required this.createdAt,
    this.busBooking,
    this.loungeBooking,
    this.preLoungeBooking,
    this.postLoungeBooking,
  });

  /// Create from bus booking list item
  factory UnifiedBooking.fromBusBooking(BookingListItem booking) {
    return UnifiedBooking(
      id: booking.id,
      bookingReference: booking.bookingReference,
      type: UnifiedBookingType.bus,
      status: _mapBusStatus(booking.bookingStatus),
      dateTime: booking.departureDatetime ?? booking.createdAt,
      totalAmount: booking.totalAmount,
      title: booking.routeName ?? 'Bus Trip',
      subtitle: '${booking.numberOfSeats ?? 1} seat(s)',
      qrCodeData: booking.qrCodeData,
      createdAt: booking.createdAt,
      busBooking: booking,
    );
  }

  /// Create from lounge booking
  factory UnifiedBooking.fromLoungeBooking(LoungeBooking booking) {
    return UnifiedBooking(
      id: booking.id,
      bookingReference: booking.bookingReference,
      type: UnifiedBookingType.lounge,
      status: _mapLoungeStatus(booking.bookingStatus),
      dateTime: booking.checkInTime,
      totalAmount: booking.totalAmount,
      title: booking.loungeName ?? 'Lounge',
      subtitle: '${booking.numberOfGuests} guest(s)',
      qrCodeData: booking.qrCodeData,
      createdAt: booking.createdAt,
      loungeBooking: booking,
    );
  }

  /// Map master booking status to unified status
  static UnifiedBookingStatus _mapBusStatus(MasterBookingStatus status) {
    switch (status) {
      case MasterBookingStatus.pending:
      case MasterBookingStatus.confirmed:
        return UnifiedBookingStatus.upcoming;
      case MasterBookingStatus.inProgress:
        return UnifiedBookingStatus.inProgress;
      case MasterBookingStatus.completed:
        return UnifiedBookingStatus.completed;
      case MasterBookingStatus.cancelled:
        return UnifiedBookingStatus.cancelled;
      case MasterBookingStatus.partialCancel:
        // Partial seat cancellations should not classify the whole booking as cancelled
        // Treat as still active/upcoming for the Activities categorization
        return UnifiedBookingStatus.upcoming;
    }
  }

  /// Map lounge booking status to unified status
  static UnifiedBookingStatus _mapLoungeStatus(LoungeBookingStatus status) {
    switch (status) {
      case LoungeBookingStatus.pending:
      case LoungeBookingStatus.confirmed:
        return UnifiedBookingStatus.upcoming;
      case LoungeBookingStatus.checkedIn:
        return UnifiedBookingStatus.inProgress;
      case LoungeBookingStatus.completed:
        return UnifiedBookingStatus.completed;
      case LoungeBookingStatus.cancelled:
      case LoungeBookingStatus.noShow:
        return UnifiedBookingStatus.cancelled;
    }
  }

  String get formattedTotal => 'LKR ${totalAmount.toStringAsFixed(2)}';

  String get formattedDate {
    final months = [
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
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
  }

  String get formattedTime {
    final hour = dateTime.hour > 12
        ? dateTime.hour - 12
        : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} $period';
  }

  String get formattedDateTime => '$formattedDate, $formattedTime';

  bool get isUpcoming =>
      status == UnifiedBookingStatus.upcoming &&
      dateTime.isAfter(DateTime.now());
  bool get isPast => dateTime.isBefore(DateTime.now());
}
