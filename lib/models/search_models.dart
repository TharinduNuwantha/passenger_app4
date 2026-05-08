/// Models for Trip Search functionality
/// Matches backend API response structure

class SearchRequest {
  final String from;
  final String to;
  final DateTime? datetime;
  final int? limit;
  final double? fromLat;
  final double? fromLng;
  final double? toLat;
  final double? toLng;

  SearchRequest({
    required this.from,
    required this.to,
    this.datetime,
    this.limit = 20,
    this.fromLat,
    this.fromLng,
    this.toLat,
    this.toLng,
  });

  Map<String, dynamic> toJson() {
    // Format datetime to RFC3339 with timezone (required by Go backend)
    String? formattedDatetime;
    if (datetime != null) {
      // Ensure datetime is in UTC and formatted with 'Z' suffix
      formattedDatetime = datetime!.toUtc().toIso8601String();
      // toIso8601String() on UTC datetime should include 'Z', but ensure it
      if (!formattedDatetime.endsWith('Z') &&
          !formattedDatetime.contains('+')) {
        formattedDatetime = '${formattedDatetime}Z';
      }
    }

    return {
      'from': from,
      'to': to,
      if (formattedDatetime != null) 'datetime': formattedDatetime,
      if (limit != null) 'limit': limit,
      if (fromLat != null) 'from_lat': fromLat,
      if (fromLng != null) 'from_lng': fromLng,
      if (toLat != null) 'to_lat': toLat,
      if (toLng != null) 'to_lng': toLng,
    };
  }
}

class SearchResponse {
  final String status;
  final String message;
  final SearchDetails searchDetails;
  final List<TripResult> results;
  final int searchTimeMs;
  final String discoveryStatus;
  final double remainingGapKm;
  final bool routeExists;

  SearchResponse({
    required this.status,
    required this.message,
    required this.searchDetails,
    required this.results,
    required this.searchTimeMs,
    required this.discoveryStatus,
    required this.remainingGapKm,
    required this.routeExists,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      status: json['status'] as String? ?? 'error',
      message: json['message'] as String? ?? 'Unknown error',
      searchDetails: SearchDetails.fromJson(json['search_details'] ?? {}),
      results:
          (json['results'] as List<dynamic>?)
              ?.map((e) => TripResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      searchTimeMs: json['search_time_ms'] as int? ?? 0,
      discoveryStatus: json['discovery_status'] as String? ?? 'unknown',
      remainingGapKm: (json['remaining_gap_km'] as num?)?.toDouble() ?? 0.0,
      routeExists: json['route_exists'] as bool? ?? false,
    );
  }

  bool get isSuccess => status == 'success';
  bool get hasResults => results.isNotEmpty;
  bool get hasRouteOnlyDiscovery => !hasResults && routeExists;
  bool get hasPartialCoverage =>
      discoveryStatus == 'partial_coverage' || remainingGapKm > 0.0;
}

class SearchDetails {
  final StopInfo fromStop;
  final StopInfo toStop;
  final String searchType;

  SearchDetails({
    required this.fromStop,
    required this.toStop,
    required this.searchType,
  });

  factory SearchDetails.fromJson(Map<String, dynamic> json) {
    return SearchDetails(
      fromStop: StopInfo.fromJson(json['from_stop'] ?? {}),
      toStop: StopInfo.fromJson(json['to_stop'] ?? {}),
      searchType: json['search_type'] as String? ?? 'exact',
    );
  }
}

class StopInfo {
  final String? id;
  final String? name;
  final bool matched;
  final String originalInput;

  StopInfo({
    this.id,
    this.name,
    required this.matched,
    required this.originalInput,
  });

  factory StopInfo.fromJson(Map<String, dynamic> json) {
    return StopInfo(
      id: json['id'] as String?,
      name: json['name'] as String?,
      matched: json['matched'] as bool? ?? false,
      originalInput: json['original_input'] as String? ?? '',
    );
  }

  String get displayName => name ?? originalInput;
}

class TripResult {
  final String tripId;
  final String? scheduleName;
  final String routeName;
  final String? routeNumber;
  final String? busOwnerId;
  final String? busOwnerName;
  final String busType;
  final DateTime departureTime;
  final DateTime estimatedArrival;
  final int durationMinutes;
  final int totalSeats;
  final double fare;
  final String boardingPoint;
  final String droppingPoint;
  final String? fromLounge;
  final String? toLounge;
  final double fromLoungeDistKm;
  final double toLoungeDistKm;
  final BusFeatures busFeatures;
  final bool isBookable;
  final List<RouteStop> routeStops;
  final String discoveryStatus;
  final double remainingGapKm;
  final bool routeExists;

  /// Master route ID for lounge lookup
  final String? masterRouteId;
  final String? mainRouteOrigin;
  final String? mainRouteDestination;
  final bool isTransit;
  final String? transitPointId;
  final String? transitPoint;
  final TripResult? leg1;
  final TripResult? leg2;

