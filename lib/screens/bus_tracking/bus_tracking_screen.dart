// TODO Implement this library.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_style.dart';

/// Bus Tracking Screen - Shows real-time bus location on map
class BusTrackingScreen extends StatefulWidget {
  const BusTrackingScreen({super.key});

  @override
  State<BusTrackingScreen> createState() => _BusTrackingScreenState();
}

class _BusTrackingScreenState extends State<BusTrackingScreen> {
  GoogleMapController? _mapController;
  Position? _userLocation;
  Map<String, dynamic>? _activeBooking;
  bool _isLoading = true;
  bool _isTracking = false;
  final Set<Marker> _markers = {};
  StreamSubscription<Position>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _loadActiveBooking();
    await _getUserLocation();
    setState(() => _isLoading = false);
  }

  Future<void> _loadActiveBooking() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookingData = prefs.getString('activeBooking');
      if (bookingData != null) {
        setState(() {
          _activeBooking = Map<String, dynamic>.from(
            // ignore: collection_methods_unrelated_type
            Uri.splitQueryString(bookingData),
          );
        });
      }
    } catch (e) {
      print('Error loading active booking: $e');
    }
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _userLocation = position;
          _updateUserMarker(position);
        });
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _updateUserMarker(Position position) {
    _markers.removeWhere((m) => m.markerId.value == 'user');
    _markers.add(
      Marker(
        markerId: const MarkerId('user'),
        position: LatLng(position.latitude, position.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Your Location'),
      ),
    );
  }

  void _startTracking() {
    setState(() => _isTracking = true);

    _locationSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((position) {
          if (mounted) {
            setState(() {
              _userLocation = position;
              _updateUserMarker(position);
            });
          }
        });
  }

  void _stopTracking() {
    _locationSubscription?.cancel();
    setState(() => _isTracking = false);
  }

  void _centerOnUser() {
    if (_userLocation != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_userLocation!.latitude, _userLocation!.longitude),
          15.0,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Bus Tracking',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  // Map Container
                  Expanded(
                    flex: 2,
                    child: _userLocation != null
                        ? Stack(
                            children: [
                              GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  target: LatLng(
                                    _userLocation!.latitude,
                                    _userLocation!.longitude,
                                  ),
                                  zoom: 14.0,
                                ),
                                markers: _markers,
                                myLocationEnabled: true,
                                myLocationButtonEnabled: false,
                                onMapCreated: (controller) {
                                  _mapController = controller;
                                },
                              ),
                              // Center button
                              Positioned(
                                right: 16,
                                bottom: 16,
                                child: FloatingActionButton(
                                  mini: true,
                                  onPressed: _centerOnUser,
                                  backgroundColor: AppColors.white,
                                  child: const Icon(
                                    Icons.my_location,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceWhite,
                              border: Border.all(color: AppColors.divider ?? Colors.grey.shade300),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.location_off,
                                    size: 80,
                                    color: AppColors.primary.withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Location permission required',
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _getUserLocation,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                    ),
                                    child: const Text(
                                      'Enable Location',
                                      style: TextStyle(color: AppColors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),

                  // Bus Information Panel
                  Expanded(
                    flex: 1,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadowMedium,
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Handle bar
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: AppColors.divider,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),

                            if (_activeBooking != null) ...[
                              // Active Booking Info
                              _buildInfoRow(
                                icon: Icons.directions_bus,
                                label: 'Status',
                                value: _isTracking
                                    ? 'Tracking Active'
                                    : 'Ready to Track',
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                icon: Icons.route,
                                label: 'Route',
                                value:
                                    '${_activeBooking!['from'] ?? 'N/A'} → ${_activeBooking!['to'] ?? 'N/A'}',
                              ),
                              const SizedBox(height: 20),

                              // Tracking Control Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _isTracking
                                      ? _stopTracking
                                      : _startTracking,
                                  icon: Icon(
                                    _isTracking ? Icons.stop : Icons.play_arrow,
                                    color: AppColors.white,
                                  ),
                                  label: Text(
                                    _isTracking
                                        ? 'Stop Tracking'
                                        : 'Start Tracking',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isTracking
                                        ? AppColors.error
                                        : AppColors.primary,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ] else ...[
                              // No Active Booking
                              Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 48,
                                      color: AppColors.textTertiary,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No Active Booking',
                                      style: AppTextStyles.h3.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Book a bus to start tracking',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    ElevatedButton(
                                      onPressed: () {
                                        // Navigate back to home to book
                                        Navigator.pop(context);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 32,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Book a Bus',
                                        style: TextStyle(
                                          color: AppColors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryLighter,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
