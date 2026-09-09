import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Widget que muestra una animación de estrellitas/sparkles.
/// 
/// Se usa para celebrar respuestas correctas.
class SparklesOverlay extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback? onComplete;
  final Duration duration;
  final Offset? center;

  const SparklesOverlay({
    super.key,
    required this.isPlaying,
    this.onComplete,
    this.duration = const Duration(milliseconds: 1500),
    this.center,
  });

  @override
  State<SparklesOverlay> createState() => _SparklesOverlayState();
}

class _SparklesOverlayState extends State<SparklesOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Sparkle> _sparkles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    if (widget.isPlaying) {
      _startSparkles();
    }
  }

  @override
  void didUpdateWidget(SparklesOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _startSparkles();
    } else if (!widget.isPlaying && oldWidget.isPlaying) {
      _controller.stop();
    }
  }

  void _startSparkles() {
    _generateSparkles();
    _controller.forward(from: 0);
  }

  void _generateSparkles() {
    _sparkles.clear();
    for (int i = 0; i < 20; i++) {
      final angle = _random.nextDouble() * 2 * math.pi;
      final distance = 50 + _random.nextDouble() * 100;
      
      _sparkles.add(_Sparkle(
        color: _getRandomColor(),
        angle: angle,
        distance: distance,
        size: 4 + _random.nextDouble() * 8,
        delay: _random.nextDouble() * 0.2,
        rotationSpeed: (_random.nextDouble() - 0.5) * 4,
      ));
    }
  }

  Color _getRandomColor() {
    final colors = [
      Colors.amber,
      Colors.yellow,
      Colors.orange,
      Colors.white,
      const Color(0xFFFFD700), // Gold
      const Color(0xFFFFF8DC), // Cornsilk
    ];
    return colors[_random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isPlaying && !_controller.isAnimating) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size.infinite,
            painter: _SparklesPainter(
              sparkles: _sparkles,
              progress: _controller.value,
              center: widget.center,
            ),
          );
        },
      ),
    );
  }
}

class _Sparkle {
  final Color color;
  final double angle;
  final double distance;
  final double size;
  final double delay;
  final double rotationSpeed;

  _Sparkle({
    required this.color,
    required this.angle,
    required this.distance,
    required this.size,
    required this.delay,
    required this.rotationSpeed,
  });
}

class _SparklesPainter extends CustomPainter {
  final List<_Sparkle> sparkles;
  final double progress;
  final Offset? center;

  _SparklesPainter({
    required this.sparkles,
    required this.progress,
    this.center,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerPoint = center ?? Offset(size.width / 2, size.height / 2);

    for (final sparkle in sparkles) {
      final adjustedProgress = ((progress - sparkle.delay) / (1 - sparkle.delay)).clamp(0.0, 1.0);
      if (adjustedProgress <= 0) continue;

      // Curva de aparición y desaparición
      final fadeIn = (adjustedProgress * 3).clamp(0.0, 1.0);
      final fadeOut = (1 - (adjustedProgress - 0.5) * 2).clamp(0.0, 1.0);
      final opacity = fadeIn * fadeOut;

      if (opacity <= 0) continue;

      // Posición expandiéndose desde el centro
      final currentDistance = sparkle.distance * adjustedProgress;
      final x = centerPoint.dx + math.cos(sparkle.angle) * currentDistance;
      final y = centerPoint.dy + math.sin(sparkle.angle) * currentDistance;

      // Escala pulsante
      final scale = 0.5 + 0.5 * math.sin(adjustedProgress * math.pi);
      final currentSize = sparkle.size * scale;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(sparkle.rotationSpeed * adjustedProgress * math.pi);

      final paint = Paint()
        ..color = sparkle.color.withAlpha((opacity * 255).round())
        ..style = PaintingStyle.fill;

      // Dibujar estrella de 4 puntas
      _drawStar(canvas, currentSize, paint);

      canvas.restore();
    }
  }

  void _drawStar(Canvas canvas, double size, Paint paint) {
    final path = Path();
    final halfSize = size / 2;
    final quarterSize = size / 4;

    // Estrella de 4 puntas
    path.moveTo(0, -halfSize);
    path.lineTo(quarterSize, -quarterSize);
    path.lineTo(halfSize, 0);
    path.lineTo(quarterSize, quarterSize);
    path.lineTo(0, halfSize);
    path.lineTo(-quarterSize, quarterSize);
    path.lineTo(-halfSize, 0);
    path.lineTo(-quarterSize, -quarterSize);
    path.close();

    canvas.drawPath(path, paint);

    // Brillo central
    final glowPaint = Paint()
      ..color = Colors.white.withAlpha(((paint.color.a / 255.0) * 0.8 * 255).round())
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset.zero, size * 0.15, glowPaint);
  }

  @override
  bool shouldRepaint(_SparklesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
