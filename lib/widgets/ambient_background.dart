import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/game_theme.dart';

class AmbientBackground extends StatefulWidget {
  final Widget child;

  const AmbientBackground({
    super.key,
    required this.child,
  });

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _rand = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    for (int i = 0; i < 28; i++) {
      _particles.add(
        _Particle(
          x: _rand.nextDouble(),
          y: _rand.nextDouble(),
          size: 1.5 + _rand.nextDouble() * 3.5,
          speed: 0.05 + _rand.nextDouble() * 0.1,
          opacity: 0.2 + _rand.nextDouble() * 0.5,
          isPurple: _rand.nextBool(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Pitch black to deep purple gradient
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.0, -0.4),
              radius: 1.2,
              colors: [
                Color(0xFF140B2E), // Subtle dark purple glow at center
                Color(0xFF090514), // Deep obsidian
                Color(0xFF05030A), // Pitch black at edges
              ],
              stops: [0.0, 0.6, 1.0],
            ),
          ),
        ),

        // Animated particles canvas
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              size: Size.infinite,
              painter: _ParticlePainter(
                progress: _controller.value,
                particles: _particles,
              ),
            );
          },
        ),

        // Foreground content
        widget.child,
      ],
    );
  }
}

class _Particle {
  double x;
  double y;
  final double size;
  final double speed;
  final double opacity;
  final bool isPurple;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.isPurple,
  });
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  final List<_Particle> particles;

  _ParticlePainter({
    required this.progress,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final purplePaint = Paint()
      ..color = GameTheme.primaryPurple
      ..style = PaintingStyle.fill;

    final lilacPaint = Paint()
      ..color = GameTheme.neonLavender
      ..style = PaintingStyle.fill;

    // Ambient top-left soft glow orb
    final orbGlowPaint = Paint()
      ..color = GameTheme.royalPurple.withValues(alpha: 0.12 + 0.05 * sin(progress * 2 * pi))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70);
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.25),
      size.width * 0.35,
      orbGlowPaint,
    );

    // Ambient bottom-left soft glow orb
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.8),
      size.width * 0.4,
      orbGlowPaint,
    );

    // Draw drifting particles
    for (var p in particles) {
      final currentY = (p.y - (progress * p.speed)) % 1.0;
      final currentX = p.x + 0.02 * sin((progress + p.y) * 2 * pi);

      final screenX = (currentX % 1.0) * size.width;
      final screenY = (currentY < 0 ? currentY + 1.0 : currentY) * size.height;

      final paint = p.isPurple ? purplePaint : lilacPaint;
      paint.color = paint.color.withValues(
        alpha: p.opacity * (0.6 + 0.4 * sin((progress * 3 + p.x) * 2 * pi)),
      );

      canvas.drawCircle(Offset(screenX, screenY), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
