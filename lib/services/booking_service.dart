import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../models/booking_models.dart';
import '../utils/error_handler.dart';
import 'api_service.dart';

/// Service for handling app booking operations
class BookingService {
  static final BookingService _instance = BookingService._internal();
  factory BookingService() => _instance;
  BookingService._internal();

  final ApiService _apiService = ApiService();
  final Logger _logger = Logger();

  // ============================================================================
  // TRIP SEATS
  // ============================================================================

  /// Get available seats for a scheduled trip
  ///
  /// [tripId] - The scheduled trip ID
  ///
  /// Returns [TripSeatsResponse] with seat availability
  Future<TripSeatsResponse> getTripSeats(String tripId) async {
    try {
      _logger.i('Fetching seats for trip: $tripId');

      final response = await _apiService.get(
        '/api/v1/scheduled-trips/$tripId/seats',
      );

      _logger.d('Trip seats response: ${response.data}');

      final seatsResponse = TripSeatsResponse.fromJson(response.data);

      _logger.i(
        'Fetched ${seatsResponse.seats.length} seats: '
        '${seatsResponse.availableSeats} available, '
        '${seatsResponse.bookedSeats} booked',
      );

      return seatsResponse;
    } on DioException catch (e) {
      _logger.e('Failed to get trip seats: ${e.message}');
      throw ErrorHandler.handleError(e);
    } catch (e) {
      _logger.e('Unexpected error getting trip seats: $e');
      throw Exception('Failed to get seat availability: $e');
    }
  }

  // ============================================================================
  // CREATE BOOKING
  // ============================================================================

  /// Create a new bus booking
  ///
  /// [request] - The booking request with trip, seats, and passenger details
  ///
  /// Returns [BookingResponse] with booking details and QR code
  Future<BookingResponse> createBooking(CreateBookingRequest request) async {
    try {
      _logger.i('Creating booking for trip: ${request.scheduledTripId}');
      _logger.i('Seats: ${request.seats.length}');

      final response = await _apiService.post(
        '/api/v1/bookings',
        data: request.toJson(),
      );

      _logger.d('Create booking response: ${response.data}');

      final bookingResponse = BookingResponse.fromJson(response.data);

      _logger.i('Booking created: ${bookingResponse.booking.bookingReference}');

      return bookingResponse;
    } on DioException catch (e) {
      _logger.e('Failed to create booking: ${e.message}');

      // Handle specific error cases
      if (e.response?.statusCode == 409) {
        throw Exception(
          'Selected seats are no longer available. Please select different seats.',
        );
      }
      if (e.response?.statusCode == 400) {
        final error = e.response?.data?['error'] ?? 'Invalid booking request';
        throw Exception(error);
      }

      throw ErrorHandler.handleError(e);
    } catch (e) {
      _logger.e('Unexpected error creating booking: $e');
      throw Exception('Failed to create booking: $e');
    }
  }

  // ============================================================================
  // GET BOOKINGS
  // ============================================================================

