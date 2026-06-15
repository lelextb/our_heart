import 'dart:math';
import 'package:flutter/material.dart';

/// A stack of softly falling heart-shaped petals that covers the entire
/// screen behind the main content. The animation runs continuously and
/// adapts to light / dark mode.
class PetalBackground extends StatefulWidget {
  const PetalBackground({super.key, required this.child});

  final Widget child;

  @override
  State<PetalBackground> createState() => _PetalBackgroundState();
}

class _PetalBackgroundState extends State<PetalBackground>
    with TickerProviderStateMixin {
  late final AnimationController _controller;

  // Each petal has a random position, size, speed, and opacity.
  final List<_Petal> _petals = [];
  final Random _random = Random(42); // fixed seed for reproducibility

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Generate 30 petals with varied parameters.
    for (int i = 0; i < 30; i++) {
      _petals.add(_Petal(
        left: _random.nextDouble(),
        top: _random.nextDouble(),
        size: 10.0 + _random.nextDouble() * 14.0,
        speed: 0.3 + _random.nextDouble() * 0.7,
        opacity: 0.15 + _random.nextDouble() * 0.25,
        delay: _random.nextDouble(),
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final petalColor = isDark
        ? Colors.white.withOpacity(0.07)
        : const Color(0xFFFF6B81).withOpacity(0.08);

    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
              return CustomPaint(
                painter: _PetalPainter(
                  petals: _petals,
                  color: petalColor,
                  time: now,
                ),
              );
            },
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _Petal {
  final double left;   // 0..1 fraction of screen width
  final double top;    // initial 0..1 fraction of screen height
  final double size;   // logical pixels
  final double speed;  // how fast it falls
  final double opacity;
  final double delay;

  const _Petal({
    required this.left,
    required this.top,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.delay,
  });
}

class _PetalPainter extends CustomPainter {
  _PetalPainter({
    required this.petals,
    required this.color,
    required this.time,
  });

  final List<_Petal> petals;
  final Color color;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    for (final petal in petals) {
      final paint = Paint()..color = color.withOpacity(petal.opacity);

      // Falling motion: top moves down, wraps around.
      double y = (petal.top + time * petal.speed * 0.05 + petal.delay) % 1.0;
      if (y < 0) y += 1.0;

      final x = petal.left * size.width;
      final yPos = y * size.height;

      // Draw a tiny heart using a custom path.
      final heartPath = _heartPath(
        center: Offset(x, yPos),
        size: petal.size,
      );

      canvas.drawPath(heartPath, paint);
    }
  }

  Path _heartPath({required Offset center, required double size}) {
    final w = size;
    final h = size * 0.9;
    final path = Path();
    path.moveTo(center.dx, center.dy + h * 0.3); // bottom point
    path.cubicTo(
      center.dx - w * 0.5, center.dy - h * 0.2,
      center.dx - w * 0.45, center.dy - h * 0.8,
      center.dx, center.dy - h * 0.3,
    );
    path.cubicTo(
      center.dx + w * 0.45, center.dy - h * 0.8,
      center.dx + w * 0.5, center.dy - h * 0.2,
      center.dx, center.dy + h * 0.3,
    );
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(_PetalPainter oldDelegate) => true;
}