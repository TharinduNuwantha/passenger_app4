import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../../theme/app_colors.dart';
import '../../widgets/map_selection_screen.dart';

/// Full-screen location selection page.
///
/// Opens when the user taps the "From" or "To" field on the home screen.
/// Returns a map `{ 'address': String, 'lat': double?, 'lng': double? }`
/// via [Navigator.pop] when a location is selected.
class LocationSelectionScreen extends StatefulWidget {
  /// True if this is picking the pickup (From) location.
  final bool isPickup;

  /// Google Maps API key (for Places Autocomplete + Geocoding).
  final String googleMapsApiKey;

  /// Recent search history to show as quick suggestions.
  final List<Map<String, String>> searchHistory;

  /// If true, choosing on map will pop back instead of pushing MapSelectionScreen.
  final bool selectOnMapIsPop;

  const LocationSelectionScreen({
    super.key,
    required this.isPickup,
    required this.googleMapsApiKey,
    this.searchHistory = const [],
    this.selectOnMapIsPop = false,
  });

  @override
  State<LocationSelectionScreen> createState() =>
      _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoadingSuggestions = false;
  bool _isGettingLocation = false;
  Timer? _debounceTimer;

  late final AnimationController _slideController;
  late final AnimationController _pulseController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _pulseAnimation;

  // Centralized SmartTransit brand colors
  Color get _accentColor => AppColors.primary;
  Color get _accentColorLight => AppColors.primarySurface;
  Color get _gradientEnd => AppColors.primaryLight;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideController.forward();

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ── Search ──────────────────────────────────────────────────────────────

