import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_colors.dart';
import '../screens/home/location_selection_screen.dart';

// Modern Map Selection Screen supporting Single Location & Complete Route selection
class MapSelectionScreen extends StatefulWidget {
  final String apiKey;
  final bool isRouteSelection;

  // Initial values for Route Selection Mode
  final String? initialPickupAddress;
  final double? initialPickupLat;
  final double? initialPickupLng;
  final String? initialDropAddress;
  final double? initialDropLat;
  final double? initialDropLng;
  final bool startWithPickup;

  const MapSelectionScreen({
    super.key,
    required this.apiKey,
    this.isRouteSelection = false,
    this.initialPickupAddress,
    this.initialPickupLat,
    this.initialPickupLng,
    this.initialDropAddress,
    this.initialDropLat,
    this.initialDropLng,
    this.startWithPickup = true,
  });

  @override
  State<MapSelectionScreen> createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  
  // --- State for Single Location Mode ---
  LatLng _selectedLocation = const LatLng(7.2905, 80.6337); // Sri Lanka center
  String _selectedAddress = 'Retrieving address...';

  // --- State for Route Selection Mode ---
  LatLng? _pickupLocation;
  String? _pickupAddress;
  LatLng? _dropLocation;
  String? _dropAddress;
  bool _isSelectingPickup = true;

  // --- Common States ---
  bool _isLoading = false;
  bool _isMoving = false;

  @override
  void initState() {
    super.initState();
    _isSelectingPickup = widget.startWithPickup;

    if (widget.isRouteSelection) {
      if (widget.initialPickupLat != null && widget.initialPickupLng != null) {
        _pickupLocation = LatLng(widget.initialPickupLat!, widget.initialPickupLng!);
        _pickupAddress = widget.initialPickupAddress ?? 'Selected Pickup';
      }
      if (widget.initialDropLat != null && widget.initialDropLng != null) {
        _dropLocation = LatLng(widget.initialDropLat!, widget.initialDropLng!);
        _dropAddress = widget.initialDropAddress ?? 'Selected Destination';
      }
      
      // Focus map on the active initial location or request GPS
      if (_isSelectingPickup && _pickupLocation != null) {
        _selectedLocation = _pickupLocation!;
      } else if (!_isSelectingPickup && _dropLocation != null) {
        _selectedLocation = _dropLocation!;
      } else if (_pickupLocation != null) {
        _selectedLocation = _pickupLocation!;
      } else {
        _getCurrentLocation();
      }
    } else {
      if (widget.initialPickupLat != null && widget.initialPickupLng != null) {
        _selectedLocation = LatLng(widget.initialPickupLat!, widget.initialPickupLng!);
        _selectedAddress = widget.initialPickupAddress ?? 'Selected Location';
      } else {
        _getCurrentLocation();
      }
    }
  }

  // Retrieve current location of user
  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        final currentLatLng = LatLng(position.latitude, position.longitude);
        
        setState(() {
          if (widget.isRouteSelection) {
            if (_isSelectingPickup) {
              _pickupLocation = currentLatLng;
            } else {
              _dropLocation = currentLatLng;
            }
          } else {
            _selectedLocation = currentLatLng;
          }
        });
        
