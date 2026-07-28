import 'package:flutter/material.dart';

import '../../utils/responsive.dart';

class AnimatedMenuCard extends StatefulWidget {
  final Key? cardKey;
  final String emoji;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;
  final int index;

  const AnimatedMenuCard({
    super.key,
    this.cardKey,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
    required this.index,
  });

  @override
  State<AnimatedMenuCard> createState() => _AnimatedMenuCardState();
}

class _AnimatedMenuCardState extends State<AnimatedMenuCard>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _floatController;
  late AnimationController _emojiPulseController;

  late Animation<double> _entryFadeAnimation;
  late Animation<Offset> _entrySlideAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _emojiPulseAnimation;

  bool _isHovered = false;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _floatController = AnimationController(
      duration: Duration(milliseconds: 2800 + widget.index * 400),
      vsync: this,
    )..repeat(reverse: true);

    _emojiPulseController = AnimationController(
      duration: Duration(milliseconds: 2000 + widget.index * 300),
      vsync: this,
    )..repeat(reverse: true);

    final entryDelay = widget.index * 0.15;
    const entryCurve = Curves.easeOutCubic;

    _entryFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(entryDelay.clamp(0.0, 1.0), 1.0, curve: entryCurve),
      ),
    );

    _entrySlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(entryDelay.clamp(0.0, 1.0), 1.0, curve: entryCurve),
      ),
    );

    _floatAnimation = Tween<double>(
      begin: -4.0,
      end: 4.0,
    ).animate(
      CurvedAnimation(
        parent: _floatController,
        curve: Curves.easeInOut,
      ),
    );

    _emojiPulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.12,
    ).animate(
      CurvedAnimation(
        parent: _emojiPulseController,
        curve: Curves.easeInOut,
      ),
    );

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _floatController.dispose();
    _emojiPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = widget.gradient as LinearGradient;
    final hasHover = Responsive.hasHover(context);

    Widget card = _buildCardContent(context, gradient);

    return FadeTransition(
      opacity: _entryFadeAnimation,
      child: SlideTransition(
        position: _entrySlideAnimation,
        child: AnimatedBuilder(
          animation: _floatController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _floatAnimation.value),
              child: child,
            );
          },
          child: hasHover
              ? MouseRegion(
                  onEnter: (_) => setState(() => _isHovered = true),
                  onExit: (_) => setState(() => _isHovered = false),
                  cursor: SystemMouseCursors.click,
                  child: card,
                )
              : card,
        ),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context, LinearGradient gradient) {
    final borderRadius = Responsive.scale(context, 20, 24, 28);
    final hoverScale = _isHovered ? 1.05 : 1.0;
    final shadowBlur = _isHovered
        ? Responsive.scale(context, 24, 28, 32)
        : Responsive.scale(context, 16, 20, 24);
    final shadowOffset = _isHovered
        ? Responsive.scale(context, 10, 12, 14)
        : Responsive.scale(context, 6, 8, 10);

    return GestureDetector(
      key: widget.cardKey,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: hoverScale,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withAlpha(_isHovered ? 90 : 60),
                blurRadius: shadowBlur,
                offset: Offset(0, shadowOffset),
                spreadRadius: Responsive.scale(context, -4, -5, -6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                  child: Padding(
                    padding: EdgeInsets.all(Responsive.scale(context, 12, 16, 20)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            vertical: Responsive.scale(context, 6, 10, 14),
                          ),
                          child: AnimatedBuilder(
                            animation: _emojiPulseController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _emojiPulseAnimation.value,
                                child: child,
                              );
                            },
                            child: Text(
                              widget.emoji,
                              style: TextStyle(
                                fontSize: Responsive.scale(context, 36, 48, 56),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        SizedBox(height: Responsive.scale(context, 4, 6, 8)),
                        Text(
                          widget.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: Responsive.scale(context, 18, 22, 24),
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: Responsive.scale(context, 4, 6, 8)),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            color: Colors.white.withAlpha(80),
                            fontSize: Responsive.scale(context, 13, 15, 16),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
