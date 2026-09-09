import 'package:flutter/material.dart';

import '../models/practice_activity.dart';
import '../theme/app_colors_extension.dart';
import '../theme/text_styles.dart';
import '../utils/responsive.dart';

class AdaptivePracticeCard extends StatefulWidget {
  final PracticeActivity activity;
  final bool isUnlocked;
  final PracticeProgress? progress;
  final VoidCallback onTap;
  final int index;

  const AdaptivePracticeCard({
    required this.activity,
    required this.isUnlocked,
    required this.onTap,
    this.progress,
    this.index = 0,
    super.key,
  });

  @override
  State<AdaptivePracticeCard> createState() => _AdaptivePracticeCardState();
}

class _AdaptivePracticeCardState extends State<AdaptivePracticeCard>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _entryFadeAnimation;
  late Animation<Offset> _entrySlideAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    final entryDelay = widget.index * 0.08;
    const entryCurve = Curves.easeOutCubic;

    _entryFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(entryDelay.clamp(0.0, 1.0), 1.0, curve: entryCurve),
      ),
    );

    _entrySlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(entryDelay.clamp(0.0, 1.0), 1.0, curve: entryCurve),
      ),
    );

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activityColor = Color(widget.activity.color);
    final hasHover = Responsive.hasHover(context);
    final borderRadius = Responsive.scale(context, 12.0, 14.0, 16.0);

    Widget card = _buildCardContent(context, activityColor, borderRadius);

    return FadeTransition(
      opacity: _entryFadeAnimation,
      child: SlideTransition(
        position: _entrySlideAnimation,
        child: hasHover
            ? MouseRegion(
                onEnter: (_) => setState(() => _isHovered = true),
                onExit: (_) => setState(() => _isHovered = false),
                cursor: SystemMouseCursors.click,
                child: card,
              )
            : card,
      ),
    );
  }

  Widget _buildCardContent(
    BuildContext context,
    Color activityColor,
    double borderRadius,
  ) {
    final hoverScale = _isHovered ? 1.02 : 1.0;
    final padding = Responsive.scale(context, 10.0, 12.0, 14.0);

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: hoverScale,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: Container(
          decoration: BoxDecoration(
            color: context.appColors.cardBackground,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: widget.isUnlocked
                  ? activityColor.withAlpha(30)
                  : context.appColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isUnlocked
                    ? activityColor.withAlpha(_isHovered ? 35 : 15)
                    : context.appColors.shadow,
                blurRadius: _isHovered ? 16 : 8,
                offset: Offset(0, _isHovered ? 6 : 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  _buildAccentBar(activityColor),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: padding,
                        vertical: padding * 0.8,
                      ),
                      child: _buildContent(activityColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccentBar(Color activityColor) {
    return Container(
      width: 4,
      decoration: BoxDecoration(
        gradient: widget.isUnlocked
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  activityColor,
                  activityColor.withAlpha(150),
                ],
              )
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  context.appColors.border,
                  context.appColors.surfaceVariant,
                ],
              ),
      ),
    );
  }

  Widget _buildContent(Color activityColor) {
    final emojiSize = Responsive.scale(context, 24.0, 28.0, 32.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: emojiSize + 12,
              height: emojiSize + 12,
              decoration: BoxDecoration(
                color: widget.isUnlocked
                    ? activityColor.withAlpha(15)
                    : context.appColors.surfaceVariant,
                borderRadius: BorderRadius.circular(emojiSize / 2),
              ),
              alignment: Alignment.center,
              child: Text(
                widget.activity.iconEmoji,
                style: TextStyle(fontSize: emojiSize),
              ),
            ),
            SizedBox(width: Responsive.scale(context, 8, 10, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.activity.title,
                          style: context.cardTitle.copyWith(
                            fontSize: Responsive.scale(context, 13, 14, 15),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.isUnlocked) _buildStars(),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: widget.isUnlocked
                                ? activityColor.withAlpha(20)
                                : context.appColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.isUnlocked
                                ? widget.activity.typeName
                                : 'Bloqueado',
                            style: TextStyle(
                              fontSize: Responsive.scale(context, 9, 10, 11),
                              fontWeight: FontWeight.w600,
                              color: widget.isUnlocked
                                  ? activityColor
                                  : context.appColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (widget.isUnlocked) ...[
          SizedBox(height: Responsive.scale(context, 6, 8, 10)),
          _buildProgressBar(activityColor),
        ],
      ],
    );
  }

  Widget _buildStars() {
    final stars = widget.progress?.starsEarned ?? 0;
    final starSize = Responsive.scale(context, 12.0, 14.0, 16.0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (index) => Padding(
          padding: const EdgeInsets.only(left: 1),
          child: Icon(
            index < stars ? Icons.star : Icons.star_border,
            size: starSize,
            color: index < stars ? Colors.amber : context.appColors.border,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(Color activityColor) {
    final percentage = widget.progress?.completionPercentage ?? 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: percentage / 100),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Container(
              height: 3,
              decoration: BoxDecoration(
                color: context.appColors.surfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: constraints.maxWidth * value,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        activityColor,
                        activityColor.withAlpha(180),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
