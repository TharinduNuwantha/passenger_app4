import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../models/booking_intent_models.dart';
import '../utils/error_handler.dart';
import 'api_service.dart';

/// Service for Booking Orchestration (Intent → Payment → Confirm)
///
/// This service handles the new booking flow:
/// 1. Create Intent - Holds seats/lounges for 10 minutes
/// 2. Initiate Payment - Get payment gateway URL
/// 3. Confirm Booking - Creates actual bookings after payment
class BookingIntentService {
  static final BookingIntentService _instance =
      BookingIntentService._internal();
  factory BookingIntentService() => _instance;
  BookingIntentService._internal();

  final ApiService _apiService = ApiService();
  final Logger _logger = Logger();

  // ============================================================================
  // CREATE INTENT
  // ============================================================================

  /// Create a booking intent with TTL-based seat holding
  ///
  /// [request] - The intent request with bus/lounge details
  ///
  /// Returns [BookingIntentResponse] with intent ID and expiry time
  ///
  /// Throws [PartialAvailabilityException] if some items are unavailable
  Future<BookingIntentResponse> createIntent(
    CreateBookingIntentRequest request,
  ) async {
    try {
      _logger.i('Creating booking intent: ${request.intentType.toJson()}');
      if (request.bus != null) {
        _logger.i('Trip: ${request.bus!.scheduledTripId}');
        _logger.i('Seats: ${request.bus!.seats.length}');
      }

      final response = await _apiService.post(
        '/api/v1/booking/intent',
        data: request.toJson(),
      );

      _logger.d('Create intent response: ${response.data}');

      final intentResponse = BookingIntentResponse.fromJson(response.data);

      _logger.i('Intent created: ${intentResponse.intentId}');
      _logger.i('Expires at: ${intentResponse.expiresAt}');
      _logger.i('Total: ${intentResponse.pricing.formattedTotal}');

      return intentResponse;
    } on DioException catch (e) {
      _logger.e('Failed to create intent: ${e.message}');

      // Handle partial availability (409 Conflict)
      if (e.response?.statusCode == 409) {
        final errorData = e.response?.data as Map<String, dynamic>?;
        if (errorData != null && errorData['error'] == 'partial_availability') {
          throw PartialAvailabilityException(
            PartialAvailabilityError.fromJson(errorData),
          );
        }
      }

      // Handle other 400 errors
      if (e.response?.statusCode == 400) {
        final error = e.response?.data?['error'] ?? 'Invalid request';
        throw Exception(error);
      }

      throw ErrorHandler.handleError(e);
    } catch (e) {
      if (e is PartialAvailabilityException) rethrow;
      _logger.e('Unexpected error creating intent: $e');
      throw Exception('Failed to create booking intent: $e');
    }
  }

  // ============================================================================
  // GET INTENT STATUS
  // ============================================================================

  /// Get current status of a booking intent
  ///
  /// [intentId] - The intent ID
  ///
  /// Returns [IntentStatusResponse] with current status and time remaining
  Future<IntentStatusResponse> getIntentStatus(String intentId) async {
    try {
      _logger.i('Getting intent status: $intentId');

      final response = await _apiService.get(
        '/api/v1/booking/intent/$intentId',
      );

      _logger.d('Intent status response: ${response.data}');

      final statusResponse = IntentStatusResponse.fromJson(response.data);

      _logger.i('Intent status: ${statusResponse.status.displayName}');
      _logger.i('Time remaining: ${statusResponse.formattedRemainingTime}');

      return statusResponse;
    } on DioException catch (e) {
      _logger.e('Failed to get intent status: ${e.message}');

      if (e.response?.statusCode == 404) {
        throw Exception('Intent not found');
      }

      throw ErrorHandler.handleError(e);
    } catch (e) {
      _logger.e('Unexpected error getting intent status: $e');
      throw Exception('Failed to get intent status: $e');
    }
  }

  // ============================================================================
  // ADD LOUNGE TO INTENT
  // ============================================================================

