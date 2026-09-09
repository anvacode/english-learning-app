import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/app_colors_extension.dart';

class FloatingParticlesBackground extends StatefulWidget {
  final Widget child;
  final int particleCount;
  final List<String>? emojis;

  const FloatingParticlesBackground({
    super.key,
    required this.child,
    this.particleCount = 12,
    this.emojis,
  });

  @override
  State<FloatingParticlesBackground> createState() =>
      _FloatingParticlesBackgroundState();
}

class _FloatingParticlesBackgroundState
    extends State<FloatingParticlesBackground>
    with TickerProviderStateMixin {
  late List<_Particle> _particles;
  late AnimationController _controller;

  static const _defaultEmojis = ['✨', '⭐', '💫', '🌟', '✦', '◆', '●', '○'];

  @override
  void initState() {
    super.initState();
    _particles = List.generate(
      widget.particleCount,
      (i) => _Particle.random(i, widget.emojis ?? _defaultEmojis),
    );

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        
        return Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _ParticlePainter(
                          particles: _particles,
                          progress: _controller.value,
                          baseColor: context.appColors.textPrimary,
                        ),
                        size: size,
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: RepaintBoundary(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Stack(
                        children: _particles.map((p) {
                          final pos = p.getPosition(_controller.value, size);
                          return Positioned(
                            left: pos.dx,
                            top: pos.dy,
                            child: Opacity(
                              opacity: p.getOpacity(_controller.value),
                              child: Transform.rotate(
                                angle: p.getRotation(_controller.value),
                                child: Text(
                                  p.emoji,
                                  style: TextStyle(fontSize: p.size),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: widget.child,
            ),
          ],
        );
      },
    );
  }
}

class _Particle {
  final String emoji;
  final double size;
  final double baseX;
  final double baseY;
  final double speedX;
  final double speedY;
  final double amplitude;
  final double phase;
  final double rotationSpeed;
  final double opacityBase;

  _Particle({
    required this.emoji,
    required this.size,
    required this.baseX,
    required this.baseY,
    required this.speedX,
    required this.speedY,
    required this.amplitude,
    required this.phase,
    required this.rotationSpeed,
    required this.opacityBase,
  });

  factory _Particle.random(int index, List<String> emojis) {
    final rng = math.Random(index * 42 + 7);
    return _Particle(
      emoji: emojis[rng.nextInt(emojis.length)],
      size: 10 + rng.nextDouble() * 18,
      baseX: rng.nextDouble(),
      baseY: rng.nextDouble(),
      speedX: 0.3 + rng.nextDouble() * 0.7,
      speedY: 0.2 + rng.nextDouble() * 0.5,
      amplitude: 20 + rng.nextDouble() * 40,
      phase: rng.nextDouble() * math.pi * 2,
      rotationSpeed: 0.5 + rng.nextDouble() * 1.5,
      opacityBase: 0.08 + rng.nextDouble() * 0.15,
    );
  }

  Offset getPosition(double progress, Size size) {
    final x = baseX * size.width +
        math.sin(progress * math.pi * 2 * speedX + phase) * amplitude;
    final y = baseY * size.height +
        math.cos(progress * math.pi * 2 * speedY + phase) * amplitude * 0.6;
    return Offset(x, y);
  }

  double getOpacity(double progress) {
    return opacityBase *
        (0.5 + 0.5 * math.sin(progress * math.pi * 2 * 0.5 + phase));
  }

  double getRotation(double progress) {
    return progress * math.pi * 2 * rotationSpeed;
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  /// Color base de las partículas, adaptado al tema activo para que
  /// sean visibles tanto en fondos claros como oscuros.
  final Color baseColor;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    for (final particle in particles) {
      final pos = particle.getPosition(progress, canvasSize);
      final opacity = particle.getOpacity(progress);

      final paint = Paint()
        ..color = baseColor.withAlpha((opacity * 255).toInt())
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, particle.size * 0.3);

      canvas.drawCircle(pos, particle.size * 0.4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.baseColor != baseColor;
  }
}
