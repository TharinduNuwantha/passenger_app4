import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../../theme/app_colors.dart';
import '../../theme/app_text_style.dart';
import '../../providers/search_provider.dart';
import '../../services/search_service.dart';
import '../bus_booking/booking_conform.dart' hide AppColors;
import '../bus_booking/bus_booking_screen.dart';
import '../bus_booking/activities_screen.dart';
import '../lounge/lounge_list_screen.dart';
import '../lounge/my_lounge_bookings_screen.dart';
import '../profile/profile_screen.dart';

// Advertisement Model
class Advertisement {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String targetUrl;
  final int displayOrder;
  final bool active;
  final DateTime startDate;
  final DateTime endDate;
  final int priority;

  Advertisement({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.targetUrl,
    required this.displayOrder,
    required this.active,
    required this.startDate,
    required this.endDate,
    required this.priority,
  });
}

class DashBoard extends StatefulWidget {
  const DashBoard({super.key});

  @override
  State<DashBoard> createState() => _DashBoardState();
}

class _DashBoardState extends State<DashBoard> {
  int _selectedIndex = 0;

  bool isOneWay = true;
  DateTime? selectedDate;
  DateTime? returnDate;
  bool showPickupSuggestions = false;
  bool showDropSuggestions = false;

  final TextEditingController pickupController = TextEditingController();
  final TextEditingController dropController = TextEditingController();

  // Return trip controllers
  final TextEditingController returnPickupController = TextEditingController();
  final TextEditingController returnDropController = TextEditingController();

  List<Map<String, dynamic>> pickupAutocompleteSuggestions = [];
  List<Map<String, dynamic>> dropAutocompleteSuggestions = [];
  List<Map<String, dynamic>> returnPickupAutocompleteSuggestions = [];
  List<Map<String, dynamic>> returnDropAutocompleteSuggestions = [];
  bool isLoadingPickupSuggestions = false;
  bool isLoadingDropSuggestions = false;
  bool isLoadingReturnPickupSuggestions = false;
  bool isLoadingReturnDropSuggestions = false;
  bool showReturnPickupSuggestions = false;
  bool showReturnDropSuggestions = false;

  final String googleMapsApiKey = 'AIzaSyCs7dOTJ-9GlNB1T29k5Bexz8XOY1IuaA4';

  final List<Map<String, String>> nearbyLocations = [];

  // Search service for fuzzy matching
  final SearchService _searchService = SearchService();

  String? firstName;

  // Advertisement carousel
  final PageController _pageController = PageController();
  int _currentAdIndex = 0;
  Timer? _adTimer;

