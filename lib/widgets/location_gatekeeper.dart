import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../screens/location_permission_screen.dart';

class LocationGatekeeper extends StatefulWidget {
  final Widget child;

  const LocationGatekeeper({super.key, required this.child});

  @override
  State<LocationGatekeeper> createState() => _LocationGatekeeperState();
}

class _LocationGatekeeperState extends State<LocationGatekeeper>
    with WidgetsBindingObserver {
  bool _isChecking = true;
  bool _hasAccess = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAccess();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAccess();
    }
  }

  Future<void> _checkAccess() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    final permission = await Geolocator.checkPermission();

    final hasAccess = serviceEnabled &&
        (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse);

    if (mounted) {
      setState(() {
        _hasAccess = hasAccess;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_hasAccess) {
      return LocationPermissionScreen(
        onGranted: () {
          setState(() {
            _hasAccess = true;
          });
        },
      );
    }

    return widget.child;
  }
}
