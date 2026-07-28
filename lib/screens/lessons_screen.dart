import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/lessons_data.dart';
import '../logic/badge_service.dart';
import '../logic/lesson_completion_service.dart';
import '../logic/lesson_controller.dart';
import '../logic/mastery_evaluator.dart';
import '../models/lesson.dart';
import '../models/lesson_exercise.dart';
import '../services/diagnostic_service.dart';
import '../utils/responsive.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/level_section.dart';
import '../widgets/progress_header.dart';
import 'lesson_flow_screen.dart';
import 'lesson_screen.dart';

class LessonsScreen extends StatefulWidget {
  final bool showNavBar;

  const LessonsScreen({
    super.key,
    this.showNavBar = true,
  });

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  final _evaluator = MasteryEvaluator();
  String? _userLevel;
  int _completedLessons = 0;
  int _totalLessons = 0;
  int? _expandedLevelIndex;

  @override
  void initState() {
    super.initState();
    _calculateProgress();
    _loadUserLevel();
    _evaluator.ensureCacheLoaded();
  }

  Future<void> _calculateProgress() async {
    _totalLessons = lessonLevels.fold(0, (sum, level) => sum + level.lessons.length);
    final completedIds = await LessonCompletionService.getCompletedLessonIds();
    if (mounted) {
      setState(() {
        _completedLessons = completedIds.length;
      });
    }
  }

  Future<void> _loadUserLevel() async {
    final level = await DiagnosticService.getUserLevel();
    if (mounted) {
      setState(() {
        _userLevel = level;
      });
    }
  }

  Future<void> _openLesson(Lesson lesson) async {
    final lessonStateChanged = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          final hasMatching = lesson.exercises.any(
            (e) => e.type == ExerciseType.matching,
          );

          if (hasMatching) {
            return ChangeNotifierProvider(
              create: (context) => LessonController(),
              child: LessonFlowScreen(
                key: UniqueKey(),
                lesson: lesson,
                exercises: lesson.exercises,
              ),
            );
          }
          return ChangeNotifierProvider(
            create: (context) => LessonController(),
            child: LessonScreen(key: UniqueKey(), lesson: lesson),
          );
        },
      ),
    );

    if (lessonStateChanged == true) {
      MasteryEvaluator.invalidateCache();
      BadgeService.invalidateCache();
      await _calculateProgress();
    }
  }

  bool _isLevelUnlocked(int levelIndex) {
    if (levelIndex == 0) return true;
    return true;
  }

  void _onLevelToggle(int index) {
    setState(() {
      _expandedLevelIndex = _expandedLevelIndex == index ? null : index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = context.isMobile;
        final isTablet = context.isTablet;
        final horizontalPadding = Responsive.horizontalPadding(context);

        if (isMobile) {
          return _buildMobileLayout(context, horizontalPadding);
        } else if (isTablet) {
          return _buildTabletLayout(context, constraints, horizontalPadding);
        } else {
          return _buildDesktopLayout(context, constraints, horizontalPadding);
        }
      },
    );

    if (widget.showNavBar) {
      return AppScaffold(
        currentIndex: 1,
        child: content,
      );
    }

    return content;
  }

  Widget _buildMobileLayout(BuildContext context, double horizontalPadding) {
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(horizontalPadding),
            child: ProgressHeader(
              completedLessons: _completedLessons,
              totalLessons: _totalLessons,
              userLevel: _userLevel,
            ),
          ),
          ..._buildLevelCardsMobile(horizontalPadding),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context, BoxConstraints constraints, double horizontalPadding) {
    const sidebarWidth = 200.0;
    const maxContentWidth = 900.0;

    return _buildSidebarContent(
      context: context,
      constraints: constraints,
      horizontalPadding: horizontalPadding,
      sidebarWidth: sidebarWidth,
      gridColumns: 3,
      maxContentWidth: maxContentWidth,
    );
  }

  Widget _buildDesktopLayout(BuildContext context, BoxConstraints constraints, double horizontalPadding) {
    final isWide = context.isWide;
    final sidebarWidth = isWide ? 220.0 : 200.0;
    const gridColumns = 4;
    const maxContentWidth = 900.0;

    return _buildSidebarContent(
      context: context,
      constraints: constraints,
      horizontalPadding: horizontalPadding,
      sidebarWidth: sidebarWidth,
      gridColumns: gridColumns,
      maxContentWidth: maxContentWidth,
    );
  }

  Widget _buildSidebarContent({
    required BuildContext context,
    required BoxConstraints constraints,
    required double horizontalPadding,
    required double sidebarWidth,
    required int gridColumns,
    required double maxContentWidth,
  }) {
    final availableHeight = constraints.maxHeight - (horizontalPadding * 2);

    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: availableHeight),
        child: Align(
          child: Padding(
            padding: EdgeInsets.all(horizontalPadding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: sidebarWidth,
                  height: availableHeight,
                  child: ProgressHeader(
                    completedLessons: _completedLessons,
                    totalLessons: _totalLessons,
                    userLevel: _userLevel,
                    isSidebar: true,
                  ),
                ),
                SizedBox(width: horizontalPadding),
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: Column(
                      children: _buildLevelSections(gridColumns),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLevelSections(int gridColumns) {
    return List.generate(lessonLevels.length, (i) {
      return LevelSection(
        level: lessonLevels[i],
        levelIndex: i,
        isUnlocked: _isLevelUnlocked(i),
        evaluator: _evaluator,
        onLessonTap: _openLesson,
        startIndex: lessonLevels.take(i).fold(0, (sum, l) => sum + l.lessons.length),
        gridColumns: gridColumns,
        isExpanded: _expandedLevelIndex == i,
        onToggle: () => _onLevelToggle(i),
      );
    });
  }

  List<Widget> _buildLevelCardsMobile(double horizontalPadding) {
    return List.generate(lessonLevels.length, (i) {
      return Padding(
        padding: EdgeInsets.only(
          left: horizontalPadding,
          right: horizontalPadding,
          bottom: i < lessonLevels.length - 1 ? 12.0 : 0.0,
        ),
        child: LevelSection(
          level: lessonLevels[i],
          levelIndex: i,
          isUnlocked: _isLevelUnlocked(i),
          evaluator: _evaluator,
          onLessonTap: _openLesson,
          startIndex: lessonLevels.take(i).fold(0, (sum, l) => sum + l.lessons.length),
          gridColumns: 2,
          isExpanded: _expandedLevelIndex == i,
          onToggle: () => _onLevelToggle(i),
        ),
      );
    });
  }
}
