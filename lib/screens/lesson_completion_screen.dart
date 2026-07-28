import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/effects_service.dart';
import '../theme/app_colors_extension.dart';
import '../utils/responsive.dart';
import '../utils/safe_math.dart';
import '../widgets/confetti_overlay.dart';

class LessonCompletionScreen extends StatefulWidget {
  final String lessonTitle;
  final int starsEarned;
  final int correctAnswers;
  final int totalQuestions;
  final String? badgeIcon;
  final String? badgeTitle;
  final bool isPerfectScore;
  final VoidCallback onContinue;

  const LessonCompletionScreen({
    super.key,
    required this.lessonTitle,
    required this.starsEarned,
    required this.correctAnswers,
    required this.totalQuestions,
    this.badgeIcon,
    this.badgeTitle,
    this.isPerfectScore = false,
    required this.onContinue,
  });

  @override
  State<LessonCompletionScreen> createState() => _LessonCompletionScreenState();
}

class _LessonCompletionScreenState extends State<LessonCompletionScreen>
    with TickerProviderStateMixin {
  late AnimationController _celebrationController;
  late AnimationController _starController;
  late AnimationController _scaleController;
  late Animation<double> _celebrationAnimation;
  late Animation<double> _starAnimation;
  late Animation<double> _scaleAnimation;

  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();

    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _celebrationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _celebrationController,
        curve: Curves.elasticOut,
      ),
    );

    _starController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _starAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _starController,
        curve: Curves.easeOut,
      ),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeOutBack,
      ),
    );

    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _celebrationController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      _starController.forward();
    });

    _checkConfettiEffect();
  }

  Future<void> _checkConfettiEffect() async {
    final shouldShow = await EffectsService.shouldShowConfetti();
    if (mounted && shouldShow) {
      setState(() {
        _showConfetti = true;
      });
    }
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _starController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percentage = safeRound(safePercentage(widget.correctAnswers, widget.totalQuestions));
    final isDesktop = !Responsive.isMobile(context);
    final maxWidth = isDesktop ? 700.0 : double.infinity;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.deepPurple[50]!,
                  Colors.purple[50]!,
                  Colors.pink[50]!,
                ],
              ),
            ),
          ),
          if (_showConfetti)
            Positioned.fill(
              child: ConfettiOverlay(
                isPlaying: _showConfetti,
                onComplete: () {
                  if (mounted) {
                    setState(() {
                      _showConfetti = false;
                    });
                  }
                },
              ),
            ),
          SafeArea(
            child: Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.scale(context, 20.0, 24.0, 32.0),
                      vertical: Responsive.scale(context, 16.0, 20.0, 24.0),
                    ),
                    child: isDesktop
                        ? _buildDesktopLayout(context, percentage)
                        : _buildMobileLayout(context, percentage),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, int percentage) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildEmoji(context),
          SizedBox(height: Responsive.scale(context, 16.0, 18.0, 20.0)),
          _buildTitle(context),
          SizedBox(height: Responsive.scale(context, 8.0, 10.0, 12.0)),
          _buildSubtitle(context),
          SizedBox(height: Responsive.scale(context, 24.0, 26.0, 28.0)),
          _buildStars(context),
          SizedBox(height: Responsive.scale(context, 24.0, 26.0, 28.0)),
          _buildStatsCard(context, percentage),
          if (widget.badgeIcon != null && widget.badgeTitle != null) ...[
            SizedBox(height: Responsive.scale(context, 16.0, 18.0, 20.0)),
            _buildBadge(context),
          ],
          SizedBox(height: Responsive.scale(context, 28.0, 32.0, 36.0)),
          _buildContinueButton(context),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, int percentage) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _buildEmoji(context),
                  SizedBox(height: Responsive.scale(context, 8.0, 10.0, 12.0)),
                  _buildTitle(context),
                  SizedBox(height: Responsive.scale(context, 4.0, 6.0, 8.0)),
                  _buildSubtitle(context),
                  SizedBox(height: Responsive.scale(context, 16.0, 18.0, 20.0)),
                  _buildStars(context),
                ],
              ),
            ),
            SizedBox(width: Responsive.scale(context, 24.0, 32.0, 40.0)),
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  _buildStatsCard(context, percentage),
                  if (widget.badgeIcon != null && widget.badgeTitle != null) ...[
                    SizedBox(height: Responsive.scale(context, 12.0, 14.0, 16.0)),
                    _buildBadge(context),
                  ],
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: Responsive.scale(context, 24.0, 28.0, 32.0)),
        _buildContinueButton(context),
      ],
    );
  }

  Widget _buildEmoji(BuildContext context) {
    return AnimatedBuilder(
      animation: _celebrationAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _celebrationAnimation.value * 2 * math.pi * 0.1,
          child: Transform.scale(
            scale: 0.5 + (_celebrationAnimation.value * 0.5),
            child: Text(
              '🎉',
              style: TextStyle(fontSize: Responsive.scale(context, 64.0, 72.0, 80.0)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Text(
      widget.isPerfectScore ? '¡Puntuación Perfecta!' : '¡Lección Completada!',
      style: TextStyle(
        fontSize: Responsive.scale(context, 22.0, 24.0, 28.0),
        fontWeight: FontWeight.bold,
        color: Colors.deepPurple,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    return Text(
      widget.lessonTitle,
      style: TextStyle(
        fontSize: Responsive.scale(context, 15.0, 16.0, 18.0),
        fontWeight: FontWeight.w600,
        color: context.appColors.textPrimary,
      ),
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildStars(BuildContext context) {
    return AnimatedBuilder(
      animation: _starAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _starAnimation.value,
          child: Transform.scale(
            scale: _starAnimation.value,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.scale(context, 16.0, 18.0, 20.0),
                vertical: Responsive.scale(context, 8.0, 10.0, 12.0),
              ),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.amber[300]!, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: Colors.amber[700], size: Responsive.scale(context, 24.0, 26.0, 28.0)),
                  SizedBox(width: Responsive.scale(context, 6.0, 8.0, 10.0)),
                  Text(
                    '+${widget.starsEarned}',
                    style: TextStyle(
                      fontSize: Responsive.scale(context, 20.0, 22.0, 24.0),
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[900],
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

  Widget _buildStatsCard(BuildContext context, int percentage) {
    return Container(
      padding: EdgeInsets.all(Responsive.scale(context, 16.0, 18.0, 20.0)),
      decoration: BoxDecoration(
        color: context.appColors.cardBackground,
        borderRadius: BorderRadius.circular(Responsive.borderRadius(context) + 4),
        boxShadow: [
          BoxShadow(color: context.appColors.shadow, blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Respuestas correctas:',
                  style: TextStyle(fontSize: Responsive.scale(context, 14.0, 15.0, 16.0), color: context.appColors.textSecondary),
                ),
              ),
              Text(
                '${widget.correctAnswers}/${widget.totalQuestions}',
                style: TextStyle(
                  fontSize: Responsive.scale(context, 16.0, 17.0, 18.0),
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.scale(context, 10.0, 12.0, 14.0)),
          LinearProgressIndicator(
            value: safeDivideDouble(widget.correctAnswers.toDouble(), widget.totalQuestions.toDouble()),
            backgroundColor: context.appColors.surfaceVariant,
            color: widget.isPerfectScore ? Colors.green : Colors.deepPurple,
            minHeight: Responsive.scale(context, 8.0, 10.0, 12.0),
            borderRadius: BorderRadius.circular(4),
          ),
          SizedBox(height: Responsive.scale(context, 6.0, 8.0, 10.0)),
          Text(
            '$percentage% de aciertos',
            style: TextStyle(
              fontSize: Responsive.scale(context, 13.0, 14.0, 15.0),
              fontWeight: FontWeight.w600,
              color: context.appColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Responsive.scale(context, 10.0, 12.0, 14.0)),
      decoration: BoxDecoration(
        color: Colors.amber[100],
        borderRadius: BorderRadius.circular(Responsive.borderRadius(context)),
        border: Border.all(color: Colors.amber[400]!, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.badgeIcon!, style: TextStyle(fontSize: Responsive.scale(context, 28.0, 30.0, 32.0))),
          SizedBox(width: Responsive.scale(context, 6.0, 8.0, 10.0)),
          Flexible(
            child: Text(
              'Badge: ${widget.badgeTitle!}',
              style: TextStyle(
                fontSize: Responsive.scale(context, 13.0, 14.0, 15.0),
                fontWeight: FontWeight.bold,
                color: Colors.amber[900],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: Responsive.buttonHeight(context),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.borderRadius(context))),
          elevation: 4,
        ),
        onPressed: widget.onContinue,
        child: Text(
          '¡Continuar!',
          style: TextStyle(
            fontSize: Responsive.scale(context, 16.0, 17.0, 18.0),
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
