import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../../theme/app_colors.dart';
import '../../services/advertisement_service.dart';
import '../../services/notification_service.dart';
import '../../services/booking_service.dart';
import '../../models/advertisement_model.dart';
import '../../models/booking_models.dart';
import '../../services/search_service.dart';
import '../../theme/app_text_style.dart';
import '../bus_booking/activities_screen.dart';
import '../bus_booking/booking_conform.dart' hide AppColors;
import '../bus_booking/bus_booking_screen.dart';
import '../bus_booking/nav_booking_screen.dart';
import '../bus_booking/check_in_status_screen.dart';
import '../bus_booking/booking_qr_screen.dart' hide CheckInStatusScreen;
import '../bus_booking/booking_detail_screen.dart';
import '../lounge/lounge_booking_screen.dart';
import '../lounge/lounge_list_screen.dart';
import '../profile/profile_screen.dart';
import '../notifications/notifications_screen.dart';
import '../advertisements/advertisement_detail_screen.dart';
import '../bus_tracking/bus_tracking_screen.dart';

class DashBoard extends StatefulWidget {
  const DashBoard({super.key});

  @override
  State<DashBoard> createState() => _DashBoardState();
}

class _DashBoardState extends State<DashBoard> with WidgetsBindingObserver {
  int _selectedIndex = 0;

  bool isOneWay = true;
  DateTime? selectedDate;
  DateTime? returnDate;
  bool showPickupSuggestions = false;
  bool showDropSuggestions = false;
  bool showStopSuggestions = false;

  late AdvertisementService _advertisementService;
  late NotificationService _notificationService;
  late BookingService _bookingService;
  List<Advertisement> advertisements = [];
  String? userId;
  int _unreadNotifications = 0;

  // Upcoming bookings
  List<BookingListItem> _upcomingBookings = [];
  bool _isLoadingBookings = false;
  PageController _bookingPageController = PageController();
  Timer? _bookingTimer;
  int _currentBookingIndex = 0;

  // Advertisement carousel
  PageController _adPageController = PageController();
  Timer? _adTimer;
  int _currentAdIndex = 0;

  final TextEditingController pickupController = TextEditingController();
  final TextEditingController dropController = TextEditingController();
  final TextEditingController stopController = TextEditingController();

  // Return trip controllers
  final TextEditingController returnPickupController = TextEditingController();
  final TextEditingController returnDropController = TextEditingController();
  final TextEditingController returnStopController = TextEditingController();

  List<Map<String, dynamic>> pickupAutocompleteSuggestions = [];
  List<Map<String, dynamic>> dropAutocompleteSuggestions = [];
  List<Map<String, dynamic>> stopAutocompleteSuggestions = [];
  List<Map<String, dynamic>> returnPickupAutocompleteSuggestions = [];
  List<Map<String, dynamic>> returnDropAutocompleteSuggestions = [];
  bool isLoadingPickupSuggestions = false;
  bool isLoadingDropSuggestions = false;
  bool isLoadingStopSuggestions = false;
  bool isLoadingReturnPickupSuggestions = false;
  bool isLoadingReturnDropSuggestions = false;
  bool showReturnPickupSuggestions = false;
  bool showReturnDropSuggestions = false;

  final String googleMapsApiKey = 'AIzaSyCs7dOTJ-9GlNB1T29k5Bexz8XOY1IuaA4';

  final List<Map<String, String>> nearbyLocations = [];

  // Search service for fuzzy matching
  final SearchService _searchService = SearchService();

  String? firstName;

  // Active booking data
  Map<String, dynamic>? activeBooking;
  bool hasActiveBooking = false;

