import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Indicador visual de racha de respuestas correctas.
///
/// Muestra un icono de fuego con el número de aciertos seguidos.
/// Colores progresivos: 2-3 (naranja), 4-5 (rojo), 6+ (arcoíris).
/// Aparece solo cuando la racha >= 2.
class StreakIndicator extends StatefulWidget {
  final int streak;
  final VoidCallback? onTap;

  const StreakIndicator({
    super.key,
    required this.streak,
    this.onTap,
  });

  @override
  State<StreakIndicator> createState() => _StreakIndicatorState();
}

class _StreakIndicatorState extends State<StreakIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.95), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOut,
    ));

    if (widget.streak >= 2) {
      _pulseController.forward();
    }
  }

  @override
  void didUpdateWidget(StreakIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.streak > oldWidget.streak && widget.streak >= 2) {
      _pulseController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _getStreakColor() {
    if (widget.streak >= 6) return AppColors.rainbowRed;
    if (widget.streak >= 4) return Colors.red;
    return Colors.orange;
  }

  Color _getBackgroundColor() {
    if (widget.streak >= 6) return AppColors.rainbowPurple.withAlpha(40);
    if (widget.streak >= 4) return Colors.red.withAlpha(30);
    return Colors.orange.withAlpha(30);
  }

  String _getEmoji() {
    if (widget.streak >= 10) return '👑';
    if (widget.streak >= 7) return '🏆';
    if (widget.streak >= 5) return '💎';
    if (widget.streak >= 3) return '🔥';
    return '⭐';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.streak < 2) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getBackgroundColor(),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getStreakColor().withAlpha(150),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getStreakColor().withAlpha(80),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_getEmoji(), style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.streak}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getStreakColor(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
