import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../theme/app_colors.dart';
import '../bus_booking/booking_conform.dart' hide AppColors;
import '../bus_booking/bus_booking_screen.dart';
import '../bus_booking/nav_booking_screen.dart';
import '../lounge/lounge_details.dart';
import '../profile/profile_screen.dart';

class DashBoard extends StatefulWidget {
  const DashBoard({super.key});

  @override
  State<DashBoard> createState() => _DashBoardState();
}

class _DashBoardState extends State<DashBoard> {
  int _selectedIndex = 0;

  bool isOneWay = true;
  DateTime? selectedDate;
  bool showPickupSuggestions = false;
  bool showDropSuggestions = false;

  final TextEditingController pickupController = TextEditingController();
  final TextEditingController dropController = TextEditingController();

  List<Map<String, dynamic>> pickupAutocompleteSuggestions = [];
  List<Map<String, dynamic>> dropAutocompleteSuggestions = [];
  bool isLoadingPickupSuggestions = false;
  bool isLoadingDropSuggestions = false;

  final String googleMapsApiKey = 'AIzaSyCs7dOTJ-9GlNB1T29k5Bexz8XOY1IuaA4';

  final List<Map<String, String>> nearbyLocations = [];

  String? firstName;

  @override
  void initState() {
    super.initState();
    _loadFirstName();
    pickupController.addListener(_onPickupTextChanged);
    dropController.addListener(_onDropTextChanged);
  }

  @override
  void dispose() {
    pickupController.removeListener(_onPickupTextChanged);
    dropController.removeListener(_onDropTextChanged);
    pickupController.dispose();
    dropController.dispose();
    super.dispose();
  }

  Future<void> _loadFirstName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      firstName = prefs.getString('firstName') ?? 'User';
    });
  }

  // Listen to pickup field changes and fetch autocomplete
  void _onPickupTextChanged() {
    final text = pickupController.text;
    if (text.length > 2) {
      _fetchAutocompleteSuggestions(text, isPickup: true);
    } else {
      setState(() {
        pickupAutocompleteSuggestions.clear();
        isLoadingPickupSuggestions = false;
      });
    }
  }

  // Listen to drop field changes and fetch autocomplete
  void _onDropTextChanged() {
    final text = dropController.text;
    if (text.length > 2) {
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
      initialDate: selectedDate ?? DateTime.now(),
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

  // Auto navigate to booking screen
  void _autoNavigateToBooking() {
    if (pickupController.text.isNotEmpty &&
        dropController.text.isNotEmpty &&
        selectedDate != null) {
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
          const SizedBox(height: 10),
          Text('Hello ${firstName ?? 'User'},', style: AppTextStyles.h2),
          Text('Where to go?', style: AppTextStyles.h2),
          const SizedBox(height: 15),

          // Date Picker
          InkWell(
            onTap: () => _selectDate(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    selectedDate == null
                        ? 'Select Date'
                        : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
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
                    onTap: () => setState(() => isOneWay = true),
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
                const Text('PickUp', style: TextStyle(color: Colors.black54)),
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
                const Text('Drop', style: TextStyle(color: Colors.black54)),
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

          // Offer Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enjoy 2% off',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.white.withOpacity(0.7),
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
                          ScaffoldMessenger.of(context).showSnackBar(
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
              ],
            ),
          ),
        ],
      ),
    );
    final List<Widget> pages = [
      // Page 0: Your Full Dashboard UI
      SafeArea(child: singleChildScrollView),

      const BookingScreen(),
      const LocationPage(),
      const LoungeDetailsScreen(),
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
