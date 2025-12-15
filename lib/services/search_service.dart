import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../config/api_config.dart';
import '../models/search_models.dart';
import '../utils/error_handler.dart';
import 'api_service.dart';

/// Service for handling trip search operations
class SearchService {
  static final SearchService _instance = SearchService._internal();
  factory SearchService() => _instance;
  SearchService._internal();

  final ApiService _apiService = ApiService();
  final Logger _logger = Logger();

  /// Search for trips between two locations
  ///
  /// [from] - Origin location/stop name
  /// [to] - Destination location/stop name
  /// [datetime] - Optional departure datetime filter
  /// [limit] - Maximum number of results (default: 20)
  ///
  /// Returns [SearchResponse] with trip results
  Future<SearchResponse> searchTrips({
    required String from,
    required String to,
    DateTime? datetime,
    int limit = 20,
  }) async {
    try {
      _logger.i('Searching trips: $from → $to');

      final request = SearchRequest(
        from: from,
        to: to,
        datetime: datetime,
        limit: limit,
      );

      final jsonPayload = request.toJson();
      _logger.i('🔍 REQUEST PAYLOAD: $jsonPayload');
      _logger.i('🔍 FROM: "${jsonPayload['from']}"');
      _logger.i('🔍 TO: "${jsonPayload['to']}"');
      _logger.i('🔍 DATETIME: ${jsonPayload['datetime']}');
      _logger.i('🔍 LIMIT: ${jsonPayload['limit']}');
      _logger.i('🔍 ENDPOINT: ${ApiConfig.searchTripsEndpoint}');
      _logger.i('🔍 BASE URL: ${ApiConfig.baseUrl}');

      final response = await _apiService.post(
        ApiConfig.searchTripsEndpoint,
        data: jsonPayload,
      );

      _logger.d('Search response: ${response.data}');
      
      // Debug: Log master_route_id from raw results
      final rawResults = response.data['results'] as List<dynamic>?;
      if (rawResults != null && rawResults.isNotEmpty) {
        for (int i = 0; i < rawResults.length; i++) {
          final trip = rawResults[i] as Map<String, dynamic>;
          _logger.i('🔍 Trip $i master_route_id: ${trip['master_route_id']}');
        }
      }

      final searchResponse = SearchResponse.fromJson(response.data);

      _logger.i(
        'Search completed: ${searchResponse.results.length} results in ${searchResponse.searchTimeMs}ms',
      );

      return searchResponse;
    } on DioException catch (e) {
      _logger.e('Search failed: ${e.message}');
      throw ErrorHandler.handleError(e);
    } catch (e) {
      _logger.e('Unexpected error during search: $e');
      throw Exception('Failed to search trips: $e');
    }
  }

  /// Get popular routes for quick selection
  ///
  /// [limit] - Maximum number of routes to return (default: 10)
  ///
  /// Returns list of [PopularRoute]
  Future<List<PopularRoute>> getPopularRoutes({int limit = 10}) async {
    try {
      _logger.i('Fetching popular routes');

      final response = await _apiService.get(
        ApiConfig.popularRoutesEndpoint,
        queryParameters: {'limit': limit},
      );

      final routes = (response.data['routes'] as List<dynamic>?)
              ?.map((e) => PopularRoute.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      _logger.i('Fetched ${routes.length} popular routes');

      return routes;
    } on DioException catch (e) {
      _logger.e('Failed to get popular routes: ${e.message}');
      throw ErrorHandler.handleError(e);
    } catch (e) {
      _logger.e('Unexpected error getting popular routes: $e');
      throw Exception('Failed to get popular routes: $e');
    }
  }

  /// Get autocomplete suggestions for stop names
  ///
  /// [searchTerm] - Text to search for
  /// [limit] - Maximum number of suggestions (default: 10)
  ///
  /// Returns list of [StopAutocomplete]
  Future<List<StopAutocomplete>> getStopAutocomplete({
    required String searchTerm,
    int limit = 10,
  }) async {
    try {
      if (searchTerm.isEmpty || searchTerm.length < 2) {
        return [];
      }

      _logger.d('Getting autocomplete for: $searchTerm');

      final response = await _apiService.get(
        ApiConfig.autocompleteEndpoint,
        queryParameters: {
          'q': searchTerm,
          'limit': limit,
        },
      );

      final suggestions = (response.data['suggestions'] as List<dynamic>?)
              ?.map((e) => StopAutocomplete.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      _logger.d('Got ${suggestions.length} autocomplete suggestions');

      return suggestions;
    } on DioException catch (e) {
      _logger.w('Autocomplete request failed: ${e.message}');
      // Don't throw error for autocomplete - just return empty list
      return [];
    } catch (e) {
      _logger.w('Unexpected error in autocomplete: $e');
      return [];
    }
  }

  /// Check if search service is healthy
  ///
  /// Returns true if service is operational
  Future<bool> checkHealth() async {
    try {
      final response = await _apiService.get(ApiConfig.searchHealthEndpoint);
      return response.data['status'] == 'healthy';
    } catch (e) {
      _logger.e('Search health check failed: $e');
      return false;
    }
  }

  /// Get quick search suggestions based on user's search history
  /// This is a placeholder for future implementation with local storage
  Future<List<String>> getRecentSearches() async {
    // TODO: Implement with shared preferences
    return [];
  }

  /// Save a search to recent searches
  /// This is a placeholder for future implementation with local storage
  Future<void> saveRecentSearch(String from, String to) async {
    // TODO: Implement with shared preferences
    _logger.d('Saving recent search: $from → $to');
  }

  /// Clear recent search history
  Future<void> clearRecentSearches() async {
    // TODO: Implement with shared preferences
    _logger.d('Clearing recent searches');
  }
}
