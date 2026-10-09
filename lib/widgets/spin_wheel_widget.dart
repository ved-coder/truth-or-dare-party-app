import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/player_model.dart';

class SpinWheelWidget extends StatefulWidget {
  final List<Player> players;
  final bool isHost;
  final double targetAngle;
  final int spinTimestamp;
  final Function(Player chosenPlayer, double finalAngle)? onSpinTriggered;
  final Function(Player landedPlayer)? onSpinLanded;

  const SpinWheelWidget({
    super.key,
    required this.players,
    this.isHost = false,
    this.targetAngle = 0.0,
    this.spinTimestamp = 0,
    this.onSpinTriggered,
    this.onSpinLanded,
  });

  @override
  State<SpinWheelWidget> createState() => _SpinWheelWidgetState();
}

class _SpinWheelWidgetState extends State<SpinWheelWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;
  double _currentRotation = 0.0;
  int _lastHandledTimestamp = 0;
  int _lastTickSegment = -1;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    );

    _animation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    )..addListener(_onAnimationTick)
      ..addStatusListener(_onAnimationStatus);
  }

  @override
  void didUpdateWidget(covariant SpinWheelWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.spinTimestamp > 0 &&
        widget.spinTimestamp != _lastHandledTimestamp &&
        widget.spinTimestamp != oldWidget.spinTimestamp) {
      _lastHandledTimestamp = widget.spinTimestamp;
      _animateToAngle(widget.targetAngle);
    }
  }

  List<Player> get _effectivePlayers {
    if (widget.players.isEmpty) {
      return [
        const Player(id: '1', name: 'laxi', avatarEmoji: 'L', colorValue: 0xFFF59E0B),
        const Player(id: '2', name: 'max', avatarEmoji: 'M', colorValue: 0xFF10B981),
        const Player(id: '3', name: 'sam', avatarEmoji: 'S', colorValue: 0xFF9D84F6),
        const Player(id: '4', name: 'alex', avatarEmoji: 'A', colorValue: 0xFFEE6083),
      ];
    }
    if (widget.players.length == 1) {
      return [widget.players.first, widget.players.first];
    }
    return widget.players;
  }

  static int getIndexUnderPointer(double rotation, int totalSlices) {
    if (totalSlices <= 0) return 0;
    final sliceAngle = (2 * pi) / totalSlices;
    double alpha = (3 * pi / 2) - (rotation % (2 * pi));
    while (alpha < 0) {
      alpha += 2 * pi;
    }
    alpha = alpha % (2 * pi);

    int index = (alpha / sliceAngle).floor() % totalSlices;
    return index;
  }

  void _onAnimationTick() {
    setState(() {
      _currentRotation = _animation.value;
    });

    final players = _effectivePlayers;
    final currentSeg = getIndexUnderPointer(_currentRotation, players.length);
    if (currentSeg != _lastTickSegment) {
      _lastTickSegment = currentSeg;
      HapticFeedback.selectionClick();
    }
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      HapticFeedback.mediumImpact();
      final players = _effectivePlayers;
      final landedIndex = getIndexUnderPointer(_currentRotation, players.length);
      final landedPlayer = players[landedIndex];
      widget.onSpinLanded?.call(landedPlayer);
    }
  }

  void _animateToAngle(double targetAngle) {
    final start = _currentRotation;
    _animation = Tween<double>(
      begin: start,
      end: targetAngle,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animController.forward(from: 0.0);
  }

  void triggerSpin() {
    if (_animController.isAnimating) return;

    final players = _effectivePlayers;
    final random = Random();
    final targetIndex = random.nextInt(players.length);
    final sliceAngle = (2 * pi) / players.length;

    final targetSliceCenter = (targetIndex + 0.5) * sliceAngle;

    double neededNorm = (3 * pi / 2) - targetSliceCenter;
    while (neededNorm < 0) {
      neededNorm += 2 * pi;
    }
    neededNorm = neededNorm % (2 * pi);

    final currentNorm = _currentRotation % (2 * pi);
    double forwardDelta = (neededNorm - currentNorm) % (2 * pi);
    if (forwardDelta <= 0.1) {
      forwardDelta += 2 * pi;
    }

    final finalTargetAngle = _currentRotation + (5 * 2 * pi) + forwardDelta;

    _lastHandledTimestamp = DateTime.now().millisecondsSinceEpoch;
    _animateToAngle(finalTargetAngle);

    final chosenPlayer = players[targetIndex];
    widget.onSpinTriggered?.call(chosenPlayer, finalTargetAngle);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final players = _effectivePlayers;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 290,
            height: 310,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Rotating Wheel Canvas (Matching PDF 4-Color Slices)
                Transform.rotate(
                  angle: _currentRotation,
                  child: CustomPaint(
                    size: const Size(270, 270),
                    painter: _WheelPainter(players: players),
                  ),
                ),

                // Pink Triangle Pointer at top center (12 o'clock) matching PDF
                Positioned(
                  top: 4,
                  child: CustomPaint(
                    size: const Size(20, 16),
                    painter: _PdfPinkPointerPainter(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<Player> players;

  _WheelPainter({required this.players});

  static const List<Color> pdfWheelColors = [
    Color(0xFFEE6083), // Pink
    Color(0xFFB197FC), // Purple
    Color(0xFF4CD9A4), // Green
    Color(0xFFF59E0B), // Orange
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sliceAngle = (2 * pi) / players.length;

    final paint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = const Color(0xFF13111C)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < players.length; i++) {
      final startAngle = i * sliceAngle;
      paint.color = pdfWheelColors[i % pdfWheelColors.length];

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sliceAngle,
        true,
        paint,
      );

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sliceAngle,
        true,
        borderPaint,
      );
    }

    // Outer dark border rim matching PDF
    final rimPaint = Paint()
      ..color = const Color(0xFF13111C)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius - 3, rimPaint);
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) {
    return oldDelegate.players != players;
  }
}

class _PdfPinkPointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(size.width / 2, size.height); // Downward tip pointing into wheel
    path.lineTo(size.width, 0); // Top right
    path.lineTo(0, 0); // Top left
    path.close();

    final fillPaint = Paint()
      ..color = const Color(0xFFEE6083) // Pink accent pointer
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
