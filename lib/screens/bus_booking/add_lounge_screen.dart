import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import '../../models/booking_intent_models.dart';
import '../../models/booking_models.dart';
import '../../models/lounge_booking_models.dart';
import '../../models/search_models.dart';
import '../../services/lounge_booking_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/map_selection_screen.dart';
import '../../core/theme/app_theme.dart';

/// Data class to hold selected lounge information for combined booking
class SelectedLoungeData {
  final Lounge lounge;
  final String pricingType;
  final double pricePerGuest;
  final List<LoungeGuestRequest> guests;
  final List<PreOrderItemData> preOrders;
  final double basePrice;
  final double preOrderTotal;
  final double totalPrice;
  final DateTime tripDate; // Date from the trip
  final String
  checkInTime; // Check-in time (e.g., trip departure time for pre-trip)
  final String? transportType; // van, car, or tuktuk
  final String? pickupLocation; // Selected pickup location
  final String? pickupLocationId; // Selected pickup location id
  final double transportCost; // Cost for transport
  final String pendingGuestName;
  final String pendingGuestPhone;
  final bool isExplicitlyBooked; // New field
  final DateTime? transportDateTime; // Selected pickup date and time

  SelectedLoungeData({
    required this.lounge,
    required this.pricingType,
    required this.pricePerGuest,
    required this.guests,
    this.preOrders = const [],
    required this.basePrice,
    required this.preOrderTotal,
    required this.totalPrice,
    required this.tripDate,
    required this.checkInTime,
    this.transportType,
    this.pickupLocation,
    this.pickupLocationId,
    this.transportCost = 0.0,
    this.pendingGuestName = '',
    this.pendingGuestPhone = '',
    this.isExplicitlyBooked = true, // Default to true for manual bookings
    this.transportDateTime,
  });

  SelectedLoungeData copyWith({
    Lounge? lounge,
    String? pricingType,
    double? pricePerGuest,
    List<LoungeGuestRequest>? guests,
    List<PreOrderItemData>? preOrders,
    double? basePrice,
    double? preOrderTotal,
    double? totalPrice,
    DateTime? tripDate,
    String? checkInTime,
    String? transportType,
    String? pickupLocation,
    String? pickupLocationId,
    double? transportCost,
    String? pendingGuestName,
    String? pendingGuestPhone,
    bool? isExplicitlyBooked,
    DateTime? transportDateTime,
  }) {
    return SelectedLoungeData(
      lounge: lounge ?? this.lounge,
      pricingType: pricingType ?? this.pricingType,
      pricePerGuest: pricePerGuest ?? this.pricePerGuest,
      guests: guests ?? this.guests,
      preOrders: preOrders ?? this.preOrders,
      basePrice: basePrice ?? this.basePrice,
      preOrderTotal: preOrderTotal ?? this.preOrderTotal,
      totalPrice: totalPrice ?? this.totalPrice,
      tripDate: tripDate ?? this.tripDate,
      checkInTime: checkInTime ?? this.checkInTime,
      transportType: transportType ?? this.transportType,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      pickupLocationId: pickupLocationId ?? this.pickupLocationId,
      transportCost: transportCost ?? this.transportCost,
      pendingGuestName: pendingGuestName ?? this.pendingGuestName,
      pendingGuestPhone: pendingGuestPhone ?? this.pendingGuestPhone,
      isExplicitlyBooked: isExplicitlyBooked ?? this.isExplicitlyBooked,
      transportDateTime: transportDateTime ?? this.transportDateTime,
    );
  }

  LoungeIntentRequest toIntentRequest() {
    return LoungeIntentRequest(
      loungeId: lounge.id,
      loungeName: lounge.loungeName,
      loungeAddress: lounge.address,
      pricingType: pricingType,
      date: DateFormat('yyyy-MM-dd').format(tripDate),
      checkInTime: checkInTime,
      guests: guests,
      preOrders: preOrders
          .map(
            (p) => PreOrderItem(
              productId: p.productId,
              productName: p.productName,
              productType: 'product',
              imageUrl: p.imageUrl,
              quantity: p.quantity,
              unitPrice: p.unitPrice,
              totalPrice: p.totalPrice,
            ),
          )
          .toList(),
      pricePerGuest: pricePerGuest,
      basePrice: basePrice,
      preOrderTotal: preOrderTotal,
      totalPrice: totalPrice,
      transportType: transportType,
      pickupLocation: pickupLocation,
      pickupLocationId: pickupLocationId,
      transportCost: transportCost,
      transportTime: transportDateTime != null
          ? DateFormat('yyyy-MM-dd HH:mm').format(transportDateTime!)
          : null,
    );
  }
}

/// Pre-order item with product details for display
class PreOrderItemData {
  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final String? imageUrl;

  PreOrderItemData({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    this.imageUrl,
  });

  double get totalPrice => unitPrice * quantity;
}

/// Screen to add lounges (pre-trip and/or post-trip) to a bus booking
/// This appears after seat selection and passenger details, before payment
class AddLoungeScreen extends StatefulWidget {
  final TripResult trip;
  final List<TripSeat> selectedSeats;
  final String boardingPoint;
  final String alightingPoint;
  final String? boardingStopId;
  final String? alightingStopId;
  final String? masterRouteId;
  final double busFare;
  final String passengerName;
  final String passengerPhone;
  final String? passengerEmail;

  /// The origin city the user typed in the search (e.g. "Colombo").
  /// Used to filter boarding lounges via master_routes.origin_city.
  /// Falls back to route-based or stop-based queries when null.
  final String? originCity;
  final String? destinationCity;

  /// User's exact GPS coordinates from the search request.
  /// Used to sort lounges by real distance (proximity weight).
  final double? startLat;
  final double? startLng;
  final double? dropLat;
  final double? dropLng;

  const AddLoungeScreen({
    super.key,
    required this.trip,
    required this.selectedSeats,
    required this.boardingPoint,
    required this.alightingPoint,
    this.boardingStopId,
    this.alightingStopId,
    this.masterRouteId,
    required this.busFare,
    required this.passengerName,
    required this.passengerPhone,
    this.passengerEmail,
    this.originCity,
    this.destinationCity,
    this.startLat,
    this.startLng,
    this.dropLat,
    this.dropLng,
  });

  @override
  State<AddLoungeScreen> createState() => _AddLoungeScreenState();
}

class _AddLoungeScreenState extends State<AddLoungeScreen> {
  final LoungeBookingService _loungeService = LoungeBookingService();
  final Logger _logger = Logger();

  bool _isLoadingDeparture = true;
  bool _isLoadingArrival = true;
  String? _departureError;
  String? _arrivalError;

  List<Lounge> _departureLounges = [];
  List<Lounge> _arrivalLounges = [];

  // Selected lounges with full booking data
  SelectedLoungeData? _selectedPreTripLounge;
  SelectedLoungeData? _selectedPostTripLounge;

  // Smart Suggestion state
  String? _suggestedDepartureLoungeId;
  String? _suggestedArrivalLoungeId;
  bool _isSelectingFromMap = false;
  Map<String, double> _loungeDistances = {}; // loungeId -> distanceKm
  String? _smartLocationName;
  bool _isGettingLiveLocation = false;