  void _onSearchChanged() {
    final text = _searchController.text.trim();

    _debounceTimer?.cancel();
    if (text.length < 2) {
      setState(() {
        _suggestions = [];
        _isLoadingSuggestions = false;
      });
      return;
    }

    setState(() => _isLoadingSuggestions = true);

    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _fetchPlaceSuggestions(text);
    });
  }

  Future<void> _fetchPlaceSuggestions(String input) async {
    final encoded = Uri.encodeComponent(input);
    final url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=$encoded'
        '&components=country:lk'
        '&key=${widget.googleMapsApiKey}';

    try {
      final response = await http.get(Uri.parse(url));
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          setState(() {
            _suggestions = List<Map<String, dynamic>>.from(
              (data['predictions'] as List).map(
                (p) => {
                  'description': p['description'],
                  'place_id': p['place_id'],
                  'main_text':
                      p['structured_formatting']?['main_text'] ??
                      p['description'],
                  'secondary_text':
                      p['structured_formatting']?['secondary_text'] ?? '',
                },
              ),
            );
            _isLoadingSuggestions = false;
          });
        } else {
          setState(() {
            _suggestions = [];
            _isLoadingSuggestions = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isLoadingSuggestions = false;
        });
      }
    }
  }

  Future<void> _selectPlace(Map<String, dynamic> place) async {
    HapticFeedback.selectionClick();
    final placeId = place['place_id'] as String;
    final description = place['description'] as String;

    final url =
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId'
        '&fields=geometry,formatted_address'
        '&key=${widget.googleMapsApiKey}';

    try {
      final response = await http.get(Uri.parse(url));
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final loc = data['result']['geometry']['location'];
          Navigator.pop(context, {
            'address': data['result']['formatted_address'] ?? description,
            'lat': (loc['lat'] as num).toDouble(),
            'lng': (loc['lng'] as num).toDouble(),
          });
          return;
        }
      }
    } catch (_) {}

    Navigator.pop(context, {'address': description, 'lat': null, 'lng': null});
  }

  String _getCleanAddress(List<dynamic> results) {
    if (results.isEmpty) return '';

    for (var result in results) {
      final addr = result['formatted_address'] as String? ?? '';
      final trimmed = addr.trim();
      if (!addr.contains('+') &&
          trimmed != 'Sri Lanka' &&
          trimmed != 'Sri Lanka,' &&
          trimmed.isNotEmpty) {
        return addr;
      }
    }

    for (var result in results) {
      final components = result['address_components'] as List<dynamic>? ?? [];
      final preferredTypes = [
        'point_of_interest',
        'establishment',
        'neighborhood',
        'sublocality_level_1',
        'sublocality',
        'locality',
        'administrative_area_level_3',
        'administrative_area_level_2',
      ];

      for (var type in preferredTypes) {
        for (var component in components) {
          final List<dynamic> types = component['types'] ?? [];
          if (types.contains(type)) {
            final name = component['long_name'] as String? ?? '';
            if (name.isNotEmpty && !name.contains('+')) {
              return name;
            }
          }
        }
      }
    }

    return results[0]['formatted_address'] as String? ?? '';
  }

  // ── Current Location ─────────────────────────────────────────────────────

  Future<void> _useCurrentLocation() async {
    HapticFeedback.mediumImpact();
    setState(() => _isGettingLocation = true);

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final url =
          'https://maps.googleapis.com/maps/api/geocode/json'
          '?latlng=${position.latitude},${position.longitude}'
          '&key=${widget.googleMapsApiKey}';

      final response = await http.get(Uri.parse(url));
      if (!mounted) return;

      String address = 'Your Location';
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' &&
            data['results'] != null &&
            (data['results'] as List).isNotEmpty) {
          address = _getCleanAddress(data['results']);
        }
      }

      if (mounted) {
        Navigator.pop(context, {
          'address': address,
          'lat': position.latitude,
          'lng': position.longitude,
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGettingLocation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.location_off_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('Could not get current location'),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  // ── Map Selection ─────────────────────────────────────────────────────────

  Future<void> _chooseOnMap() async {
    HapticFeedback.lightImpact();
    _searchFocusNode.unfocus();

    if (widget.selectOnMapIsPop) {
      Navigator.pop(context, {'select_on_map': true});
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapSelectionScreen(apiKey: widget.googleMapsApiKey),
      ),
    );

    if (result != null && mounted) {
      String address;
      double? lat, lng;

      if (result is Map) {
        address = result['address'] ?? '';
        lat = (result['lat'] as num?)?.toDouble();
        lng = (result['lng'] as num?)?.toDouble();
      } else {
        address = result.toString();
      }

      if (address.isNotEmpty) {
        Navigator.pop(context, {'address': address, 'lat': lat, 'lng': lng});
      }
    }
  }

  // ── Recent history quick select ───────────────────────────────────────────

  void _selectFromHistory(Map<String, String> item) {
    HapticFeedback.selectionClick();
    final address = widget.isPickup ? item['pickup']! : item['drop']!;
    Navigator.pop(context, {'address': address, 'lat': null, 'lng': null});
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final isSearching = _searchController.text.trim().isNotEmpty;
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: const Color(0xFFF8F9FB),
          body: Column(
            children: [
              // ── Header with Gradient ──────────────────────────────────
              _buildHeader(topPadding, isKeyboardVisible),

              // ── Quick Action Buttons ──────────────────────────────────
              if (!isKeyboardVisible)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionButton(
                          icon: Icons.my_location_rounded,
                          label: _isGettingLocation
                              ? 'Locating...'
                              : 'Current Location',
                          sublabel: 'Use GPS',
                          color: _accentColor,
                          bgColor: _accentColorLight,
                          onTap: _isGettingLocation ? null : _useCurrentLocation,
                          isLoading: _isGettingLocation,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickActionButton(
                          icon: Icons.map_rounded,
                          label: 'Pick on Map',
                          sublabel: 'Drop a pin',
                          color: _accentColor,
                          bgColor: _accentColorLight,
                          onTap: _chooseOnMap,
                        ),
                      ),
                    ],
                  ),
                ),

              if (!isKeyboardVisible) const SizedBox(height: 20),

              // ── Section Divider Label ─────────────────────────────────
              if (!isKeyboardVisible)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _accentColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSearching
                                  ? Icons.search_rounded
                                  : Icons.history_rounded,
                              size: 13,
                              color: _accentColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isSearching ? 'SUGGESTIONS' : 'RECENT SEARCHES',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _accentColor,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _accentColor.withOpacity(0.2),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (!isKeyboardVisible) const SizedBox(height: 4),

              // ── Suggestions / History List ────────────────────────────
              Expanded(child: _buildList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double topPadding, bool isKeyboardVisible) {
    return Container(
      padding: EdgeInsets.fromLTRB(0, topPadding, 0, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, _accentColor, _gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withOpacity(0.30),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative background circles
          Positioned(
            top: -10,
            right: -20,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            top: 30,
            right: 60,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.fromLTRB(8, 12, 12, isKeyboardVisible ? 12 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button + label row
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    // Pill badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.isPickup
                                ? Icons.trip_origin_rounded
                                : Icons.location_on_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.isPickup ? 'Pickup Point' : 'Drop Point',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                isKeyboardVisible
                    ? const SizedBox(height: 8)
                    : const SizedBox(height: 10),
                isKeyboardVisible
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          widget.isPickup
                              ? 'Where are you\nstarting from?'
                              : 'Where are\nyou going?',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.2,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                isKeyboardVisible
                    ? const SizedBox.shrink()
                    : const SizedBox(height: 16),
                // Search Bar
                Padding(
                  key: const ValueKey('search_bar_padding'),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Hero(
                    tag: widget.isPickup ? 'search_pickup' : 'search_drop',
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Icon(
                                Icons.search_rounded,
                                color: _accentColor,
                                size: 22,
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                  letterSpacing: 0.1,
                                ),
                                decoration: InputDecoration(
                                  hintText: widget.isPickup
                                      ? 'Search pickup location...'
                                      : 'Search destination...',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 17),
                                ),
                                textInputAction: TextInputAction.search,
                                cursorColor: _accentColor,
                              ),
                            ),
                            if (_isLoadingSuggestions)
                              Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
                                  ),
                                ),
                              )
                            else if (_searchController.text.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() {
                                    _suggestions = [];
                                    _isLoadingSuggestions = false;
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 14),
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
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
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required String sublabel,
    required Color color,
    required Color bgColor,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.15), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(11),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    )
                  : Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sublabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
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

  Widget _buildList() {
    final isSearching = _searchController.text.trim().isNotEmpty;

    if (isSearching && _suggestions.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          return _buildSuggestionTile(_suggestions[index], index);
        },
      );
    }

    if (isSearching && _suggestions.isEmpty && !_isLoadingSuggestions) {
      return _buildEmptySearchState();
    }

    if (widget.searchHistory.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: widget.searchHistory.length,
        itemBuilder: (context, index) {
          return _buildHistoryTile(widget.searchHistory[index], index);
        },
      );
    }

    return _buildEmptyHistoryState();
  }

  Widget _buildSuggestionTile(Map<String, dynamic> suggestion, int index) {
    final mainText = suggestion['main_text'] as String;
    final secondaryText = suggestion['secondary_text'] as String;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 200 + index * 40),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 10),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => _selectPlace(suggestion),
            borderRadius: BorderRadius.circular(16),
            splashColor: _accentColor.withOpacity(0.06),
            highlightColor: _accentColor.withOpacity(0.03),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _accentColorLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.location_on_rounded,
                      color: _accentColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mainText,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (secondaryText.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            secondaryText,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _accentColorLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.arrow_outward_rounded,
                      size: 16,
                      color: _accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTile(Map<String, String> item, int index) {
    final displayText = widget.isPickup ? item['pickup']! : item['drop']!;
    final otherText = widget.isPickup ? item['drop']! : item['pickup']!;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 180 + index * 50),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 8),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => _selectFromHistory(item),
            borderRadius: BorderRadius.circular(16),
            splashColor: Colors.grey.withOpacity(0.06),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.history_rounded,
                      color: Colors.grey.shade500,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayText,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.swap_horiz_rounded,
                                    size: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                  const SizedBox(width: 4),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 160),
                                    child: Text(
                                      otherText,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
                  const SizedBox(width: 10),
                  Icon(
                    Icons.north_east_rounded,
                    size: 18,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _accentColor.withOpacity(0.12),
                    _accentColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 40,
                color: _accentColor.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No locations found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different keyword or use\n"Pick on Map" to pin your location',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _chooseOnMap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_accentColor, _gradientEnd],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: _accentColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Open Map',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyHistoryState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _accentColor.withOpacity(0.15),
                      _accentColor.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(
                  widget.isPickup
                      ? Icons.trip_origin_rounded
                      : Icons.location_on_rounded,
                  size: 44,
                  color: _accentColor.withOpacity(0.7),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.isPickup
                  ? 'Where are you starting from?'
                  : 'Where are you going?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Search for a location above or use\nthe quick actions to get started',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