  var ThemeSelectorWidget;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _advertisementService = AdvertisementService();
    _notificationService = NotificationService();
    _bookingService = BookingService();
    _loadUserData();
    _loadActiveBooking();
    _loadUpcomingBookings();
    _loadDummyAdvertisements();
    _loadNotifications();
    pickupController.addListener(_onPickupTextChanged);
    dropController.addListener(_onDropTextChanged);
    stopController.addListener(_onStopTextChanged);
    returnPickupController.addListener(_onReturnPickupTextChanged);
    returnDropController.addListener(_onReturnDropTextChanged);
    _startAdCarousel();
    _startBookingCarousel();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _adTimer?.cancel();
    _bookingTimer?.cancel();
    _adPageController.dispose();
    _bookingPageController.dispose();
    pickupController.removeListener(_onPickupTextChanged);
    dropController.removeListener(_onDropTextChanged);
    stopController.removeListener(_onStopTextChanged);
    returnPickupController.removeListener(_onReturnPickupTextChanged);
    returnDropController.removeListener(_onReturnDropTextChanged);
    pickupController.dispose();
    dropController.dispose();
    stopController.dispose();
    returnPickupController.dispose();
    returnDropController.dispose();
    returnStopController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh active booking when app comes back to foreground
      _loadActiveBooking();
      _loadNotifications();
      _loadUpcomingBookings(); // Refresh upcoming bookings
    }
  }

  void _clearSearchFields() {
    setState(() {
      pickupController.clear();
      dropController.clear();
      stopController.clear();
      returnPickupController.clear();
      returnDropController.clear();
      returnStopController.clear();
      selectedDate = null;
      returnDate = null;
      pickupAutocompleteSuggestions.clear();
      dropAutocompleteSuggestions.clear();
      stopAutocompleteSuggestions.clear();
      returnPickupAutocompleteSuggestions.clear();
      returnDropAutocompleteSuggestions.clear();
      showPickupSuggestions = false;
      showDropSuggestions = false;
      showStopSuggestions = false;
      showReturnPickupSuggestions = false;
      showReturnDropSuggestions = false;
    });
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      firstName = prefs.getString('firstName') ?? 'User';
      userId = prefs.getString('userId');
    });
  }

  Future<void> _loadActiveBooking() async {
    final prefs = await SharedPreferences.getInstance();
    final bookingData = prefs.getString('activeBooking');
    if (bookingData != null) {
      setState(() {
        activeBooking = json.decode(bookingData);
        hasActiveBooking = true;
      });
      // Clear search fields when active booking is loaded
      _clearSearchFields();
    } else {
      setState(() {
        activeBooking = null;
        hasActiveBooking = false;
      });
    }
  }

  Future<void> saveActiveBooking(Map<String, dynamic> booking) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('activeBooking', json.encode(booking));
    setState(() {
      activeBooking = booking;
      hasActiveBooking = true;
    });
  }

  Future<void> clearActiveBooking() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('activeBooking');
    setState(() {
      activeBooking = null;
      hasActiveBooking = false;
    });
  }

  Future<void> _loadUpcomingBookings() async {
    setState(() {
      _isLoadingBookings = true;
    });

    try {
      final bookings = await _bookingService.getUpcomingBookings(limit: 5);
      // Show all upcoming bookings
      setState(() {
        _upcomingBookings = bookings;
        _isLoadingBookings = false;
      });
    } catch (e) {
      print('Failed to load upcoming bookings: $e');
      setState(() {
        _isLoadingBookings = false;
      });
    }
  }

  void _loadDummyAdvertisements() {
    setState(() {
      advertisements = [
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
          title: 'Weekend Travel Deals',
          description: 'Explore new destinations every weekend',
          imageUrl:
              'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=800&q=80',
          targetUrl: 'https://example.com/offer2',
          displayOrder: 2,
          active: true,
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 30)),
          priority: 70,
        ),
        Advertisement(
          id: '3',
          title: 'Premium Lounge Access',
          description: 'Upgrade your travel experience with lounge benefits',
          imageUrl:
              'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?w=800&q=80',
          targetUrl: 'https://example.com/offer3',
          displayOrder: 3,
          active: true,
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 30)),
          priority: 60,
        ),
        Advertisement(
          id: '4',
          title: 'Early Bird Special',
          description: 'Book 7 days in advance and get 15% off',
          imageUrl:
              'https://images.unsplash.com/photo-1570125909232-eb263c188f7e?w=800&q=80',
          targetUrl: 'https://example.com/offer4',
          displayOrder: 4,
          active: true,
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 30)),
          priority: 50,
        ),
        Advertisement(
          id: '5',
          title: 'Family Package',
          description: 'Travel with family and enjoy group discounts',
          imageUrl:
              'https://images.unsplash.com/photo-1511632765486-a01980e01a18?w=800&q=80',
          targetUrl: 'https://example.com/offer5',
          displayOrder: 5,
          active: true,
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 30)),
          priority: 40,
        ),
      ];
    });
  }

  void _startAdCarousel() {
    _adTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (advertisements.isNotEmpty && _adPageController.hasClients) {
        int nextPage = (_currentAdIndex + 1) % advertisements.length;
        _adPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _startBookingCarousel() {
    _bookingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_upcomingBookings.isNotEmpty && _bookingPageController.hasClients) {
        int nextPage = (_currentBookingIndex + 1) % _upcomingBookings.length;
        _bookingPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _navigateToAdDetail(Advertisement ad) async {
    // Track view
    await _advertisementService.trackView(ad.id);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdvertisementDetailScreen(advertisement: ad),
        ),
      );
    }
  }

  Future<void> _loadNotifications() async {
    if (userId != null) {
      final count = await _notificationService.getUnreadCount(userId!);
      setState(() {
        _unreadNotifications = count;
      });
    }
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationsScreen(userId: userId ?? ''),
      ),
    ).then((_) {
      _loadNotifications(); // Refresh count when returning
    });
  }

  // Listen to pickup field changes and fetch autocomplete
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
      _fetchAutocompleteSuggestions(text, isPickup: false, isStop: false);
    } else {
      setState(() {
        dropAutocompleteSuggestions.clear();
        isLoadingDropSuggestions = false;
      });
    }

    // Auto-fill return pickup with one-way drop location (only for return trips)
    if (!isOneWay && text.isNotEmpty && pickupController.text.isEmpty) {
      // This will auto-populate the pickup field for return journey
      // User can still change it manually if needed
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !isOneWay && pickupController.text.isEmpty) {
          setState(() {
            // Return pickup = One-way drop location
          });
        }
      });
    }
  }

  // Listen to stop field changes and fetch Google Maps autocomplete
  void _onStopTextChanged() {
    final text = stopController.text;
    if (text.length >= 2) {
      _fetchAutocompleteSuggestions(text, isPickup: false, isStop: true);
    } else {
      setState(() {
        stopAutocompleteSuggestions.clear();
        isLoadingStopSuggestions = false;
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
    bool isStop = false,
  }) async {
    setState(() {
      if (isPickup) {
        isLoadingPickupSuggestions = true;
      } else if (isStop) {
        isLoadingStopSuggestions = true;
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
            } else if (isStop) {
              stopAutocompleteSuggestions = List<Map<String, dynamic>>.from(
                data['predictions'].map(
                  (prediction) => {
                    'description': prediction['description'],
                    'place_id': prediction['place_id'],
                  },
                ),
              );
              isLoadingStopSuggestions = false;
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
            } else if (isStop) {
              stopAutocompleteSuggestions.clear();
              isLoadingStopSuggestions = false;
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
        } else if (isStop) {
          stopAutocompleteSuggestions.clear();
          isLoadingStopSuggestions = false;
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

  Future<void> _selectDate(
    BuildContext context, {
    bool isReturn = false,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isReturn
          ? (returnDate ?? selectedDate ?? DateTime.now())
          : (selectedDate ?? DateTime.now()),
      firstDate: isReturn && selectedDate != null
          ? selectedDate!
          : DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isReturn) {
          returnDate = picked;
        } else {
          selectedDate = picked;
        }
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

    // Navigate to bus list screen with search (no stop location)
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BusListScreen(
            date: searchDate,
            returnDate: returnDate,
            pickup: fromStop,
            drop: toStop,
            stop: null, // Remove stop parameter
          ),
        ),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildUpcomingBookingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.confirmation_number,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Upcoming Bookings',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/bookings');
              },
              child: Text(
                'View All',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _bookingPageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentBookingIndex = index;
                    });
                  },
                  itemCount: _upcomingBookings.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _buildBookingCard(_upcomingBookings[index]),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              // Page indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _upcomingBookings.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentBookingIndex == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentBookingIndex == index
                          ? AppColors.primary
                          : AppColors.primary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
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

  Widget _buildBookingCard(BookingListItem booking) {
    final departureDate = booking.departureDatetime;
    final routeName = booking.routeName ?? 'Bus Trip';
    final numberOfSeats = booking.numberOfSeats ?? 1;
    final totalPrice = booking.formattedTotal;
    final status = booking.bookingStatus;

    Color statusColor;
    Color bgColor;
    IconData statusIcon;

    switch (status) {
      case MasterBookingStatus.confirmed:
        statusColor = const Color(0xFF4CAF50);
        bgColor = const Color(0xFF4CAF50).withOpacity(0.1);
        statusIcon = Icons.check_circle;
        break;
      case MasterBookingStatus.pending:
        statusColor = Colors.orange;
        bgColor = Colors.orange.withOpacity(0.1);
        statusIcon = Icons.pending;
        break;
      case MasterBookingStatus.cancelled:
        statusColor = Colors.red;
        bgColor = Colors.red.withOpacity(0.1);
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        bgColor = Colors.grey.withOpacity(0.1);
        statusIcon = Icons.info;
    }

    return GestureDetector(
      onTap: () {
        // Navigate to BookingDetailScreen for full booking information
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookingDetailScreen(bookingId: booking.id),
          ),
        ).then((_) {
          // Refresh bookings when returning from detail screen
          _loadUpcomingBookings();
        });
      },
      child: Container(
        width: MediaQuery.of(context).size.width - 48,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          status.displayName,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    booking.bookingType == BookingType.loungeOnly ||
                            booking.bookingType == BookingType.busWithLounge
                        ? Icons.weekend
                        : Icons.directions_bus,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Route Name
              Text(
                routeName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              // Booking Reference
              Text(
                'Ref: ${booking.bookingReference}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              // Bottom Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.event_seat,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$numberOfSeats seat${numberOfSeats > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    totalPrice,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              if (departureDate != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      _formatBookingDate(departureDate),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatBookingDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now).inDays;

    if (difference == 0) {
      return 'Today, ${_formatTime(dateTime)}';
    } else if (difference == 1) {
      return 'Tomorrow, ${_formatTime(dateTime)}';
    } else if (difference < 7) {
      return 'In $difference days, ${_formatTime(dateTime)}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${_formatTime(dateTime)}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12
        ? dateTime.hour - 12
        : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    var singleChildScrollView = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello ${firstName ?? 'User'},',
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.explore_outlined,
                        color: AppColors.secondaryLight,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Where to go?',
                        style: AppTextStyles.h2.copyWith(
                          color: AppColors.textLight,
                          fontWeight: FontWeight.w500,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              GestureDetector(
                onTap: _openNotifications,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowMedium,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      const Icon(
                        Icons.notifications,
                        color: AppColors.primary,
                        size: 28,
                      ),
                      if (_unreadNotifications > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.notificationBadge,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              _unreadNotifications > 9
                                  ? '9+'
                                  : '$_unreadNotifications',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Upcoming Bookings Section
          if (_upcomingBookings.isNotEmpty) _buildUpcomingBookingsSection(),

          const SizedBox(height: 16),

          // Active Trip Notification Card (old booking - keep for now)
          if (hasActiveBooking && activeBooking != null)
            GestureDetector(
              onTap: () {
                // Navigate to QR screen with booking data
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        BookingQRScreen(bookingData: activeBooking!),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.infoLight, AppColors.surfaceWhite],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.info, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.info.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.qr_code_2,
                        color: AppColors.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'ACTIVE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Tap to view QR',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            activeBooking!['route'] ?? 'Unknown Route',
                            style: TextStyle(
                              color: Colors.grey[900],
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Date: ${activeBooking!['dateTime'] ?? 'N/A'}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Seat: ${activeBooking!['seatNo'] ?? 'N/A'} | ${activeBooking!['busType'] ?? 'N/A'}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ref: ${activeBooking!['referenceNo'] ?? 'N/A'}',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'View QR',
                          style: TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          if (hasActiveBooking) const SizedBox(height: 20),

          // Date Pickers Row
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowLight,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          color: AppColors.primary,
                          size: 22,
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
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, isReturn: true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
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
                          const SizedBox(width: 6),
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
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isOneWay = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: isOneWay
                            ? LinearGradient(
                                colors: [
                                  AppColors.secondary,
                                  AppColors.secondary.withOpacity(0.8),
                                ],
                              )
                            : null,
                        color: isOneWay ? null : AppColors.white,
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
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'One way',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
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
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: !isOneWay
                            ? LinearGradient(
                                colors: [
                                  AppColors.secondary,
                                  AppColors.secondary.withOpacity(0.8),
                                ],
                              )
                            : null,
                        color: !isOneWay ? null : AppColors.white,
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
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Return trip',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
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
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PICKUP FIELD
                Row(
                  children: [
                    const Icon(
                      Icons.my_location,
                      color: AppColors.pickupGreen,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'PickUp',
                      style: TextStyle(
                        color: AppColors.textPrimary,
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
                    const Icon(
                      Icons.location_on,
                      color: AppColors.dropRed,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Drop',
                      style: TextStyle(
                        color: AppColors.textPrimary,
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

          // Return Trip Section - Second Booking Input Fields
          if (!isOneWay) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.infoLight, AppColors.surfaceWhite],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.info, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.info.withOpacity(0.15),
                    blurRadius: 10,
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
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.swap_horizontal_circle,
                          color: AppColors.iconLight,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Return Trip - Second Booking',
                        style: TextStyle(
                          fontSize: 17,
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
                        color: AppColors.pickupGreen,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Return PickUp',
                        style: TextStyle(
                          color: AppColors.textPrimary,
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

          // Advertisement carousel (auto-rotating every 5s)
          SizedBox(
            height: 200,
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _adPageController,
                    itemCount: advertisements.isNotEmpty
                        ? advertisements.length
                        : 1,
                    onPageChanged: (index) {
                      setState(() {
                        _currentAdIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      if (advertisements.isEmpty) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              'No offers right now',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }

                      final ad = advertisements[index];
                      return GestureDetector(
                        onTap: () => _navigateToAdDetail(ad),
                        child: Hero(
                          tag: 'ad_${ad.id}',
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: NetworkImage(ad.imageUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.6),
                                  ],
                                ),
                              ),
                              padding: const EdgeInsets.all(12),
                              alignment: Alignment.bottomLeft,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ad.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    ad.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    advertisements.isNotEmpty ? advertisements.length : 1,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: _currentAdIndex == i ? 24 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: _currentAdIndex == i
                            ? AppColors.white
                            : AppColors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
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
      const BusTrackingScreen(),
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