  TripResult({
    required this.tripId,
    this.scheduleName,
    required this.routeName,
    this.routeNumber,
    this.busOwnerId,
    this.busOwnerName,
    required this.busType,
    required this.departureTime,
    required this.estimatedArrival,
    required this.durationMinutes,
    required this.totalSeats,
    required this.fare,
    required this.boardingPoint,
    required this.droppingPoint,
    this.fromLounge,
    this.toLounge,
    this.fromLoungeDistKm = 0.0,
    this.toLoungeDistKm = 0.0,
    required this.busFeatures,
    required this.isBookable,
    this.routeStops = const [],
    this.masterRouteId,
    this.mainRouteOrigin,
    this.mainRouteDestination,
    this.isTransit = false,
    this.transitPointId,
    this.transitPoint,
    this.leg1,
    this.leg2,
    this.discoveryStatus = 'unknown',
    this.remainingGapKm = 0.0,
    this.routeExists = false,
  });

  bool get isRouteOnly =>
      !isBookable && (routeExists || discoveryStatus == 'route_available');

  bool get isPartialCoverage =>
      discoveryStatus == 'partial_coverage' || remainingGapKm > 0.0;

  String get discoveryReason {
    if (discoveryStatus == 'partial_coverage') {
      return 'Partial coverage';
    }

    if (routeExists || discoveryStatus == 'route_available') {
      return 'Route available';
    }

    return 'No route available';
  }

  // Helper to ensure dates are parsed as UTC
  static DateTime _parseUtcDate(String dateStr) {
    if (!dateStr.endsWith('Z') &&
        !dateStr.contains('+') &&
        !dateStr.contains('-')) {
      dateStr += 'Z';
    }
    return DateTime.parse(dateStr).toLocal();
  }

  static String? _parseBusOwnerName(Map<String, dynamic> json) {
    if (json['bus_owner_name'] is String &&
        (json['bus_owner_name'] as String).isNotEmpty) {
      return json['bus_owner_name'] as String;
    }

    if (json['bus_owner'] is Map<String, dynamic>) {
      return json['bus_owner']['company_name'] as String?;
    }

    if (json['bus_owner'] is Map) {
      return (json['bus_owner'] as Map)['company_name'] as String?;
    }

    return null;
  }

  static String? _parseMainRouteOrigin(Map<String, dynamic> json) {
    if (json['main_route_origin'] is String) {
      return json['main_route_origin'] as String;
    }

    if (json['bus_owner_route'] != null &&
        json['bus_owner_route']['master_route'] != null) {
      return json['bus_owner_route']['master_route']['origin_city'] as String?;
    }

    // Support flat structure if returned by backend join
    if (json['master_route_origin'] is String) {
      return json['master_route_origin'] as String;
    }

    return null;
  }

  static String? _parseMainRouteDestination(Map<String, dynamic> json) {
    if (json['main_route_destination'] is String) {
      return json['main_route_destination'] as String;
    }

    if (json['bus_owner_route'] != null &&
        json['bus_owner_route']['master_route'] != null) {
      return json['bus_owner_route']['master_route']['destination_city']
          as String?;
    }

    // Support flat structure if returned by backend join
    if (json['master_route_destination'] is String) {
      return json['master_route_destination'] as String;
    }

    return null;
  }

