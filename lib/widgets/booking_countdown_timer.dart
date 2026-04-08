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

  String _formatDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (days > 0) {
      return '${days}d ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.timer_outlined,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                _formatDuration(_timeRemaining),
                style: widget.textStyle ??
                    AppTextStyles.bodyMedium.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 14,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on,
                size: 10,
                color: _currentPosition != null ? AppColors.success : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                _locationStatus,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 9,
                  color: _currentPosition != null ? AppColors.success : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
