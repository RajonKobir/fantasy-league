import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A reusable countdown timer widget that displays time remaining until a match starts.
///
/// Features:
/// - Updates every second automatically
/// - Handles timezone conversion for UTC
/// - Shows "Match Started" or "Live" when countdown reaches 0
/// - Supports custom formatting and styling
/// - Properly disposes timer to prevent memory leaks
class CountdownTimerWidget extends StatefulWidget {
  /// The datetime when the match starts (as ISO 8601 string or DateTime object)
  final dynamic startDateTime;

  /// Text style for the countdown display
  final TextStyle? style;

  /// Builder function to show custom widget when countdown ends
  final Widget Function()? expiredBuilder;

  /// Format for display: 'auto' (default), 'full', 'short'
  /// auto: Shows HH:MM:SS -> M:SS -> S based on time remaining
  /// full: Always shows HH:MM:SS
  /// short: Always shows M:SS
  final String format;

  /// Text to show when match has already started
  final String? liveText;

  /// Color to use for "Live" or expired state (defaults to red)
  final Color? liveColor;

  const CountdownTimerWidget({
    super.key,
    required this.startDateTime,
    this.style,
    this.expiredBuilder,
    this.format = 'auto',
    this.liveText,
    this.liveColor,
  });

  @override
  _CountdownTimerWidgetState createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget> {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _hasExpired = false;
  late DateTime _matchStartTime;

  @override
  void initState() {
    super.initState();
    _initializeMatchTime();
    _startCountdown();
  }

  /// Parse and initialize the match start time from various formats
  void _initializeMatchTime() {
    try {
      if (widget.startDateTime is DateTime) {
        _matchStartTime = widget.startDateTime as DateTime;
      } else if (widget.startDateTime is String) {
        final dateStr = widget.startDateTime as String;
        if (dateStr.isEmpty) {
          _hasExpired = true;
          return;
        }
        try {
          // Try parsing as ISO 8601 (most common from backend)
          _matchStartTime = DateTime.parse(dateStr);
        } catch (_) {
          // Try other formats if needed
          if (kDebugMode) {
            debugPrint('[CountdownTimer] Failed to parse datetime: $dateStr');
          }
          _hasExpired = true;
          return;
        }
      } else {
        if (kDebugMode) {
          debugPrint(
              '[CountdownTimer] Invalid startDateTime type: ${widget.startDateTime.runtimeType}');
        }
        _hasExpired = true;
        return;
      }

      // Ensure we're comparing in UTC
      if (!_matchStartTime.isUtc) {
        // If local time, convert to UTC
        _matchStartTime = _matchStartTime.toUtc();
      }

      // Calculate initial remaining time
      _updateCountdown();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CountdownTimer] Error initializing match time: $e');
      }
      _hasExpired = true;
    }
  }

  /// Calculate remaining duration and update UI
  void _updateCountdown() {
    if (!mounted) return;

    try {
      final now = DateTime.now().toUtc();
      _remaining = _matchStartTime.difference(now);

      // Check if countdown has expired
      if (_remaining.isNegative) {
        _remaining = Duration.zero;
        _hasExpired = true;
      } else {
        _hasExpired = false;
      }

      setState(() {});
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CountdownTimer] Error calculating countdown: $e');
      }
    }
  }

  /// Start the timer that updates every second
  void _startCountdown() {
    _updateCountdown(); // Initial update

    if (_hasExpired) return;

    // Update every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdown();

      // Stop timer if expired to save resources
      if (_hasExpired) {
        _timer?.cancel();
        _timer = null;
      }
    });
  }

  /// Format duration to display string based on format preference
  String _formatDuration(Duration duration) {
    if (_hasExpired) {
      return '';
    }

    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    switch (widget.format) {
      case 'full':
        // Always show HH:MM:SS
        return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

      case 'short':
        // Always show MM:SS
        return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

      case 'auto':
      default:
        // Auto format: show most relevant units
        if (hours > 0) {
          // HH:MM:SS format when more than 1 hour
          return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
        } else if (minutes > 0) {
          // M:MM:SS format when less than 1 hour
          return '${minutes.toString()}:${seconds.toString().padLeft(2, '0')}';
        } else {
          // SS format when less than 1 minute
          return '${seconds.toString().padLeft(2, '0')}s';
        }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasExpired) {
      if (widget.expiredBuilder != null) {
        return widget.expiredBuilder!();
      }

      // Default expired display
      return Text(
        widget.liveText ?? 'Started',
        style: widget.style?.copyWith(
              color: widget.liveColor ?? Colors.red,
            ) ??
            TextStyle(
              color: widget.liveColor ?? Colors.red,
              fontWeight: FontWeight.w500,
            ),
      );
    }

    return Text(
      _formatDuration(_remaining),
      style: widget.style ??
          const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: Colors.red,
            fontWeight: FontWeight.w500,
          ),
    );
  }
}
