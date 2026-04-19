import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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
import '../../providers/auth_provider.dart';
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
import '../../widgets/blue_header.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/map_selection_screen.dart';

class DashBoard extends StatefulWidget {
  const DashBoard({super.key});

  @override
  State<DashBoard> createState() => _DashBoardState();
}

class _DashBoardState extends State<DashBoard> with WidgetsBindingObserver {
  int _selectedIndex = 0;

  DateTime? selectedDate;
  bool showPickupSuggestions = false;
  bool showDropSuggestions = false;

  late AdvertisementService _advertisementService;
  late NotificationService _notificationService;
  late BookingService _bookingService;
  List<Advertisement> advertisements = [];
  String? userId;
  int _unreadNotifications = 0;
  int _previousUnreadNotifications =
      0; // Track previous count for minimal alerts

  // Upcoming bookings
  List<BookingListItem> _upcomingBookings = [];
  bool _isLoadingBookings = false;
  final PageController _bookingPageController = PageController();
  Timer? _bookingTimer;
  int _currentBookingIndex = 0;

  // Advertisement carousel
  final PageController _adPageController = PageController();
  Timer? _adTimer;
  int _currentAdIndex = 0;

  // Calendar scroll controller
  final ScrollController _calendarScrollController = ScrollController();

  // Refresh timer for periodic updates
  Timer? _refreshTimer;

  final TextEditingController pickupController = TextEditingController();
  final TextEditingController dropController = TextEditingController();

  List<Map<String, dynamic>> pickupAutocompleteSuggestions = [];
  List<Map<String, dynamic>> dropAutocompleteSuggestions = [];
  bool isLoadingPickupSuggestions = false;
  bool isLoadingDropSuggestions = false;

  final String googleMapsApiKey = 'AIzaSyAuA_RMUaOuqKOasnd5GU8MdYvrDmToXPg';

  final List<Map<String, String>> nearbyLocations = [];

  // Search service for fuzzy matching
  final SearchService _searchService = SearchService();

  // Search History (last 3 searches)
  List<Map<String, String>> _searchHistory = [];

  String? firstName;

  // Selected location coordinates
  double? pickupLat;
  double? pickupLng;
  double? dropLat;
  double? dropLng;

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

    // Initialize data
    _initializeData();

