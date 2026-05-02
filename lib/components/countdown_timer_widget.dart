import 'dart:async';
import 'package:flutter/material.dart';

/// Reusable countdown widget that ticks every second.
class CountdownTimerWidget extends StatefulWidget {
  final DateTime targetDate;
  final TextStyle? textStyle;
  final String prefix;
  final String expiredLabel;
  final Widget Function(String timeString)? builder;

  const CountdownTimerWidget({
    super.key,
    required this.targetDate,
    this.textStyle,
    this.prefix = '',
    this.expiredLabel = 'Expired',
    this.builder,
  });

  @override
  State<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _calculateRemaining();
    });
  }

  void _calculateRemaining() {
    final now = DateTime.now();
    final diff = widget.targetDate.difference(now);
    if (mounted) {
      setState(() {
        _remaining = diff.isNegative ? Duration.zero : diff;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    if (d == Duration.zero) return widget.expiredLabel;

    final days = d.inDays;
    final hours = d.inHours.remainder(24);
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);

    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m';
    }
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    }
    return '${minutes}m ${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${widget.prefix}${_formatDuration(_remaining)}';

    if (widget.builder != null) {
      return widget.builder!(timeStr);
    }

    return Text(
      timeStr,
      style: widget.textStyle ??
          const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
    );
  }
}