  @override
  void initState() {
    super.initState();
    _loadLounges();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadLounges() async {
    _logger.i('=== STARTING LOUNGE DISCOVERY (3KM RADIUS) ===');
    _logger.i(
      'Departure: ${widget.boardingPoint} (ID: ${widget.boardingStopId}) in ${widget.originCity}',
    );
    _logger.i(
      'Arrival: ${widget.alightingPoint} (ID: ${widget.alightingStopId}) in ${widget.destinationCity}',
    );
    _logger.i('Route: ${widget.masterRouteId}');

    // ── Load Departure Lounges ──────────────────────────────────────────────
    _loadDepartureLounges();

    // ── Load Arrival Lounges ────────────────────────────────────────────────
    _loadArrivalLounges();
  }

  /// Sort a lounge list by GPS distance from [userLat]/[userLng].
  /// Lounges without coordinates are placed at the end.
  List<Lounge> _sortByProximity(
    List<Lounge> lounges,
    double? userLat,
    double? userLng,
  ) {
    if (userLat == null || userLng == null) return lounges;

    final distMap = <String, double>{};
    for (final l in lounges) {
      if (l.latitude != null && l.longitude != null) {
        distMap[l.id] = _calculateDistance(
          userLat,
          userLng,
          l.latitude!,
          l.longitude!,
        );
        // Cache for later UI display
        _loungeDistances[l.id] = distMap[l.id]!;
      }
    }

    return List.of(lounges)..sort((a, b) {
      final da = distMap[a.id] ?? double.infinity;
      final db = distMap[b.id] ?? double.infinity;
      return da.compareTo(db);
    });
  }

  Future<void> _loadDepartureLounges() async {
    final routeId =
        (widget.masterRouteId != null &&
            widget.masterRouteId != 'null' &&
            widget.masterRouteId!.isNotEmpty)
        ? widget.masterRouteId
        : null;
    final stopId =
        (widget.boardingStopId != null &&
            widget.boardingStopId != 'null' &&
            widget.boardingStopId!.isNotEmpty)
        ? widget.boardingStopId
        : null;
    final city =
        (widget.originCity != null &&
            widget.originCity != 'null' &&
            widget.originCity!.isNotEmpty)
        ? widget.originCity
        : null;

    try {
      List<Lounge> allFound = [];

      // Priority 1: Proximity to boarding stop
      if (stopId != null) {
        if (routeId != null) {
          _logger.i('Discovery: boarding stop $stopId on route $routeId (3km)');
          final nearStop = await _loungeService.getLoungesNearStop(
            routeId,
            stopId,
            maxDistance: 3,
          );
          allFound.addAll(nearStop);
        } else {
          _logger.i('Discovery: boarding stop $stopId (direct)');
          final atStop = await _loungeService.getLoungesByStop(stopId);
          allFound.addAll(atStop);
        }
      }

      // Priority 2: City fallback (using specialized city endpoint)
      if (allFound.isEmpty && city != null) {
        _logger.i('Discovery: city fallback for $city');
        final cityLounges = await _loungeService.getLoungesByOriginCity(city);
        allFound.addAll(cityLounges);
      }

      // Priority 3: Route fallback
      if (allFound.isEmpty && routeId != null) {
        _logger.i('Discovery: route fallback for $routeId');
        final routeLounges = await _loungeService.getLoungesByRoute(routeId);
        allFound.addAll(routeLounges);
      }

      // De-duplicate and filter by status
      final uniqueMap = <String, Lounge>{
        for (final l in allFound.where((l) => l.status == 'approved')) l.id: l,
      };

      final sorted = _sortByProximity(
        uniqueMap.values.toList(),
        widget.startLat,
        widget.startLng,
      );

      // Reorder so lounges matching the search-API hint appear first.
      // This ensures the Add Lounge screen shows the same lounge the
      // user saw on the bus booking card.
      final prioritized = _prioritizeByHintName(sorted, widget.trip.fromLounge);

      setState(() {
        _departureLounges = prioritized;
        _isLoadingDeparture = false;
      });

      _logger.i('Departure: ${prioritized.length} lounges discovered');

      if (prioritized.isNotEmpty && _selectedPreTripLounge == null) {
        _autoSelectLounge(
          _pickBestLounge(prioritized, widget.trip.fromLounge),
          true,
        );
        _suggestedDepartureLoungeId = prioritized.first.id;
      }
    } catch (e) {
      _logger.e('Error discovered departure lounges: $e');
      setState(() {
        _departureError = 'Search failed. Please try again.';
        _isLoadingDeparture = false;
      });
    }
  }

  Future<void> _loadArrivalLounges() async {
    final routeId =
        (widget.masterRouteId != null &&
            widget.masterRouteId != 'null' &&
            widget.masterRouteId!.isNotEmpty)
        ? widget.masterRouteId
        : null;
    final stopId =
        (widget.alightingStopId != null &&
            widget.alightingStopId != 'null' &&
            widget.alightingStopId!.isNotEmpty)
        ? widget.alightingStopId
        : null;
    final city =
        (widget.destinationCity != null &&
            widget.destinationCity != 'null' &&
            widget.destinationCity!.isNotEmpty)
        ? widget.destinationCity
        : null;

    try {
      List<Lounge> allFound = [];

      // Priority 1: Proximity to alighting stop
      if (stopId != null) {
        if (routeId != null) {
          _logger.i(
            'Discovery: alighting stop $stopId on route $routeId (3km)',
          );
          final nearStop = await _loungeService.getLoungesNearStop(
            routeId,
            stopId,
            maxDistance: 3,
          );
          allFound.addAll(nearStop);
        } else {
          _logger.i('Discovery: alighting stop $stopId (direct)');
          final atStop = await _loungeService.getLoungesByStop(stopId);
          allFound.addAll(atStop);
        }
      }

      // Priority 2: City fallback
      if (allFound.isEmpty && city != null) {
        _logger.i('Discovery: arrival city fallback for $city');
        final cityLounges = await _loungeService.getLoungesByDestinationCity(
          city,
        );
        allFound.addAll(cityLounges);
      }

      // Priority 3: Route fallback
      if (allFound.isEmpty && routeId != null) {
        _logger.i('Discovery: arrival route fallback for $routeId');
        final routeLounges = await _loungeService.getLoungesByRoute(routeId);
        allFound.addAll(routeLounges);
      }

      // De-duplicate and filter by status
      final uniqueMap = <String, Lounge>{
        for (final l in allFound.where((l) => l.status == 'approved')) l.id: l,
      };

      final sorted = _sortByProximity(
        uniqueMap.values.toList(),
        widget.dropLat,
        widget.dropLng,
      );

      // Reorder so lounges matching the search-API hint appear first.
      final prioritized = _prioritizeByHintName(sorted, widget.trip.toLounge);

      setState(() {
        _arrivalLounges = prioritized;
        _isLoadingArrival = false;
      });

      _logger.i('Arrival: ${prioritized.length} lounges discovered');

      if (prioritized.isNotEmpty && _selectedPostTripLounge == null) {
        _autoSelectLounge(
          _pickBestLounge(prioritized, widget.trip.toLounge),
          false,
        );
        _suggestedArrivalLoungeId = prioritized.first.id;
      }
    } catch (e) {
      _logger.e('Error discovered arrival lounges: $e');
      setState(() {
        _arrivalError = 'Search failed. Please try again.';
        _isLoadingArrival = false;
      });
    }
  }

  /// Selects the lounge matching [hintName] from [lounges], or [lounges.first] as default.
  ///
  /// Matching strategy (in priority order):
  ///   1. Exact case-insensitive match
  ///   2. One name contains the other (handles "Everest Lounge" vs "Ruwan Hotel - Everest Lounges")
  ///   3. Falls back to the first lounge in the list
  Lounge _pickBestLounge(List<Lounge> lounges, String? hintName) {
    if (hintName != null && hintName.isNotEmpty) {
      final hint = hintName.toLowerCase().trim();

      // Priority 1: Exact match
      final exact = lounges.where(
        (l) => l.loungeName.toLowerCase().trim() == hint,
      );
      if (exact.isNotEmpty) return exact.first;

      // Priority 2: Partial / contains match
      final partial = lounges.where((l) {
        final name = l.loungeName.toLowerCase().trim();
        return name.contains(hint) || hint.contains(name);
      });
      if (partial.isNotEmpty) return partial.first;
    }
    return lounges.first;
  }

  /// Reorders [lounges] so entries whose name matches [hintName] come first,
  /// preserving relative order within each group.
  ///
  /// This ensures the Add Lounge screen shows the same lounge that the
  /// search API surfaced on the bus booking card at the top of the list.
  List<Lounge> _prioritizeByHintName(List<Lounge> lounges, String? hintName) {
    if (hintName == null || hintName.isEmpty || lounges.length <= 1) {
      return lounges;
    }

    final hint = hintName.toLowerCase().trim();

    bool matches(Lounge l) {
      final name = l.loungeName.toLowerCase().trim();
      return name == hint || name.contains(hint) || hint.contains(name);
    }

    final matched = lounges.where(matches).toList();
    final rest = lounges.where((l) => !matches(l)).toList();

    if (matched.isNotEmpty) {
      _logger.i(
        'Prioritized ${matched.length} lounge(s) matching hint "$hintName"',
      );
    }

    return [...matched, ...rest];
  }

  /// Calculate distance between two points in km
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000.0;
  }

