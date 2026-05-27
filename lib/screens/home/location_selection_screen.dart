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

  const LocationSelectionScreen({
    super.key,
    required this.isPickup,
    required this.googleMapsApiKey,
    this.searchHistory = const [],
  });

  @override
  State<LocationSelectionScreen> createState() =>
      _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoadingSuggestions = false;
  bool _isGettingLocation = false;
  Timer? _debounceTimer;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    // Auto-focus the search field after the animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ── Search ──────────────────────────────────────────────────────────────

  void _onSearchChanged() {
    final text = _searchController.text.trim();

    // Debounce to avoid too many API calls
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

  // Fetch coordinates from a place_id then return
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

    // Fallback: return without coordinates
    Navigator.pop(context, {'address': description, 'lat': null, 'lng': null});
  }

  String _getCleanAddress(List<dynamic> results) {
    if (results.isEmpty) return '';

    // 1. Try to find the first result whose formatted_address does NOT contain a plus code and is not just "Sri Lanka"
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

    // 2. If all results contain a plus code or are just "Sri Lanka", try to extract the locality/neighborhood/POI from components
    for (var result in results) {
      final components = result['address_components'] as List<dynamic>? ?? [];
      
      // Check preferred component types in order of specificity
      final preferredTypes = [
        'point_of_interest',
        'establishment',
        'neighborhood',
        'sublocality_level_1',
        'sublocality',
        'locality',
        'administrative_area_level_3',
        'administrative_area_level_2'
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

    // 3. Fallback to the first formatted address if nothing else is available
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
        if (data['status'] == 'OK' && data['results'] != null && (data['results'] as List).isNotEmpty) {
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
          const SnackBar(
            content: Text('Could not get current location'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // ── Map Selection ─────────────────────────────────────────────────────────

  Future<void> _chooseOnMap() async {
    HapticFeedback.lightImpact();
    // Unfocus keyboard before pushing map screen
    _searchFocusNode.unfocus();

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
    final address =
        widget.isPickup ? item['pickup']! : item['drop']!;
    Navigator.pop(context, {'address': address, 'lat': null, 'lng': null});
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // ── Custom App Bar ───────────────────────────────────────────
            _buildAppBar(topPadding),

            // ── Quick Actions ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildQuickActionButton(
                      icon: Icons.my_location_rounded,
                      label: _isGettingLocation
                          ? 'Getting location...'
                          : 'Use current location',
                      color: AppColors.primary,
                      onTap: _isGettingLocation ? null : _useCurrentLocation,
                      isLoading: _isGettingLocation,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionButton(
                      icon: Icons.map_rounded,
                      label: 'Choose on map',
                      color: const Color(0xFFFF6B35),
                      onTap: _chooseOnMap,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Section label ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    _searchController.text.trim().isEmpty
                        ? 'RECENT SEARCHES'
                        : 'SUGGESTIONS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade500,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Divider(color: Colors.grey.shade200, thickness: 1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Suggestions / History List ────────────────────────────────
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(double topPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(8, topPadding + 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: Colors.black87,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Hero(
              tag: widget.isPickup ? 'search_pickup' : 'search_drop',
              child: Material(
                color: Colors.transparent,
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Icon(
                          Icons.search_rounded,
                          color: Colors.grey.shade400,
                          size: 22,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            letterSpacing: 0.2,
                          ),
                          decoration: InputDecoration(
                            hintText: widget.isPickup
                                ? 'Where from?'
                                : 'Where to?',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 16),
                          ),
                          textInputAction: TextInputAction.search,
                          cursorColor: AppColors.primary,
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() {
                              _suggestions = [];
                              _isLoadingSuggestions = false;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
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
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              )
            else
              Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    final isSearching = _searchController.text.trim().isNotEmpty;

    if (_isLoadingSuggestions) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Searching locations...',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (isSearching && _suggestions.isNotEmpty) {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: Colors.grey.shade100),
        itemBuilder: (context, index) {
          return _buildSuggestionTile(_suggestions[index]);
        },
      );
    }

    if (isSearching && _suggestions.isEmpty) {
      return _buildEmptySearchState();
    }

    // Show search history when not typing
    if (widget.searchHistory.isNotEmpty) {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: widget.searchHistory.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: Colors.grey.shade100),
        itemBuilder: (context, index) {
          return _buildHistoryTile(widget.searchHistory[index], index);
        },
      );
    }

    return _buildEmptyHistoryState();
  }

  Widget _buildSuggestionTile(Map<String, dynamic> suggestion) {
    final mainText = suggestion['main_text'] as String;
    final secondaryText = suggestion['secondary_text'] as String;

    return InkWell(
      onTap: () => _selectPlace(suggestion),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: Colors.black87,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mainText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (secondaryText.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      secondaryText,
                      style: TextStyle(
                        fontSize: 13,
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
            const SizedBox(width: 12),
            Icon(
              Icons.arrow_outward_rounded,
              size: 18,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTile(Map<String, String> item, int index) {
    final displayText =
        widget.isPickup ? item['pickup']! : item['drop']!;
    final otherText =
        widget.isPickup ? item['drop']! : item['pickup']!;

    return InkWell(
      onTap: () => _selectFromHistory(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: Icon(
                Icons.history_rounded,
                color: Colors.grey.shade500,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.swap_horiz_rounded, size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          otherText,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.arrow_outward_rounded,
              size: 18,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 20),
          const Text(
            'No locations found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search or use the map',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistoryState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on_rounded,
              size: 48,
              color: AppColors.primary.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.isPickup
                ? 'Where are you starting from?'
                : 'Where are you going?',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search for a location or use quick actions',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
