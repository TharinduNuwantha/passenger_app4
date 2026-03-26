import 'package:logger/logger.dart';
import '../models/booking_models.dart';
import '../models/lounge_booking_models.dart';
import '../models/unified_booking.dart';
import 'booking_service.dart';
import 'lounge_booking_service.dart';

/// Paged result for combined bookings
class PagedCombinedBookings {
  final List<UnifiedBooking> bookings;
  final bool hasMoreBus;
  final bool hasMoreLounge;
  final int busCount;
  final int loungeCount;

  PagedCombinedBookings({
    required this.bookings,
    required this.hasMoreBus,
    required this.hasMoreLounge,
    required this.busCount,
    required this.loungeCount,
  });
}

/// Service that combines bus and lounge bookings into a unified view
class CombinedBookingsService {
  static final CombinedBookingsService _instance =
      CombinedBookingsService._internal();
  factory CombinedBookingsService() => _instance;
  CombinedBookingsService._internal();

  final BookingService _busBookingService = BookingService();
  final LoungeBookingService _loungeBookingService = LoungeBookingService();
  final Logger _logger = Logger();

  /// Get combined bookings for a given status with pagination
  Future<PagedCombinedBookings> getPagedBookings({
    required String status,
    required int busPage,
    required int loungePage,
    int limit = 20,
  }) async {
    try {
      _logger.i(
        'Fetching combined $status bookings (busPage: $busPage, loungePage: $loungePage, limit: $limit)',
      );

      // Fetch both types in parallel, but handle errors individually
      List<BookingListItem> busBookings = [];
      List<LoungeBooking> loungeBookings = [];

      await Future.wait([
        // Bus bookings
        _busBookingService
            .getMyBookings(status: status, page: busPage, limit: limit)
            .then((result) {
              busBookings = result;
            })
            .catchError((e) {
              _logger.e('Failed to fetch bus bookings: $e');
              // Continue with empty list
              busBookings = [];
            }),

        // Lounge bookings
        () async {
          try {
            if (status == 'upcoming') {
              loungeBookings = await _loungeBookingService.getUpcomingBookings(
                page: loungePage,
                limit: limit,
              );
            } else {
              loungeBookings = await _loungeBookingService.getMyBookings(
                status: status,
                page: loungePage,
                limit: limit,
              );
            }
          } catch (e) {
            _logger.e('Failed to fetch lounge bookings: $e');
            // Continue with empty list
            loungeBookings = [];
          }
        }(),
      ]);

      _logger.d(
        'Got ${busBookings.length} $status bus and ${loungeBookings.length} $status lounge bookings',
      );

      final List<UnifiedBooking> unified = [];

      for (final bus in busBookings) {
        unified.add(UnifiedBooking.fromBusBooking(bus));
      }

      for (final lounge in loungeBookings) {
        // Skip linked lounge bookings for non-cancelled lists; bus cards will show linked lounges
        final skipLinked = lounge.busBookingId != null && status != 'cancelled';
        if (!skipLinked) {
          unified.add(UnifiedBooking.fromLoungeBooking(lounge));
        }
      }

      // Defensive filter: ensure only exact cancelled items are included when status is cancelled
      if (status == 'cancelled') {
        unified.retainWhere((b) => b.status == UnifiedBookingStatus.cancelled);
      }

      // Defensive filter: ensure only exact completed items are included when status is completed
      if (status == 'completed') {
        unified.retainWhere((b) => b.status == UnifiedBookingStatus.completed);
      }

      // Sort based on status semantics
      if (status == 'upcoming') {
        unified.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      } else if (status == 'completed') {
        unified.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      } else {
        unified.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      final hasMoreBus = busBookings.length == limit;
      final hasMoreLounge = loungeBookings.length == limit;

      return PagedCombinedBookings(
        bookings: unified,
        hasMoreBus: hasMoreBus,
        hasMoreLounge: hasMoreLounge,
        busCount: busBookings.length,
        loungeCount: loungeBookings.length,
      );
    } catch (e) {
      _logger.e('Failed to get combined $status bookings: $e');
      rethrow;
    }
  }

  /// Get all upcoming bookings (both bus and lounge) - first page
  /// Sorted by datetime ascending (nearest first)
  Future<List<UnifiedBooking>> getUpcomingBookings({
    int page = 1,
    int limit = 50,
  }) async {
    final result = await getPagedBookings(
      status: 'upcoming',
      busPage: page,
      loungePage: page,
      limit: limit,
    );
    return result.bookings;
  }

  /// Get completed bookings (both bus and lounge) - first page
  /// Sorted by datetime descending (most recent first)
  Future<List<UnifiedBooking>> getCompletedBookings({
    int page = 1,
    int limit = 50,
  }) async {
    final result = await getPagedBookings(
      status: 'completed',
      busPage: page,
      loungePage: page,
      limit: limit,
    );
    return result.bookings;
  }

  /// Get cancelled bookings (both bus and lounge) - first page
  /// Sorted by created date descending
  Future<List<UnifiedBooking>> getCancelledBookings({
    int page = 1,
    int limit = 50,
  }) async {
    final result = await getPagedBookings(
      status: 'cancelled',
      busPage: page,
      loungePage: page,
      limit: limit,
    );
    return result.bookings;
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
