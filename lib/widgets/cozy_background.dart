import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A cozy, animated background widget with optional image overlay
/// Perfect for that warm Friends-inspired aesthetic
class CozyBackground extends StatefulWidget {
  const CozyBackground({
    super.key,
    required this.child,
    this.showPattern = true,
    this.imageUrl,
  });

  final Widget child;
  final bool showPattern;
  final String? imageUrl;

  @override
  State<CozyBackground> createState() => _CozyBackgroundState();
}

class _CozyBackgroundState extends State<CozyBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
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
        // Clean white background with subtle purple tint
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                const Color(0xFFF8F7FC), // Very subtle purple tint
              ],
            ),
          ),
        ),

        // Simple floating shapes
        if (widget.showPattern)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _SimpleFloatingShapesPainter(
                  animation: _controller.value,
                ),
                size: Size.infinite,
              );
            },
          ),

        // Content
        widget.child,
      ],
    );
  }
}

class _SimpleFloatingShapesPainter extends CustomPainter {
  _SimpleFloatingShapesPainter({required this.animation});

  final double animation;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);

    // Simple floating circles with light purple tones
    _drawFloatingCircle(
      canvas,
      size,
      const Color(0xFF8B7FD9).withOpacity(0.03), // Light purple
      0.15,
      0.2,
      100,
      paint,
      speedFactor: 0.5,
    );
    
    _drawFloatingCircle(
      canvas,
      size,
      const Color(0xFFB8B0E8).withOpacity(0.04), // Lighter purple
      0.75,
      0.5,
      140,
      paint,
      speedFactor: 0.7,
    );
    
    _drawFloatingCircle(
      canvas,
      size,
      const Color(0xFF6C63D6).withOpacity(0.02), // Deeper purple
      0.5,
      0.75,
      110,
      paint,
      speedFactor: 0.6,
    );

    // Add a few smaller shapes for depth
    _drawFloatingCircle(
      canvas,
      size,
      const Color(0xFF8B7FD9).withOpacity(0.02),
      0.85,
      0.15,
      60,
      paint,
      speedFactor: 0.8,
    );
  }

  void _drawFloatingCircle(
    Canvas canvas,
    Size size,
    Color color,
    double xFactor,
    double yFactor,
    double radius,
    Paint paint, {
    double speedFactor = 1.0,
  }) {
    final offset = Offset(
      size.width * xFactor + math.sin(animation * 2 * math.pi * speedFactor) * 20,
      size.height * yFactor + math.cos(animation * 2 * math.pi * speedFactor) * 25,
    );
    paint.color = color;
    canvas.drawCircle(offset, radius, paint);
  }

  @override
  bool shouldRepaint(_SimpleFloatingShapesPainter oldDelegate) => true;
}
