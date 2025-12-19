import 'package:logger/logger.dart';
import '../models/booking_models.dart';
import '../models/lounge_booking_models.dart';
import '../models/unified_booking.dart';
import 'booking_service.dart';
import 'lounge_booking_service.dart';

/// Service that combines bus and lounge bookings into a unified view
class CombinedBookingsService {
  static final CombinedBookingsService _instance =
      CombinedBookingsService._internal();
  factory CombinedBookingsService() => _instance;
  CombinedBookingsService._internal();

  final BookingService _busBookingService = BookingService();
  final LoungeBookingService _loungeBookingService = LoungeBookingService();
  final Logger _logger = Logger();

  /// Get all upcoming bookings (both bus and lounge)
  /// Sorted by datetime ascending (nearest first)
  Future<List<UnifiedBooking>> getUpcomingBookings() async {
    try {
      _logger.i('Fetching all upcoming bookings');

      // Fetch both types in parallel
      final results = await Future.wait([
        _busBookingService.getUpcomingBookings(limit: 50),
        _loungeBookingService.getUpcomingBookings(),
      ]);

      final busBookings = results[0] as List<BookingListItem>;
      final loungeBookings = results[1] as List<LoungeBooking>;

      _logger.d(
        'Got ${busBookings.length} bus and ${loungeBookings.length} lounge bookings',
      );

      // Convert to unified format
      final List<UnifiedBooking> unified = [];

      for (final bus in busBookings) {
        unified.add(UnifiedBooking.fromBusBooking(bus));
      }

      for (final lounge in loungeBookings) {
        // Skip lounge bookings that are linked to a bus booking (they'll show with the bus)
        if (lounge.busBookingId == null) {
          unified.add(UnifiedBooking.fromLoungeBooking(lounge));
        }
      }

      // Sort by datetime (nearest first)
      unified.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      _logger.i('Returning ${unified.length} unified upcoming bookings');
      return unified;
    } catch (e) {
      _logger.e('Failed to get combined upcoming bookings: $e');
      rethrow;
    }
  }

  /// Get completed bookings (both bus and lounge)
  /// Sorted by datetime descending (most recent first)
  Future<List<UnifiedBooking>> getCompletedBookings() async {
    try {
      _logger.i('Fetching completed bookings');

      // Fetch both types in parallel
      final results = await Future.wait([
        _busBookingService.getMyBookings(status: 'completed', limit: 50),
        _loungeBookingService.getMyBookings(status: 'completed'),
      ]);

      final busBookings = results[0] as List<BookingListItem>;
      final loungeBookings = results[1] as List<LoungeBooking>;

      _logger.d(
        'Got ${busBookings.length} completed bus and ${loungeBookings.length} completed lounge bookings',
      );

      // Convert to unified format
      final List<UnifiedBooking> unified = [];

      for (final bus in busBookings) {
        unified.add(UnifiedBooking.fromBusBooking(bus));
      }

      for (final lounge in loungeBookings) {
        if (lounge.busBookingId == null) {
          unified.add(UnifiedBooking.fromLoungeBooking(lounge));
        }
      }

      // Sort by datetime (most recent first)
      unified.sort((a, b) => b.dateTime.compareTo(a.dateTime));

      _logger.i('Returning ${unified.length} unified completed bookings');
      return unified;
    } catch (e) {
      _logger.e('Failed to get combined completed bookings: $e');
      rethrow;
    }
  }

  /// Get cancelled bookings (both bus and lounge)
  /// Sorted by created date descending
  Future<List<UnifiedBooking>> getCancelledBookings() async {
    try {
      _logger.i('Fetching cancelled bookings');

      // Fetch both types in parallel
      final results = await Future.wait([
        _busBookingService.getMyBookings(status: 'cancelled', limit: 50),
        _loungeBookingService.getMyBookings(status: 'cancelled'),
      ]);

      final busBookings = results[0] as List<BookingListItem>;
      final loungeBookings = results[1] as List<LoungeBooking>;

      _logger.d(
        'Got ${busBookings.length} cancelled bus and ${loungeBookings.length} cancelled lounge bookings',
      );

      // Convert to unified format
      final List<UnifiedBooking> unified = [];

      for (final bus in busBookings) {
        unified.add(UnifiedBooking.fromBusBooking(bus));
      }

      for (final lounge in loungeBookings) {
        unified.add(UnifiedBooking.fromLoungeBooking(lounge));
      }

      // Sort by created date (most recent first)
      unified.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _logger.i('Returning ${unified.length} unified cancelled bookings');
      return unified;
    } catch (e) {
      _logger.e('Failed to get combined cancelled bookings: $e');
      rethrow;
    }
  }

  /// Get linked lounge bookings for a bus booking ID
  Future<List<LoungeBooking>> getLinkedLoungeBookings(
    String busBookingId,
  ) async {
    try {
      // Get all lounge bookings and filter by busBookingId
      final loungeBookings = await _loungeBookingService.getMyBookings();
      return loungeBookings
          .where((l) => l.busBookingId == busBookingId)
          .toList();
    } catch (e) {
      _logger.e('Failed to get linked lounge bookings: $e');
      return [];
    }
  }
}