  // Advertisement data
  final List<Advertisement> _advertisements = [
    Advertisement(
      id: '1',
      title: 'Special Discount 20% Off',
      description: 'Book your bus ticket now and save big!',
      imageUrl:
          'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=800&q=80',
      targetUrl: 'https://example.com/offer1',
      displayOrder: 1,
      active: true,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 30)),
      priority: 80,
    ),
    Advertisement(
      id: '2',
      title: 'Weekend Lounge Access',
      description: 'Enjoy premium lounge with 15% off this weekend',
      imageUrl:
          'https://images.unsplash.com/photo-1517457373958-b7bdd4587205?w=800&q=80',
      targetUrl: 'https://example.com/offer2',
      displayOrder: 2,
      active: true,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 7)),
      priority: 90,
    ),
    Advertisement(
      id: '3',
      title: 'Travel Rewards Program',
      description: 'Earn points on every trip and redeem exciting rewards',
      imageUrl:
          'https://images.unsplash.com/photo-1483791424735-e9ad0209eea2?w=800&q=80',
      targetUrl: 'https://example.com/offer3',
      displayOrder: 3,
      active: true,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 60)),
      priority: 70,
    ),
    Advertisement(
      id: '4',
      title: 'Group Booking Offer',
      description: 'Save up to 25% when booking for 5 or more passengers',
      imageUrl:
          'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=800&q=80',
      targetUrl: 'https://example.com/offer4',
      displayOrder: 4,
      active: true,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 45)),
      priority: 75,
    ),
    Advertisement(
      id: '5',
      title: 'First Trip Bonus',
      description: 'Get 2% cashback on your first bus booking with us',
      imageUrl:
          'https://images.unsplash.com/photo-1523906834658-6e24ef2386f9?w=800&q=80',
      targetUrl: 'https://example.com/offer5',
      displayOrder: 5,
      active: true,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 90)),
      priority: 85,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadFirstName();
    pickupController.addListener(_onPickupTextChanged);
    dropController.addListener(_onDropTextChanged);
    returnPickupController.addListener(_onReturnPickupTextChanged);
    returnDropController.addListener(_onReturnDropTextChanged);
    _startAdTimer();
  }

  @override
  void dispose() {
    _adTimer?.cancel();
    _pageController.dispose();
    pickupController.removeListener(_onPickupTextChanged);
    dropController.removeListener(_onDropTextChanged);
    returnPickupController.removeListener(_onReturnPickupTextChanged);
    returnDropController.removeListener(_onReturnDropTextChanged);
    pickupController.dispose();
    dropController.dispose();
    returnPickupController.dispose();
    returnDropController.dispose();
    super.dispose();
  }

  void _startAdTimer() {
    _adTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_currentAdIndex < _advertisements.length - 1) {
        _currentAdIndex++;
      } else {
        _currentAdIndex = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentAdIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _loadFirstName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      firstName = prefs.getString('firstName') ?? 'User';
    });
  }

  // Listen to pickup field changes and fetch Google Maps autocomplete
  void _onPickupTextChanged() {
    final text = pickupController.text;
    if (text.length >= 2) {
      // Use Google Maps autocomplete for better UX
      _fetchAutocompleteSuggestions(text, isPickup: true);
    } else {
      setState(() {
        pickupAutocompleteSuggestions.clear();
        isLoadingPickupSuggestions = false;
      });
    }
  }

  // Listen to drop field changes and fetch Google Maps autocomplete
  void _onDropTextChanged() {
    final text = dropController.text;
    if (text.length >= 2) {
      // Use Google Maps autocomplete for better UX
      _fetchAutocompleteSuggestions(text, isPickup: false);
    } else {
      setState(() {
        dropAutocompleteSuggestions.clear();
        isLoadingDropSuggestions = false;
      });
    }
  }

  // Listen to return pickup field changes
  void _onReturnPickupTextChanged() {
    final text = returnPickupController.text;
    if (text.length >= 2) {
      _fetchReturnAutocompleteSuggestions(text, isPickup: true);
    } else {
      setState(() {
        returnPickupAutocompleteSuggestions.clear();
        isLoadingReturnPickupSuggestions = false;
      });
    }
  }

  // Listen to return drop field changes
  void _onReturnDropTextChanged() {
    final text = returnDropController.text;
    if (text.length >= 2) {
      _fetchReturnAutocompleteSuggestions(text, isPickup: false);
    } else {
      setState(() {
        returnDropAutocompleteSuggestions.clear();
        isLoadingReturnDropSuggestions = false;
      });
    }
  }

  // Fetch Google Places Autocomplete suggestions
  Future<void> _fetchAutocompleteSuggestions(
    String input, {
    required bool isPickup,
  }) async {
    setState(() {
      if (isPickup) {
        isLoadingPickupSuggestions = true;
      } else {
        isLoadingDropSuggestions = true;
      }
    });

    final String encodedInput = Uri.encodeComponent(input);
    final String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$encodedInput&components=country:lk&key=$googleMapsApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('API Status: ${data['status']}');

        if (data['status'] == 'OK' && data['predictions'] != null) {
          setState(() {
            if (isPickup) {
              pickupAutocompleteSuggestions = List<Map<String, dynamic>>.from(
                data['predictions'].map(
                  (prediction) => {
                    'description': prediction['description'],
                    'place_id': prediction['place_id'],
                  },
                ),
              );
              isLoadingPickupSuggestions = false;
            } else {
              dropAutocompleteSuggestions = List<Map<String, dynamic>>.from(
                data['predictions'].map(
                  (prediction) => {
                    'description': prediction['description'],
                    'place_id': prediction['place_id'],
                  },
                ),
              );
              isLoadingDropSuggestions = false;
            }
          });
          print(
            'Suggestions loaded: ${isPickup ? pickupAutocompleteSuggestions.length : dropAutocompleteSuggestions.length}',
          );
        } else {
          print('API returned status: ${data['status']}');
          setState(() {
            if (isPickup) {
              pickupAutocompleteSuggestions.clear();
              isLoadingPickupSuggestions = false;
            } else {
              dropAutocompleteSuggestions.clear();
              isLoadingDropSuggestions = false;
            }
          });
        }
      }
    } catch (e) {
      print('Error fetching autocomplete: $e');
      setState(() {
        if (isPickup) {
          pickupAutocompleteSuggestions.clear();
          isLoadingPickupSuggestions = false;
        } else {
          dropAutocompleteSuggestions.clear();
          isLoadingDropSuggestions = false;
        }
      });
    }
  }

  // Fetch Google Places Autocomplete suggestions for return trip
  Future<void> _fetchReturnAutocompleteSuggestions(
    String input, {
    required bool isPickup,
  }) async {
    setState(() {
      if (isPickup) {
        isLoadingReturnPickupSuggestions = true;
      } else {
        isLoadingReturnDropSuggestions = true;
      }
    });

    final String encodedInput = Uri.encodeComponent(input);
    final String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$encodedInput&components=country:lk&key=$googleMapsApiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['predictions'] != null) {
          setState(() {
            if (isPickup) {
              returnPickupAutocompleteSuggestions =
                  List<Map<String, dynamic>>.from(
                    data['predictions'].map(
                      (prediction) => {
                        'description': prediction['description'],
                        'place_id': prediction['place_id'],
                      },
                    ),
                  );
              isLoadingReturnPickupSuggestions = false;
            } else {
              returnDropAutocompleteSuggestions =
                  List<Map<String, dynamic>>.from(
                    data['predictions'].map(
                      (prediction) => {
                        'description': prediction['description'],
                        'place_id': prediction['place_id'],
                      },
                    ),
                  );
              isLoadingReturnDropSuggestions = false;
            }
          });
        } else {
          setState(() {
            if (isPickup) {
              returnPickupAutocompleteSuggestions.clear();
              isLoadingReturnPickupSuggestions = false;
            } else {
              returnDropAutocompleteSuggestions.clear();
              isLoadingReturnDropSuggestions = false;
            }
          });
        }
      }
    } catch (e) {
      print('Error fetching return autocomplete: $e');
      setState(() {
        if (isPickup) {
          returnPickupAutocompleteSuggestions.clear();
          isLoadingReturnPickupSuggestions = false;
        } else {
          returnDropAutocompleteSuggestions.clear();
          isLoadingReturnDropSuggestions = false;
        }
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        // Clear return date if it's before the new outbound date
        if (returnDate != null && returnDate!.isBefore(picked)) {
          returnDate = null;
        }
      });
    }
  }

  Future<void> _selectReturnDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          returnDate ??
          (selectedDate ?? DateTime.now()).add(const Duration(days: 1)),
      firstDate: selectedDate ?? DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        returnDate = picked;
      });
    }
  }

  // Navigate to map and get selected location
  Future<void> _navigateToMapForLocation({required bool isPickup}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapSelectionScreen(apiKey: googleMapsApiKey),
      ),
    );

    if (result != null && result is String) {
      setState(() {
        if (isPickup) {
          pickupController.text = result;
          showPickupSuggestions = false;
        } else {
          dropController.text = result;
          showDropSuggestions = false;
        }
      });

      // Auto-navigate to booking if all fields are filled
      _autoNavigateToBooking();
    }
  }

  // Extract keywords from Google Maps location for fuzzy matching
  // Example: "Colombo Fort Railway Station, Colombo, Western Province, Sri Lanka" → "Colombo Fort"
  String _extractKeywords(String googleLocation) {
    // Split by comma and take the first part (usually the main location name)
    final parts = googleLocation.split(',');
    if (parts.isEmpty) return googleLocation;

    // Take first part and clean it up
    String keyword = parts[0].trim();

    // Remove common suffixes like "Railway Station", "Bus Stand", etc.
    keyword = keyword
        .replaceAll(
          RegExp(r'\s+(Railway|Bus|Train)\s+Station', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'\s+Bus\s+Stand', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+Terminal', caseSensitive: false), '')
        .trim();

    return keyword;
  }

  // Fuzzy match Google location to backend bus stop
  Future<String?> _fuzzyMatchToStop(String googleLocation) async {
    try {
      // Extract keywords from the Google location
      final keywords = _extractKeywords(googleLocation);

      // Call backend autocomplete API with extracted keywords
      final suggestions = await _searchService.getStopAutocomplete(
        searchTerm: keywords,
        limit: 5,
      );

      // If we have matches, use the first one (highest relevance)
      if (suggestions.isNotEmpty) {
        print(
          'Fuzzy matched "$googleLocation" → "${suggestions.first.stopName}"',
        );
        return suggestions.first.stopName;
      }

      // If no match, return the extracted keywords
      print(
        'No fuzzy match for "$googleLocation", using keywords: "$keywords"',
      );
      return keywords;
    } catch (e) {
      print('Error fuzzy matching: $e');
      // Fallback to extracted keywords
      return _extractKeywords(googleLocation);
    }
  }

  // Auto navigate to booking screen (triggers search)
  Future<void> _autoNavigateToBooking() async {
    if (pickupController.text.isEmpty || dropController.text.isEmpty) {
      return;
    }

    // Fuzzy match pickup location to bus stop
    final fromStop = await _fuzzyMatchToStop(pickupController.text);

    // Fuzzy match drop location to bus stop
    final toStop = await _fuzzyMatchToStop(dropController.text);

    if (fromStop == null || toStop == null) {
      // Show error if fuzzy matching failed completely
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not find bus stops for selected locations'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    // Use selected date or default to next 7 days
    final searchDate = selectedDate ?? DateTime.now();

    // Navigate to bus list screen with search
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              BusListScreen(date: searchDate, pickup: fromStop, drop: toStop),
        ),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    var singleChildScrollView = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: const AssetImage(
                  'assets/images/johns_photo.png',
                ),
                backgroundColor: AppColors.white70.withOpacity(0.3),
              ),
              Row(
                children: [
                  const GradientGlowVersion(version: '2.0.0'),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Hello ${firstName ?? 'User'},', style: AppTextStyles.h2),
          Text('Where to go?', style: AppTextStyles.h2),
          const SizedBox(height: 15),

          // Date Pickers
          Row(
            children: [
              // Outbound Date Picker
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            selectedDate == null
                                ? 'Departure'
                                : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!isOneWay) ...[
                const SizedBox(width: 10),
                // Return Date Picker
                Expanded(
                  child: InkWell(
                    onTap: () => _selectReturnDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.event_repeat,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              returnDate == null
                                  ? 'Return'
                                  : '${returnDate!.day}/${returnDate!.month}/${returnDate!.year}',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),

          // Trip type toggle
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      isOneWay = true;
                      returnDate = null;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isOneWay ? AppColors.secondary : AppColors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomLeft: Radius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isOneWay
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'One way',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isOneWay = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !isOneWay
                            ? AppColors.secondary
                            : AppColors.white,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            !isOneWay
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Return trip',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),

          // Input Fields
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PICKUP FIELD
                Row(
                  children: [
                    const Icon(
                      Icons.my_location,
                      color: Colors.green,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'PickUp',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Focus(
                  onFocusChange: (hasFocus) {
                    setState(() {
                      showPickupSuggestions = hasFocus;
                      if (!hasFocus) {
                        // Clear suggestions when losing focus
                        pickupAutocompleteSuggestions.clear();
                      }
                    });
                  },
                  child: TextField(
                    controller: pickupController,
                    style: const TextStyle(color: Colors.black),
                    decoration: const InputDecoration(
                      hintText: 'Your Location',
                      border: UnderlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onTap: () {
                      setState(() {
                        showPickupSuggestions = true;
                      });
                    },
                  ),
                ),

                // PICKUP SUGGESTIONS
                if (showPickupSuggestions) ...[
                  const SizedBox(height: 10),

                  // Show loading indicator for pickup
                  if (isLoadingPickupSuggestions)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    ),

                  // Show Google autocomplete suggestions for pickup
                  if (!isLoadingPickupSuggestions &&
                      pickupAutocompleteSuggestions.isNotEmpty)
                    Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Search Results',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        ...pickupAutocompleteSuggestions.map(
                          (suggestion) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.location_on,
                              color: AppColors.primary,
                            ),
                            title: Text(
                              suggestion['description'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                pickupController.text =
                                    suggestion['description'];
                                showPickupSuggestions = false;
                                pickupAutocompleteSuggestions.clear();
                                FocusScope.of(context).unfocus();
                              });
                              // Auto-navigate to booking after selection
                              _autoNavigateToBooking();
                            },
                          ),
                        ),
                        const Divider(height: 20),
                      ],
                    ),

                  // Show nearby locations when no search or typing less than 3 chars
                  if (!isLoadingPickupSuggestions &&
                      pickupAutocompleteSuggestions.isEmpty)
                    Column(
                      children: [
                        if (pickupController.text.length <= 2) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Nearby Locations',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                          ...nearbyLocations.map(
                            (loc) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.location_pin,
                                color: AppColors.primary,
                              ),
                              title: Text(
                                loc["title"]!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              subtitle: Text(
                                '${loc["subtitle"]!}\n${loc["distance"]!}',
                                style: const TextStyle(color: Colors.black54),
                              ),
                              onTap: () {
                                setState(() {
                                  pickupController.text = loc["title"]!;
                                  showPickupSuggestions = false;
                                  FocusScope.of(context).unfocus();
                                });
                                // Auto-navigate to booking after selection
                                _autoNavigateToBooking();
                              },
                            ),
                          ),
                          const Divider(height: 20),
                        ],
                      ],
                    ),

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.bookmark_outline,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      'Saved Addresses',
                      style: TextStyle(color: Colors.black54),
                    ),
                    onTap: () {
                      // Handle saved addresses
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Saved addresses feature'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      'Set location on map',
                      style: TextStyle(color: Colors.black54),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.black54,
                    ),
                    onTap: () {
                      setState(() {
                        showPickupSuggestions = false;
                      });
                      FocusScope.of(context).unfocus();
                      _navigateToMapForLocation(isPickup: true);
                    },
                  ),
                ],

                // Spacing between pickup and drop
                const SizedBox(height: 10),

                // DROP FIELD
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.red, size: 18),
                    const SizedBox(width: 6),
                    const Text(
                      'Drop',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Focus(
                  onFocusChange: (hasFocus) {
                    setState(() {
                      showDropSuggestions = hasFocus;
                      if (!hasFocus) {
                        // Clear suggestions when losing focus
                        dropAutocompleteSuggestions.clear();
                      }
                    });
                  },
                  child: TextField(
                    controller: dropController,
                    style: const TextStyle(color: Colors.black),
                    decoration: const InputDecoration(
                      hintText: 'Where are you going?',
                      border: UnderlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onTap: () {
                      setState(() {
                        showDropSuggestions = true;
                      });
                    },
                  ),
                ),

                // DROP SUGGESTIONS
                if (showDropSuggestions) ...[
                  const SizedBox(height: 10),

                  // Show loading indicator
                  if (isLoadingDropSuggestions)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    ),

                  // Show Google autocomplete suggestions
                  if (!isLoadingDropSuggestions &&
                      dropAutocompleteSuggestions.isNotEmpty)
                    Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Search Results',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        ...dropAutocompleteSuggestions.map(
                          (suggestion) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.location_on,
                              color: AppColors.primary,
                            ),
                            title: Text(
                              suggestion['description'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                dropController.text = suggestion['description'];
                                showDropSuggestions = false;
                                dropAutocompleteSuggestions.clear();
                                FocusScope.of(context).unfocus();
                              });
                              // Auto-navigate to booking after selection
                              _autoNavigateToBooking();
                            },
                          ),
                        ),
                      ],
                    ),

                  // Show nearby locations when no search or no results
                  if (!isLoadingDropSuggestions &&
                      dropAutocompleteSuggestions.isEmpty &&
                      dropController.text.length <= 2)
                    Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Nearby Locations',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        ...nearbyLocations.map(
                          (loc) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.location_pin,
                              color: AppColors.primary,
                            ),
                            title: Text(
                              loc["title"]!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              '${loc["subtitle"]!}\n${loc["distance"]!}',
                              style: const TextStyle(color: Colors.black54),
                            ),
                            onTap: () {
                              setState(() {
                                dropController.text = loc["title"]!;
                                showDropSuggestions = false;
                                FocusScope.of(context).unfocus();
                              });
                              // Auto-navigate to booking after selection
                              _autoNavigateToBooking();
                            },
                          ),
                        ),
                      ],
                    ),

                  const Divider(height: 20),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.bookmark_outline,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      'Saved Addresses',
                      style: TextStyle(color: Colors.black54),
                    ),
                    onTap: () {
                      // Handle saved addresses
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Saved addresses feature'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      'Set location on map',
                      style: TextStyle(color: Colors.black54),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.black54,
                    ),
                    onTap: () {
                      setState(() {
                        showDropSuggestions = false;
                      });
                      FocusScope.of(context).unfocus();
                      _navigateToMapForLocation(isPickup: false);
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Return Trip Section with Input Fields
          if (!isOneWay) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.secondary, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
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
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.swap_horiz,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Return Trip Booking',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // RETURN PICKUP FIELD
                  Row(
                    children: [
                      const Icon(
                        Icons.my_location,
                        color: Colors.green,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Return PickUp',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Focus(
                    onFocusChange: (hasFocus) {
                      setState(() {
                        showReturnPickupSuggestions = hasFocus;
                        if (!hasFocus) {
                          returnPickupAutocompleteSuggestions.clear();
                        }
                      });
                    },
                    child: TextField(
                      controller: returnPickupController,
                      style: const TextStyle(color: Colors.black),
                      decoration: const InputDecoration(
                        hintText: 'Return pickup location',
                        border: UnderlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onTap: () {
                        setState(() {
                          showReturnPickupSuggestions = true;
                        });
                      },
                    ),
                  ),

                  // RETURN PICKUP SUGGESTIONS
                  if (showReturnPickupSuggestions) ...[
                    const SizedBox(height: 10),
                    if (isLoadingReturnPickupSuggestions)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    if (!isLoadingReturnPickupSuggestions &&
                        returnPickupAutocompleteSuggestions.isNotEmpty)
                      Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Search Results',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                          ...returnPickupAutocompleteSuggestions.map(
                            (suggestion) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.location_on,
                                color: AppColors.primary,
                              ),
                              title: Text(
                                suggestion['description'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  returnPickupController.text =
                                      suggestion['description'];
                                  showReturnPickupSuggestions = false;
                                  returnPickupAutocompleteSuggestions.clear();
                                  FocusScope.of(context).unfocus();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                  ],

                  const SizedBox(height: 16),

                  // RETURN DROP FIELD
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Return Drop',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Focus(
                    onFocusChange: (hasFocus) {
                      setState(() {
                        showReturnDropSuggestions = hasFocus;
                        if (!hasFocus) {
                          returnDropAutocompleteSuggestions.clear();
                        }
                      });
                    },
                    child: TextField(
                      controller: returnDropController,
                      style: const TextStyle(color: Colors.black),
                      decoration: const InputDecoration(
                        hintText: 'Return destination',
                        border: UnderlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onTap: () {
                        setState(() {
                          showReturnDropSuggestions = true;
                        });
                      },
                    ),
                  ),

                  // RETURN DROP SUGGESTIONS
                  if (showReturnDropSuggestions) ...[
                    const SizedBox(height: 10),
                    if (isLoadingReturnDropSuggestions)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    if (!isLoadingReturnDropSuggestions &&
                        returnDropAutocompleteSuggestions.isNotEmpty)
                      Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Search Results',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                          ...returnDropAutocompleteSuggestions.map(
                            (suggestion) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.location_on,
                                color: AppColors.primary,
                              ),
                              title: Text(
                                suggestion['description'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  returnDropController.text =
                                      suggestion['description'];
                                  showReturnDropSuggestions = false;
                                  returnDropAutocompleteSuggestions.clear();
                                  FocusScope.of(context).unfocus();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Advertisement Carousel
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentAdIndex = index;
                    });
                  },
                  itemCount: _advertisements.length,
                  itemBuilder: (context, index) {
                    final ad = _advertisements[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Background Image
                            Image.network(
                              ad.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppColors.secondary,
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    size: 50,
                                    color: AppColors.primary,
                                  ),
                                );
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      color: AppColors.secondary,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value:
                                              loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                              : null,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    );
                                  },
                            ),
                            // Gradient Overlay
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7),
                                  ],
                                ),
                              ),
                            ),
                            // Content
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    ad.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black45,
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    ad.description,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black45,
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 10,
                                      ),
                                    ),
                                    onPressed: () {
                                      if (pickupController.text.isEmpty ||
                                          dropController.text.isEmpty ||
                                          selectedDate == null) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Please select a date and enter pickup & drop locations.',
                                            ),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                        );
                                      } else {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => BusListScreen(
                                              date: selectedDate,
                                              pickup: pickupController.text,
                                              drop: dropController.text,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    child: const Text(
                                      'Book now',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                // Page Indicators
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _advertisements.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentAdIndex == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentAdIndex == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    final List<Widget> pages = [
      // Page 0: Your Full Dashboard UI
      SafeArea(child: singleChildScrollView),

      const ActivitiesScreen(),
      const LocationPage(),
      const LoungeListScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.weekend), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

// Map Selection Screen with Google Maps
class MapSelectionScreen extends StatefulWidget {
  final String apiKey;

  const MapSelectionScreen({super.key, required this.apiKey});

  @override
  State<MapSelectionScreen> createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  GoogleMapController? _mapController;
  LatLng _selectedLocation = const LatLng(7.2905, 80.6337); // Sri Lanka center
  String _selectedAddress = 'Selected Location';
  bool _isLoading = false;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_selectedLocation, 15),
        );
        _getAddressFromLatLng(_selectedLocation);
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  // Get address from coordinates using Geocoding API
  Future<void> _getAddressFromLatLng(LatLng position) async {
    setState(() {
      _isLoading = true;
    });

    final String url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=${widget.apiKey}';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          setState(() {
            _selectedAddress = data['results'][0]['formatted_address'];
            _markers.clear();
            _markers.add(
              Marker(
                markerId: const MarkerId('selected'),
                position: position,
                infoWindow: InfoWindow(title: _selectedAddress),
              ),
            );
          });
        }
      }
    } catch (e) {
      print('Error getting address: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Handle map tap
  void _onMapTapped(LatLng position) {
    setState(() {
      _selectedLocation = position;
    });
    _getAddressFromLatLng(position);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Select Location on Map'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation,
              zoom: 15,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onTap: _onMapTapped,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
          ),

          // Address display card
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _isLoading
                          ? const Text('Loading address...')
                          : Text(
                              _selectedAddress,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Confirm button at bottom
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                Navigator.pop(context, _selectedAddress);
              },
              child: const Text(
                'Confirm Location',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- PLACEHOLDER PAGES ---

class LocationPage extends StatelessWidget {
  const LocationPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(child: Text('Offers Page', style: AppTextStyles.h2)),
    );
  }
}

class WeekendPage extends StatelessWidget {
  const WeekendPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(child: Text('Tours Page', style: AppTextStyles.h2)),
    );
  }
}

