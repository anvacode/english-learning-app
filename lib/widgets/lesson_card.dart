import 'package:flutter/material.dart';

import '../../data/lesson_themes.dart';
import '../../logic/badge_service.dart';
import '../../logic/mastery_evaluator.dart';
import '../../models/badge.dart' as achievement;
import '../../models/lesson.dart';
import '../../utils/responsive.dart';
import '../theme/app_colors_extension.dart';

class LessonCard extends StatefulWidget {
  final Lesson lesson;
  final MasteryEvaluator evaluator;
  final bool isLocked;
  final VoidCallback? onTap;
  final int index;

  const LessonCard({
    super.key,
    required this.lesson,
    required this.evaluator,
    required this.isLocked,
    required this.onTap,
    required this.index,
  });

  @override
  State<LessonCard> createState() => _LessonCardState();
}

class _LessonCardState extends State<LessonCard> {
  @override
  Widget build(BuildContext context) {
    final theme = getLessonTheme(widget.lesson.id);

    return _buildCard(context, theme);
  }

  Widget _buildCard(BuildContext context, LessonTheme theme) {
    final borderRadius = Responsive.scale(context, 16, 18, 20);

    return Container(
      margin: EdgeInsets.only(bottom: Responsive.scale(context, 8, 10, 12)),
      decoration: BoxDecoration(
        gradient: widget.isLocked
            ? LinearGradient(
                colors: [
                  context.appColors.border,
                  context.appColors.surfaceVariant,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : theme.gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: widget.isLocked
                ? context.appColors.shadow
                : theme.gradientColors.first.withAlpha(50),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.isLocked ? null : widget.onTap,
            child: Padding(
              padding: EdgeInsets.all(Responsive.scale(context, 10, 14, 16)),
              child: Row(
                children: [
                  _buildEmojiSection(context, theme),
                  SizedBox(width: Responsive.scale(context, 8, 12, 14)),
                  Expanded(
                    child: _buildContentSection(context),
                  ),
                  SizedBox(width: Responsive.scale(context, 6, 10, 12)),
                  _buildStatusSection(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmojiSection(BuildContext context, LessonTheme theme) {
    final size = Responsive.scale(context, 36, 44, 50);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(widget.isLocked ? 80 : 60),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Center(
        child: Text(
          widget.isLocked ? '🔒' : theme.emoji,
          style: TextStyle(fontSize: size * 0.55),
        ),
      ),
    );
  }

  Widget _buildContentSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.lesson.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: Responsive.scale(context, 15, 16, 17),
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            FutureBuilder<achievement.Badge?>(
              future: BadgeService.getBadge(widget.lesson),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null && snapshot.data!.unlocked) {
                  return Padding(
                    padding: EdgeInsets.only(left: Responsive.scale(context, 6, 8, 10)),
                    child: Text(
                      snapshot.data!.icon,
                      style: TextStyle(fontSize: Responsive.scale(context, 16, 18, 20)),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        SizedBox(height: Responsive.scale(context, 4, 5, 6)),
        Text(
          widget.lesson.id.replaceAll('_', ' ').toUpperCase(),
          style: TextStyle(
            color: Colors.white.withAlpha(180),
            fontSize: Responsive.scale(context, 11, 12, 13),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection(BuildContext context) {
    if (widget.isLocked) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.scale(context, 10, 12, 14),
          vertical: Responsive.scale(context, 6, 7, 8),
        ),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(40),
          borderRadius: BorderRadius.circular(Responsive.scale(context, 10, 12, 14)),
        ),
        child: Text(
          '🔒',
          style: TextStyle(fontSize: Responsive.scale(context, 14, 16, 18)),
        ),
      );
    }

    return FutureBuilder<LessonMasteryStatus>(
      future: widget.evaluator.evaluateLesson(widget.lesson.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(
            width: Responsive.scale(context, 20, 24, 28),
            height: Responsive.scale(context, 20, 24, 28),
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
            ),
          );
        }

        final status = snapshot.data!;
        return _buildStatusIndicator(context, status);
      },
    );
  }

  Widget _buildStatusIndicator(BuildContext context, LessonMasteryStatus status) {
    late IconData icon;
    late String text;
    late Color bgColor;

    switch (status) {
      case LessonMasteryStatus.notStarted:
        icon = Icons.play_arrow_rounded;
        text = 'Jugar';
        bgColor = Colors.white.withAlpha(50);
        break;
      case LessonMasteryStatus.inProgress:
        icon = Icons.refresh_rounded;
        text = 'Repasar';
        bgColor = Colors.amber.withAlpha(200);
        break;
      case LessonMasteryStatus.mastered:
        icon = Icons.check_circle_rounded;
        text = 'Listo';
        bgColor = Colors.green.withAlpha(220);
        break;
    }

    if (context.isMobile) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.scale(context, 6, 8, 10),
          vertical: Responsive.scale(context, 4, 5, 6),
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(Responsive.scale(context, 8, 10, 12)),
          boxShadow: [
            BoxShadow(
              color: context.appColors.shadow,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: Responsive.scale(context, 14, 16, 18),
          color: Colors.white,
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.scale(context, 10, 12, 14),
        vertical: Responsive.scale(context, 6, 7, 8),
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(Responsive.scale(context, 10, 12, 14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: Responsive.scale(context, 14, 16, 18),
            color: Colors.white,
          ),
          SizedBox(width: Responsive.scale(context, 4, 5, 6)),
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: Responsive.scale(context, 11, 12, 13),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
