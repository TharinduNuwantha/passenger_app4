import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui' as ui;
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

class _MapSelectionScreenState extends State<MapSelectionScreen> {
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
  bool _isSelectingFrom = false;
  bool _isSelectingTo = false;
  bool _hasUserConfirmedSelection = false;
  bool _isNavigatingToSearch = false;

  // --- Common States ---
  bool _isLoading = false;

  /// Tracks how many programmatic camera moves are in-flight.
  /// While > 0, onCameraMove won't overwrite coordinates and
  /// onCameraIdle won't reverse-geocode.
  int _programmaticMoveCount = 0;

  // --- Custom Bus Marker Bitmaps ---
  BitmapDescriptor? _busMarkerGreen;
  BitmapDescriptor? _busMarkerRed;

  // ─── Custom bus marker bitmap builder ───────────────────────────────────
  /// Renders a bus-themed marker badge onto a [ui.Canvas] and returns
  /// a [BitmapDescriptor] that can be used directly as a Google Maps marker.
  Future<BitmapDescriptor> _buildBusMarkerIcon(Color baseColor) async {
    const double scale = 3.0; // pixel density multiplier
    const double w = 72.0;
    const double h = 90.0;
    const double tipH = 16.0; // height of the pointed tail
    const double bodyH = h - tipH;
    const double radius = 18.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final paint = Paint()..isAntiAlias = true;

    // ── Drop shadow ──
    paint
      ..color = Colors.black.withOpacity(0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 4, w - 8, bodyH),
        const Radius.circular(radius),
      ),
      paint,
    );
    paint.maskFilter = null;

    // ── Badge body gradient ──
    final gradient = ui.Gradient.linear(
      Offset(w / 2, 0),
      Offset(w / 2, bodyH),
      [baseColor, Color.lerp(baseColor, Colors.black, 0.28)!],
    );
    paint.shader = gradient;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, bodyH),
        const Radius.circular(radius),
      ),
      paint,
    );
    paint.shader = null;

    // ── Pointer tip (centred below badge) ──
    final tipPath = Path()
      ..moveTo(w / 2 - 10, bodyH - 1)
      ..lineTo(w / 2 + 10, bodyH - 1)
      ..lineTo(w / 2, h - 2)
      ..close();
    paint.color = Color.lerp(baseColor, Colors.black, 0.28)!;
    canvas.drawPath(tipPath, paint);

    // ── Inner white circle ──
    paint.color = Colors.white.withOpacity(0.15);
    canvas.drawCircle(Offset(w / 2, bodyH * 0.42), 22, paint);

    // ── Bus icon (drawn as simple geometric shapes for pure Canvas) ──
    // Bus body
    final busPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Bus silhouette — front rect
    const double busX = 18.0;
    const double busY = 14.0;
    const double busW = 36.0;
    const double busBodyH = 22.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(busX, busY, busW, busBodyH),
        const Radius.circular(4.5),
      ),
      busPaint,
    );

    // Windows row (3 small rects inside bus body)
    final windowPaint = Paint()
      ..color = baseColor.withOpacity(0.85)
      ..isAntiAlias = true;
    for (int i = 0; i < 3; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(busX + 4 + i * 11.0, busY + 4, 8, 8),
          const Radius.circular(2),
        ),
        windowPaint,
      );
    }

    // Wheels (2 circles)
    final wheelPaint = Paint()
      ..color = Colors.white
      ..isAntiAlias = true;
    canvas.drawCircle(Offset(busX + 8, busY + busBodyH + 1), 5, wheelPaint);
    canvas.drawCircle(
      Offset(busX + busW - 8, busY + busBodyH + 1),
      5,
      wheelPaint,
    );

    // Wheel hubs
    final hubPaint = Paint()
      ..color = baseColor.withOpacity(0.85)
      ..isAntiAlias = true;
    canvas.drawCircle(Offset(busX + 8, busY + busBodyH + 1), 2.5, hubPaint);
    canvas.drawCircle(
      Offset(busX + busW - 8, busY + busBodyH + 1),
      2.5,
      hubPaint,
    );

    // ── White border ring ──
    paint
      ..color = Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(1, 1, w - 2, bodyH - 2),
        const Radius.circular(radius - 1),
      ),
      paint,
    );
    paint.style = PaintingStyle.fill;

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      (w * scale).toInt(),
      (h * scale).toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  // ─── Static center overlay bus pin (Flutter Widget) ──────────────────────
  Widget _buildBusCenterPin(Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Badge
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color, Color.lerp(color, Colors.black, 0.28)!],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.45),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.30),
              width: 1.2,
            ),
          ),
          child: const Icon(
            Icons.directions_bus_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
        // Pointer tip
        CustomPaint(
          size: const Size(20, 12),
          painter: _PointerTipPainter(
            color: Color.lerp(color, Colors.black, 0.28)!,
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _isSelectingPickup = widget.startWithPickup;
    _isSelectingFrom = widget.startWithPickup;
    _isSelectingTo = !widget.startWithPickup;
    _hasUserConfirmedSelection = false;
    _isNavigatingToSearch = false;
    _initBusMarkers();

    if (widget.isRouteSelection) {
      if (widget.initialPickupLat != null && widget.initialPickupLng != null) {
        _pickupLocation = LatLng(
          widget.initialPickupLat!,
          widget.initialPickupLng!,
        );
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
        _selectedLocation = LatLng(
          widget.initialPickupLat!,
          widget.initialPickupLng!,
        );
        _selectedAddress = widget.initialPickupAddress ?? 'Selected Location';
      } else {
        _getCurrentLocation();
      }
    }
  }

  Future<void> _initBusMarkers() async {
    final green = await _buildBusMarkerIcon(AppColors.pickupGreen);
    final red = await _buildBusMarkerIcon(AppColors.dropRed);
    if (mounted) {
      setState(() {
        _busMarkerGreen = green;
        _busMarkerRed = red;
      });
    }
  }

  @override
  void dispose() {
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

        _animateCameraTo(currentLatLng);
        _getAddressFromLatLng(currentLatLng);
      }
    } catch (e) {
      debugPrint('Error getting current location: $e');
    }
  }

  /// Animates the camera to [position] **without** updating
  /// any address/location state. Increments _programmaticMoveCount
  /// so that onCameraMove/onCameraIdle ignore the resulting events.
  void _animateCameraTo(LatLng position, {double zoom = 16}) {
    _programmaticMoveCount++;
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(position, zoom));
  }

  // Fits map bounds to show both pickup and destination locations
  void _fitMapToRoute() {
    if (_mapController == null ||
        _pickupLocation == null ||
        _dropLocation == null)
      return;

    if (_pickupLocation!.latitude == _dropLocation!.latitude &&
        _pickupLocation!.longitude == _dropLocation!.longitude) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_pickupLocation!, 15),
      );
      return;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(
        _pickupLocation!.latitude < _dropLocation!.latitude
            ? _pickupLocation!.latitude
            : _dropLocation!.latitude,
        _pickupLocation!.longitude < _dropLocation!.longitude
            ? _pickupLocation!.longitude
            : _dropLocation!.longitude,
      ),
      northeast: LatLng(
        _pickupLocation!.latitude > _dropLocation!.latitude
            ? _pickupLocation!.latitude
            : _dropLocation!.latitude,
        _pickupLocation!.longitude > _dropLocation!.longitude
            ? _pickupLocation!.longitude
            : _dropLocation!.longitude,
      ),
    );

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 90));
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

  // Reverse geocodes the coordinates to address using Google Maps Geocoding API
  Future<void> _getAddressFromLatLng(LatLng position) async {
    setState(() => _isLoading = true);

    final String url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=${widget.apiKey}';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' &&
            data['results'] != null &&
            (data['results'] as List).isNotEmpty) {
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
    if (_isNavigatingToSearch) return;
    setState(() {
      _isNavigatingToSearch = true;
      _isSelectingPickup = isPickup;
      _isSelectingFrom = isPickup;
      _isSelectingTo = !isPickup;
    });
    HapticFeedback.lightImpact();

    try {
      final result = await Navigator.push<Map<String, dynamic>>(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              LocationSelectionScreen(
                isPickup: isPickup,
                googleMapsApiKey: widget.apiKey,
                selectOnMapIsPop: true,
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.fastOutSlowIn;
            var tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));
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
            _isSelectingFrom = isPickup;
            _isSelectingTo = !isPickup;
            if (isPickup) {
              _pickupLocation = null;
              _pickupAddress = null;
            } else {
              _dropLocation = null;
              _dropAddress = null;
            }
          });
          return;
        }

        final address = result['address'] as String?;
        double? lat = (result['lat'] as num?)?.toDouble();
        double? lng = (result['lng'] as num?)?.toDouble();

        if (address != null) {
          // Resolve coordinates via Geocoding API if not provided
          if (lat == null || lng == null) {
            final url =
                'https://maps.googleapis.com/maps/api/geocode/json'
                '?address=${Uri.encodeComponent(address)}&key=${widget.apiKey}';
            try {
              final response = await http.get(Uri.parse(url));
              if (response.statusCode == 200) {
                final data = json.decode(response.body);
                if (data['status'] == 'OK' &&
                    data['results'] != null &&
                    (data['results'] as List).isNotEmpty) {
                  final loc = data['results'][0]['geometry']['location'];
                  lat = (loc['lat'] as num).toDouble();
                  lng = (loc['lng'] as num).toDouble();
                }
              }
            } catch (e) {
              debugPrint('Error geocoding fallback: $e');
            }
          }

          if (lat != null && lng != null) {
            final latLng = LatLng(lat, lng);

            // 1) Set the correct selection mode so onCameraMove/center pin
            //    both track the right field from this point forward.
            setState(() {
              if (widget.isRouteSelection) {
                _isSelectingPickup = isPickup;
                _isSelectingFrom = isPickup;
                _isSelectingTo = !isPickup;
                if (isPickup) {
                  _pickupAddress = address;
                  _pickupLocation = latLng;
                } else {
                  _dropAddress = address;
                  _dropLocation = latLng;
                }
              } else {
                _selectedAddress = address;
                _selectedLocation = latLng;
              }
            });

            // 2) Always animate camera to the SELECTED location so the
            //    center overlay pin lands exactly on it.
            _animateCameraTo(latLng);
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isNavigatingToSearch = false;
        });
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
      _programmaticMoveCount++;
      _fitMapToRoute();
    } else if (_isSelectingPickup && _pickupLocation != null) {
      _animateCameraTo(_pickupLocation!);
    } else if (!_isSelectingPickup && _dropLocation != null) {
      _animateCameraTo(_dropLocation!);
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
          _isSelectingFrom = false;
          _isSelectingTo = true;
        });

        if (_dropLocation != null) {
          _animateCameraTo(_dropLocation!);
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
            _isSelectingFrom = true;
            _isSelectingTo = false;
          });
          return;
        }

        setState(() {
          _hasUserConfirmedSelection = true;
        });

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
      setState(() {
        _hasUserConfirmedSelection = true;
      });
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
            icon:
                _busMarkerGreen ??
                BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen,
                ),
            anchor: const Offset(0.5, 1.0),
          ),
        );
      }
      // Show fixed red destination marker if set and we are NOT actively picking it
      if (_dropLocation != null && _isSelectingPickup) {
        markers.add(
          Marker(
            markerId: const MarkerId('drop_marker'),
            position: _dropLocation!,
            icon:
                _busMarkerRed ??
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            anchor: const Offset(0.5, 1.0),
          ),
        );
      }
    }

    // Generate Polylines
    Set<Polyline> polylines = {};
    if (widget.isRouteSelection &&
        _pickupLocation != null &&
        _dropLocation != null) {
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

    final Color themeColor = _isSelectingPickup
        ? AppColors.pickupGreen
        : AppColors.dropRed;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // --- Premium Structured Top Header Area ---
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Compact Top Bar Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        // Back navigation button with large touch target (48x48)
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: Material(
                            color: Colors.grey.shade50,
                            shape: const CircleBorder(),
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.black87,
                                size: 18,
                              ),
                              tooltip: 'Go Back',
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          widget.isRouteSelection ? 'Select Route' : 'Select Location',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 2. Centered Container Block for input fields
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 20.0),
                    child: widget.isRouteSelection
                        ? _buildRouteInputsRow(context)
                        : _buildSingleInputRow(context),
                  ),
                ],
              ),
            ),
          ),

          // --- Bottom Map & Controls Area (Fills remaining space) ---
          Expanded(
            child: Stack(
              children: [
                // 1. Map View
                Positioned.fill(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: widget.isRouteSelection
                          ? (_isSelectingPickup
                                ? (_pickupLocation ?? _selectedLocation)
                                : (_dropLocation ?? _selectedLocation))
                          : _selectedLocation,
                      zoom: 16,
                    ),
                    onMapCreated: (controller) {
                      _mapController = controller;
                      if (widget.isRouteSelection &&
                          _pickupLocation != null &&
                          _dropLocation != null) {
                        _fitMapToRoute();
                      }
                    },
                    onCameraMove: (position) {
                      if (_programmaticMoveCount > 0) return;
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
                      if (_programmaticMoveCount > 0) {
                        _programmaticMoveCount--;
                        setState(() {});
                        return;
                      }
                      setState(() {});
                      final currentPos = widget.isRouteSelection
                          ? (_isSelectingPickup ? _pickupLocation : _dropLocation)
                          : _selectedLocation;
                      if (currentPos != null) {
                        _getAddressFromLatLng(currentPos);
                      }
                    },
                    onTap: (position) {
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
                      _animateCameraTo(position);
                      _getAddressFromLatLng(position);
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    markers: markers,
                    polylines: polylines,
                    padding: const EdgeInsets.only(bottom: 240, top: 12),
                  ),
                ),

                // 2. Static Center Pin (Bus Theme)
                IgnorePointer(
                  child: Center(
                    child: Transform.translate(
                      offset: const Offset(0, -35),
                      child: _buildBusCenterPin(
                        widget.isRouteSelection ? themeColor : AppColors.primary,
                      ),
                    ),
                  ),
                ),

                // 3. Floating Map Controls (Zoom / Recenter)
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
                        onTap: () =>
                            _mapController?.animateCamera(CameraUpdate.zoomIn()),
                        heroTag: 'zoom_in_btn',
                      ),
                      const SizedBox(height: 12),
                      _buildMapFloatingButton(
                        icon: Icons.remove_rounded,
                        onTap: () =>
                            _mapController?.animateCamera(CameraUpdate.zoomOut()),
                        heroTag: 'zoom_out_btn',
                      ),
                      if (widget.isRouteSelection &&
                          _pickupLocation != null &&
                          _dropLocation != null) ...[
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

                // 4. Draggable confirm panel
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildBottomConfirmPanel(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Centered Container Row for Route Inputs (From / To fields)
  Widget _buildRouteInputsRow(BuildContext context) {
    return Row(
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

        // Search Inputs fields (dimensions exactly unchanged)
        Expanded(
          child: Column(
            children: [
              _buildRouteInputBlock(
                label: 'FROM',
                displayText: _pickupAddress,
                placeholder: 'Choose pickup point',
                isActive: _isSelectingFrom,
                activeColor: AppColors.pickupGreen,
                onTap: () => _openSearchOverlay(isPickup: true),
                onClear: () => _clearInput(isPickup: true),
              ),
              const SizedBox(height: 12),
              _buildRouteInputBlock(
                label: 'TO',
                displayText: _dropAddress,
                placeholder: 'Choose destination',
                isActive: _isSelectingTo,
                activeColor: AppColors.dropRed,
                onTap: () => _openSearchOverlay(isPickup: false),
                onClear: () => _clearInput(isPickup: false),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Swap Locations Button
        IconButton(
          icon: const Icon(
            Icons.swap_vert_rounded,
            color: AppColors.primary,
            size: 24,
          ),
          tooltip: 'Swap locations',
          onPressed: _swapLocations,
        ),
      ],
    );
  }

  // Centered Container Block for Single Location Input
  Widget _buildSingleInputRow(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => _openSearchOverlay(isPickup: true),
              behavior: HitTestBehavior.opaque,
              child: Text(
                _selectedAddress.isEmpty
                    ? 'Search for a location...'
                    : _selectedAddress,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _selectedAddress.isEmpty
                      ? Colors.grey.shade400
                      : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
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
            color: isActive
                ? activeColor.withOpacity(0.45)
                : Colors.grey.shade200,
            width: isActive ? 1.6 : 1.0,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? activeColor.withOpacity(0.12)
                    : Colors.grey.shade200,
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
                  child: const Icon(
                    Icons.close_rounded,
                    size: 12,
                    color: Colors.black54,
                  ),
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
      if (_hasUserConfirmedSelection) {
        headingText = 'CONFIRMING JOURNEY...';
      } else if (_isSelectingPickup) {
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
          if (widget.isRouteSelection &&
              _pickupLocation != null &&
              _dropLocation != null) ...[
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
                child: Icon(
                  Icons.location_on_rounded,
                  color: themeColor,
                  size: 28,
                ),
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
                                : (_pickupLocation != null &&
                                          _dropLocation != null
                                      ? 'CONFIRM ROUTE & BOOK'
                                      : 'CONFIRM DESTINATION'))
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
      distance =
          Geolocator.distanceBetween(
            _pickupLocation!.latitude,
            _pickupLocation!.longitude,
            _dropLocation!.latitude,
            _dropLocation!.longitude,
          ) /
          1000.0;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.directions_outlined,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          const Text(
            'Direct Distance:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const Spacer(),
          Text(
            '${distance.toStringAsFixed(1)} km',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
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

class _ShimmerLoaderState extends State<ShimmerLoader>
    with SingleTickerProviderStateMixin {
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

/// Draws a downward-pointing triangle used as the pin tail on [_buildBusCenterPin].
class _PointerTipPainter extends CustomPainter {
  final Color color;
  const _PointerTipPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PointerTipPainter old) => old.color != color;
}
