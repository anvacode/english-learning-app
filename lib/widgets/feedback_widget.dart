import 'dart:async';

import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import 'feedback_messages.dart';

/// Widget de retroalimentación animado para niños.
///
/// Muestra un modal centrado con emoji grande + mensaje motivacional:
/// - Correcto: emoji bounce + mensaje verde
/// - Incorrecto: emoji pulse + mensaje rojo/naranja
/// - Racha 3+: emoji fuego con escala creciente
/// - Auto-dismiss después de 2 segundos
class FeedbackWidget extends StatefulWidget {
  final bool isCorrect;
  final int attemptNumber;
  final int streak;
  final String? correctAnswer;
  final VoidCallback onContinue;

  const FeedbackWidget({
    super.key,
    required this.isCorrect,
    required this.attemptNumber,
    this.streak = 0,
    this.correctAnswer,
    required this.onContinue,
  });

  @override
  State<FeedbackWidget> createState() => _FeedbackWidgetState();
}

class _FeedbackWidgetState extends State<FeedbackWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shakeAnimation;
  late Animation<double> _fadeAnimation;
  late String _cachedMessage;
  late String _cachedEmoji;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _cacheMessageAndEmoji();
    _setupAnimations();
    _animationController.forward();
    
    // Auto-dismiss después de 2 segundos
    _autoDismissTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        widget.onContinue();
      }
    });
  }

  void _cacheMessageAndEmoji() {
    _cachedEmoji = _getEmojiForState();
    _cachedMessage = _getMessageForState();
  }

  String _getEmojiForState() {
    if (widget.isCorrect) {
      if (widget.streak >= 10) return '👑';
      if (widget.streak >= 7) return '🏆';
      if (widget.streak >= 5) return '💎';
      if (widget.streak >= 3) return '🔥';
      return '🎉';
    }
    return '💪';
  }

  String _getMessageForState() {
    if (widget.isCorrect) {
      if (widget.streak >= 3) {
        return FeedbackMessages.getStreakMessage(widget.streak);
      }
      return FeedbackMessages.getCorrectMessage(includeEncouragement: true);
    }
    if (widget.attemptNumber >= 3 && widget.correctAnswer != null) {
      return '💡 La respuesta correcta es: ${widget.correctAnswer}';
    }
    return FeedbackMessages.getTryAgainMessage(attemptNumber: widget.attemptNumber);
  }

  void _setupAnimations() {
    if (widget.isCorrect) {
      _scaleAnimation = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.3), weight: 30),
        TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.9), weight: 20),
        TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 20),
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 30),
      ]).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ));
      _shakeAnimation = const AlwaysStoppedAnimation(0.0);
    } else {
      _shakeAnimation = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 15),
        TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 15),
        TweenSequenceItem(tween: Tween(begin: 10.0, end: -8.0), weight: 15),
        TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 15),
        TweenSequenceItem(tween: Tween(begin: 8.0, end: -5.0), weight: 15),
        TweenSequenceItem(tween: Tween(begin: -5.0, end: 5.0), weight: 10),
        TweenSequenceItem(tween: Tween(begin: 5.0, end: 0.0), weight: 15),
      ]).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));
      _scaleAnimation = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.0), weight: 50),
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
      ]).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ));
    }
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(FeedbackWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // No reiniciar animación en rebuilds normales
    // La key estable garantiza que el widget no se recrea al cambiar de pregunta
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    if (widget.isCorrect) return Colors.green[100]!;
    if (widget.attemptNumber >= 3) return Colors.orange[100]!;
    return Colors.red[100]!;
  }

  Color _getTextColor() {
    if (widget.isCorrect) return Colors.green[700]!;
    if (widget.attemptNumber >= 3) return Colors.orange[700]!;
    return Colors.red[700]!;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Transform.translate(
            offset: Offset(_shakeAnimation.value, 0),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: _buildModalContent(context),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalContent(BuildContext context) {
    final maxWidth = Responsive.scale(context, 280.0, 320.0, 360.0);
    
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: EdgeInsets.all(Responsive.scale(context, 24.0, 28.0, 32.0)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getBackgroundColor().withAlpha(240),
            _getBackgroundColor().withAlpha(220),
            _getBackgroundColor().withAlpha(200),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: Colors.white.withAlpha(100),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _getTextColor().withAlpha(100),
            blurRadius: 30,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.white.withAlpha(60),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Emoji con efecto glassmorphism
          Container(
            width: Responsive.scale(context, 80.0, 88.0, 96.0),
            height: Responsive.scale(context, 80.0, 88.0, 96.0),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.white.withAlpha(120),
                  Colors.white.withAlpha(40),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withAlpha(80),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                _cachedEmoji,
                style: TextStyle(
                  fontSize: Responsive.scale(context, 48.0, 52.0, 56.0),
                ),
              ),
            ),
          ),
          SizedBox(height: Responsive.scale(context, 16.0, 18.0, 20.0)),
          
          // Mensaje
          Text(
            _cachedMessage,
            style: TextStyle(
              fontSize: Responsive.scale(context, 16.0, 17.0, 18.0),
              fontWeight: FontWeight.bold,
              color: _getTextColor(),
              height: 1.3,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          
          // Indicador de racha si aplica
          if (widget.streak >= 3) ...[
            SizedBox(height: Responsive.scale(context, 12.0, 14.0, 16.0)),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.scale(context, 14.0, 16.0, 18.0),
                vertical: Responsive.scale(context, 6.0, 7.0, 8.0),
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange[400]!,
                    Colors.red[400]!,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🔥', style: TextStyle(fontSize: Responsive.scale(context, 14.0, 15.0, 16.0))),
                  SizedBox(width: Responsive.scale(context, 6.0, 7.0, 8.0)),
                  Text(
                    'Racha: ${widget.streak}',
                    style: TextStyle(
                      fontSize: Responsive.scale(context, 13.0, 14.0, 15.0),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