        _moveMapToLocation(currentLatLng);
        _getAddressFromLatLng(currentLatLng);
      }
    } catch (e) {
      debugPrint('Error getting current location: $e');
    }
  }

  void _moveMapToLocation(LatLng position) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(position, 16),
    );
    setState(() {
      if (widget.isRouteSelection) {
        if (_isSelectingPickup) {
          _pickupLocation = position;
        } else {
          _dropLocation = position;
        }
      } else {
        _selectedLocation = position;
      }
    });
  }

  // Fits map bounds to show both pickup and destination locations
  void _fitMapToRoute() {
    if (_mapController == null || _pickupLocation == null || _dropLocation == null) return;

    final LatLngBounds bounds;
    if (_pickupLocation!.latitude == _dropLocation!.latitude &&
        _pickupLocation!.longitude == _dropLocation!.longitude) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_pickupLocation!, 15));
      return;
    }

    bounds = LatLngBounds(
      southwest: LatLng(
        _pickupLocation!.latitude < _dropLocation!.latitude ? _pickupLocation!.latitude : _dropLocation!.latitude,
        _pickupLocation!.longitude < _dropLocation!.longitude ? _pickupLocation!.longitude : _dropLocation!.longitude,
      ),
      northeast: LatLng(
        _pickupLocation!.latitude > _dropLocation!.latitude ? _pickupLocation!.latitude : _dropLocation!.latitude,
        _pickupLocation!.longitude > _dropLocation!.longitude ? _pickupLocation!.longitude : _dropLocation!.longitude,
      ),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }

  // Get cleaned address from Geocoding results
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

    return results[0]['formatted_address'] as String? ?? '';
  }

  // Reverse geocodes the coordinates to address using Google Maps Geocoding API
  Future<void> _getAddressFromLatLng(LatLng position) async {
    setState(() => _isLoading = true);

    final String url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=${widget.apiKey}';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'] != null && (data['results'] as List).isNotEmpty) {
          final address = _getCleanAddress(data['results']);
          setState(() {
            if (widget.isRouteSelection) {
              if (_isSelectingPickup) {
                _pickupAddress = address;
              } else {
                _dropAddress = address;
              }
            } else {
              _selectedAddress = address;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error geocoding: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Handles clicking a text block to open search overlay
  Future<void> _openSearchOverlay({required bool isPickup}) async {
    HapticFeedback.lightImpact();
    
    // Open full-screen typing autocomplete search page as a modal
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationSelectionScreen(
          isPickup: isPickup,
          googleMapsApiKey: widget.apiKey,
          selectOnMapIsPop: true, // pops directly so user returns here to pick on map
        ),
      ),
    );

    if (result != null && mounted) {
      if (result['select_on_map'] == true) {
        // Just switch the active field state to let them select on map directly
        setState(() {
          _isSelectingPickup = isPickup;
        });
        
        // Panning camera to currently set coordinate
        final currentPos = isPickup ? _pickupLocation : _dropLocation;
        if (currentPos != null) {
          _mapController?.animateCamera(CameraUpdate.newLatLng(currentPos));
        }
        return;
      }

      final address = result['address'] as String?;
      final lat = (result['lat'] as num?)?.toDouble();
      final lng = (result['lng'] as num?)?.toDouble();

      if (address != null && lat != null && lng != null) {
        final latLng = LatLng(lat, lng);
        setState(() {
          if (widget.isRouteSelection) {
            if (isPickup) {
              _pickupAddress = address;
              _pickupLocation = latLng;
              // Auto progression to Destination
              _isSelectingPickup = false;
              _openSearchOverlay(isPickup: false);
            } else {
              _dropAddress = address;
              _dropLocation = latLng;
            }
          } else {
            _selectedAddress = address;
            _selectedLocation = latLng;
          }
        });
        
        if (widget.isRouteSelection && _pickupLocation != null && _dropLocation != null) {
          _fitMapToRoute();
        } else {
          _moveMapToLocation(latLng);
        }
      }
    }
  }

  // Swapping the locations
  void _swapLocations() {
    HapticFeedback.mediumImpact();
    setState(() {
      final tempAddress = _pickupAddress;
      final tempLocation = _pickupLocation;
      _pickupAddress = _dropAddress;
      _pickupLocation = _dropLocation;
      _dropAddress = tempAddress;
      _dropLocation = tempLocation;
    });
    
    if (_pickupLocation != null && _dropLocation != null) {
      _fitMapToRoute();
    } else if (_isSelectingPickup && _pickupLocation != null) {
      _moveMapToLocation(_pickupLocation!);
    } else if (!_isSelectingPickup && _dropLocation != null) {
      _moveMapToLocation(_dropLocation!);
    }
  }

  // Tapping the bottom CTA button
  void _handleConfirmCTA() {
    HapticFeedback.mediumImpact();
    
    if (widget.isRouteSelection) {
      if (_isSelectingPickup) {
        if (_pickupLocation == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a pickup location')),
          );
          return;
        }
        // Save pickup, auto advance to Destination
        setState(() {
          _isSelectingPickup = false;
        });
        
        if (_dropLocation != null) {
          _moveMapToLocation(_dropLocation!);
        } else {
          // Open search overlay for destination automatically
          _openSearchOverlay(isPickup: false);
        }
      } else {
        if (_dropLocation == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a destination')),
          );
          return;
        }

        if (_pickupLocation == null) {
          // Fallback to select pickup if not set
          setState(() {
            _isSelectingPickup = true;
          });
          return;
        }

        // Complete selection, return both
        Navigator.pop(context, {
          'pickupAddress': _pickupAddress,
          'pickupLat': _pickupLocation!.latitude,
          'pickupLng': _pickupLocation!.longitude,
          'dropAddress': _dropAddress,
          'dropLat': _dropLocation!.latitude,
          'dropLng': _dropLocation!.longitude,
        });
      }
    } else {
      // Single selection mode
      Navigator.pop(context, {
        'address': _selectedAddress,
        'lat': _selectedLocation.latitude,
        'lng': _selectedLocation.longitude,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Generate Markers
    Set<Marker> markers = {};
    
    if (widget.isRouteSelection) {
      if (_pickupLocation != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('pickup_marker'),
            position: _pickupLocation!,
            infoWindow: InfoWindow(title: 'Pickup: $_pickupAddress'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        );
      }
      if (_dropLocation != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('drop_marker'),
            position: _dropLocation!,
            infoWindow: InfoWindow(title: 'Destination: $_dropAddress'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
      }
    }

    // Generate Polylines
    Set<Polyline> polylines = {};
    if (widget.isRouteSelection && _pickupLocation != null && _dropLocation != null) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route_line'),
          points: [_pickupLocation!, _dropLocation!],
          color: AppColors.primary,
          width: 4,
          geodesic: true,
          patterns: [PatternItem.dash(12), PatternItem.gap(8)],
        ),
      );
    }

    // Colors
    final Color themeColor = _isSelectingPickup ? AppColors.pickupGreen : AppColors.dropRed;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Immediate Background Map
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: widget.isRouteSelection
                    ? (_isSelectingPickup ? (_pickupLocation ?? _selectedLocation) : (_dropLocation ?? _selectedLocation))
                    : _selectedLocation,
                zoom: 16,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
                if (widget.isRouteSelection && _pickupLocation != null && _dropLocation != null) {
                  _fitMapToRoute();
                }
              },
              onCameraMove: (position) {
                _isMoving = true;
                if (widget.isRouteSelection) {
                  if (_isSelectingPickup) {
                    _pickupLocation = position.target;
                  } else {
                    _dropLocation = position.target;
                  }
                } else {
                  _selectedLocation = position.target;
                }
              },
              onCameraIdle: () {
                setState(() => _isMoving = false);
                final currentPos = widget.isRouteSelection
                    ? (_isSelectingPickup ? _pickupLocation : _dropLocation)
                    : _selectedLocation;
                if (currentPos != null) {
                  _getAddressFromLatLng(currentPos);
                }
              },
              onTap: (position) {
                _moveMapToLocation(position);
                _getAddressFromLatLng(position);
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              markers: markers,
              polylines: polylines,
              padding: const EdgeInsets.only(bottom: 230, top: 120),
            ),
          ),

          // 2. Animated Center Bouncing Pin (Only visible when placing a pin)
          if (!_isMoving && !widget.isRouteSelection || 
              (widget.isRouteSelection && 
               ((_isSelectingPickup && _pickupLocation != null) || 
                (!_isSelectingPickup && _dropLocation != null))))
            IgnorePointer(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: EdgeInsets.only(bottom: _isMoving ? 24 : 0),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_isMoving)
                            Container(
                              width: 14,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.2),
                                borderRadius: const BorderRadius.all(Radius.elliptical(14, 6)),
                              ),
                            ),
                          Transform.translate(
                            offset: const Offset(0, -22),
                            child: Icon(
                              Icons.location_on_rounded,
                              size: 48,
                              color: widget.isRouteSelection ? themeColor : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),

          // 3. Top Floating Search Section (Premium Glassmorphism Overlay)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: widget.isRouteSelection 
                ? _buildRouteTopSearchCard(context)
                : _buildSingleTopSearchCard(context),
          ),

          // 4. Modern Map Interaction Controls (Floating on right side)
          Positioned(
            right: 16,
            bottom: widget.isRouteSelection ? 240 : 180,
            child: Column(
              children: [
                _buildMapFloatingButton(
                  icon: Icons.my_location_rounded,
                  onTap: _getCurrentLocation,
                ),
                const SizedBox(height: 12),
                _buildMapFloatingButton(
                  icon: Icons.add_rounded,
                  onTap: () => _mapController?.animateCamera(CameraUpdate.zoomIn()),
                ),
                const SizedBox(height: 12),
                _buildMapFloatingButton(
                  icon: Icons.remove_rounded,
                  onTap: () => _mapController?.animateCamera(CameraUpdate.zoomOut()),
                ),
                if (widget.isRouteSelection && _pickupLocation != null && _dropLocation != null) ...[
                  const SizedBox(height: 12),
                  _buildMapFloatingButton(
                    icon: Icons.zoom_out_map_rounded,
                    onTap: _fitMapToRoute,
                  ),
                ],
              ],
            ),
          ),

          // 5. Modern Premium Bottom Sheet Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomConfirmPanel(context),
          ),
        ],
      ),
    );
  }

  // Builds the Top Search Section for selecting route ("From" & "To")
  Widget _buildRouteTopSearchCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left side indicators (green circle, line, orange square)
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.pickupGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [BoxShadow(color: AppColors.pickupGreen.withOpacity(0.3), blurRadius: 4)],
                ),
              ),
              Container(
                width: 2,
                height: 35,
                color: Colors.grey.shade200,
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Inputs for FROM and TO
          Expanded(
            child: Column(
              children: [
                _buildRouteInputBlock(
                  label: 'FROM',
                  displayText: _pickupAddress,
                  placeholder: 'Choose pickup point',
                  isActive: _isSelectingPickup,
                  activeColor: AppColors.pickupGreen,
                  onTap: () => _openSearchOverlay(isPickup: true),
                ),
                const SizedBox(height: 10),
                _buildRouteInputBlock(
                  label: 'TO',
                  displayText: _dropAddress,
                  placeholder: 'Choose destination',
                  isActive: !_isSelectingPickup,
                  activeColor: Colors.orange,
                  onTap: () => _openSearchOverlay(isPickup: false),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Swap & Back Button Column
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
              IconButton(
                icon: const Icon(Icons.swap_vert_rounded, color: AppColors.primary, size: 24),
                onPressed: _swapLocations,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Single Input Top Search bar (For lounge selection backward compatibility)
  Widget _buildSingleTopSearchCard(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _openSearchOverlay(isPickup: true),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Text(
                  _selectedAddress.isEmpty ? 'Search for a location...' : _selectedAddress,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _selectedAddress.isEmpty ? Colors.grey.shade400 : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  // Helper widget for a single route input field inside the top card
  Widget _buildRouteInputBlock({
    required String label,
    required String? displayText,
    required String placeholder,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    final hasText = displayText != null && displayText.isNotEmpty;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.05) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? activeColor.withOpacity(0.4) : Colors.grey.shade200,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isActive ? activeColor.withOpacity(0.15) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: isActive ? activeColor : Colors.grey.shade600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasText ? displayText : placeholder,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: hasText ? FontWeight.w700 : FontWeight.w500,
                  color: hasText ? Colors.black87 : Colors.grey.shade400,
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

  // Floating Action controls on the map
  Widget _buildMapFloatingButton({required IconData icon, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
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

  // Modern Bottom Confirmation Panel
  Widget _buildBottomConfirmPanel(BuildContext context) {
    String headingText = 'Selected Location';
    String currentAddress = _selectedAddress;
    
    if (widget.isRouteSelection) {
      if (_isSelectingPickup) {
        headingText = 'SET PICKUP POINT';
        currentAddress = _pickupAddress ?? 'Tap map to set pickup...';
      } else {
        headingText = 'SET DESTINATION';
        currentAddress = _dropAddress ?? 'Tap map to set destination...';
      }
    }

    final Color themeColor = widget.isRouteSelection 
        ? (_isSelectingPickup ? AppColors.pickupGreen : AppColors.dropRed)
        : AppColors.primary;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Centered handlebar
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Details section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.location_on_rounded, color: themeColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headingText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: themeColor,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _isLoading 
                      ? _buildShimmerText()
                      : Text(
                          currentAddress,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Colors.black87,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Primary Confirmation Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleConfirmCTA,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      widget.isRouteSelection 
                          ? (_isSelectingPickup 
                              ? 'CONFIRM PICKUP LOCATION' 
                              : (_pickupLocation != null && _dropLocation != null ? 'CONFIRM ROUTE & BOOK' : 'CONFIRM DESTINATION'))
                          : 'CONFIRM LOCATION',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 0.6,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Shimmer animation fallback for loading addresses
  Widget _buildShimmerText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 150,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}
