import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/game_theme.dart';

class CountdownTimerWidget extends StatefulWidget {
  final int totalSeconds;
  final VoidCallback? onTimerExpired;

  const CountdownTimerWidget({
    super.key,
    required this.totalSeconds,
    this.onTimerExpired,
  });

  @override
  State<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget> {
  late int _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.totalSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining > 0) {
        setState(() {
          _remaining--;
        });
        if (_remaining <= 5 && _remaining > 0) {
          HapticFeedback.lightImpact();
        }
      } else {
        _timer?.cancel();
        HapticFeedback.heavyImpact();
        widget.onTimerExpired?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color get _color {
    final progress = _remaining / widget.totalSeconds;
    if (progress > 0.5) return GameTheme.neonGreen;
    if (progress > 0.2) return GameTheme.neonAmber;
    return GameTheme.neonPink;
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.totalSeconds > 0
        ? _remaining / widget.totalSeconds
        : 0.0;

    return Center(
      child: SizedBox(
        width: 100,
        height: 100,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Circular progress indicator
            CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(_color),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$_remaining',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: _color,
                  ),
                ),
                const Text(
                  'SEC',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: GameTheme.textSecondary,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
