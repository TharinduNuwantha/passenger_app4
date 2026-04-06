import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

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

  @override
  void initState() {
    super.initState();
    _calculateTimeRemaining();
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
      }
    });
  }

  String _formatDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    final parts = <String>[];
    if (days > 0) parts.add('${days}d');
    parts.add(hours.toString().padLeft(2, '0'));
    parts.add(minutes.toString().padLeft(2, '0'));
    parts.add(seconds.toString().padLeft(2, '0'));

    if (days > 0) {
      return '${parts[0]} ${parts[1]}:${parts[2]}:${parts[3]}';
    }
    return '${parts[0]}:${parts[1]}:${parts[2]}';
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 14,
            color: AppColors.primary.withOpacity(0.7),
          ),
          const SizedBox(width: 4),
          Text(
            _formatDuration(_timeRemaining),
            style: widget.textStyle ??
                const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
          ),
        ],
      ),
    );
  }
}