  /// Suggest the best lounge based on location and resort lists
  void _updateSmartSuggestions(double lat, double lng, {String? locationName}) {
    setState(() {
      _smartLocationName = locationName ?? 'Current Location';

      // Calculate and store distances for all lounges
      final allLounges = [..._departureLounges, ..._arrivalLounges];
      for (final lounge in allLounges) {
        if (lounge.latitude != null && lounge.longitude != null) {
          _loungeDistances[lounge.id] = _calculateDistance(
            lat,
            lng,
            lounge.latitude!,
            lounge.longitude!,
          );
        }
      }

      // Sort and suggest closest departure lounge
      if (_departureLounges.isNotEmpty) {
        _departureLounges.sort((a, b) {
          final distA = _loungeDistances[a.id] ?? double.infinity;
          final distB = _loungeDistances[b.id] ?? double.infinity;
          return distA.compareTo(distB);
        });
        _suggestedDepartureLoungeId = _departureLounges.first.id;
      }

      // Sort and suggest closest arrival lounge
      if (_arrivalLounges.isNotEmpty) {
        _arrivalLounges.sort((a, b) {
          final distA = _loungeDistances[a.id] ?? double.infinity;
          final distB = _loungeDistances[b.id] ?? double.infinity;
          return distA.compareTo(distB);
        });
        _suggestedArrivalLoungeId = _arrivalLounges.first.id;
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Optimized for $_smartLocationName',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _useCurrentLocationForSmartSuggestion() async {
    setState(() => _isGettingLiveLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showErrorSnackBar(
          'Location services are disabled. Please enable GPS in your device settings.',
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        _showErrorSnackBar(
          'Location permission denied permanently. Please enable in settings.',
        );
        return;
      }

      // If permission is denied again
      if (permission == LocationPermission.denied) {
        _showErrorSnackBar('Location permission denied.');
        return;
      }

      // Using high accuracy and longer timeout for reliability
      Position position =
          await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.best,
            timeLimit: const Duration(seconds: 25),
          ).catchError((e) async {
            // Fallback to lower accuracy if best fails
            return await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
              timeLimit: const Duration(seconds: 15),
            );
          });

      _logger.d(
        'Location obtained: ${position.latitude}, ${position.longitude}',
      );

      // Get address name for refined display
      String? name;
      try {
        final apiKey = dotenv.get('GOOGLE_MAPS_API_KEY');
        final url =
            'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$apiKey';
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK' && data['results'].isNotEmpty) {
            name = data['results'][0]['formatted_address'];
          }
        }
      } catch (e) {
        _logger.e('Reverse geocoding failed: $e');
      }

      _updateSmartSuggestions(
        position.latitude,
        position.longitude,
        locationName: name ?? 'Nearby Your Location',
      );
    } catch (e) {
      _logger.e('Failed to get location: $e');
      _showErrorSnackBar(
        'Location Error: Could not pinpoint your position clearly.',
      );
    } finally {
      setState(() => _isGettingLiveLocation = false);
    }
  }

  Future<void> _selectLocationOnMapForSmartSuggestion() async {
    setState(() => _isSelectingFromMap = true);
    // Assuming MapSelectionScreen exists and returns LatLng or similar
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              MapSelectionScreen(apiKey: dotenv.get('GOOGLE_MAPS_API_KEY')),
        ),
      );

      if (result != null && result is Map<String, dynamic>) {
        _updateSmartSuggestions(
          result['lat'],
          result['lng'],
          locationName: result['address'],
        );
      }
    } catch (e) {
      _showErrorSnackBar('Map selection failed: $e');
    } finally {
      setState(() => _isSelectingFromMap = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
      );
    }
  }

  /// Open lounge configuration bottom sheet
  Future<void> _configureLoungeBooking(Lounge lounge, bool isPreTrip) async {
    final existingSelection = (isPreTrip
        ? _selectedPreTripLounge
        : _selectedPostTripLounge);
    final result = await showModalBottomSheet<SelectedLoungeData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LoungeConfigurationSheet(
        lounge: lounge,
        isPreTrip: isPreTrip,
        busDepartureTime: widget.trip.departureTime,
        busArrivalTime: widget.trip.estimatedArrival,
        passengerName: widget.passengerName,
        passengerPhone: widget.passengerPhone,
        initialData: existingSelection?.lounge.id == lounge.id
            ? existingSelection
            : null,
        startLat: widget.startLat,
        startLng: widget.startLng,
        dropLat: widget.dropLat,
        dropLng: widget.dropLng,
        onDraftChanged: (draft) {
          setState(() {
            if (isPreTrip) {
              _selectedPreTripLounge = draft;
            } else {
              _selectedPostTripLounge = draft;
            }
          });
        },
      ),
    );

    if (result != null) {
      setState(() {
        if (isPreTrip) {
          _selectedPreTripLounge = result;
        } else {
          _selectedPostTripLounge = result;
        }
      });
    }
  }

  /// Remove selected lounge
  void _removeLounge(bool isPreTrip) {
    setState(() {
      if (isPreTrip) {
        if (_selectedPreTripLounge != null) {
          _selectedPreTripLounge = _selectedPreTripLounge!.copyWith(
            isExplicitlyBooked: false,
          );
        }
      } else {
        if (_selectedPostTripLounge != null) {
          _selectedPostTripLounge = _selectedPostTripLounge!.copyWith(
            isExplicitlyBooked: false,
          );
        }
      }
    });
  }

  /// Calculate total including lounges
  double get _totalWithLounges {
    double total = widget.busFare;
    if (_selectedPreTripLounge != null &&
        _selectedPreTripLounge!.isExplicitlyBooked) {
      total += _selectedPreTripLounge!.totalPrice;
    }
    if (_selectedPostTripLounge != null &&
        _selectedPostTripLounge!.isExplicitlyBooked) {
      total += _selectedPostTripLounge!.totalPrice;
    }
    return total;
  }

  void _autoSelectLounge(Lounge lounge, bool isPreTrip) {
    _logger.i('Auto-selecting lounge: ${lounge.loungeName} (Pre: $isPreTrip)');

    // Default guest list (primary passenger)
    final guests = [
      LoungeGuestRequest(
        guestName: widget.passengerName,
        guestPhone: widget.passengerPhone,
        isPrimary: true,
      ),
    ];

    // Priority: 'Until Bus Arrives' -> '1_hour' -> '2_hours'
    LoungePricingType selectedPricing = LoungePricingType.oneHour;
    if (lounge.priceUntilBus != null && lounge.priceUntilBus! > 0) {
      selectedPricing = LoungePricingType.untilBus;
    } else if (lounge.price1Hour != null && lounge.price1Hour! > 0) {
      selectedPricing = LoungePricingType.oneHour;
    } else if (lounge.price2Hours != null && lounge.price2Hours! > 0) {
      selectedPricing = LoungePricingType.twoHours;
    }

    final double basePrice = lounge.getPriceForType(selectedPricing) ?? 0.0;
    final double totalPrice = basePrice * guests.length;

    final data = SelectedLoungeData(
      lounge: lounge,
      pricingType: selectedPricing.toJson(),
      pricePerGuest: basePrice,
      guests: guests,
      basePrice: basePrice,
      preOrderTotal: 0.0,
      totalPrice: totalPrice,
      tripDate: widget.trip.departureTime,
      checkInTime: DateFormat(
        'HH:mm',
      ).format(widget.trip.departureTime.subtract(const Duration(hours: 1))),
      isExplicitlyBooked:
          false, // Auto-selected is NOT added to total by default
    );

    setState(() {
      if (isPreTrip) {
        _selectedPreTripLounge = data;
      } else {
        _selectedPostTripLounge = data;
      }
    });
  }

  String _formatPricingType(String type) {
    return LoungePricingType.fromJson(type).displayName;
  }

  /// Skip lounges and proceed
  void _skipLounges() {
    Navigator.pop(
      context,
      AddLoungeResult(preTripLounge: null, postTripLounge: null),
    );
  }

  /// Continue with selected lounges
  void _continueWithLounges() {
    Navigator.pop(
      context,
      AddLoungeResult(
        preTripLounge: _selectedPreTripLounge,
        postTripLounge: _selectedPostTripLounge,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
            ),
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 18,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Column(
          children: [
            const Text(
              'Lounge Experience',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              'Enhance your journey',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.75),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    _buildBusSummary(),
                    _buildLoungeCard(true), // Pre-trip
                    _buildLoungeCard(false), // Post-trip
                  ],
                ),
              ),
            ),

            // Bottom actions
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildBusSummary() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.directions_bus_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.trip.routeName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.circle,
                        size: 6,
                        color: Color(0xFF90CAF9),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${widget.boardingPoint} → ${widget.alightingPoint}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${DateFormat('dd MMM, hh:mm a').format(widget.trip.departureTime)} • ${widget.selectedSeats.length} seat(s)',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFC300).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFFC300).withOpacity(0.4),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'LKR ${widget.busFare.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Color(0xFFFFC300),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Bus Fare',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoungeCard(bool isPreTrip) {
    final selectedLounge = isPreTrip
        ? _selectedPreTripLounge
        : _selectedPostTripLounge;
    final lounges = isPreTrip ? _departureLounges : _arrivalLounges;
    final isLoading = isPreTrip ? _isLoadingDeparture : _isLoadingArrival;
    final error = isPreTrip ? _departureError : _arrivalError;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selectedLounge != null
              ? (selectedLounge.isExplicitlyBooked
                    ? AppColors.primary
                    : Colors.orange)
              : context.colors.cardBorder,
          width: selectedLounge != null ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: context.colors.shadowColor.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isPreTrip ? AppColors.primary : AppColors.secondary)
                      .withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPreTrip ? Icons.flight_takeoff : Icons.flight_land,
                  color: isPreTrip ? AppColors.primary : AppColors.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPreTrip ? 'Pre-Journey Lounge' : 'Arrival Lounge',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: context.colors.textPrimary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      isPreTrip
                          ? 'Relax before your trip'
                          : 'Refresh after your journey',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (selectedLounge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: selectedLounge.isExplicitlyBooked
                        ? AppColors.primary.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    selectedLounge.isExplicitlyBooked ? 'Booked' : 'Draft',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: selectedLounge.isExplicitlyBooked
                          ? AppColors.primary
                          : Colors.orange,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (selectedLounge != null)
            _buildSelectedLoungeChip(selectedLounge, isPreTrip)
          else
            _buildAddLoungeButton(isPreTrip, lounges, isLoading, error),
        ],
      ),
    );
  }

  Widget _buildAddLoungeButton(
    bool isPreTrip,
    List<Lounge> lounges,
    bool isLoading,
    String? error,
  ) {
    return InkWell(
      onTap: isLoading ? null : () => _addLounge(isPreTrip),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.25),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else ...[
              Icon(Icons.weekend_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                'Book ${isPreTrip ? "Pre-Journey" : "Arrival"} Lounge',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _addLounge(bool isPreTrip) async {
    final lounges = isPreTrip ? _departureLounges : _arrivalLounges;
    if (lounges.isEmpty) {
      // Try to load if not loaded
      if (isPreTrip && _isLoadingDeparture) return;
      if (!isPreTrip && _isLoadingArrival) return;
      await _loadLounges();
      final reloadedLounges = isPreTrip ? _departureLounges : _arrivalLounges;
      if (reloadedLounges.isEmpty) {
        _showErrorSnackBar(
          'No lounges available for ${isPreTrip ? "departure" : "arrival"}.',
        );
        return;
      }
    }
    // Auto-select the best lounge
    final bestLounge = lounges.first; // Or use sorting logic
    _autoSelectLounge(bestLounge, isPreTrip);
    // Then open configuration
    await _configureLoungeBooking(bestLounge, isPreTrip);
  }

  Widget _buildSelectedLoungeChip(SelectedLoungeData data, bool isPreTrip) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Edit option: configure lounge booking when clicking anywhere on the card (excluding the cancel button)
            _configureLoungeBooking(data.lounge, isPreTrip);
          },
          borderRadius: BorderRadius.circular(16),
          splashColor: (isPreTrip ? AppColors.primary : AppColors.secondary)
              .withOpacity(0.1),
          highlightColor: (isPreTrip ? AppColors.primary : AppColors.secondary)
              .withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isPreTrip
                  ? AppColors.primary.withOpacity(0.05)
                  : AppColors.secondary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (isPreTrip ? AppColors.primary : AppColors.secondary)
                    .withOpacity(0.15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isPreTrip ? AppColors.primary : AppColors.secondary)
                        .withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPreTrip ? Icons.login_rounded : Icons.logout_rounded,
                    size: 18,
                    color: isPreTrip ? AppColors.primary : AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              data.lounge.loungeName,
                              style: TextStyle(
                                color: context.colors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.edit_rounded,
                            size: 14,
                            color:
                                (isPreTrip
                                        ? AppColors.primary
                                        : AppColors.secondary)
                                    .withOpacity(0.6),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${data.guests.length} guest(s) • ${_formatPricingType(data.pricingType)}',
                        style: TextStyle(
                          color: context.colors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'LKR ${data.totalPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        if (data.isExplicitlyBooked) {
                          _removeLounge(isPreTrip);
                        } else {
                          _configureLoungeBooking(data.lounge, isPreTrip);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: data.isExplicitlyBooked
                            ? AppColors.error.withOpacity(0.12)
                            : AppColors.primary.withOpacity(0.12),
                        foregroundColor: data.isExplicitlyBooked
                            ? AppColors.error
                            : AppColors.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            data.isExplicitlyBooked
                                ? Icons.close_rounded
                                : Icons.add_circle_outline_rounded,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            data.isExplicitlyBooked ? 'Cancel' : 'Book',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.colors.inputBackground,
            context.colors.chipBackground,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.weekend_outlined,
            size: 40,
            color: context.colors.iconSecondary,
          ),
          const SizedBox(height: 6),
          Text(
            'Lounge Preview',
            style: TextStyle(
              color: context.colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    final hasBookedLounge =
        (_selectedPreTripLounge != null &&
            _selectedPreTripLounge!.isExplicitlyBooked) ||
        (_selectedPostTripLounge != null &&
            _selectedPostTripLounge!.isExplicitlyBooked);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D47A1).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.receipt_long_rounded,
                        color: Colors.white70,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        hasBookedLounge
                            ? 'Total (Bus + Lounges)'
                            : 'Total (Bus)',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'LKR ${_totalWithLounges.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Color(0xFFFFC300),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _skipLounges,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withOpacity(0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFC300), Color(0xFFFFAB00)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFC300).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _continueWithLounges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        hasBookedLounge ? 'Continue with Lounge' : 'Continue →',
                        style: const TextStyle(
                          color: Color(0xFF0D47A1),
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

/// Result from AddLoungeScreen
class AddLoungeResult {
  final SelectedLoungeData? preTripLounge;
  final SelectedLoungeData? transitLounge;
  final SelectedLoungeData? postTripLounge;

  AddLoungeResult({
    this.preTripLounge,
    this.transitLounge,
    this.postTripLounge,
  });

  bool get hasLounges =>
      preTripLounge != null || transitLounge != null || postTripLounge != null;
}

// ============================================================================
// LOUNGE CONFIGURATION SHEET
// ============================================================================

class _LoungeConfigurationSheet extends StatefulWidget {
  final Lounge lounge;
  final bool isPreTrip;
  final DateTime busDepartureTime;
  final DateTime? busArrivalTime;
  final String passengerName;
  final String passengerPhone;
  final SelectedLoungeData? initialData;
  final ValueChanged<SelectedLoungeData>? onDraftChanged;
  final double? startLat;
  final double? startLng;
  final double? dropLat;
  final double? dropLng;

  const _LoungeConfigurationSheet({
    required this.lounge,
    required this.isPreTrip,
    required this.busDepartureTime,
    this.busArrivalTime,
    required this.passengerName,
    required this.passengerPhone,
    this.initialData,
    this.onDraftChanged,
    this.startLat,
    this.startLng,
    this.dropLat,
    this.dropLng,
  });

  @override
  State<_LoungeConfigurationSheet> createState() =>
      _LoungeConfigurationSheetState();
}

class _LoungeConfigurationSheetState extends State<_LoungeConfigurationSheet> {
  final LoungeBookingService _loungeService = LoungeBookingService();

  String? _selectedPricingType;
  final List<LoungeGuestRequest> _guests = [];
  final Map<String, PreOrderItemData> _cart = {};

  List<LoungeProduct> _products = [];
  bool _isLoadingProducts = false;

  final TextEditingController _guestNameController = TextEditingController();
  final TextEditingController _guestPhoneController = TextEditingController();

  // Transport selection
  String? _preTripTransportType;
  String? _preTripPickupLocation;
  String? _postTripTransportType;
  String? _postTripPickupLocation;
  DateTime? _transportDateTime;

  List<LoungeTransportLocationOption> _transportOptions = [];
  bool _isLoadingTransport = true;
  String? _transportLoadError;
  int _transportBufferMinutes = 15;

  DateTime _calculateDefaultTime() {
    final type =
        _selectedPricingType ?? (widget.isPreTrip ? 'until_bus' : '1_hour');
    final locId = widget.isPreTrip
        ? _preTripPickupLocation
        : _postTripPickupLocation;
    final loc = _optionById(locId);
    final estDuration = loc?.estDurationMinutes ?? 0;

    DateTime calculatedTime;

    if (widget.isPreTrip) {
      int loungeStayHours = 1;
      if (type == '1_hour') {
        loungeStayHours = 1;
      } else if (type == '2_hours') {
        loungeStayHours = 2;
      } else if (type == '3_hours') {
        loungeStayHours = 3;
      } else if (type == 'until_bus') {
        loungeStayHours = 0;
      }

      if (loc != null) {
        calculatedTime = widget.busDepartureTime.subtract(
          Duration(minutes: estDuration + _transportBufferMinutes + (loungeStayHours * 60)),
        );
      } else {
        calculatedTime = widget.busDepartureTime.subtract(
          Duration(hours: loungeStayHours),
        );
      }
    } else {
      final tripDate = widget.busArrivalTime ?? widget.busDepartureTime;
      int stayHours = 2;
      if (type == '1_hour') {
        stayHours = 1;
      } else if (type == '2_hours') {
        stayHours = 2;
      } else if (type == '3_hours') {
        stayHours = 3;
      } else if (type == 'until_bus') {
        stayHours = 5;
      }
      calculatedTime = tripDate.add(Duration(hours: stayHours));
    }

    // Off-Duty Time Handling (Only applies to Post-Trip to avoid missing the bus for Pre-Trip)
    // Automatically move the pickup time forward to 04:00 AM 
    // if the calculated time falls between 00:00 and 04:00 (12:00 AM - 4:00 AM).
    if (!widget.isPreTrip && calculatedTime.hour >= 0 && calculatedTime.hour < 4) {
      calculatedTime = DateTime(
        calculatedTime.year,
        calculatedTime.month,
        calculatedTime.day,
        4,
        0,
      );
    }

    return calculatedTime;
  }

  void _updateDefaultTransportDateTime() {
    _transportDateTime = _calculateDefaultTime();
  }

  static const List<String> _locationIconPool = [
    '📍',
    '🏙️',
    '✈️',
    '🚂',
    '🏨',
    '🛍️',
  ];

  @override
  void initState() {
    super.initState();
    _guestNameController.addListener(_notifyDraftChanged);
    _guestPhoneController.addListener(_notifyDraftChanged);

    if (widget.initialData != null) {
      _initializeFromExistingData(widget.initialData!);
    } else {
      // Add primary guest automatically (from bus booking)
      _guests.add(
        LoungeGuestRequest(
          guestName: widget.passengerName,
          guestPhone: widget.passengerPhone,
          isPrimary: true,
        ),
      );
      _updateDefaultTransportDateTime();
    }
    _loadProducts();
    _loadTransportOptions();
  }

  @override
  void dispose() {
    _guestNameController.removeListener(_notifyDraftChanged);
    _guestPhoneController.removeListener(_notifyDraftChanged);
    _guestNameController.dispose();
    _guestPhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoadingProducts = true);
    try {
      final products = await _loungeService.getLoungeProducts(widget.lounge.id);
      setState(() {
        _products = products.where((p) => p.isPreOrderable).toList();
        _isLoadingProducts = false;
      });
    } catch (e) {
      setState(() => _isLoadingProducts = false);
    }
  }

  Future<void> _loadTransportOptions() async {
    setState(() {
      _isLoadingTransport = true;
      _transportLoadError = null;
    });
    try {
      final list = await _loungeService.getLoungeTransportOptions(
        widget.lounge.id,
      );
      if (!mounted) return;

      _transportBufferMinutes = _loungeService.transportBufferMinutes;

      // Distance sorting logic
      final targetLat = widget.isPreTrip ? widget.startLat : widget.dropLat;
      final targetLng = widget.isPreTrip ? widget.startLng : widget.dropLng;

      if (targetLat != null && targetLng != null && list.isNotEmpty) {
        for (var opt in list) {
          if (opt.latitude != null && opt.longitude != null) {
            opt.distanceKm =
                Geolocator.distanceBetween(
                  targetLat,
                  targetLng,
                  opt.latitude!,
                  opt.longitude!,
                ) /
                1000.0;
          }
        }
        list.sort((a, b) {
          final distA = a.distanceKm ?? double.infinity;
          final distB = b.distanceKm ?? double.infinity;
          return distA.compareTo(distB);
        });

        // Auto-select nearest if not already selected
        if (widget.isPreTrip) {
          if (_preTripPickupLocation == null && list.isNotEmpty) {
            _preTripPickupLocation = list.first.id;
            // Also auto-select a default vehicle if available
            if (list.first.threeWheelerPrice > 0) {
              _preTripTransportType = 'three_wheeler';
            } else if (list.first.carPrice > 0) {
              _preTripTransportType = 'car';
            } else if (list.first.vanPrice > 0) {
              _preTripTransportType = 'van';
            }
          }
        } else {
          if (_postTripPickupLocation == null && list.isNotEmpty) {
            _postTripPickupLocation = list.first.id;
            // Also auto-select a default vehicle if available
            if (list.first.threeWheelerPrice > 0) {
              _postTripTransportType = 'three_wheeler';
            } else if (list.first.carPrice > 0) {
              _postTripTransportType = 'car';
            } else if (list.first.vanPrice > 0) {
              _postTripTransportType = 'van';
            }
          }
        }
      }

      setState(() {
        _transportOptions = list;
        _isLoadingTransport = false;
        _updateDefaultTransportDateTime();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingTransport = false;
        _transportLoadError = e.toString();
      });
    }
  }

  void _initializeFromExistingData(SelectedLoungeData data) {
    _selectedPricingType = data.pricingType.isNotEmpty
        ? data.pricingType
        : null;
    _guests.clear();
    _guests.addAll(data.guests);
    _cart.clear();
    for (final item in data.preOrders) {
      _cart[item.productId] = item;
    }
    if (widget.isPreTrip) {
      _preTripTransportType = data.transportType;
      _preTripPickupLocation = data.pickupLocationId;
    } else {
      _postTripTransportType = data.transportType;
      _postTripPickupLocation = data.pickupLocationId;
    }
    _guestNameController.text = data.pendingGuestName;
    _guestPhoneController.text = data.pendingGuestPhone;
    _transportDateTime = data.transportDateTime;
    if (_transportDateTime == null) {
      _updateDefaultTransportDateTime();
    }
  }

  void _updateState(VoidCallback changes) {
    setState(() {
      changes();
    });
    _notifyDraftChanged();
  }

  void _notifyDraftChanged() {
    if (widget.onDraftChanged == null) return;

    final draft = _buildDraftData(
      isExplicitlyBooked: widget.initialData?.isExplicitlyBooked ?? false,
    );
    widget.onDraftChanged!(draft);
  }

  SelectedLoungeData _buildDraftData({required bool isExplicitlyBooked}) {
    int stayHours = 1;
    if (_selectedPricingType == '1_hour') {
      stayHours = 1;
    } else if (_selectedPricingType == '2_hours') {
      stayHours = 2;
    } else if (_selectedPricingType == '3_hours') {
      stayHours = 3;
    } else if (_selectedPricingType == 'until_bus') {
      stayHours = 2;
    }

    final DateTime checkInDateTime;
    if (widget.isPreTrip) {
      checkInDateTime =
          _transportDateTime ??
          widget.busDepartureTime.subtract(Duration(hours: stayHours));
    } else {
      checkInDateTime = widget.busArrivalTime ?? widget.busDepartureTime;
    }

    final checkInTime = DateFormat('HH:mm').format(checkInDateTime);

    return SelectedLoungeData(
      lounge: widget.lounge,
      pricingType: _selectedPricingType ?? '',
      pricePerGuest: _getPriceForType(_selectedPricingType),
      guests: List<LoungeGuestRequest>.from(_guests),
      preOrders: _cart.values.toList(),
      basePrice: _basePrice,
      preOrderTotal: _preOrderTotal,
      totalPrice: _totalPrice,
      tripDate: checkInDateTime,
      checkInTime: checkInTime,
      transportType: widget.isPreTrip
          ? _preTripTransportType
          : _postTripTransportType,
      pickupLocation: widget.isPreTrip
          ? _optionById(_preTripPickupLocation)?.location
          : _optionById(_postTripPickupLocation)?.location,
      pickupLocationId: widget.isPreTrip
          ? _preTripPickupLocation
          : _postTripPickupLocation,
      transportCost: _transportCost,
      pendingGuestName: _guestNameController.text,
      pendingGuestPhone: _guestPhoneController.text,
      isExplicitlyBooked: isExplicitlyBooked,
      transportDateTime: _transportDateTime,
    );
  }

  LoungeTransportLocationOption? _optionById(String? id) {
    if (id == null) return null;
    for (final o in _transportOptions) {
      if (o.id == id) return o;
    }
    return null;
  }

  bool _offersVehicle(String type) =>
      _transportOptions.any((o) => o.priceForVehicleType(type) > 0);

  bool get _anyTransportConfigured =>
      _transportOptions.isNotEmpty &&
      _transportOptions.any(
        (o) => o.threeWheelerPrice > 0 || o.carPrice > 0 || o.vanPrice > 0,
      );

  double _minPriceForVehicle(String type) {
    double? best;
    for (final o in _transportOptions) {
      final p = o.priceForVehicleType(type);
      if (p <= 0) continue;
      if (best == null || p < best) {
        best = p;
      }
    }
    return best ?? 0;
  }

  String _vehiclePriceLabel(String type) {
    if (!_offersVehicle(type)) return '';
    final locId = widget.isPreTrip
        ? _preTripPickupLocation
        : _postTripPickupLocation;
    final opt = _optionById(locId);
    if (opt != null) {
      final p = opt.priceForVehicleType(type);
      if (p <= 0) return '';
      return 'LKR ${p.toStringAsFixed(0)}';
    }
    final min = _minPriceForVehicle(type);
    if (min <= 0) return '';
    return 'from LKR ${min.toStringAsFixed(0)}';
  }

  double _getPriceForType(String? type) {
    switch (type) {
      case '1_hour':
        return widget.lounge.price1Hour ?? 0;
      case '2_hours':
        return widget.lounge.price2Hours ?? 0;
      case '3_hours':
        return widget.lounge.price3Hours ?? 0;
      case 'until_bus':
        return widget.lounge.priceUntilBus ?? 0;
      default:
        return 0;
    }
  }

  double get _basePrice =>
      _getPriceForType(_selectedPricingType) * _guests.length;

  double get _preOrderTotal =>
      _cart.values.fold(0, (sum, item) => sum + item.totalPrice);

  double get _transportCost {
    final type = widget.isPreTrip
        ? _preTripTransportType
        : _postTripTransportType;
    final locId = widget.isPreTrip
        ? _preTripPickupLocation
        : _postTripPickupLocation;
    if (type == null || locId == null) return 0.0;
    final opt = _optionById(locId);
    if (opt == null) return 0.0;
    return opt.priceForVehicleType(type);
  }

  double get _totalPrice => _basePrice + _preOrderTotal + _transportCost;

  void _addGuest() {
    final name = _guestNameController.text.trim();
    if (name.isEmpty) return;

    _updateState(() {
      _guests.add(
        LoungeGuestRequest(
          guestName: name,
          guestPhone: _guestPhoneController.text.trim().isNotEmpty
              ? _guestPhoneController.text.trim()
              : null,
          isPrimary: false,
        ),
      );
      _guestNameController.clear();
      _guestPhoneController.clear();
    });
  }

  void _removeGuest(int index) {
    if (index == 0) return; // Can't remove primary guest
    _updateState(() => _guests.removeAt(index));
  }

  void _updateCartItem(LoungeProduct product, int quantity) {
    _updateState(() {
      if (quantity <= 0) {
        _cart.remove(product.id);
      } else {
        _cart[product.id] = PreOrderItemData(
          productId: product.id,
          productName: product.name,
          unitPrice: product.price,
          quantity: quantity,
          imageUrl: product.imageUrl,
        );
      }
    });
  }

  void _confirm() {
    if (_selectedPricingType == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a duration')));
      return;
    }

    // Validate phone numbers
    for (final guest in _guests) {
      if (guest.guestPhone != null && !_isValidPhone(guest.guestPhone!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please enter a valid phone number (e.g., +94712345678 or 0712345678)',
            ),
          ),
        );
        return;
      }
    }

    final t = widget.isPreTrip ? _preTripTransportType : _postTripTransportType;
    final p = widget.isPreTrip
        ? _preTripPickupLocation
        : _postTripPickupLocation;
    if (t != null && p == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a pickup location for transport'),
        ),
      );
      return;
    }

    int stayHours = 1;
    if (_selectedPricingType == '1_hour') {
      stayHours = 1;
    } else if (_selectedPricingType == '2_hours') {
      stayHours = 2;
    } else if (_selectedPricingType == '3_hours') {
      stayHours = 3;
    } else if (_selectedPricingType == 'until_bus') {
      stayHours = 2;
    }

    final DateTime checkInDateTime;
    if (widget.isPreTrip) {
      checkInDateTime =
          _transportDateTime ??
          widget.busDepartureTime.subtract(Duration(hours: stayHours));
    } else {
      checkInDateTime = widget.busArrivalTime ?? widget.busDepartureTime;
    }

    final checkInTime = DateFormat('HH:mm').format(checkInDateTime);

    final result = SelectedLoungeData(
      lounge: widget.lounge,
      pricingType: _selectedPricingType!,
      pricePerGuest: _getPriceForType(_selectedPricingType),
      guests: _guests,
      preOrders: _cart.values.toList(),
      basePrice: _basePrice,
      preOrderTotal: _preOrderTotal,
      totalPrice: _totalPrice,
      tripDate: checkInDateTime,
      checkInTime: checkInTime,
      transportType: widget.isPreTrip
          ? _preTripTransportType
          : _postTripTransportType,
      pickupLocation: widget.isPreTrip
          ? _optionById(_preTripPickupLocation)?.location
          : _optionById(_postTripPickupLocation)?.location,
      pickupLocationId: widget.isPreTrip
          ? _preTripPickupLocation
          : _postTripPickupLocation,
      transportCost: _transportCost,
      pendingGuestName: _guestNameController.text,
      pendingGuestPhone: _guestPhoneController.text,
      isExplicitlyBooked: true, // Manually booked via sheet
      transportDateTime: _transportDateTime,
    );

    Navigator.pop(context, result);
  }

  bool _isValidPhone(String phone) {
    // Sri Lankan phone number validation: +94xxxxxxxxx or 0xxxxxxxxx
    return RegExp(r'^(?:\+94|0)[0-9]{9}$').hasMatch(phone);
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.colors.bottomSheetBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 14),
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: context.colors.dividerColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              // Header with gradient accent
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1976D2).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        widget.isPreTrip
                            ? Icons.flight_takeoff_rounded
                            : Icons.flight_land_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.lounge.loungeName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.isPreTrip
                                  ? 'Pre-Trip Boarding Lounge'
                                  : 'Post-Trip Arrival Lounge',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Divider(height: 1),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Duration selection
                      _buildSectionHeader(
                        'Select Duration',
                        Icons.schedule_rounded,
                      ),
                      const SizedBox(height: 12),
                      _buildDurationOptions(),

                      const SizedBox(height: 20),

                      // Transport selection
                      _buildSectionHeader(
                        'Transport (Optional)',
                        Icons.directions_car_rounded,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.isPreTrip
                            ? 'Get picked up from your location to the lounge'
                            : 'Get dropped off from the lounge to your destination',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTransportSection(),

                      const SizedBox(height: 20),

                      // Guests
                      _buildSectionHeader('Guests', Icons.people_alt_rounded),
                      const SizedBox(height: 12),
                      _buildGuestsList(),

                      const SizedBox(height: 20),

                      // Pre-orders (optional)
                      if (_products.isNotEmpty) ...[
                        _buildSectionHeader(
                          'Pre-Order Food & Drinks',
                          Icons.restaurant_menu_rounded,
                        ),
                        const SizedBox(height: 12),
                        _buildPreOrderSection(),
                      ],

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              // Bottom
              _buildBottomSection(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: context.colors.textPrimary,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildDurationOptions() {
    return Column(
      children: [
        if (widget.lounge.priceUntilBus != null && widget.isPreTrip)
          _buildDurationOption(
            'until_bus',
            'Until Bus Departs',
            widget.lounge.priceUntilBus!,
            isHighlighted: true,
          ),
        if (widget.lounge.price1Hour != null)
          _buildDurationOption('1_hour', '1 Hour', widget.lounge.price1Hour!),
        if (widget.lounge.price2Hours != null)
          _buildDurationOption(
            '2_hours',
            '2 Hours',
            widget.lounge.price2Hours!,
          ),
        if (widget.lounge.price3Hours != null)
          _buildDurationOption(
            '3_hours',
            '3 Hours',
            widget.lounge.price3Hours!,
          ),
        if (widget.lounge.priceUntilBus != null && !widget.isPreTrip)
          _buildDurationOption(
            'until_bus',
            'Flexible Duration',
            widget.lounge.priceUntilBus!,
          ),
      ],
    );
  }

  Widget _buildDurationOption(
    String type,
    String label,
    double price, {
    bool isHighlighted = false,
  }) {
    final isSelected = _selectedPricingType == type;
    final iconMap = {
      'until_bus': Icons.access_time_rounded,
      '1_hour': Icons.hourglass_empty_rounded,
      '2_hours': Icons.hourglass_bottom_rounded,
      '3_hours': Icons.hourglass_full_rounded,
    };
    return GestureDetector(
      onTap: () => _updateState(() {
        _selectedPricingType = type;
        _updateDefaultTransportDateTime();
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : context.colors.inputBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isHighlighted
                      ? const Color(0xFFFFC300)
                      : context.colors.cardBorder),
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.15)
                    : (isHighlighted
                          ? const Color(0xFFFFC300).withOpacity(0.12)
                          : context.colors.chipBackground),
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconMap[type] ?? Icons.access_time,
                size: 18,
                color: isSelected
                    ? AppColors.primary
                    : (isHighlighted
                          ? const Color(0xFFFFAB00)
                          : context.colors.textSecondary),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        fontSize: 14,
                        color: isSelected
                            ? AppColors.primary
                            : context.colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isHighlighted) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFC300), Color(0xFFFFAB00)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '★ Best',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'LKR ${price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: isSelected
                        ? AppColors.primary
                        : context.colors.textPrimary,
                  ),
                ),
                Text(
                  '/person',
                  style: TextStyle(
                    fontSize: 10,
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : context.colors.cardBorder,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 13)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestsList() {
    return Column(
      children: [
        ...List.generate(_guests.length, (index) {
          final guest = _guests[index];
          final isPrimary = index == 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.colors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: context.colors.cardBorder.withOpacity(0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: isPrimary
                      ? AppColors.primary
                      : context.colors.chipBackground,
                  radius: 18,
                  child: Text(
                    guest.guestName[0].toUpperCase(),
                    style: TextStyle(
                      color: isPrimary
                          ? Colors.white
                          : context.colors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            guest.guestName,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: context.colors.textPrimary,
                            ),
                          ),
                          if (isPrimary) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFC300),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Primary',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (guest.guestPhone != null)
                        Text(
                          guest.guestPhone!,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.colors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!isPrimary)
                  IconButton(
                    onPressed: () => _removeGuest(index),
                    icon: const Icon(Icons.close, color: Colors.red, size: 20),
                  ),
              ],
            ),
          );
        }),
        // Add guest form
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.colors.inputBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.colors.cardBorder.withOpacity(0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Another Guest',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _guestNameController,
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  labelText: 'Guest Name',
                  labelStyle: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: context.colors.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.colors.cardBorder.withOpacity(0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _guestPhoneController,
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 14,
                ),
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone (Optional)',
                  labelStyle: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: context.colors.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.colors.cardBorder.withOpacity(0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _addGuest,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text(
                    'Add Guest',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreOrderSection() {
    if (_isLoadingProducts) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: _products.map((product) {
        final cartItem = _cart[product.id];
        final quantity = cartItem?.quantity ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: context.colors.cardBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? Image.network(
                        product.imageUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 60,
                          height: 60,
                          color: context.colors.chipBackground,
                          child: Icon(
                            Icons.fastfood,
                            color: context.colors.iconSecondary,
                            size: 28,
                          ),
                        ),
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        color: context.colors.chipBackground,
                        child: Icon(
                          Icons.fastfood,
                          color: context.colors.iconSecondary,
                          size: 28,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'LKR ${product.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Quantity controls
              if (quantity == 0)
                IconButton(
                  onPressed: () => _updateCartItem(product, 1),
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 18),
                  ),
                )
              else
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _updateCartItem(product, quantity - 1),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: context.colors.chipBackground,
                          shape: BoxShape.circle,
                          border: Border.all(color: context.colors.cardBorder),
                        ),
                        child: Icon(
                          Icons.remove,
                          size: 16,
                          color: context.colors.iconPrimary,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '$quantity',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: context.colors.textPrimary,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _updateCartItem(product, quantity + 1),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: context.colors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: context.colors.shadowColor.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Price breakdown
          if (_selectedPricingType != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Lounge (${_guests.length} guests)',
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'LKR ${_basePrice.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.colors.textPrimary,
                  ),
                ),
              ],
            ),
            if (_preOrderTotal > 0) ...[
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pre-orders',
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'LKR ${_preOrderTotal.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
            // Transport section
            if (widget.isPreTrip && _preTripTransportType != null) ...[
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Transport (${_preTripTransportType!.toUpperCase()})',
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _preTripPickupLocation != null
                        ? 'LKR ${_transportCost.toStringAsFixed(0)}'
                        : 'Select pickup',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
            if (!widget.isPreTrip && _postTripTransportType != null) ...[
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transport (${_postTripTransportType!.toUpperCase()})',
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    _postTripPickupLocation != null
                        ? 'LKR ${_transportCost.toStringAsFixed(0)}'
                        : 'Select pickup',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
            const Divider(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: context.colors.textPrimary,
                  ),
                ),
                Text(
                  'LKR ${_totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          // Confirm button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: _selectedPricingType != null
                  ? const LinearGradient(
                      colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                    )
                  : null,
              color: _selectedPricingType == null
                  ? context.colors.chipBackground
                  : null,
              boxShadow: _selectedPricingType != null
                  ? [
                      BoxShadow(
                        color: const Color(0xFF0D47A1).withOpacity(0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: ElevatedButton(
              onPressed: _selectedPricingType != null ? _confirm : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.isPreTrip
                        ? Icons.flight_takeoff_rounded
                        : Icons.flight_land_rounded,
                    color: _selectedPricingType != null
                        ? Colors.white
                        : context.colors.iconInactive,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Add ${widget.isPreTrip ? "Pre-Trip" : "Post-Trip"} Lounge',
                    style: TextStyle(
                      color: _selectedPricingType != null
                          ? Colors.white
                          : context.colors.textSecondary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransportSection() {
    if (_isLoadingTransport) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_transportLoadError != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.errorSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.errorLight.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Could not load transport options.',
                  style: TextStyle(
                    color: AppColors.errorDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _transportLoadError!,
              style: TextStyle(
                fontSize: 12,
                color: context.colors.textSecondary,
              ),
            ),
            TextButton.icon(
              onPressed: _loadTransportOptions,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Try Again'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ),
      );
    }
    if (_transportOptions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.inputBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colors.cardBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.map_outlined, color: context.colors.iconSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No transport pickup locations are currently available for this lounge.',
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final selectedTransport = widget.isPreTrip
        ? _preTripTransportType
        : _postTripTransportType;
    final selectedLocation = widget.isPreTrip
        ? _preTripPickupLocation
        : _postTripPickupLocation;

    final locsForPickup = selectedTransport == null
        ? _transportOptions
        : _transportOptions
              .where((o) => o.priceForVehicleType(selectedTransport) > 0)
              .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Pickup Location Selection
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.isPreTrip
                  ? 'Select Pick-up Station'
                  : 'Select Drop-off Location',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_transportOptions.length} Available',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._transportOptions.asMap().entries.map((entry) {
          final index = entry.key;
          final location = entry.value;
          final isSelected = selectedLocation == location.id;
          final icon = _locationIconPool[index % _locationIconPool.length];

          return GestureDetector(
            onTap: () {
              _updateState(() {
                if (widget.isPreTrip) {
                  _preTripPickupLocation = isSelected ? null : location.id;
                  // Reset transport type if location changes
                  if (_preTripPickupLocation == null) {
                    _preTripTransportType = null;
                  }
                } else {
                  _postTripPickupLocation = isSelected ? null : location.id;
                  // Reset transport type if location changes
                  if (_postTripPickupLocation == null) {
                    _postTripTransportType = null;
                  }
                }
                _updateDefaultTransportDateTime();
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected
                    ? context.colors.cardBackground
                    : context.colors.inputBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : context.colors.cardBorder,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.15)
                        : context.colors.shadowColor.withOpacity(0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.12)
                          : context.colors.chipBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.2)
                            : Colors.transparent,
                      ),
                    ),
                    child: Center(
                      child: Text(icon, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location.location,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: isSelected
                                ? AppColors.primary
                                : context.colors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.directions_walk,
                              size: 14,
                              color: context.colors.iconSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${location.distanceKm?.toStringAsFixed(1) ?? '0.0'} km',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.colors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.history,
                              size: 14,
                              color: context.colors.iconSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${location.estDurationMinutes ?? '--'} mins',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.primary,
                      size: 24,
                    )
                  else
                    Icon(
                      Icons.arrow_forward_ios,
                      color: context.colors.iconInactive,
                      size: 14,
                    ),
                ],
              ),
            ),
          );
        }).toList(),

        // 2. Vehicle Selection (Only visible when a location is selected)
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          child: selectedLocation != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 20),
                    Text(
                      'Select Vehicle Type',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (_offersVehicle('van')) ...[
                          Expanded(
                            child: _buildVehicleOption(
                              'van',
                              '🚐',
                              'Van',
                              '8 Seats',
                            ),
                          ),
                          if (_offersVehicle('car') || _offersVehicle('tuktuk'))
                            const SizedBox(width: 10),
                        ],
                        if (_offersVehicle('car')) ...[
                          Expanded(
                            child: _buildVehicleOption(
                              'car',
                              '🚗',
                              'Car',
                              '4 Seats',
                            ),
                          ),
                          if (_offersVehicle('tuktuk'))
                            const SizedBox(width: 10),
                        ],
                        if (_offersVehicle('tuktuk'))
                          Expanded(
                            child: _buildVehicleOption(
                              'tuktuk',
                              '🛺',
                              'Tuk Tuk',
                              '3 Seats',
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 8,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3CD),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFFECB5),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 24,
                            color: Color(0xFF856404),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Builder(
                              builder: (context) {
                                final pickupTime =
                                    _transportDateTime ?? _calculateDefaultTime();

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.isPreTrip
                                          ? 'Please arrive at the transport location by ${DateFormat('hh:mm a').format(pickupTime)}'
                                          : 'Transport will pick you up at ${DateFormat('hh:mm a').format(pickupTime)}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF856404),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Driver will contact you once the booking is confirmed for specific pickup timing.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF856404),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selectedTransport != null) _buildTimeSelectionCard(),
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 20.0),
                  child: Center(
                    child: Text(
                      'Select a pick-up station to see available transport prices',
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildVehicleOption(
    String type,
    String emoji,
    String name,
    String capacity,
  ) {
    final isSelected = widget.isPreTrip
        ? _preTripTransportType == type
        : _postTripTransportType == type;
    final priceLabel = _vehiclePriceLabel(type);

    return GestureDetector(
      onTap: () {
        _updateState(() {
          if (widget.isPreTrip) {
            _preTripTransportType = (_preTripTransportType == type)
                ? null
                : type;
          } else {
            _postTripTransportType = (_postTripTransportType == type)
                ? null
                : type;
          }
          _updateDefaultTransportDateTime();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.08)
              : context.colors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : context.colors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            if (isSelected)
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(2),
                child: const Icon(Icons.check, color: Colors.white, size: 12),
              ),
            Column(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(height: 10),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? AppColors.primary
                        : context.colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  capacity,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.8)
                        : context.colors.textSecondary,
                  ),
                ),
                if (priceLabel.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.15)
                          : context.colors.chipBackground,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      priceLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? AppColors.primary
                            : context.colors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelectionCard() {
    final formattedDate = _transportDateTime != null
        ? DateFormat('EEEE, dd MMM yyyy').format(_transportDateTime!)
        : 'Select Date';
    final formattedTime = _transportDateTime != null
        ? DateFormat('hh:mm a').format(_transportDateTime!)
        : 'Select Time';

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.colors.cardBorder.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: context.colors.cardBorder.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  size: 22,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Transport Schedule Time',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: context.colors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _selectTransportDate,
                    borderRadius: BorderRadius.circular(16),
                    splashColor: AppColors.primary.withOpacity(0.1),
                    highlightColor: AppColors.primary.withOpacity(0.05),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: context.colors.inputBackground,
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.15),
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_month_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Pick-up Date',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.colors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: context.colors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _selectTransportTime,
                    borderRadius: BorderRadius.circular(16),
                    splashColor: AppColors.primary.withOpacity(0.1),
                    highlightColor: AppColors.primary.withOpacity(0.05),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: context.colors.inputBackground,
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.15),
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Pick-up Time',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.colors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            formattedTime,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: context.colors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.1)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isPreTrip
                            ? 'Defaulted to pick you up to arrive before bus departure (Latest allowed: ${DateFormat('hh:mm a').format(_calculateDefaultTime())}).'
                            : 'Defaulted to pick you up after your ${_selectedPricingType == "until_bus" ? "5 hour" : "lounge stay"} duration (Earliest allowed: ${DateFormat('hh:mm a').format(_calculateDefaultTime())}).',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: context.colors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 14,
                            color: AppColors.warningDark,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Please arrive at the pickup location 15 minutes before the selected time.',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.warningDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectTransportDate() async {
    final defaultDateTime = _calculateDefaultTime();
    final initialDate = _transportDateTime ?? defaultDateTime;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final defaultDate = DateTime(
      defaultDateTime.year,
      defaultDateTime.month,
      defaultDateTime.day,
    );
    final firstDate = widget.isPreTrip ? today : defaultDate;
    final lastDate = widget.isPreTrip ? defaultDate : today.add(const Duration(days: 30));
    
    DateTime safeInitialDate = initialDate;
    if (safeInitialDate.isBefore(firstDate)) safeInitialDate = firstDate;
    if (safeInitialDate.isAfter(lastDate)) safeInitialDate = lastDate;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: safeInitialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppColors.primary),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final newDateTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _transportDateTime?.hour ?? defaultDateTime.hour,
        _transportDateTime?.minute ?? defaultDateTime.minute,
      );
      if (widget.isPreTrip) {
        if (newDateTime.isAfter(defaultDateTime)) {
          _showErrorSnackBar(
            'Selected date/time cannot be later than the default time (${DateFormat('yyyy-MM-dd hh:mm a').format(defaultDateTime)}).',
          );
          return;
        }
      } else {
        if (newDateTime.isBefore(defaultDateTime)) {
          _showErrorSnackBar(
            'Selected date/time cannot be earlier than the default time (${DateFormat('yyyy-MM-dd hh:mm a').format(defaultDateTime)}).',
          );
          return;
        }
      }
      _updateState(() {
        _transportDateTime = newDateTime;
      });
    }
  }

  Future<void> _selectTransportTime() async {
    final defaultDateTime = _calculateDefaultTime();
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _transportDateTime ?? defaultDateTime,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppColors.primary),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final currentDateTime = _transportDateTime ?? defaultDateTime;
      final newDateTime = DateTime(
        currentDateTime.year,
        currentDateTime.month,
        currentDateTime.day,
        picked.hour,
        picked.minute,
      );
      if (widget.isPreTrip) {
        if (newDateTime.isAfter(defaultDateTime)) {
          _showErrorSnackBar(
            'Selected time cannot be later than the default time (${DateFormat('hh:mm a').format(defaultDateTime)}).',
          );
          return;
        }
      } else {
        if (newDateTime.isBefore(defaultDateTime)) {
          _showErrorSnackBar(
            'Selected time cannot be earlier than the default time (${DateFormat('hh:mm a').format(defaultDateTime)}).',
          );
          return;
        }
      }
      _updateState(() {
        _transportDateTime = newDateTime;
      });
    }
  }
}

class AnimatedGradientButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  const AnimatedGradientButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  State<AnimatedGradientButton> createState() => _AnimatedGradientButtonState();
}

class _AnimatedGradientButtonState extends State<AnimatedGradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.isLoading) _controller.repeat();
  }

  @override
  void didUpdateWidget(AnimatedGradientButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.value = 0.0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double gradientOffset = _controller.value;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: widget.isLoading
                ? LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.05),
                      AppColors.primary.withOpacity(0.4),
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.4),
                      AppColors.primary.withOpacity(0.05),
                    ],
                    stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                    begin: Alignment(-2.0 + (gradientOffset * 4), -0.5),
                    end: Alignment(0.0 + (gradientOffset * 4), 0.5),
                  )
                : null,
            border: !widget.isLoading
                ? Border.all(color: AppColors.primary.withOpacity(0.15))
                : null,
            boxShadow: [
              if (widget.isLoading)
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.all(widget.isLoading ? 2.0 : 0),
          child: Container(
            decoration: BoxDecoration(
              color: context.colors.cardBackground,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.isLoading ? null : widget.onTap,
                borderRadius: BorderRadius.circular(13),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.isLoading)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        )
                      else
                        Icon(widget.icon, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        widget.isLoading
                            ? (widget.label.contains('Location')
                                  ? 'Pinpointing Location...'
                                  : 'Selecting from Map...')
                            : widget.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: widget.isLoading
                              ? AppColors.primary
                              : context.colors.textPrimary,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