    pickupController.addListener(_onPickupTextChanged);
    dropController.addListener(_onDropTextChanged);
    _startAdCarousel();
    _startBookingCarousel();
    _startRefreshTimer();
  }

  Future<void> _initializeData() async {
    await _loadUserData();
    await _loadSearchHistory();
    _loadActiveBooking();
    _loadUpcomingBookings();
    _loadDummyAdvertisements();
    _loadNotifications(silent: true);
    
    // Auto-detect current location for pickup
    _useCurrentLocation(isPickup: true);
  }

  void _startRefreshTimer() {
    // Refresh notifications and upcoming bookings every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadNotifications();
        _loadUpcomingBookings();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _adTimer?.cancel();
    _bookingTimer?.cancel();
    _refreshTimer?.cancel();
    _adPageController.dispose();
    _bookingPageController.dispose();
    _calendarScrollController.dispose();
    pickupController.removeListener(_onPickupTextChanged);
    dropController.removeListener(_onDropTextChanged);
    pickupController.dispose();
    dropController.dispose();
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
      selectedDate = null;
      pickupAutocompleteSuggestions.clear();
      dropAutocompleteSuggestions.clear();
      showPickupSuggestions = false;
      showDropSuggestions = false;
    });
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      firstName = prefs.getString('firstName') ?? 'User';
      userId = prefs.getString('userId');
    });
  }

  // Load search history from SharedPreferences
  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('searchHistory');
    if (historyJson != null) {
      final List<dynamic> decoded = json.decode(historyJson);
      setState(() {
        _searchHistory = decoded.map((item) {
          return {
            'pickup': item['pickup'] as String,
            'drop': item['drop'] as String,
          };
        }).toList();
      });
    }
  }

  // Save search history to SharedPreferences
  Future<void> _saveSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('searchHistory', json.encode(_searchHistory));
  }

  // Add search to history (limit to 3)
  Future<void> _addToSearchHistory(String pickup, String drop) async {
    // Check if this combination already exists
    _searchHistory.removeWhere(
      (item) => item['pickup'] == pickup && item['drop'] == drop,
    );

    // Add to beginning of list
    _searchHistory.insert(0, {'pickup': pickup, 'drop': drop});

    // Keep only last 3 searches
    if (_searchHistory.length > 3) {
      _searchHistory = _searchHistory.sublist(0, 3);
    }

    await _saveSearchHistory();
    setState(() {});
  }

  // Remove search from history
  Future<void> _removeFromSearchHistory(int index) async {
    setState(() {
      _searchHistory.removeAt(index);
    });
    await _saveSearchHistory();
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

  Future<void> _loadNotifications({bool silent = false}) async {
    if (userId != null) {
      final count = await _notificationService.getUnreadCount(userId!);

      // If count increased, show a minimal "WhatsApp-style" top banner
      if (!silent && count > _unreadNotifications && mounted) {
        _showMinimalNotificationBanner();
      }

      setState(() {
        _previousUnreadNotifications = _unreadNotifications;
        _unreadNotifications = count;
      });
    }
  }

  void _showMinimalNotificationBanner() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.notifications_active_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'New notification received',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                _openNotifications();
              },
              child: const Text(
                'VIEW',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 150,
          left: 16,
          right: 16,
        ),
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
    
    // Reset coordinates on manual text change to avoid stale location data
    if (pickupLat != null || pickupLng != null) {
      if (mounted) {
        setState(() {
          pickupLat = null;
          pickupLng = null;
        });
      }
    }

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

    // Reset coordinates on manual text change to avoid stale location data
    if (dropLat != null || dropLng != null) {
      if (mounted) {
        setState(() {
          dropLat = null;
          dropLng = null;
        });
      }
    }

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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (selectedDate ?? DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
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

    if (result != null) {
      String? address;
      double? lat;
      double? lng;

      if (result is String) {
        address = result;
      } else if (result is Map) {
        address = result['address'];
        lat = result['lat'];
        lng = result['lng'];
      }

      if (address != null) {
        setState(() {
          if (isPickup) {
            pickupController.text = address!;
            pickupLat = lat;
            pickupLng = lng;
            showPickupSuggestions = false;
          } else {
            dropController.text = address!;
            dropLat = lat;
            dropLng = lng;
            showDropSuggestions = false;
          }
        });

        // Auto-navigate to booking if all fields are filled
        _autoNavigateToBooking();
      }
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



  // Swap pickup and drop locations
  void _swapLocations() {
    HapticFeedback.mediumImpact();
    setState(() {
      final temp = pickupController.text;
      pickupController.text = dropController.text;
      dropController.text = temp;
    });

    // Show feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.swap_vert, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(child: Text('Locations swapped')),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Auto navigate to booking screen (triggers search)
  Future<void> _autoNavigateToBooking() async {
    if (pickupController.text.isEmpty || dropController.text.isEmpty) {
      return;
    }

    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return PopScope(
            canPop: false,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Searching for trips...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please wait',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    try {
      print('🔍 Starting search...');
      print('🔍 Raw Pickup: "${pickupController.text}"');
      print('🔍 Raw Drop: "${dropController.text}"');

      // Using direct coordinate-based search for Lounge-to-Lounge discovery
      final fromDisplay = pickupController.text;
      final toDisplay = dropController.text;

      // Dismiss loading dialog
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (fromDisplay.isEmpty || toDisplay.isEmpty) {
        // Show error if locations are empty
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select valid start and end locations'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      // Use selected date or default to today
      // Normalize to start of day (00:00:00) to search from beginning of the day
      final rawDate = selectedDate ?? DateTime.now();
      final searchDate = DateTime(rawDate.year, rawDate.month, rawDate.day);
      print('🔍 Search Date (normalized to start of day): $searchDate');

      // Add to search history
      await _addToSearchHistory(pickupController.text, dropController.text);

      // Navigate to bus list screen with search (no stop location)
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BusListScreen(
              date: searchDate,
              pickup: fromDisplay,
              drop: toDisplay,
              fromLat: pickupLat,
              fromLng: pickupLng,
              toLat: dropLat,
              toLng: dropLng,
              stop: null, 
            ),
          ),
        ).then((_) {
          // Refresh bookings and notifications when returning from booking flow
          _loadUpcomingBookings();
          _loadNotifications();
          _loadActiveBooking();
        });
      }
    } catch (e) {
      // Dismiss loading dialog on error
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // Get current location and populate search field
  Future<void> _useCurrentLocation({required bool isPickup}) async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission denied'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission permanently denied. Please enable in settings.',
              ),
              backgroundColor: Colors.redAccent,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Getting your location...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Reverse geocode to get address
      final String url =
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$googleMapsApiKey';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final address = data['results'][0]['formatted_address'];

          setState(() {
            if (isPickup) {
              pickupController.text = address;
              pickupLat = position.latitude;
              pickupLng = position.longitude;
              showPickupSuggestions = false;
            } else {
              dropController.text = address;
              dropLat = position.latitude;
              dropLng = position.longitude;
              showDropSuggestions = false;
            }
          });

          if (mounted) {
            FocusScope.of(context).unfocus();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Location set: ${address.length > 50 ? address.substring(0, 50) + '...' : address}',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error getting current location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to get current location'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Widget _buildModernLocationSelector() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Icons Column (Connected with vertical line)
                _buildModernIconsColumn(),

                // Fields Column
                Expanded(
                  child: Column(
                    children: [
                      _buildModernField(
                        controller: pickupController,
                        hint: 'Your Location',
                        isPickup: true,
                        showSuggestions: showPickupSuggestions,
                      ),
                      const Divider(
                        height: 1,
                        indent: 0,
                        endIndent: 15,
                        thickness: 0.5,
                      ),
                      _buildModernField(
                        controller: dropController,
                        hint: 'Where to?',
                        isPickup: false,
                        showSuggestions: showDropSuggestions,
                      ),
                    ],
                  ),
                ),

                // Swap Button on the right
                _buildSwapButtonBlock(),
              ],
            ),
          ),
        ),

        // Intelligent Suggestions Panel
        if (showPickupSuggestions || showDropSuggestions)
          _buildCompactSuggestionsPanel(),

        const SizedBox(height: 16),

        // Modern Search Button
        if (!showPickupSuggestions && !showDropSuggestions)
          _buildModernSearchButton(),
      ],
    );
  }

  Widget _buildModernIconsColumn() {
    return Container(
      width: 50,
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Column(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Container(
              width: 1.5,
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          const Icon(Icons.location_on, color: Colors.red, size: 20),
        ],
      ),
    );
  }

  Widget _buildModernField({
    required TextEditingController controller,
    required String hint,
    required bool isPickup,
    required bool showSuggestions,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Focus(
        onFocusChange: (hasFocus) {
          setState(() {
            if (isPickup) {
              showPickupSuggestions = hasFocus;
            } else {
              showDropSuggestions = hasFocus;
            }
          });
        },
        child: TextField(
          controller: controller,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (controller.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                    onPressed: () {
                      setState(() {
                        controller.clear();
                        if (isPickup) {
                          pickupLat = null;
                          pickupLng = null;
                        } else {
                          dropLat = null;
                          dropLng = null;
                        }
                      });
                    },
                  ),
                IconButton(
                  icon: Icon(
                    isPickup ? Icons.my_location : Icons.map_outlined,
                    size: 20,
                    color: AppColors.primary.withOpacity(0.7),
                  ),
                  onPressed: () {
                    if (isPickup) {
                      _useCurrentLocation(isPickup: true);
                    } else {
                      _navigateToMapForLocation(isPickup: false);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwapButtonBlock() {
    return Container(
      width: 45,
      alignment: Alignment.center,
      child: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.swap_vert, color: AppColors.primary, size: 22),
        ),
        onPressed: _swapLocations,
      ),
    );
  }

  Widget _buildCompactSuggestionsPanel() {
    final bool isPickup = showPickupSuggestions;
    final suggestions = isPickup ? pickupAutocompleteSuggestions : dropAutocompleteSuggestions;
    final isLoading = isPickup ? isLoadingPickupSuggestions : isLoadingDropSuggestions;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else ...[
            if (isPickup && pickupController.text.isEmpty && _searchHistory.isNotEmpty)
              ..._searchHistory.take(3).map((history) => ListTile(
                leading: const Icon(Icons.history, size: 18, color: Colors.grey),
                title: Text(history['pickup']!, style: const TextStyle(fontSize: 14)),
                onTap: () {
                  setState(() {
                    pickupController.text = history['pickup']!;
                    dropController.text = history['drop']!;
                    showPickupSuggestions = false;
                  });
                  FocusScope.of(context).unfocus();
                },
              )),
            
            ...suggestions.take(5).map((s) => ListTile(
              leading: const Icon(Icons.location_on_outlined, size: 20, color: AppColors.primary),
              title: Text(
                s['description'],
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                setState(() {
                  if (isPickup) {
                    pickupController.text = s['description'];
                    showPickupSuggestions = false;
                  } else {
                    dropController.text = s['description'];
                    showDropSuggestions = false;
                  }
                });
                FocusScope.of(context).unfocus();
                _autoNavigateToBooking();
              },
            )),

            if (suggestions.isEmpty && !isLoading)
              ListTile(
                leading: const Icon(Icons.map_outlined, color: AppColors.primary),
                title: const Text('Select on map', style: TextStyle(fontSize: 14)),
                onTap: () {
                   setState(() {
                    showPickupSuggestions = false;
                    showDropSuggestions = false;
                  });
                  FocusScope.of(context).unfocus();
                  _navigateToMapForLocation(isPickup: isPickup);
                },
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildModernSearchButton() {
    final bool isReady = pickupController.text.isNotEmpty && dropController.text.isNotEmpty;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isReady ? _autoNavigateToBooking : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: isReady ? 4 : 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          shadowColor: AppColors.primary.withOpacity(0.4),
        ),
        child: const Text(
          'SEARCH TRIPS',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
      ),
    );
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green, Colors.lightGreen.shade700],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.confirmation_number_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Upcoming Trips',
                    style: AppTextStyles.h3.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () {
                  _onItemTapped(1);
                },
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text(
                  'View All',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ],
          ),
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

  String _greetingName(AuthProvider authProvider) {
    final providerName = authProvider.user?.firstName?.trim();
    if (providerName != null && providerName.isNotEmpty) {
      return providerName;
    }

    final cachedName = firstName?.trim();
    if (cachedName != null && cachedName.isNotEmpty) {
      return cachedName;
    }

    return 'User';
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

  String _getDayName(DateTime date) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[date.weekday % 7];
  }

  String _getMonthName(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[date.month - 1];
  }

  // Helper method to scroll calendar to a specific date
  void _scrollCalendarToDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    final daysDifference = targetDate.difference(today).inDays;

    // Each date card is 70 width + 10 margin = 80 total
    final scrollOffset = daysDifference * 80.0;

    // Animate to the position
    if (_calendarScrollController.hasClients) {
      _calendarScrollController.animateTo(
        scrollOffset.clamp(
          0.0,
          _calendarScrollController.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Helper method to build quick date buttons
  Widget _buildQuickDateButton(String label, DateTime date) {
    final isSelected =
        selectedDate?.day == date.day &&
        selectedDate?.month == date.month &&
        selectedDate?.year == date.year;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedDate = date;
        });
        // Auto-scroll calendar to the selected date
        _scrollCalendarToDate(date);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Helper method to build quick route buttons
  Widget _buildQuickRouteButton(
    String label,
    IconData icon,
    String fromLocation,
    String toLocation,
  ) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          pickupController.text = fromLocation;
          dropController.text = toLocation;
          showPickupSuggestions = false;
          showDropSuggestions = false;
        });
        FocusScope.of(context).unfocus();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.primary.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: AppColors.primary, size: 16),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final greetingName = _greetingName(authProvider);
    final topInset = MediaQuery.of(context).padding.top;

    var singleChildScrollView = SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced Header with Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.85),
                  const Color(0xFF1565C0),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              // borderRadius: const BorderRadius.only(
              //   bottomLeft: Radius.circular(32),
              //   bottomRight: Radius.circular(32),
              // ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: EdgeInsets.fromLTRB(20, topInset + 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello $greetingName! ',
                          style: AppTextStyles.h2.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.explore_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Ready to explore?',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.95),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onLongPress: () async {
                        // Minimal way to "create" a notification for testing
                        HapticFeedback.heavyImpact();
                        await _notificationService.addLocalNotification(
                          title: 'Special Offer! 🎫',
                          message: 'Get 25% off on your next trip to Kandy.',
                          type: 'offer',
                        );
                        _loadNotifications();
                      },
                      child: NotificationBell(
                        userId: userId ?? '',
                        initialCount: _unreadNotifications,
                        onTap: _openNotifications,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 1),

          // Upcoming Bookings Section
          if (_upcomingBookings.isNotEmpty) _buildUpcomingBookingsSection(),

          const SizedBox(height: 09),

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

          // Horizontal Date Selector
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Scrollable Date Cards
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    controller: _calendarScrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: 30,
                    itemBuilder: (context, index) {
                      final date = DateTime.now().add(Duration(days: index));
                      final isSelected =
                          selectedDate?.day == date.day &&
                          selectedDate?.month == date.month &&
                          selectedDate?.year == date.year;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedDate = date;
                          });
                        },
                        child: Container(
                          width: 70,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _getMonthName(date).substring(0, 3),
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${date.day}',
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.primary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _getDayName(date),
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Quick Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickDateButton('Today', DateTime.now()),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildQuickDateButton(
                        'Tomorrow',
                        DateTime.now().add(const Duration(days: 1)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildQuickDateButton(
                        'Next Month',
                        DateTime(
                          DateTime.now().year,
                          DateTime.now().month + 1,
                          1,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Quick Route Buttons Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.flash_on,
                            color: AppColors.primary,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Popular Routes',
                          style: AppTextStyles.h3.copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildQuickRouteButton(
                        'Colombo → Kandy',
                        Icons.trending_up,
                        'Colombo Fort',
                        'Kandy',
                      ),
                      const SizedBox(width: 10),
                      _buildQuickRouteButton(
                        'Colombo → Galle',
                        Icons.beach_access,
                        'Colombo Fort',
                        'Galle',
                      ),
                      const SizedBox(width: 10),
                      _buildQuickRouteButton(
                        'Kandy → Nuwara Eliya',
                        Icons.landscape,
                        'Kandy',
                        'Nuwara Eliya',
                      ),
                      const SizedBox(width: 10),
                      _buildQuickRouteButton(
                        'Colombo → Jaffna',
                        Icons.directions_bus,
                        'Colombo Fort',
                        'Jaffna',
                      ),
                      const SizedBox(width: 10),
                      _buildQuickRouteButton(
                        'Galle → Matara',
                        Icons.waves,
                        'Galle',
                        'Matara',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // MODERN PICKME STYLE LOCATION SELECTOR
          _buildModernLocationSelector(),
          const SizedBox(height: 20),
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
      SafeArea(top: false, child: singleChildScrollView),
      const ActivitiesScreen(),
      const BusTrackingScreen(),
      const LoungeListScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
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


