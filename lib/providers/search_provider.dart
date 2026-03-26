import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/search_models.dart';
import '../services/search_service.dart';

/// Provider for managing trip search state
class SearchProvider with ChangeNotifier {
  final SearchService _searchService = SearchService();
  final Logger _logger = Logger();

  // Search state
  bool _isSearching = false;
  SearchResponse? _searchResponse;
  String? _errorMessage;
  List<PopularRoute> _popularRoutes = [];
  bool _loadingPopularRoutes = false;

  // Autocomplete state
  List<StopAutocomplete> _fromStopSuggestions = [];
  List<StopAutocomplete> _toStopSuggestions = [];
  bool _loadingFromSuggestions = false;
  bool _loadingToSuggestions = false;

  // Getters
  bool get isSearching => _isSearching;
  SearchResponse? get searchResponse => _searchResponse;
  String? get errorMessage => _errorMessage;
  List<TripResult> get tripResults => _searchResponse?.results ?? [];
  bool get hasResults => tripResults.isNotEmpty;
  List<PopularRoute> get popularRoutes => _popularRoutes;
  bool get loadingPopularRoutes => _loadingPopularRoutes;
  List<StopAutocomplete> get fromStopSuggestions => _fromStopSuggestions;
  List<StopAutocomplete> get toStopSuggestions => _toStopSuggestions;
  bool get loadingFromSuggestions => _loadingFromSuggestions;
  bool get loadingToSuggestions => _loadingToSuggestions;

  /// Search for trips
  Future<void> searchTrips({
    required String from,
    required String to,
    DateTime? datetime,
    int limit = 20,
  }) async {
    _isSearching = true;
    _errorMessage = null;
    _searchResponse = null;
    notifyListeners();

    try {
      _logger.i('Searching trips: $from → $to');

      final response = await _searchService.searchTrips(
        from: from,
        to: to,
        datetime: datetime,
        limit: limit,
      );

      _searchResponse = response;
      _isSearching = false;

      if (!response.isSuccess) {
        _errorMessage = response.message;
      }

      // Save to recent searches
      await _searchService.saveRecentSearch(from, to);

      notifyListeners();

      _logger.i(
        'Search completed: ${response.results.length} results, status: ${response.status}',
      );
    } catch (e) {
      _logger.e('Search error: $e');
      _errorMessage = e.toString();
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Load popular routes
  Future<void> loadPopularRoutes({int limit = 10}) async {
    _loadingPopularRoutes = true;
    notifyListeners();

    try {
      _popularRoutes = await _searchService.getPopularRoutes(limit: limit);
      _loadingPopularRoutes = false;
      notifyListeners();

      _logger.i('Loaded ${_popularRoutes.length} popular routes');
    } catch (e) {
      _logger.e('Error loading popular routes: $e');
      _loadingPopularRoutes = false;
      notifyListeners();
    }
  }

  /// Get autocomplete suggestions for FROM field
  Future<void> getFromStopSuggestions(String searchTerm) async {
    if (searchTerm.isEmpty || searchTerm.length < 2) {
      _fromStopSuggestions = [];
      notifyListeners();
      return;
    }

    _loadingFromSuggestions = true;
    notifyListeners();

    try {
      _fromStopSuggestions = await _searchService.getStopAutocomplete(
        searchTerm: searchTerm,
        limit: 10,
      );
      _loadingFromSuggestions = false;
      notifyListeners();
    } catch (e) {
      _logger.w('Error getting FROM suggestions: $e');
      _fromStopSuggestions = [];
      _loadingFromSuggestions = false;
      notifyListeners();
    }
  }

  /// Get autocomplete suggestions for TO field
  Future<void> getToStopSuggestions(String searchTerm) async {
    if (searchTerm.isEmpty || searchTerm.length < 2) {
      _toStopSuggestions = [];
      notifyListeners();
      return;
    }

    _loadingToSuggestions = true;
    notifyListeners();

    try {
      _toStopSuggestions = await _searchService.getStopAutocomplete(
        searchTerm: searchTerm,
        limit: 10,
      );
      _loadingToSuggestions = false;
      notifyListeners();
    } catch (e) {
      _logger.w('Error getting TO suggestions: $e');
      _toStopSuggestions = [];
      _loadingToSuggestions = false;
      notifyListeners();
    }
  }

  /// Clear FROM suggestions
  void clearFromSuggestions() {
    _fromStopSuggestions = [];
    notifyListeners();
  }

  /// Clear TO suggestions
  void clearToSuggestions() {
    _toStopSuggestions = [];
    notifyListeners();
  }

  /// Clear search results
  void clearSearch() {
    _searchResponse = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Quick search using a popular route
  Future<void> searchPopularRoute(PopularRoute route) async {
    await searchTrips(
      from: route.fromStopName,
      to: route.toStopName,
    );
  }

  /// Swap FROM and TO locations
  void swapLocations(
    TextEditingController fromController,
    TextEditingController toController,
  ) {
    final temp = fromController.text;
    fromController.text = toController.text;
    toController.text = temp;
    notifyListeners();
  }

  /// Get search statistics
  Map<String, dynamic> getSearchStats() {
    if (_searchResponse == null) {
      return {};
    }

    return {
      'total_results': tripResults.length,
      'search_time_ms': _searchResponse!.searchTimeMs,
      'from_stop': _searchResponse!.searchDetails.fromStop.displayName,
      'to_stop': _searchResponse!.searchDetails.toStop.displayName,
      'search_type': _searchResponse!.searchDetails.searchType,
    };
  }

  /// Check if a specific date has available trips
  bool hasTripsOnDate(DateTime date) {
    return tripResults.any((trip) {
      return trip.departureTime.year == date.year &&
          trip.departureTime.month == date.month &&
          trip.departureTime.day == date.day;
    });
  }

  /// Filter trips by bus type
  List<TripResult> filterByBusType(String busType) {
    return tripResults
        .where((trip) => trip.busType.toLowerCase() == busType.toLowerCase())
        .toList();
  }

  /// Sort trips by fare (low to high)
  List<TripResult> sortByFare({bool ascending = true}) {
    final sorted = List<TripResult>.from(tripResults);
    sorted.sort((a, b) =>
        ascending ? a.fare.compareTo(b.fare) : b.fare.compareTo(a.fare));
    return sorted;
  }

  /// Sort trips by departure time (earliest first)
  List<TripResult> sortByDepartureTime({bool ascending = true}) {
    final sorted = List<TripResult>.from(tripResults);
    sorted.sort((a, b) => ascending
        ? a.departureTime.compareTo(b.departureTime)
        : b.departureTime.compareTo(a.departureTime));
    return sorted;
  }

  /// Sort trips by duration (shortest first)
  List<TripResult> sortByDuration({bool ascending = true}) {
    final sorted = List<TripResult>.from(tripResults);
    sorted.sort((a, b) => ascending
        ? a.durationMinutes.compareTo(b.durationMinutes)
        : b.durationMinutes.compareTo(a.durationMinutes));
    return sorted;
  }

  /// Get trips with available AC buses
  List<TripResult> getAcBuses() {
    return tripResults.where((trip) => trip.busFeatures.hasAc).toList();
  }

  /// Get trips with WiFi
  List<TripResult> getWifiBuses() {
    return tripResults.where((trip) => trip.busFeatures.hasWifi).toList();
  }
}
