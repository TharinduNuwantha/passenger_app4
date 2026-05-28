import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_colors.dart';
import '../screens/home/location_selection_screen.dart';

// Complete Premium Redesigned Map Selection Screen
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
    this.isRouteSelection = false, // defaults to false for legacy compatibility
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

class _MapSelectionScreenState extends State<MapSelectionScreen> with TickerProviderStateMixin {
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

  // --- Animations ---
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _isSelectingPickup = widget.startWithPickup;

    // Pulse animation for custom center map pin ripple effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    if (widget.isRouteSelection) {
      if (widget.initialPickupLat != null && widget.initialPickupLng != null) {
        _pickupLocation = LatLng(widget.initialPickupLat!, widget.initialPickupLng!);
        _pickupAddress = widget.initialPickupAddress ?? 'Selected Pickup';
      }
      if (widget.initialDropLat != null && widget.initialDropLng != null) {
        _dropLocation = LatLng(widget.initialDropLat!, widget.initialDropLng!);
        _dropAddress = widget.initialDropAddress ?? 'Selected Destination';
      }
      
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

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
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

    if (_pickupLocation!.latitude == _dropLocation!.latitude &&
        _pickupLocation!.longitude == _dropLocation!.longitude) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_pickupLocation!, 15));
      return;
    }

    final bounds = LatLngBounds(
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
      CameraUpdate.newLatLngBounds(bounds, 90),
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
    
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => LocationSelectionScreen(
          isPickup: isPickup,
          googleMapsApiKey: widget.apiKey,
          selectOnMapIsPop: true,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.fastOutSlowIn;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );

    if (result != null && mounted) {
      if (result['select_on_map'] == true) {
        setState(() {
          _isSelectingPickup = isPickup;
          if (isPickup) {
            _pickupLocation = null;
            _pickupAddress = null;
          } else {
            _dropLocation = null;
            _dropAddress = null;
          }
        });
        
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
        setState(() {
          _isSelectingPickup = false;
        });
        
        if (_dropLocation != null) {
          _moveMapToLocation(_dropLocation!);
        }
      } else {
        if (_dropLocation == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a destination')),
          );
          return;
        }

        if (_pickupLocation == null) {
          setState(() {
            _isSelectingPickup = true;
          });
          return;
        }

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
      Navigator.pop(context, {
        'address': _selectedAddress,
        'lat': _selectedLocation.latitude,
        'lng': _selectedLocation.longitude,
      });
    }
  }

  // Clear text inside specific inputs
  void _clearInput({required bool isPickup}) {
    HapticFeedback.lightImpact();
    setState(() {
      if (isPickup) {
        _pickupAddress = null;
        _pickupLocation = null;
      } else {
        _dropAddress = null;
        _dropLocation = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Generate Markers
    Set<Marker> markers = {};
    if (widget.isRouteSelection) {
      // Show fixed green pickup marker if set and we are NOT actively picking it
      if (_pickupLocation != null && !_isSelectingPickup) {
        markers.add(
          Marker(
            markerId: const MarkerId('pickup_marker'),
            position: _pickupLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        );
      }
      // Show fixed red destination marker if set and we are NOT actively picking it
      if (_dropLocation != null && _isSelectingPickup) {
        markers.add(
          Marker(
            markerId: const MarkerId('drop_marker'),
            position: _dropLocation!,
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
          width: 5,
          geodesic: true,
          patterns: [PatternItem.dash(12), PatternItem.gap(6)],
        ),
      );
    }

    final Color themeColor = _isSelectingPickup ? AppColors.pickupGreen : AppColors.dropRed;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Full-screen background Google Map (Primary UI layer)
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
              padding: const EdgeInsets.only(bottom: 240, top: 180),
            ),
          ),

          // 2. Animated Center Bouncing Pin & Pulsing Ripple Ring
          IgnorePointer(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated ripple/pulse ring on the map ground
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 48 * _pulseAnimation.value,
                          height: 18 * _pulseAnimation.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: themeColor.withOpacity(1.0 - _pulseAnimation.value),
                              width: 2.2,
                            ),
                          ),
                        );
                      },
                    ),
                    
                    // The premium bouncing pin
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: EdgeInsets.only(bottom: _isMoving ? 28 : 0),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Transform.translate(
                            offset: const Offset(0, -22),
                            child: Icon(
                              Icons.location_on_rounded,
                              size: 52,
                              color: widget.isRouteSelection ? themeColor : AppColors.primary,
                              shadows: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.18),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),

          // 3. Floating Modern Top Search Card
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: widget.isRouteSelection 
                ? _buildRouteTopSearchCard(context)
                : _buildSingleTopSearchCard(context),
          ),

          // 4. Floating Circular Map FAB Buttons
          Positioned(
            right: 16,
            bottom: widget.isRouteSelection ? 250 : 190,
            child: Column(
              children: [
                _buildMapFloatingButton(
                  icon: Icons.gps_fixed_rounded,
                  onTap: _getCurrentLocation,
                  heroTag: 'my_loc_btn',
                ),
                const SizedBox(height: 12),
                _buildMapFloatingButton(
                  icon: Icons.add_rounded,
                  onTap: () => _mapController?.animateCamera(CameraUpdate.zoomIn()),
                  heroTag: 'zoom_in_btn',
                ),
                const SizedBox(height: 12),
                _buildMapFloatingButton(
                  icon: Icons.remove_rounded,
                  onTap: () => _mapController?.animateCamera(CameraUpdate.zoomOut()),
                  heroTag: 'zoom_out_btn',
                ),
                if (widget.isRouteSelection && _pickupLocation != null && _dropLocation != null) ...[
                  const SizedBox(height: 12),
                  _buildMapFloatingButton(
                    icon: Icons.zoom_out_map_rounded,
                    onTap: _fitMapToRoute,
                    heroTag: 'fit_route_btn',
                  ),
                ],
              ],
            ),
          ),

          // 5. Draggable Bottom Sheet Panel (Uber/PickMe Styled)
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

  // Redesigns the Top Floating Route Search Card
  Widget _buildRouteTopSearchCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 28,
            spreadRadius: -2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Elegant left timeline column
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.pickupGreen.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.pickupGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: CustomPaint(
                  size: const Size(2, 45),
                  painter: DottedLinePainter(),
                ),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.dropRed.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Center(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.dropRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Search Inputs fields
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
                  onClear: () => _clearInput(isPickup: true),
                ),
                const SizedBox(height: 12),
                _buildRouteInputBlock(
                  label: 'TO',
                  displayText: _dropAddress,
                  placeholder: 'Choose destination',
                  isActive: !_isSelectingPickup,
                  activeColor: AppColors.dropRed,
                  onTap: () => _openSearchOverlay(isPickup: false),
                  onClear: () => _clearInput(isPickup: false),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Actions Column
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 6),
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

  // Single Input Top Card (For lounge selection backward compatibility)
  Widget _buildSingleTopSearchCard(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey.shade100, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _openSearchOverlay(isPickup: true),
              behavior: HitTestBehavior.opaque,
              child: Text(
                _selectedAddress.isEmpty ? 'Search for a location...' : _selectedAddress,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _selectedAddress.isEmpty ? Colors.grey.shade400 : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  // Individual Input panel with animation focus states and clear triggers
  Widget _buildRouteInputBlock({
    required String label,
    required String? displayText,
    required String placeholder,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    final hasText = displayText != null && displayText.isNotEmpty;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.04) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? activeColor.withOpacity(0.45) : Colors.grey.shade200,
            width: isActive ? 1.6 : 1.0,
          ),
          boxShadow: isActive ? [
            BoxShadow(
              color: activeColor.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ] : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? activeColor.withOpacity(0.12) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isActive ? activeColor : Colors.grey.shade600,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasText ? displayText : placeholder,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: hasText ? FontWeight.w700 : FontWeight.w500,
                  color: hasText ? Colors.black87 : Colors.grey.shade400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasText)
              GestureDetector(
                onTap: () {
                  onClear();
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, size: 12, color: Colors.black54),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Floating map circular button builder
  Widget _buildMapFloatingButton({
    required IconData icon,
    required VoidCallback onTap,
    required String heroTag,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
        ),
      ),
    );
  }

  // Uber/PickMe Draggable-Style Bottom sheet panel
  Widget _buildBottomConfirmPanel(BuildContext context) {
    String headingText = 'Selected Location';
    String currentAddress = _selectedAddress;
    
    if (widget.isRouteSelection) {
      if (_isSelectingPickup) {
        headingText = 'SET PICKUP POINT';
        currentAddress = _pickupAddress ?? 'Tap map to choose pickup...';
      } else {
        headingText = 'SET DESTINATION';
        currentAddress = _dropAddress ?? 'Tap map to choose destination...';
      }
    }

    final Color themeColor = widget.isRouteSelection 
        ? (_isSelectingPickup ? AppColors.pickupGreen : AppColors.dropRed)
        : AppColors.primary;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 34),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 28,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Draggable indicator bar
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Route info stats (if both set)
          if (widget.isRouteSelection && _pickupLocation != null && _dropLocation != null) ...[
            _buildRouteInfoSection(),
            const SizedBox(height: 16),
          ],

          // Details preview block
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.location_on_rounded, color: themeColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headingText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: themeColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _isLoading 
                      ? const ShimmerLoader()
                      : Text(
                          currentAddress,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Colors.black87,
                            height: 1.35,
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

          // Large premium CTA button
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
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.2,
                      ),
                    )
                  : Text(
                      widget.isRouteSelection 
                          ? (_isSelectingPickup 
                              ? 'CONFIRM PICKUP POINT' 
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

  // Custom route preview overview
  Widget _buildRouteInfoSection() {
    double distance = 0.0;
    if (_pickupLocation != null && _dropLocation != null) {
      distance = Geolocator.distanceBetween(
        _pickupLocation!.latitude,
        _pickupLocation!.longitude,
        _dropLocation!.latitude,
        _dropLocation!.longitude,
      ) / 1000.0;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.12), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_outlined, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          const Text(
            'Direct Distance:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54),
          ),
          const Spacer(),
          Text(
            '${distance.toStringAsFixed(1)} km',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

// Custom Painter to draw a clean timeline dotted vertical line
class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double dashHeight = 5, dashSpace = 4, startY = 0;
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 2;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Premium Shimmer skeleton loader widget
class ShimmerLoader extends StatefulWidget {
  const ShimmerLoader({super.key});

  @override
  State<ShimmerLoader> createState() => _ShimmerLoaderState();
}

class _ShimmerLoaderState extends State<ShimmerLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _opacity = Tween<double>(begin: 0.35, end: 0.85).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 180,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