  /// Add lounge bookings to an existing bus-only intent
  ///
  /// This is used when the user selects lounges after seats are already held.
  /// The intent is updated to include lounge data and the hold timer is extended.
  ///
  /// [intentId] - The existing intent ID
  /// [preTripLounge] - Optional boarding lounge data
  /// [postTripLounge] - Optional destination lounge data
  ///
  /// Returns updated [BookingIntentResponse] with new totals and extended expiry
  Future<BookingIntentResponse> addLoungeToIntent({
    required String intentId,
    LoungeIntentRequest? preTripLounge,
    LoungeIntentRequest? postTripLounge,
  }) async {
    try {
      _logger.i('Adding lounge to intent: $intentId');
      if (preTripLounge != null) {
        _logger.i('Boarding lounge: ${preTripLounge.loungeName}');
      }
      if (postTripLounge != null) {
        _logger.i('Destination lounge: ${postTripLounge.loungeName}');
      }

      final data = <String, dynamic>{};
      if (preTripLounge != null) {
        data['pre_trip_lounge'] = preTripLounge.toJson();
      }
      if (postTripLounge != null) {
        data['post_trip_lounge'] = postTripLounge.toJson();
      }

      final response = await _apiService.patch(
        '/api/v1/booking/intent/$intentId/add-lounge',
        data: data,
      );

      _logger.d('Add lounge response: ${response.data}');

      final intentResponse = BookingIntentResponse.fromJson(response.data);

      _logger.i(
        'Lounge added, new total: ${intentResponse.pricing.formattedTotal}',
      );
      _logger.i('Extended expiry: ${intentResponse.expiresAt}');

      return intentResponse;
    } on DioException catch (e) {
      _logger.e('Failed to add lounge: ${e.message}');

      if (e.response?.statusCode == 400) {
        final error = e.response?.data?['error'] ?? 'Cannot add lounge';
        throw Exception(error);
      }
      if (e.response?.statusCode == 404) {
        throw Exception('Intent not found');
      }
      if (e.response?.statusCode == 409) {
        throw Exception('Lounge capacity not available');
      }

      throw ErrorHandler.handleError(e);
    } catch (e) {
      _logger.e('Unexpected error adding lounge: $e');
      throw Exception('Failed to add lounge: $e');
    }
  }

  // ============================================================================
  // INITIATE PAYMENT
  // ============================================================================

  /// Initiate payment for a booking intent
  ///
  /// [intentId] - The intent ID
  ///
  /// Returns [InitiatePaymentResponse] with payment gateway details
  Future<InitiatePaymentResponse> initiatePayment(String intentId) async {
    try {
      _logger.i('Initiating payment for intent: $intentId');

      final response = await _apiService.post(
        '/api/v1/booking/intent/$intentId/initiate-payment',
      );

      _logger.d('Initiate payment response: ${response.data}');

      final paymentResponse = InitiatePaymentResponse.fromJson(response.data);

      _logger.i('Payment reference: ${paymentResponse.paymentReference}');
      _logger.i('Amount: ${paymentResponse.formattedAmount}');
      _logger.i('Gateway: ${paymentResponse.paymentGateway}');

      return paymentResponse;
    } on DioException catch (e) {
      _logger.e('Failed to initiate payment: ${e.message}');

      if (e.response?.statusCode == 400) {
        final error = e.response?.data?['error'] ?? 'Intent expired or invalid';
        throw Exception(error);
      }
      if (e.response?.statusCode == 404) {
        throw Exception('Intent not found');
      }

      throw ErrorHandler.handleError(e);
    } catch (e) {
      _logger.e('Unexpected error initiating payment: $e');
      throw Exception('Failed to initiate payment: $e');
    }
  }

  // ============================================================================
  // CONFIRM BOOKING
  // ============================================================================

  /// Confirm booking after successful payment
  ///
  /// [intentId] - The intent ID
  /// [paymentReference] - Payment reference from gateway
  ///
  /// Returns [ConfirmBookingResponse] with booking references
  Future<ConfirmBookingResponse> confirmBooking({
    required String intentId,
    required String paymentReference,
  }) async {
    try {
      _logger.i('Confirming booking for intent: $intentId');
      _logger.i('Payment reference: $paymentReference');

      final request = ConfirmIntentRequest(
        intentId: intentId,
        paymentReference: paymentReference,
      );

      final response = await _apiService.post(
        '/api/v1/booking/confirm',
        data: request.toJson(),
      );

      _logger.d('Confirm booking response: ${response.data}');

      final confirmResponse = ConfirmBookingResponse.fromJson(response.data);

      _logger.i('Booking confirmed: ${confirmResponse.masterReference}');
      if (confirmResponse.busBooking != null) {
        _logger.i('Bus booking: ${confirmResponse.busBooking!.reference}');
      }
      // Log lounge booking details
      if (confirmResponse.preLoungeBooking != null) {
        _logger.i(
          'Pre-lounge booking: ${confirmResponse.preLoungeBooking!.reference}, QR: ${confirmResponse.preLoungeBooking!.qrCode}',
        );
      } else {
        _logger.w('No pre-lounge booking in confirm response');
      }
      if (confirmResponse.postLoungeBooking != null) {
        _logger.i(
          'Post-lounge booking: ${confirmResponse.postLoungeBooking!.reference}, QR: ${confirmResponse.postLoungeBooking!.qrCode}',
        );
      }

      return confirmResponse;
    } on DioException catch (e) {
      _logger.e('Failed to confirm booking: ${e.message}');

      if (e.response?.statusCode == 400) {
        final error = e.response?.data?['error'];
        if (error == 'intent_expired') {
          throw IntentExpiredException(
            e.response?.data?['message'] ?? 'Intent has expired',
          );
        }
        throw Exception(error ?? 'Booking confirmation failed');
      }
      if (e.response?.statusCode == 404) {
        throw Exception('Intent not found');
      }
      if (e.response?.statusCode == 409) {
        throw SeatsNoLongerAvailableException(
          'Selected seats are no longer available',
        );
      }

      throw ErrorHandler.handleError(e);
    } catch (e) {
      if (e is IntentExpiredException || e is SeatsNoLongerAvailableException) {
        rethrow;
      }
      _logger.e('Unexpected error confirming booking: $e');
      throw Exception('Failed to confirm booking: $e');
    }
  }

