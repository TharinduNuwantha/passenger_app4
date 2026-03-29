import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../models/lounge_booking_models.dart';
import '../utils/error_handler.dart';
import 'api_service.dart';

/// Service for handling lounge booking operations
class LoungeBookingService {
  static final LoungeBookingService _instance =
      LoungeBookingService._internal();
  factory LoungeBookingService() => _instance;
  LoungeBookingService._internal();

  final ApiService _apiService = ApiService();
  final Logger _logger = Logger();

  // ============================================================================
  // LOUNGE DISCOVERY (Marketplace)
  // ============================================================================

  /// Get all active product categories
  ///
  /// Returns list of [LoungeCategory]
  Future<List<LoungeCategory>> getCategories() async {
    try {
      _logger.i('Fetching lounge marketplace categories');

      final response = await _apiService.get(
        '/api/v1/lounge-marketplace/categories',
      );

      _logger.d('Categories response: ${response.data}');

      final categories =
          (response.data['categories'] as List<dynamic>?)
              ?.map((e) => LoungeCategory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      _logger.i('Fetched ${categories.length} categories');

      return categories;
    } on DioException catch (e) {
      _logger.e('Failed to get categories: ${e.message}');
      throw ErrorHandler.handleError(e);
    } catch (e) {
      _logger.e('Unexpected error getting categories: $e');
      throw Exception('Failed to get categories: $e');
    }
  }

  /// Get products for a specific lounge
  ///
  /// [loungeId] - The lounge ID
  /// [categoryId] - Optional filter by category
  ///
  /// Returns list of [LoungeProduct]
  Future<List<LoungeProduct>> getLoungeProducts(
    String loungeId, {
    String? categoryId,
  }) async {
    try {
      _logger.i('Fetching products for lounge: $loungeId');

      final queryParams = <String, dynamic>{};
      if (categoryId != null) {
        queryParams['category_id'] = categoryId;
      }

      final response = await _apiService.get(
        '/api/v1/lounges/$loungeId/products',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      _logger.d('Products response: ${response.data}');

      final products =
          (response.data['products'] as List<dynamic>?)
              ?.map((e) => LoungeProduct.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      _logger.i('Fetched ${products.length} products');

      return products;
    } on DioException catch (e) {
      _logger.e('Failed to get products: ${e.message}');
      throw ErrorHandler.handleError(e);
    } catch (e) {
      _logger.e('Unexpected error getting products: $e');
      throw Exception('Failed to get products: $e');
    }
  }

  /// Get lounge details by ID
  ///
  /// [loungeId] - The lounge ID
  ///
  /// Returns [Lounge] with full details
  Future<Lounge> getLoungeById(String loungeId) async {
    try {
      _logger.i('Fetching lounge: $loungeId');

      final response = await _apiService.get('/api/v1/lounges/$loungeId');

      _logger.d('Lounge response: ${response.data}');

      final lounge = Lounge.fromJson(
        response.data['lounge'] as Map<String, dynamic>,
      );

      _logger.i('Fetched lounge: ${lounge.loungeName}');

      return lounge;
    } on DioException catch (e) {
      _logger.e('Failed to get lounge: ${e.message}');

      if (e.response?.statusCode == 404) {
        throw Exception('Lounge not found');
      }

      throw ErrorHandler.handleError(e);
    } catch (e) {
      _logger.e('Unexpected error getting lounge: $e');
      throw Exception('Failed to get lounge details: $e');
    }
  }

  /// Active pickup locations with prices from [lounge_transport_locations]
  /// joined with [lounge_transport_location_prices].
  Future<List<LoungeTransportLocationOption>> getLoungeTransportOptions(
    String loungeId,
  ) async {
    try {
      _logger.i('Fetching transport options for lounge: $loungeId');

      var response;
      try {
        response = await _apiService.get(
          '/api/v1/lounges/$loungeId/transport-options',
        );
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          _logger.w('Primary transport path failed (404), trying fallback...');
          // Try fallback path added to backend
          response = await _apiService.get(
            '/api/v1/lounges/transport/$loungeId',
          );
        } else {
          rethrow;
        }
      }

      final list =
          (response.data['locations'] as List<dynamic>?)
              ?.map(
                (e) => LoungeTransportLocationOption.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [];

      _logger.i('Fetched ${list.length} transport location(s)');
      return list;
    } on DioException catch (e) {
      _logger.e(
        'Failed to get transport options (lounge $loungeId): ${e.message}',
      );
      final detail = ErrorHandler.handleError(e);
      throw Exception('Transport options failed (lounge $loungeId): $detail');
    } catch (e) {
      _logger.e(
        'Unexpected error getting transport options (lounge $loungeId): $e',
      );
      throw Exception(
        'Transport options failed (lounge $loungeId): $e',
      );
    }
  }

  /// Search/filter lounges (for marketplace)
  ///
  /// [state] - Optional filter by state/province
  /// [limit] - Optional limit number of results (for initial load)
  /// [routeId] - Optional filter by route
  /// [city] - Optional filter by city
  ///
  /// Returns list of [Lounge]
  Future<List<Lounge>> searchLounges({
    String? state,
    int? limit,
    String? routeId,
    String? city,
    bool includeAllStatuses = false,
    String? status,
  }) async {
    try {
      _logger.i(
        'Searching lounges (state: $state, limit: $limit, route: $routeId, city: $city)',
      );

      final queryParams = <String, dynamic>{};
      if (state != null && state.isNotEmpty) {
        queryParams['state'] = state;
      }
      if (limit != null) {
        queryParams['limit'] = limit;
      }
      if (routeId != null) {
        queryParams['route_id'] = routeId;
      }
      if (city != null) {
        queryParams['city'] = city;
      }
      if (includeAllStatuses) {
        queryParams['include_all'] = 'true';
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final response = await _apiService.get(
        '/api/v1/lounges/active',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      _logger.d('Lounges response: ${response.data}');

      final lounges =
          (response.data['lounges'] as List<dynamic>?)
              ?.map((e) => Lounge.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      _logger.i('Found ${lounges.length} lounges');

      return lounges;
    } on DioException catch (e) {
      _logger.e('Failed to search lounges: ${e.message}');
      throw ErrorHandler.handleError(e);
    } catch (e) {
      _logger.e('Unexpected error searching lounges: $e');
      throw Exception('Failed to search lounges: $e');
    }
  }

  /// Get list of available states/provinces with lounges
  ///
  /// Returns list of state names
  Future<List<String>> getAvailableStates() async {
    try {
      _logger.i('Fetching available lounge states');

      final response = await _apiService.get('/api/v1/lounges/states');

      _logger.d('States response: ${response.data}');

      final states =
          (response.data['states'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      _logger.i('Found ${states.length} states with lounges');

      return states;
    } on DioException catch (e) {
      _logger.e('Failed to get available states: ${e.message}');
      // Return empty list instead of throwing - states are optional
      return [];
    } catch (e) {
      _logger.e('Unexpected error getting available states: $e');
      return [];
    }
  }

  /// Get lounges that serve a specific bus stop
  ///
  /// [stopId] - The stop ID (boarding or alighting stop)
  ///
  /// Returns list of [Lounge] that serve this stop
  Future<List<Lounge>> getLoungesByStop(String stopId) async {
    try {
      _logger.i('Fetching lounges for stop: $stopId');

      final response = await _apiService.get('/api/v1/lounges/by-stop/$stopId');

      _logger.d('Lounges by stop response: ${response.data}');

      final lounges =
          (response.data['lounges'] as List<dynamic>?)
              ?.map((e) => Lounge.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      _logger.i('Found ${lounges.length} lounges for stop $stopId');

      return lounges;
    } on DioException catch (e) {
      _logger.e('Failed to get lounges by stop: ${e.message}');
      // Return empty list instead of throwing - no lounges is valid
      return [];
    } catch (e) {
      _logger.e('Unexpected error getting lounges by stop: $e');
      return [];
    }
  }

  /// Get lounges near a passenger's selected stop (within 2 stops distance)
  ///
  /// [routeId] - The master route ID
  /// [stopId] - The passenger's selected stop ID (boarding or alighting)
  /// [maxDistance] - Max stop distance (default 2)
  ///
  /// Returns list of [Lounge] near the passenger's stop
  Future<List<Lounge>> getLoungesNearStop(
    String routeId,
    String stopId, {
    int maxDistance = 2,
  }) async {
    try {
      _logger.i(
        'Fetching lounges near stop: $stopId on route: $routeId (max distance: $maxDistance)',
      );

      final response = await _apiService.get(
        '/api/v1/lounges/near-stop/$routeId/$stopId?distance=$maxDistance',
      );

      _logger.d('Lounges near stop response: ${response.data}');

      final lounges =
          (response.data['lounges'] as List<dynamic>?)
              ?.map((e) => Lounge.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      _logger.i('Found ${lounges.length} lounges near stop $stopId');

      return lounges;
    } on DioException catch (e) {
      _logger.e('Failed to get lounges near stop: ${e.message}');
      return [];
    } catch (e) {
      _logger.e('Unexpected error getting lounges near stop: $e');
      return [];
    }
  }

  /// Get lounges that serve a specific route
  ///
  /// [routeId] - The master route ID
  ///
  /// Returns list of [Lounge] that serve this route
  Future<List<Lounge>> getLoungesByRoute(String routeId) async {
    try {
      _logger.i('Fetching lounges for route: $routeId');

      final response = await _apiService.get(
        '/api/v1/lounges/by-route/$routeId',
      );

      _logger.d('Lounges by route response: ${response.data}');

      final lounges =
          (response.data['lounges'] as List<dynamic>?)
              ?.map((e) => Lounge.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      _logger.i('Found ${lounges.length} lounges for route $routeId');

      return lounges;
    } on DioException catch (e) {
      _logger.e('Failed to get lounges by route: ${e.message}');
      // Return empty list instead of throwing - no lounges is valid
      return [];
    } catch (e) {
      _logger.e('Unexpected error getting lounges by route: $e');
      return [];
    }
  }

  /// Get boarding lounges filtered by the origin city of a given master route.
  ///
  /// The backend looks up [routeId] → master_routes.origin_city, then joins
  /// lounge_routes → lounges and returns only lounges near the departure city.
  /// Results are sorted by average_rating DESC, price_1_hour ASC.
  ///
  /// [routeId] - The master route ID (used server-side to resolve origin_city)
  ///
  /// Returns list of [Lounge] near the route's departure city
  Future<List<Lounge>> getBoardingLoungesByRouteOrigin(String routeId) async {
    try {
      _logger.i(
        'Fetching boarding lounges for route origin: $routeId',
      );

      final response = await _apiService.get(
        '/api/v1/lounges/boarding-by-origin/$routeId',
      );

      _logger.d('Boarding lounges by origin response: ${response.data}');

      final lounges =
          (response.data['lounges'] as List<dynamic>?)
              ?.map((e) => Lounge.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      _logger.i(
        'Found ${lounges.length} boarding lounges near route origin',
      );

      return lounges;
    } on DioException catch (e) {
      _logger.e('Failed to get boarding lounges by route origin: ${e.message}');
      return [];
    } catch (e) {
      _logger.e('Unexpected error getting boarding lounges by route origin: $e');
      return [];
    }
  }

  /// Get boarding lounges filtered by origin city name.
  ///
  /// Calls GET /api/v1/lounges/by-origin-city?city=<originCity> which runs:
  ///   SELECT l.* FROM lounges l
  ///   JOIN lounge_routes lr ON l.id = lr.lounge_id
  ///   JOIN master_routes mr ON lr.master_route_id = mr.id
  ///   WHERE mr.origin_city = :origin_city
  ///   GROUP BY l.id
  ///   ORDER BY l.average_rating DESC, l.price_1_hour ASC
  ///
  /// [originCity] - The city the user selected as the "From" location
  ///
  /// Returns list of [Lounge] near the departure city
  Future<List<Lounge>> getLoungesByOriginCity(String originCity) async {
    try {
      _logger.i('Fetching lounges for origin city: $originCity');

      final response = await _apiService.get(
        '/api/v1/lounges/by-origin-city',
        queryParameters: {'city': originCity},
      );

      _logger.d('Lounges by origin city response: ${response.data}');

      final lounges =
          (response.data['lounges'] as List<dynamic>?)
              ?.map((e) => Lounge.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      _logger.i(
        'Found ${lounges.length} lounges for origin city $originCity',
      );

      return lounges;
    } on DioException catch (e) {
      _logger.e('Failed to get lounges by origin city: ${e.message}');
      return [];
    } catch (e) {
      _logger.e('Unexpected error getting lounges by origin city: $e');
      return [];
    }
  }

  // ============================================================================
  // LOUNGE BOOKINGS
  // ============================================================================

  /// Create a new lounge booking
  ///
  /// [request] - The booking request with lounge, pricing, and guest details
  ///
  /// Returns [LoungeBooking] with booking details
  Future<LoungeBooking> createBooking(
    CreateLoungeBookingRequest request,
  ) async {
    try {
      _logger.i('Creating lounge booking for lounge: ${request.loungeId}');
      _logger.i(
        'Guests: ${request.numberOfGuests}, Type: ${request.pricingType.toJson()}',
      );

      final response = await _apiService.post(
        '/api/v1/lounge-bookings',
        data: request.toJson(),
      );

      _logger.d('Create booking response: ${response.data}');

      final booking = LoungeBooking.fromJson(
        response.data['booking'] as Map<String, dynamic>,
      );

      _logger.i('Booking created: ${booking.bookingReference}');

      return booking;
    } on DioException catch (e) {
      _logger.e('Failed to create lounge booking: ${e.message}');

      if (e.response?.statusCode == 400) {
        final error = e.response?.data?['error'] ?? 'Invalid booking request';
        throw Exception(error);
      }
      if (e.response?.statusCode == 404) {
        throw Exception('Lounge not found');
      }

      throw ErrorHandler.handleError(e);
    } catch (e) {
      _logger.e('Unexpected error creating lounge booking: $e');
      throw Exception('Failed to create lounge booking: $e');
    }
  }

  /// Get user's lounge bookings with optional filter and pagination
  ///
  /// [status] - Filter by booking status
  /// [page] - Page number for pagination (1-indexed)
  /// [limit] - Items per page
  ///
  /// Returns list of [LoungeBooking]
  Future<List<LoungeBooking>> getMyBookings({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      _logger.i(
        'Fetching user lounge bookings (status: $status, page: $page, limit: $limit)',
      );

      final queryParams = <String, dynamic>{'page': page, 'limit': limit};
      if (status != null) {
        queryParams['status'] = status;
      }

      final response = await _apiService.get(
        '/api/v1/lounge-bookings',
        queryParameters: queryParams,
      );

      _logger.d('Get bookings response: ${response.data}');

      final bookings =
          (response.data['bookings'] as List<dynamic>?)
              ?.map((e) => LoungeBooking.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      _logger.i('Fetched ${bookings.length} lounge bookings');

      return bookings;
    } on DioException catch (e) {
      _logger.e('Failed to get lounge bookings: ${e.message}');
      throw ErrorHandler.handleError(e);
    } catch (e) {
      _logger.e('Unexpected error getting lounge bookings: $e');
      throw Exception('Failed to get lounge bookings: $e');
    }
  }

  /// Get upcoming lounge bookings
  ///
  /// Returns list of [LoungeBooking] with active status
  Future<List<LoungeBooking>> getUpcomingBookings({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      _logger.i(
        'Fetching upcoming lounge bookings (page: $page, limit: $limit)',
      );

      final response = await _apiService.get(
        '/api/v1/lounge-bookings/upcoming',
        queryParameters: {'page': page, 'limit': limit},
      );

      _logger.d('Upcoming bookings response: ${response.data}');

      final bookings =
          (response.data['bookings'] as List<dynamic>?)
              ?.map((e) => LoungeBooking.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      _logger.i('Fetched ${bookings.length} upcoming lounge bookings');

      return bookings;
    } on DioException catch (e) {
      _logger.e('Failed to get upcoming lounge bookings: ${e.message}');
      throw ErrorHandler.handleError(e);
    } catch (e) {
      _logger.e('Unexpected error getting upcoming lounge bookings: $e');
      throw Exception('Failed to get upcoming lounge bookings: $e');
    }
  }

  /// Get lounge booking by ID
  ///
  /// [bookingId] - The booking ID
  ///
  /// Returns [LoungeBooking] with full details including guests and pre-orders
  Future<LoungeBooking> getBookingById(String bookingId) async {
    try {
      _logger.i('Fetching lounge booking: $bookingId');

      final response = await _apiService.get(
        '/api/v1/lounge-bookings/$bookingId',
      );

      _logger.d('Get booking response: ${response.data}');

      final booking = LoungeBooking.fromJson(
        response.data as Map<String, dynamic>,
      );

      _logger.i('Fetched booking: ${booking.bookingReference}');

      return booking;
    } on DioException catch (e) {
      _logger.e('Failed to get lounge booking: ${e.message}');

      if (e.response?.statusCode == 404) {
        throw Exception('Booking not found');
      }

      throw ErrorHandler.handleError(e);
    } catch (e) {
      _logger.e('Unexpected error getting lounge booking: $e');
      throw Exception('Failed to get booking details: $e');
    }
  }

  /// Get lounge booking by reference
  ///
  /// [reference] - The booking reference (e.g., LB-20250101-ABC123)
  ///
  /// Returns [LoungeBooking] with full details
  Future<LoungeBooking> getBookingByReference(String reference) async {
    try {
      _logger.i('Fetching lounge booking by reference: $reference');

      final response = await _apiService.get(
        '/api/v1/lounge-bookings/reference/$reference',
      );

      _logger.d('Get booking response: ${response.data}');

      final booking = LoungeBooking.fromJson(
        response.data as Map<String, dynamic>,
      );

      _logger.i('Fetched booking: ${booking.bookingReference}');

      return booking;
    } on DioException catch (e) {
      _logger.e('Failed to get lounge booking by reference: ${e.message}');

      if (e.response?.statusCode == 404) {
        throw Exception('Booking not found');
      }

      throw ErrorHandler.handleError(e);
    } catch (e) {
      _logger.e('Unexpected error getting lounge booking: $e');
      throw Exception('Failed to get booking details: $e');
    }
  }

  /// Cancel a lounge booking
  ///
  /// [bookingId] - The booking ID to cancel
  /// [reason] - Optional cancellation reason
  Future<void> cancelBooking(String bookingId, {String? reason}) async {
    try {
      _logger.i('Cancelling lounge booking: $bookingId');

      final data = <String, dynamic>{};
      if (reason != null) {
        data['reason'] = reason;
      }

      await _apiService.post(
        '/api/v1/lounge-bookings/$bookingId/cancel',
        data: data.isNotEmpty ? data : null,
      );

      _logger.i('Lounge booking cancelled: $bookingId');
    } on DioException catch (e) {
      _logger.e('Failed to cancel lounge booking: ${e.message}');

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
      _logger.e('Unexpected error cancelling lounge booking: $e');
      throw Exception('Failed to cancel booking: $e');
    }
  }

  // ============================================================================
  // LOUNGE ORDERS (In-lounge ordering)
  // ============================================================================

  /// Create a new in-lounge order
  ///
  /// [request] - The order request with lounge, items, and optional booking link
  ///
  /// Returns [LoungeOrder] with order details
  Future<LoungeOrder> createOrder(CreateLoungeOrderRequest request) async {
    try {
      _logger.i('Creating lounge order for lounge: ${request.loungeId}');
      _logger.i('Items: ${request.items.length}');

      final response = await _apiService.post(
        '/api/v1/lounge-orders',
        data: request.toJson(),
      );

      _logger.d('Create order response: ${response.data}');

      final order = LoungeOrder.fromJson(
        response.data['order'] as Map<String, dynamic>,
      );

      _logger.i('Order created: ${order.orderNumber}');

      return order;
    } on DioException catch (e) {
      _logger.e('Failed to create lounge order: ${e.message}');

      if (e.response?.statusCode == 400) {
        final error = e.response?.data?['error'] ?? 'Invalid order request';
        throw Exception(error);
      }
      if (e.response?.statusCode == 404) {
        throw Exception('Lounge or product not found');
      }

      throw ErrorHandler.handleError(e);
    } catch (e) {
      _logger.e('Unexpected error creating lounge order: $e');
      throw Exception('Failed to create order: $e');
    }
  }

  /// Get orders for a specific lounge booking
  ///
  /// [bookingId] - The lounge booking ID
  ///
  /// Returns list of [LoungeOrder]
  Future<List<LoungeOrder>> getBookingOrders(String bookingId) async {
    try {
      _logger.i('Fetching orders for booking: $bookingId');

      final response = await _apiService.get(
        '/api/v1/lounge-bookings/$bookingId/orders',
      );

      _logger.d('Get orders response: ${response.data}');

      final orders =
          (response.data['orders'] as List<dynamic>?)
              ?.map((e) => LoungeOrder.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      _logger.i('Fetched ${orders.length} orders');

      return orders;
    } on DioException catch (e) {
      // Handle 404 gracefully - lounge-only bookings without pre-orders won't have an orders endpoint
      if (e.response?.statusCode == 404) {
        _logger.i(
          'No orders endpoint for booking (404) - returning empty list',
        );
        return [];
      }
      _logger.e('Failed to get booking orders: ${e.message}');
      throw ErrorHandler.handleError(e);
    } catch (e) {
      _logger.e('Unexpected error getting booking orders: $e');
      throw Exception('Failed to get orders: $e');
    }
  }
}