  factory TripResult.fromJson(Map<String, dynamic> json) {
    return TripResult(
      tripId: json['trip_id'] as String,
      scheduleName: json['schedule_name'] as String?,
      routeName: json['route_name'] as String? ?? 'Unknown Route',
      routeNumber: json['route_number'] as String?,
      busOwnerId: json['bus_owner_id'] as String?,
      busOwnerName: _parseBusOwnerName(json),
      busType: json['bus_type'] as String? ?? 'normal',
      departureTime: _parseUtcDate(json['departure_time'] as String),
      estimatedArrival: _parseUtcDate(json['estimated_arrival'] as String),
      durationMinutes: json['duration_minutes'] as int? ?? 0,
      totalSeats: json['total_seats'] as int? ?? 0,
      fare: (json['fare'] as num?)?.toDouble() ?? 0.0,
      boardingPoint: json['boarding_point'] as String? ?? '',
      droppingPoint: json['dropping_point'] as String? ?? '',
      fromLounge: json['from_lounge'] as String?,
      toLounge: json['to_lounge'] as String?,
      fromLoungeDistKm:
          (json['from_lounge_dist_km'] as num?)?.toDouble() ?? 0.0,
      toLoungeDistKm: (json['to_lounge_dist_km'] as num?)?.toDouble() ?? 0.0,
      busFeatures: BusFeatures.fromJson(json['bus_features'] ?? {}),
      isBookable: json['is_bookable'] as bool? ?? false,
      routeStops:
          (json['route_stops'] as List<dynamic>?)
              ?.map((e) => RouteStop.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      masterRouteId: json['master_route_id'] as String?,
      mainRouteOrigin: _parseMainRouteOrigin(json),
      mainRouteDestination: _parseMainRouteDestination(json),
      isTransit: json['is_transit'] as bool? ?? false,
      transitPointId: json['transit_point_id'] as String?,
      transitPoint: json['transit_point'] as String?,
      leg1: json['leg1'] != null ? TripResult.fromJson(json['leg1']) : null,
      leg2: json['leg2'] != null ? TripResult.fromJson(json['leg2']) : null,
      discoveryStatus: json['discovery_status'] as String? ?? 'unknown',
      remainingGapKm: (json['remaining_gap_km'] as num?)?.toDouble() ?? 0.0,
      routeExists: json['route_exists'] as bool? ?? false,
    );
  }

  // Helper getters
  String get formattedDuration {
    int hours = durationMinutes ~/ 60;
    int minutes = durationMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String get formattedFare {
    return 'LKR ${fare.toStringAsFixed(2)}';
  }

  String get displayRouteName {
    if (routeName.isNotEmpty && routeName != 'Unknown Route') {
      return routeName;
    }

    if (isTransit && leg1 != null && leg2 != null) {
      return '${leg1!.routeName} / ${leg2!.routeName}';
    }

    return 'Route information unavailable';
  }

  // Seats display - booking feature not implemented yet
  String get seatsDisplay {
    return '$totalSeats seats';
  }

  String get busTypeDisplay {
    switch (busType.toLowerCase()) {
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

  String get formattedTransitWaitTime {
    if (!isTransit || leg1 == null || leg2 == null) return '';
    final wait = leg2!.departureTime.difference(leg1!.estimatedArrival);
    if (wait.inHours > 0) {
      return '${wait.inHours}h ${wait.inMinutes % 60}m wait';
    }
    return '${wait.inMinutes}m wait';
  }
}

class BusFeatures {
  final bool hasWifi;
  final bool hasAc;
  final bool hasChargingPorts;
  final bool hasEntertainment;
  final bool hasRefreshments;

  BusFeatures({
    required this.hasWifi,
    required this.hasAc,
    required this.hasChargingPorts,
    required this.hasEntertainment,
    required this.hasRefreshments,
  });

  factory BusFeatures.fromJson(Map<String, dynamic> json) {
    return BusFeatures(
      hasWifi: json['has_wifi'] as bool? ?? false,
      hasAc: json['has_ac'] as bool? ?? false,
      hasChargingPorts: json['has_charging_ports'] as bool? ?? false,
      hasEntertainment: json['has_entertainment'] as bool? ?? false,
      hasRefreshments: json['has_refreshments'] as bool? ?? false,
    );
  }

  List<String> get availableFeatures {
    List<String> features = [];
    if (hasAc) features.add('AC');
    if (hasWifi) features.add('WiFi');
    if (hasChargingPorts) features.add('Charging');
    if (hasEntertainment) features.add('Entertainment');
    if (hasRefreshments) features.add('Refreshments');
    return features;
  }

  bool get hasAnyFeatures =>
      hasWifi ||
      hasAc ||
      hasChargingPorts ||
      hasEntertainment ||
      hasRefreshments;
}

class PopularRoute {
  final String fromStopName;
  final String toStopName;
  final int routeCount;
  final int? searchCount;

  PopularRoute({
    required this.fromStopName,
    required this.toStopName,
    required this.routeCount,
    this.searchCount,
  });

  factory PopularRoute.fromJson(Map<String, dynamic> json) {
    return PopularRoute(
      fromStopName: json['from_stop_name'] as String,
      toStopName: json['to_stop_name'] as String,
      routeCount: json['route_count'] as int? ?? 0,
      searchCount: json['search_count'] as int?,
    );
  }
}

class StopAutocomplete {
  final String stopId;
  final String stopName;
  final int routeCount;

  StopAutocomplete({
    required this.stopId,
    required this.stopName,
    required this.routeCount,
  });

  factory StopAutocomplete.fromJson(Map<String, dynamic> json) {
    return StopAutocomplete(
      stopId: json['stop_id'] as String,
      stopName: json['stop_name'] as String,
      routeCount: json['route_count'] as int? ?? 0,
    );
  }
}

class RouteStop {
  final String id;
  final String stopName;
  final int stopOrder;
  final double? latitude;
  final double? longitude;
  final int? arrivalTimeOffsetMinutes;
  final bool isMajorStop;

  RouteStop({
    required this.id,
    required this.stopName,
    required this.stopOrder,
    this.latitude,
    this.longitude,
    this.arrivalTimeOffsetMinutes,
    required this.isMajorStop,
  });

  factory RouteStop.fromJson(Map<String, dynamic> json) {
    return RouteStop(
      id: json['id'] as String,
      stopName: json['stop_name'] as String,
      stopOrder: json['stop_order'] as int? ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      arrivalTimeOffsetMinutes: json['arrival_time_offset_minutes'] as int?,
      isMajorStop: json['is_major_stop'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RouteStop && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