  // ============================================================================
  // CANCEL INTENT
  // ============================================================================

  /// Cancel a booking intent and release all holds
  ///
  /// [intentId] - The intent ID to cancel
  Future<void> cancelIntent(String intentId) async {
    try {
      _logger.i('Cancelling intent: $intentId');

      await _apiService.post('/api/v1/booking/intent/$intentId/cancel');

      _logger.i('Intent cancelled successfully');
    } on DioException catch (e) {
      _logger.e('Failed to cancel intent: ${e.message}');

      if (e.response?.statusCode == 400) {
        final error = e.response?.data?['error'] ?? 'Cannot cancel this intent';
        throw Exception(error);
      }
      if (e.response?.statusCode == 404) {
        throw Exception('Intent not found');
      }

      throw ErrorHandler.handleError(e);
    } catch (e) {
      _logger.e('Unexpected error cancelling intent: $e');
      throw Exception('Failed to cancel intent: $e');
    }
  }

  // ============================================================================
  // GET MY INTENTS
  // ============================================================================

  /// Get list of user's booking intents
  ///
  /// [limit] - Number of results (default 20)
  /// [offset] - Pagination offset
  Future<List<BookingIntentListItem>> getMyIntents({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      _logger.i('Fetching my intents (limit: $limit, offset: $offset)');

      final response = await _apiService.get(
        '/api/v1/booking/intents',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      _logger.d('Get intents response: ${response.data}');

      final intents =
          (response.data['intents'] as List<dynamic>?)
              ?.map(
                (e) =>
                    BookingIntentListItem.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [];

      _logger.i('Fetched ${intents.length} intents');

      return intents;
    } on DioException catch (e) {
      _logger.e('Failed to get intents: ${e.message}');
      throw ErrorHandler.handleError(e);
    } catch (e) {
      _logger.e('Unexpected error getting intents: $e');
      throw Exception('Failed to get intents: $e');
    }
  }
}

// ============================================================================
// LIST ITEM MODEL (for my intents)
// ============================================================================

/// Summary item for intent list
class BookingIntentListItem {
  final String id;
  final String? userId;
  final IntentType intentType;
  final BookingIntentStatus status;
  final double busFare;
  final double preLoungeFare;
  final double postLoungeFare;
  final double totalAmount;
  final String currency;
  final DateTime expiresAt;
  final DateTime createdAt;

  BookingIntentListItem({
    required this.id,
    this.userId,
    required this.intentType,
    required this.status,
    required this.busFare,
    required this.preLoungeFare,
    required this.postLoungeFare,
    required this.totalAmount,
    required this.currency,
    required this.expiresAt,
    required this.createdAt,
  });

  factory BookingIntentListItem.fromJson(Map<String, dynamic> json) {
    return BookingIntentListItem(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      intentType: IntentType.fromJson(json['intent_type'] as String?),
      status: BookingIntentStatus.fromJson(json['status'] as String?),
      busFare: (json['bus_fare'] as num?)?.toDouble() ?? 0.0,
      preLoungeFare: (json['pre_lounge_fare'] as num?)?.toDouble() ?? 0.0,
      postLoungeFare: (json['post_lounge_fare'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'LKR',
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  String get formattedTotal => '$currency ${totalAmount.toStringAsFixed(2)}';
}

// ============================================================================
// CUSTOM EXCEPTIONS
// ============================================================================

/// Exception for partial availability
class PartialAvailabilityException implements Exception {
  final PartialAvailabilityError error;

  PartialAvailabilityException(this.error);

  @override
  String toString() => error.displayMessage;
}

/// Exception when intent has expired
class IntentExpiredException implements Exception {
  final String message;

  IntentExpiredException(this.message);

  @override
  String toString() => message;
}

/// Exception when seats are no longer available
class SeatsNoLongerAvailableException implements Exception {
  final String message;

  SeatsNoLongerAvailableException(this.message);

  @override
  String toString() => message;
}