  /// Get user's bookings with optional filters
  ///
  /// [status] - Filter by booking status
  /// [page] - Page number for pagination
  /// [limit] - Items per page
  ///
  /// Returns list of [BookingListItem]
  Future<List<BookingListItem>> getMyBookings({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      _logger.i('Fetching user bookings (page: $page, status: $status)');

      final queryParams = <String, dynamic>{'page': page, 'limit': limit};
      if (status != null) {
        queryParams['status'] = status;
      }

      final response = await _apiService.get(
        '/api/v1/bookings',
        queryParameters: queryParams,
      );

      _logger.d('Get bookings response: ${response.data}');

      final bookings =
          (response.data['bookings'] as List<dynamic>?)
              ?.map((e) => BookingListItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      _logger.i('Fetched ${bookings.length} bookings');

      return bookings;
    } on DioException catch (e) {
      _logger.e('Failed to get bookings: ${e.message}');
      throw ErrorHandler.handleError(e);
    } catch (e) {
      _logger.e('Unexpected error getting bookings: $e');
      throw Exception('Failed to get bookings: $e');
    }
  }

  /// Get upcoming bookings (departures in the future)
  ///
  /// [limit] - Maximum number of results
  ///
  /// Returns list of [BookingListItem]
  Future<List<BookingListItem>> getUpcomingBookings({int limit = 10}) async {
    try {
      _logger.i('Fetching upcoming bookings');

      final response = await _apiService.get(
        '/api/v1/bookings/upcoming',
        queryParameters: {'limit': limit},
      );

      _logger.d('Upcoming bookings response: ${response.data}');

      final bookings =
          (response.data['bookings'] as List<dynamic>?)
              ?.map((e) => BookingListItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      _logger.i('Fetched ${bookings.length} upcoming bookings');

      return bookings;
    } on DioException catch (e) {
      _logger.e('Failed to get upcoming bookings: ${e.message}');
      throw ErrorHandler.handleError(e);
    } catch (e) {
      _logger.e('Unexpected error getting upcoming bookings: $e');
      throw Exception('Failed to get upcoming bookings: $e');
    }
  }

  /// Get booking details by ID
  ///
  /// [bookingId] - The booking ID
  ///
  /// Returns [BookingResponse] with full details
  Future<BookingResponse> getBookingById(String bookingId) async {
    try {
      _logger.i('Fetching booking: $bookingId');

      final response = await _apiService.get('/api/v1/bookings/$bookingId');

      _logger.d('Get booking response: ${response.data}');

      final bookingResponse = BookingResponse.fromJson(response.data);

      _logger.i('Fetched booking: ${bookingResponse.booking.bookingReference}');

      return bookingResponse;
    } on DioException catch (e) {
      _logger.e('Failed to get booking: ${e.message}');

      if (e.response?.statusCode == 404) {
        throw Exception('Booking not found');
      }

      throw ErrorHandler.handleError(e);
    } catch (e) {
      _logger.e('Unexpected error getting booking: $e');
      throw Exception('Failed to get booking details: $e');
    }
  }

  // ============================================================================
  // BOOKING ACTIONS
  // ============================================================================

  /// Cancel a booking
  ///
  /// [bookingId] - The booking ID to cancel
  /// [reason] - Optional cancellation reason
  ///
  /// Returns updated [BookingResponse]
  Future<BookingResponse> cancelBooking(
    String bookingId, {
    String? reason,
  }) async {
    try {
      _logger.i('Cancelling booking: $bookingId');

      final request = CancelBookingRequest(reason: reason);

      final response = await _apiService.post(
        '/api/v1/bookings/$bookingId/cancel',
        data: request.toJson(),
      );

      _logger.d('Cancel booking response: ${response.data}');

      final bookingResponse = BookingResponse.fromJson(response.data);

      _logger.i(
        'Booking cancelled: ${bookingResponse.booking.bookingReference}',
      );

      return bookingResponse;
    } on DioException catch (e) {
      _logger.e('Failed to cancel booking: ${e.message}');

      if (e.response?.statusCode == 400) {
        final error =
            e.response?.data?['error'] ?? 'Cannot cancel this booking';
        throw Exception(error);
      }
      if (e.response?.statusCode == 404) {
        throw Exception('Booking not found');
      }

      throw ErrorHandler.handleError(e);
    } catch (e) {
      _logger.e('Unexpected error cancelling booking: $e');
      throw Exception('Failed to cancel booking: $e');
    }
  }

  /// Confirm payment for a booking
  ///
  /// [bookingId] - The booking ID
  /// [paymentMethod] - Payment method used (e.g., 'card', 'cash')
  /// [paymentReference] - Payment transaction reference
  /// [paymentGateway] - Optional payment gateway name
  ///
  /// Returns updated [BookingResponse]
  Future<BookingResponse> confirmPayment({
    required String bookingId,
    required String paymentMethod,
    required String paymentReference,
    String? paymentGateway,
  }) async {
    try {
      _logger.i('Confirming payment for booking: $bookingId');

      final request = ConfirmPaymentRequest(
        paymentMethod: paymentMethod,
        paymentReference: paymentReference,
        paymentGateway: paymentGateway,
      );

      final response = await _apiService.post(
        '/api/v1/bookings/$bookingId/confirm-payment',
        data: request.toJson(),
      );

      _logger.d('Confirm payment response: ${response.data}');

      final bookingResponse = BookingResponse.fromJson(response.data);

      _logger.i(
        'Payment confirmed for: ${bookingResponse.booking.bookingReference}',
      );

      return bookingResponse;
    } on DioException catch (e) {
      _logger.e('Failed to confirm payment: ${e.message}');

      if (e.response?.statusCode == 400) {
        final error =
            e.response?.data?['error'] ?? 'Payment confirmation failed';
        throw Exception(error);
      }

      throw ErrorHandler.handleError(e);
    } catch (e) {
      _logger.e('Unexpected error confirming payment: $e');
      throw Exception('Failed to confirm payment: $e');
    }
  }

  // ============================================================================
  // QR CODE
  // ============================================================================

  /// Get QR code data for a booking
  ///
  /// [bookingId] - The booking ID
  ///
  /// Returns QR code data string
  Future<String> getBookingQR(String bookingId) async {
    try {
      _logger.i('Fetching QR code for booking: $bookingId');

      final response = await _apiService.get('/api/v1/bookings/$bookingId/qr');

      _logger.d('Get QR response: ${response.data}');

      final qrCode = response.data['qr_code'] as String? ?? '';

      _logger.i('QR code fetched for booking: $bookingId');

      return qrCode;
    } on DioException catch (e) {
      _logger.e('Failed to get QR code: ${e.message}');
      throw ErrorHandler.handleError(e);
    } catch (e) {
      _logger.e('Unexpected error getting QR code: $e');
      throw Exception('Failed to get QR code: $e');
    }
  }
}
