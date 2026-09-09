import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Widget que muestra una animación de confeti.
/// 
/// Se usa para celebrar logros como completar lecciones.
class ConfettiOverlay extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback? onComplete;
  final Duration duration;

  const ConfettiOverlay({
    super.key,
    required this.isPlaying,
    this.onComplete,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiPiece> _confettiPieces = [];
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
      _startConfetti();
    }
  }

  @override
  void didUpdateWidget(ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _startConfetti();
    } else if (!widget.isPlaying && oldWidget.isPlaying) {
      _controller.stop();
    }
  }

  void _startConfetti() {
    _generateConfetti();
    _controller.forward(from: 0);
  }

  void _generateConfetti() {
    _confettiPieces.clear();
    for (int i = 0; i < 50; i++) {
      _confettiPieces.add(_ConfettiPiece(
        color: _getRandomColor(),
        startX: _random.nextDouble(),
        startY: -0.1 - _random.nextDouble() * 0.3,
        endX: _random.nextDouble() * 0.4 - 0.2,
        rotation: _random.nextDouble() * 4 * math.pi,
        size: 8 + _random.nextDouble() * 8,
        delay: _random.nextDouble() * 0.3,
      ));
    }
  }

  Color _getRandomColor() {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.cyan,
      Colors.amber,
      Colors.teal,
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
            painter: _ConfettiPainter(
              pieces: _confettiPieces,
              progress: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _ConfettiPiece {
  final Color color;
  final double startX;
  final double startY;
  final double endX;
  final double rotation;
  final double size;
  final double delay;

  _ConfettiPiece({
    required this.color,
    required this.startX,
    required this.startY,
    required this.endX,
    required this.rotation,
    required this.size,
    required this.delay,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiPiece> pieces;
  final double progress;

  _ConfettiPainter({
    required this.pieces,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final piece in pieces) {
      final adjustedProgress = ((progress - piece.delay) / (1 - piece.delay)).clamp(0.0, 1.0);
      if (adjustedProgress <= 0) continue;

      final x = size.width * (piece.startX + piece.endX * adjustedProgress);
      final y = size.height * (piece.startY + 1.3 * adjustedProgress);
      final rotation = piece.rotation * adjustedProgress;
      final opacity = (1 - adjustedProgress * 0.5).clamp(0.0, 1.0);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      final paint = Paint()
        ..color = piece.color.withAlpha((opacity * 255).round())
        ..style = PaintingStyle.fill;

      // Dibujar rectángulo de confeti
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: piece.size,
          height: piece.size * 0.6,
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
