import 'package:flutter/material.dart';

import '../../data/lesson_themes.dart';
import '../../logic/mastery_evaluator.dart';
import '../../models/lesson.dart';
import '../../utils/responsive.dart';
import '../theme/app_colors_extension.dart';

class LessonGridCard extends StatefulWidget {
  final Lesson lesson;
  final MasteryEvaluator evaluator;
  final bool isLocked;
  final VoidCallback? onTap;
  final int index;

  const LessonGridCard({
    super.key,
    required this.lesson,
    required this.evaluator,
    required this.isLocked,
    required this.onTap,
    required this.index,
  });

  @override
  State<LessonGridCard> createState() => _LessonGridCardState();
}

class _LessonGridCardState extends State<LessonGridCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = getLessonTheme(widget.lesson.id);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: _buildCard(context, theme),
      ),
    );
  }

  Widget _buildCard(BuildContext context, LessonTheme theme) {
    final borderRadius = Responsive.scale(context, 14, 16, 18);

    return FutureBuilder<LessonMasteryStatus>(
      future: widget.evaluator.evaluateLesson(widget.lesson.id),
      builder: (context, snapshot) {
        final status = snapshot.data ?? LessonMasteryStatus.notStarted;
        final isCompleted = status == LessonMasteryStatus.mastered;
        final isInProgress = status == LessonMasteryStatus.inProgress;

        final gradient = widget.isLocked
            ? LinearGradient(
                colors: [
                  context.appColors.border,
                  context.appColors.surfaceVariant,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : theme.gradient;

        final card = Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: widget.isLocked
                    ? context.appColors.shadow
                    : theme.gradientColors.first.withAlpha(_isHovered ? 70 : 45),
                blurRadius: _isHovered ? 16 : 10,
                offset: Offset(0, _isHovered ? 6 : 3),
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
                  padding: EdgeInsets.all(Responsive.scale(context, 10, 12, 14)),
                  child: _buildLayout(context, theme, status),
                ),
              ),
            ),
          ),
        );

        if (widget.isLocked || (!isCompleted && !isInProgress)) {
          return ColorFiltered(
            colorFilter: const ColorFilter.matrix(<double>[
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0,      0,      0,      1, 0,
            ]),
            child: card,
          );
        }

        return card;
      },
    );
  }

  Widget _buildLayout(BuildContext context, LessonTheme theme, LessonMasteryStatus status) {
    final emojiSize = Responsive.scale(context, 32, 36, 40);
    
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: 0,
          left: 0,
          child: Text(
            (widget.index + 1).toString().padLeft(2, '0'),
            style: TextStyle(
              color: Colors.white.withAlpha(180),
              fontSize: Responsive.scale(context, 10, 11, 12),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.isLocked ? '🔒' : theme.emoji,
              style: TextStyle(fontSize: emojiSize),
            ),
            SizedBox(height: Responsive.scale(context, 6, 8, 10)),
            Text(
              widget.lesson.title,
              style: TextStyle(
                color: Colors.white,
                fontSize: Responsive.scale(context, 12, 13, 14),
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        if (!widget.isLocked)
          Positioned(
            bottom: 0,
            right: 0,
            child: _buildStatusBadge(status),
          ),
      ],
    );
  }

  Widget _buildStatusBadge(LessonMasteryStatus status) {
    switch (status) {
      case LessonMasteryStatus.mastered:
        return Container(
          width: Responsive.scale(context, 18, 20, 22),
          height: Responsive.scale(context, 18, 20, 22),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withAlpha(120),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(
            Icons.check_rounded,
            size: Responsive.scale(context, 11, 12, 13),
            color: Colors.white,
          ),
        );
      case LessonMasteryStatus.inProgress:
        return Container(
          width: Responsive.scale(context, 18, 20, 22),
          height: Responsive.scale(context, 18, 20, 22),
          decoration: BoxDecoration(
            color: const Color(0xFFFFC107),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFC107).withAlpha(120),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(
            Icons.refresh_rounded,
            size: Responsive.scale(context, 11, 12, 13),
            color: Colors.white,
          ),
        );
      case LessonMasteryStatus.notStarted:
        return const SizedBox.shrink();
    }
  }
}