class profile extends StatelessWidget {
  const profile({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(child: Text('Tours Page', style: AppTextStyles.h2)),
    );
  }
}

// =============================================================================
// GRADIENT GLOW VERSION BADGE - Gold gradient with animated glow
// =============================================================================

class GradientGlowVersion extends StatefulWidget {
  final String version;
  const GradientGlowVersion({super.key, required this.version});

  @override
  State<GradientGlowVersion> createState() => _GradientGlowVersionState();
}

class _GradientGlowVersionState extends State<GradientGlowVersion>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 750),
      vsync: this,
    )..repeat(reverse: true);
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
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFD4AF37), // Liora Gold
                Color(0xFFC5A028), // Subtle Gold Shift
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFFD4AF37,
                ).withOpacity(0.3 + (_controller.value * 0.4)),
                blurRadius: 10 + (_controller.value * 8),
                spreadRadius: 1 + (_controller.value * 3),
              ),
              BoxShadow(
                color: const Color(
                  0xFFC5A028,
                ).withOpacity(0.2 + (_controller.value * 0.3)),
                blurRadius: 15 + (_controller.value * 5),
                spreadRadius: 0,
                offset: const Offset(3, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, color: Colors.white, size: 14),
              const SizedBox(width: 4),
              Text(
                'v${widget.version}',
                style: const TextStyle(
                  color: Color(0xFF111C2E), // Royal Navy
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
