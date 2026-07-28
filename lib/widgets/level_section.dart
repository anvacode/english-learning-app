import 'package:flutter/material.dart';

import '../../logic/mastery_evaluator.dart';
import '../../models/lesson.dart';
import '../../models/lesson_level.dart';
import '../../utils/responsive.dart';
import '../theme/app_colors_extension.dart';
import 'lesson_grid_card.dart';

class LevelSection extends StatelessWidget {
  final LessonLevel level;
  final int levelIndex;
  final bool isUnlocked;
  final MasteryEvaluator evaluator;
  final Function(Lesson) onLessonTap;
  final int startIndex;
  final int gridColumns;
  final bool isExpanded;
  final VoidCallback onToggle;

  const LevelSection({
    super.key,
    required this.level,
    required this.levelIndex,
    required this.isUnlocked,
    required this.evaluator,
    required this.onLessonTap,
    required this.startIndex,
    this.gridColumns = 3,
    required this.isExpanded,
    required this.onToggle,
  });

  _LevelTheme get _levelTheme {
    switch (levelIndex) {
      case 0:
        return _LevelTheme(
          emoji: '🌱',
          title: 'Principiante',
          subtitle: 'Fundamentos',
          gradient: const LinearGradient(
            colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          accentColor: const Color(0xFF43e97b),
        );
      case 1:
        return _LevelTheme(
          emoji: '🔥',
          title: 'Intermedio',
          subtitle: 'Expande tu vocabulario',
          gradient: const LinearGradient(
            colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          accentColor: const Color(0xFFf5576c),
        );
      case 2:
        return _LevelTheme(
          emoji: '⭐',
          title: 'Avanzado',
          subtitle: 'Domina el idioma',
          gradient: const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          accentColor: const Color(0xFF764ba2),
        );
      default:
        return _LevelTheme(
          emoji: '📚',
          title: level.title,
          subtitle: '',
          gradient: const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          accentColor: const Color(0xFF667eea),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = _levelTheme;

    return Container(
      margin: EdgeInsets.only(bottom: Responsive.scale(context, 12, 14, 16)),
      decoration: BoxDecoration(
        color: context.appColors.cardBackground,
        borderRadius: BorderRadius.circular(Responsive.scale(context, 16, 18, 20)),
        border: Border.all(
          color: theme.accentColor.withAlpha(40),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.accentColor.withAlpha(15),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, theme),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: isExpanded ? _buildLessonsGrid(context, theme) : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, _LevelTheme theme) {
    final totalLessons = level.lessons.length;
    final completedLessons = level.lessons.where((l) {
      final status = evaluator.evaluateLessonSync(l.id);
      return status == LessonMasteryStatus.mastered;
    }).length;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Responsive.scale(context, 16, 18, 20)),
          bottom: Radius.circular(isExpanded ? 0 : Responsive.scale(context, 16, 18, 20)),
        ),
        child: Container(
          padding: EdgeInsets.all(Responsive.scale(context, 10, 12, 14)),
          decoration: BoxDecoration(
            gradient: theme.gradient,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(Responsive.scale(context, 16, 18, 20)),
              bottom: Radius.circular(isExpanded ? 0 : Responsive.scale(context, 16, 18, 20)),
            ),
          ),
          child: Row(
            children: [
              _buildLevelIcon(context, theme),
              SizedBox(width: Responsive.scale(context, 8, 10, 12)),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            theme.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: Responsive.scale(context, 13, 14, 15),
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isUnlocked) ...[
                          SizedBox(width: Responsive.scale(context, 4, 6, 8)),
                          Text(
                            '🔒',
                            style: TextStyle(
                              fontSize: Responsive.scale(context, 10, 11, 12),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      theme.subtitle,
                      style: TextStyle(
                        color: Colors.white.withAlpha(180),
                        fontSize: Responsive.scale(context, 10, 11, 12),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: Responsive.scale(context, 6, 8, 10)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.scale(context, 6, 8, 10),
                  vertical: Responsive.scale(context, 3, 4, 5),
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(Responsive.scale(context, 6, 8, 10)),
                ),
                child: Text(
                  '$completedLessons/$totalLessons',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: Responsive.scale(context, 10, 11, 12),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: Responsive.scale(context, 4, 6, 8)),
              AnimatedRotation(
                turns: isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white,
                  size: Responsive.scale(context, 16, 18, 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelIcon(BuildContext context, _LevelTheme theme) {
    final size = Responsive.scale(context, 32, 36, 40);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(35),
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(color: Colors.white.withAlpha(50), width: 1.5),
      ),
      child: Center(
        child: Text(
          theme.emoji,
          style: TextStyle(fontSize: size * 0.5),
        ),
      ),
    );
  }

  Widget _buildLessonsGrid(BuildContext context, _LevelTheme theme) {
    if (!isUnlocked) {
      return Container(
        padding: EdgeInsets.all(Responsive.scale(context, 16, 18, 20)),
        child: Center(
          child: Column(
            children: [
              Text(
                '🔒',
                style: TextStyle(fontSize: Responsive.scale(context, 28, 32, 36)),
              ),
              SizedBox(height: Responsive.scale(context, 8, 10, 12)),
              Text(
                'Completa el nivel anterior para desbloquear',
                style: TextStyle(
                  color: context.appColors.textTertiary,
                  fontSize: Responsive.scale(context, 11, 12, 13),
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (level.lessons.isEmpty) {
      return Container(
        padding: EdgeInsets.all(Responsive.scale(context, 16, 18, 20)),
        child: Center(
          child: Text(
            'No hay lecciones disponibles',
            style: TextStyle(
              color: context.appColors.textTertiary,
              fontSize: Responsive.scale(context, 11, 12, 13),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(Responsive.scale(context, 8, 10, 12)),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridColumns,
          crossAxisSpacing: Responsive.scale(context, 6, 8, 10),
          mainAxisSpacing: Responsive.scale(context, 6, 8, 10),
          childAspectRatio: Responsive.scale(context, 1.2, 1.3, 1.4),
        ),
        itemCount: level.lessons.length,
        itemBuilder: (context, index) {
          final lesson = level.lessons[index];
          final isLocked = !isUnlocked;

          return RepaintBoundary(
            child: LessonGridCard(
              key: ValueKey('lesson_grid_${lesson.id}'),
              lesson: lesson,
              evaluator: evaluator,
              isLocked: isLocked,
              onTap: () => onLessonTap(lesson),
              index: startIndex + index,
            ),
          );
        },
      ),
    );
  }
}

class _LevelTheme {
  final String emoji;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final Color accentColor;

  _LevelTheme({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.accentColor,
  });
}
