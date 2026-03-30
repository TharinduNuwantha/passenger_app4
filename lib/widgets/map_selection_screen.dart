import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_colors.dart';

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
  String _selectedAddress = 'Retrieving address...';
  bool _isLoading = false;
  final Set<Marker> _markers = {};
  
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        _moveMapToLocation(_selectedLocation);
        _getAddressFromLatLng(_selectedLocation);
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  void _moveMapToLocation(LatLng position) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(position, 16),
    );
    setState(() {
      _selectedLocation = position;
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('selected'),
          position: position,
        ),
      );
    });
  }

  // Search locations using Google Places Autocomplete API
  Future<void> _searchLocations(String query) async {
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }

    final String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=${widget.apiKey}&components=country:lk';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          setState(() {
            _suggestions = data['predictions'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error searching: $e');
    }
  }

  // Get latlng from place_id
  Future<void> _getPlaceDetails(String placeId) async {
    setState(() {
      _suggestions = [];
      _isLoading = true;
    });

    final String url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry,formatted_address&key=${widget.apiKey}';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final loc = data['result']['geometry']['location'];
          final address = data['result']['formatted_address'];
          final newPos = LatLng(loc['lat'], loc['lng']);
          
          _moveMapToLocation(newPos);
          setState(() {
            _selectedAddress = address;
            _searchController.text = address;
          });
        }
      }
    } catch (e) {
      debugPrint('Error place details: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Get address from coordinates using Geocoding API
  Future<void> _getAddressFromLatLng(LatLng position) async {
    setState(() => _isLoading = true);

    final String url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=${widget.apiKey}';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          setState(() {
            _selectedAddress = data['results'][0]['formatted_address'];
            _searchController.text = _selectedAddress;
          });
        }
      }
    } catch (e) {
      debugPrint('Error geocoding: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false, // Prevent map resizing and artifacts
      body: Stack(
        children: [
          // The Map
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: _selectedLocation, zoom: 15),
              onMapCreated: (controller) => _mapController = controller,
              onTap: (position) {
                _moveMapToLocation(position);
                _getAddressFromLatLng(position);
              },
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              padding: const EdgeInsets.only(bottom: 150),
            ),
          ),

          // Custom Header with Search
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 10,
                bottom: 15,
                left: 15,
                right: 15,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Back Button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black87),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Search Bar
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search for a location...',
                              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                              prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 20),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _suggestions = []);
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onChanged: (val) => _searchLocations(val),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Suggestion List
                  if (_suggestions.isNotEmpty)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(top: 10, left: 60),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _suggestions.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: Colors.grey.withOpacity(0.1),
                          ),
                          itemBuilder: (context, index) {
                            final suggestion = _suggestions[index];
                            final mainText = suggestion['structured_formatting']?['main_text'] ?? suggestion['description'];
                            final secondaryText = suggestion['structured_formatting']?['secondary_text'] ?? '';
                            
                            return ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.location_on_outlined,
                                    color: AppColors.primary, size: 18),
                              ),
                              title: Text(
                                mainText,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              subtitle: secondaryText.isNotEmpty 
                                ? Text(
                                    secondaryText,
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                              onTap: () => _getPlaceDetails(suggestion['place_id']),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Action Buttons (Right side)
          Positioned(
            right: 15,
            bottom: 210,
            child: Column(
              children: [
                _buildMapActionBtn(
                  icon: Icons.my_location,
                  onTap: _getCurrentLocation,
                ),
                const SizedBox(height: 10),
                _buildMapActionBtn(
                  icon: Icons.add,
                  onTap: () => _mapController?.animateCamera(CameraUpdate.zoomIn()),
                ),
                const SizedBox(height: 10),
                _buildMapActionBtn(
                  icon: Icons.remove,
                  onTap: () => _mapController?.animateCamera(CameraUpdate.zoomOut()),
                ),
              ],
            ),
          ),

          // Bottom Selection Card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // HandleBar
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.location_on, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selected Location',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedAddress,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.pop(context, {
                                'address': _selectedAddress,
                                'lat': _selectedLocation.latitude,
                                'lng': _selectedLocation.longitude,
                              });
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'CONFIRM SELECTION',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                letterSpacing: 0.5,
                              ),
                            ),
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

  Widget _buildMapActionBtn({required IconData icon, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
        ),
      ),
    );
  }
}
