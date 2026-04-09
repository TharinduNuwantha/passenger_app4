import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_style.dart';

class BookingCountdownTimer extends StatefulWidget {
  final DateTime targetDateTime;
  final TextStyle? textStyle;
  final String expiredMessage;
  final VoidCallback? onExpired;

  const BookingCountdownTimer({
    super.key,
    required this.targetDateTime,
    this.textStyle,
    this.expiredMessage = 'Boarding Started',
    this.onExpired,
  });

  @override
  State<BookingCountdownTimer> createState() => _BookingCountdownTimerState();
}

class _BookingCountdownTimerState extends State<BookingCountdownTimer> {
  Timer? _timer;
  late Duration _timeRemaining;
  bool _isExpired = false;
  String _locationStatus = 'Locating...';
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _calculateTimeRemaining();
    _getCurrentLocation();
    if (!_isExpired) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(BookingCountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.targetDateTime != oldWidget.targetDateTime) {
      _calculateTimeRemaining();
      if (!_isExpired && _timer == null) {
        _startTimer();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _locationStatus = 'GPS Off');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _locationStatus = 'Permission Denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _locationStatus = 'Permission Denied Forever');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _locationStatus = 'Location Live';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _locationStatus = 'Location Error');
      }
    }
  }

  void _calculateTimeRemaining() {
    final now = DateTime.now();
    _timeRemaining = widget.targetDateTime.difference(now);
    
    if (_timeRemaining.isNegative) {
      _isExpired = true;
      _timeRemaining = Duration.zero;
      _timer?.cancel();
      _timer = null;
      widget.onExpired?.call();
    } else {
      _isExpired = false;
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _calculateTimeRemaining();
        });
        // Periodically refresh location every 30 seconds
        if (timer.tick % 30 == 0) {
          _getCurrentLocation();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isExpired) {
      return Text(
        widget.expiredMessage,
        style: widget.textStyle ??
            const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
            ),
      );
    }

    final days = _timeRemaining.inDays;
    final hours = _timeRemaining.inHours % 24;
    final minutes = _timeRemaining.inMinutes % 60;
    final seconds = _timeRemaining.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimeUnit(days.toString().padLeft(2, '0'), 'DAYS'),
              _buildSeparator(),
              _buildTimeUnit(hours.toString().padLeft(2, '0'), 'HRS'),
              _buildSeparator(),
              _buildTimeUnit(minutes.toString().padLeft(2, '0'), 'MINS'),
              _buildSeparator(),
              _buildTimeUnit(seconds.toString().padLeft(2, '0'), 'SECS', isLast: true),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on,
                  size: 14,
                  color: _currentPosition != null ? AppColors.success : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  _locationStatus,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _currentPosition != null ? AppColors.success : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeUnit(String value, String label, {bool isLast = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: AppColors.primary.withOpacity(0.5),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSeparator() {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 16),
      child: Text(
        ':',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
    );
  }
}
