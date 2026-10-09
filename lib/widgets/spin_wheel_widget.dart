import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/player_model.dart';
import '../theme/game_theme.dart';

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
      duration: const Duration(milliseconds: 4000),
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
        const Player(id: '1', name: 'Player 1', avatarEmoji: '😎', colorValue: 0xFF6366F1),
        const Player(id: '2', name: 'Player 2', avatarEmoji: '🦄', colorValue: 0xFFEC4899),
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
    // Pointer is stationary at 12 o'clock (3*pi/2 radians).
    // Canvas angle alpha that ends up at 3*pi/2 after clockwise rotation R:
    // alpha + R = 3*pi/2  ==> alpha = 3*pi/2 - R.
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

    // Center of target slice
    final targetSliceCenter = (targetIndex + 0.5) * sliceAngle;

    // We want targetSliceCenter + rotation = 3*pi/2 (mod 2*pi)
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

    // 5 full spins + forwardDelta
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
    final isSpinning = _animController.isAnimating;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 310,
            height: 330,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Clean subtle ambient halo
                Container(
                  width: 290,
                  height: 290,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: GameTheme.neonPurple.withValues(alpha: 0.25),
                        blurRadius: 28,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),

                // Rotating Wheel Canvas
                Transform.rotate(
                  angle: _currentRotation,
                  child: CustomPaint(
                    size: const Size(270, 270),
                    painter: _WheelPainter(players: players),
                  ),
                ),

                // Top Pointer Arrow (12 o'clock, pointing directly at the top slice)
                Positioned(
                  top: 8,
                  child: CustomPaint(
                    size: const Size(28, 34),
                    painter: _CleanPointerPainter(),
                  ),
                ),

                // Center Clean Spin Button
                GestureDetector(
                  onTap: triggerSpin,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: GameTheme.neonPurple.withValues(alpha: 0.6),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isSpinning ? Icons.sync : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                          Text(
                            isSpinning ? 'SPINNING' : 'SPIN',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
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

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sliceAngle = (2 * pi) / players.length;

    final paint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw Slices
    for (int i = 0; i < players.length; i++) {
      final player = players[i];
      final startAngle = i * sliceAngle;

      paint.color = Color(player.colorValue);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sliceAngle,
        true,
        paint,
      );

      // Slice dividing border
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sliceAngle,
        true,
        borderPaint,
      );

      // Draw Avatar & Name on the slice
      canvas.save();
      final midAngle = startAngle + (sliceAngle / 2);
      canvas.translate(center.dx, center.dy);
      canvas.rotate(midAngle);

      // Avatar Emoji
      final emojiPainter = TextPainter(
        text: TextSpan(
          text: player.avatarEmoji,
          style: const TextStyle(fontSize: 22),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      emojiPainter.paint(canvas, Offset(radius * 0.65 - 11, -11));

      // Player Name
      final nameText = player.name.length > 7
          ? '${player.name.substring(0, 6)}…'
          : player.name;
      final namePainter = TextPainter(
        text: TextSpan(
          text: nameText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(1, 1)),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: radius * 0.42);
      namePainter.paint(canvas, Offset(radius * 0.26, -7));

      canvas.restore();
    }

    // Outer rim border
    final rimPaint = Paint()
      ..color = const Color(0xFF1E163B)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius - 4, rimPaint);

    final rimHighlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius - 1, rimHighlight);

    // Rim indicator pegs
    final pegPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final pegCount = max(players.length * 2, 10);
    for (int p = 0; p < pegCount; p++) {
      final pegAngle = (p * 2 * pi) / pegCount;
      final pegX = center.dx + (radius - 4) * cos(pegAngle);
      final pegY = center.dy + (radius - 4) * sin(pegAngle);
      canvas.drawCircle(Offset(pegX, pegY), 2.5, pegPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) {
    return oldDelegate.players != players;
  }
}

class _CleanPointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(size.width / 2, size.height); // Bottom point pointing down into top slice
    path.lineTo(size.width, 0); // Top right
    path.lineTo(0, 0); // Top left
    path.close();

    final fillPaint = Paint()
      ..color = const Color(0xFFF43F5E) // Clean coral red pointer
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
