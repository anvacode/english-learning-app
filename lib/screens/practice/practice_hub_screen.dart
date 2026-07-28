import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/lessons_data.dart';
import '../../logic/badge_service.dart';
import '../../logic/lesson_completion_service.dart';
import '../../logic/lesson_controller.dart';
import '../../logic/mastery_evaluator.dart';
import '../../logic/practice_service.dart';
import '../../logic/star_service.dart';
import '../../models/lesson.dart';
import '../../models/lesson_exercise.dart';
import '../../models/practice_activity.dart';
import '../../theme/app_colors_extension.dart';
import '../../theme/text_styles.dart';
import '../../utils/responsive.dart';
import '../../widgets/adaptive_practice_card.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/responsive_snack_bar.dart';
import '../lesson_flow_screen.dart';
import '../lesson_screen.dart';
import 'listening_practice_screen.dart';
import 'memory_game_screen.dart';
import 'pronunciation_practice_screen.dart';
import 'speed_match_screen.dart';
import 'spelling_practice_screen.dart';

class PracticeHubScreen extends StatefulWidget {
  final bool showNavBar;

  const PracticeHubScreen({
    super.key,
    this.showNavBar = true,
  });

  @override
  State<PracticeHubScreen> createState() => _PracticeHubScreenState();
}

class _PracticeHubScreenState extends State<PracticeHubScreen>
    with TickerProviderStateMixin {
  String? _selectedLessonFilter;
  bool _isLoading = true;
  List<PracticeActivity> _activities = [];
  Map<String, PracticeProgress> _progressMap = {};
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  int _loginStreak = 0;
  Lesson? _nextLesson;
  int _nextLessonIndex = 0;
  int _totalLessonsCount = 0;
  late ScrollController _filterScrollController;
  late AnimationController _filterAutoScrollController;
  Timer? _filterAutoScrollTimer;
  Timer? _userInteractionTimer;
  bool _isUserInteracting = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    _filterScrollController = ScrollController();
    _filterScrollController.addListener(_onFilterScroll);
    _filterAutoScrollController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadData();
    _loadSidebarData();
  }

  void _onFilterScroll() {
    if (_filterScrollController.position.isScrollingNotifier.value) {
      _isUserInteracting = true;
      _stopFilterAutoScroll();
      _userInteractionTimer?.cancel();
      _userInteractionTimer = Timer(const Duration(seconds: 3), () {
        _isUserInteracting = false;
        _startFilterAutoScroll();
      });
    }
  }

  @override
  void dispose() {
    _filterAutoScrollTimer?.cancel();
    _userInteractionTimer?.cancel();
    _filterScrollController.removeListener(_onFilterScroll);
    _filterScrollController.dispose();
    _filterAutoScrollController.dispose();
    _animController.dispose();
    super.dispose();
  }

  bool get _showSidebar => !Responsive.isMobile(context);

  int get _gridColumns {
    if (_selectedLessonFilter != null) return 2;
    if (_showSidebar) {
      // Con el sidebar visible el grid queda reducido; menos columnas
      // para que las tarjetas no queden demasiado angostas.
      if (Responsive.isWide(context)) return 4;
      if (Responsive.isDesktop(context)) return 3;
      return 2;
    }
    return 2;
  }

  double get _childAspectRatio {
    if (Responsive.isMobile(context)) return 1.6;
    if (Responsive.isTablet(context)) return 1.8;
    if (Responsive.isDesktop(context)) return 2.0;
    return 2.8;
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final activities =
          await PracticeService.getAllActivitiesWithUnlockStatus();
      final progressMap = await PracticeService.getAllProgress();

      setState(() {
        _activities = activities;
        _progressMap = progressMap;
        _isLoading = false;
      });
      _animController.forward();
      _loadSidebarData();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ResponsiveSnackBar.showError(
          context,
          message: 'Error al cargar actividades: $e',
        );
      }
    }
  }

  Future<void> _loadSidebarData() async {
    try {
      final streak = await StarService.getLoginStreak();
      final completedIds = await LessonCompletionService.getCompletedLessonIds();
      
      Lesson? nextLesson;
      int nextLessonIndex = 0;
      int totalLessons = 0;
      
      for (final level in lessonLevels) {
        for (int i = 0; i < level.lessons.length; i++) {
          final lesson = level.lessons[i];
          totalLessons++;
          if (!completedIds.contains(lesson.id) && nextLesson == null) {
            nextLesson = lesson;
            nextLessonIndex = totalLessons;
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _loginStreak = streak;
          _nextLesson = nextLesson;
          _nextLessonIndex = nextLessonIndex;
          _totalLessonsCount = totalLessons;
        });
      }
    } catch (e) {
      debugPrint('Error loading sidebar data: $e');
    }
  }

  void _startFilterAutoScroll() {
    final totalFilters = _getFilterCount();
    if (totalFilters <= 1) return;
    
    _filterAutoScrollTimer?.cancel();
    _filterAutoScrollTimer = Timer.periodic(const Duration(milliseconds: 4000), (timer) {
      if (!mounted || !_filterScrollController.hasClients || _isUserInteracting) return;
      
      final maxScroll = _filterScrollController.position.maxScrollExtent;
      final currentScroll = _filterScrollController.offset;
      
      if (currentScroll >= maxScroll - 10) {
        _filterScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
        );
      } else {
        _filterScrollController.animateTo(
          currentScroll + 200,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _stopFilterAutoScroll() {
    _filterAutoScrollTimer?.cancel();
  }

  int _getFilterCount() {
    final lessonIds = _activities.map((a) => a.lessonId).toSet().toList();
    return lessonIds.length + 1;
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
      await _loadSidebarData();
    }
  }

  List<PracticeActivity> get _filteredActivities {
    if (_selectedLessonFilter == null) return _activities;
    return _activities
        .where((a) => a.lessonId == _selectedLessonFilter)
        .toList();
  }

  int get _completedCount =>
      _progressMap.values.where((p) => p.isCompleted).length;

  int get _unlockedCount => _activities.where((a) => a.isUnlocked).length;

  int get _totalCount => _activities.length;

  int get _practiceStars =>
      _progressMap.values.fold(0, (sum, p) => sum + p.starsEarned);

  double get _completionPercentage =>
      _totalCount > 0 ? (_completedCount / _totalCount * 100) : 0.0;

  void _onActivityTap(PracticeActivity activity) {
    if (!activity.isUnlocked) {
      ResponsiveSnackBar.showInfo(
        context,
        message: 'Esta actividad aún no está desbloqueada',
        duration: const Duration(seconds: 2),
      );
      return;
    }

    switch (activity.type) {
      case PracticeActivityType.spelling:
        _navigateToSpelling(activity);
        break;
      case PracticeActivityType.listening:
        _navigateToListening(activity);
        break;
      case PracticeActivityType.speedMatch:
        _navigateToSpeedMatch(activity);
        break;
      case PracticeActivityType.wordScramble:
        _showComingSoon('Word Scramble');
        break;
      case PracticeActivityType.fillBlanks:
        _showComingSoon('Fill the Blanks');
        break;
      case PracticeActivityType.pictureMemory:
        _navigateToMemory(activity);
        break;
      case PracticeActivityType.trueFalse:
        _showComingSoon('True or False');
        break;
      case PracticeActivityType.pronunciation:
        _navigateToPronunciation();
        break;
    }
  }

  void _navigateToSpelling(PracticeActivity activity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SpellingPracticeScreen(activity: activity),
      ),
    ).then((_) => _loadData());
  }

  void _navigateToListening(PracticeActivity activity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ListeningPracticeScreen(lessonId: activity.lessonId),
      ),
    ).then((_) => _loadData());
  }

  void _navigateToSpeedMatch(PracticeActivity activity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SpeedMatchScreen(lessonId: activity.lessonId),
      ),
    ).then((_) => _loadData());
  }

  void _navigateToMemory(PracticeActivity activity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MemoryGameScreen(lessonId: activity.lessonId),
      ),
    ).then((_) => _loadData());
  }

  void _navigateToPronunciation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PronunciationPracticeScreen(),
      ),
    ).then((_) => _loadData());
  }

  void _showComingSoon(String activityName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🚧 Próximamente'),
        content: Text('$activityName estará disponible pronto!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showProgressBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildProgressBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _buildMainLayout();

    if (widget.showNavBar) {
      return AppScaffold(
        currentIndex: 2,
        child: content,
      );
    }

    return content;
  }

  Widget _buildMainLayout() {
    if (_showSidebar) {
      return Row(
        children: [
          SizedBox(
            width: Responsive.isWide(context) ? 360 : 320,
            child: _buildSidebar(),
          ),
          Expanded(
            child: _buildGridContent(),
          ),
        ],
      );
    }

    return Stack(
      children: [
        _buildGridContent(),
        Positioned(
          right: 16,
          bottom: 16,
          child: _buildFloatingProgressButton(),
        ),
      ],
    );
  }

  Widget _buildGridContent() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                Responsive.scale(context, 12.0, 16.0, 20.0),
                Responsive.scale(context, 12.0, 16.0, 20.0),
                Responsive.scale(context, 12.0, 16.0, 20.0),
                Responsive.scale(context, 8.0, 10.0, 12.0),
              ),
              child: _buildLessonFilter(),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.scale(context, 12.0, 16.0, 20.0),
            ),
            sliver: _filteredActivities.isEmpty
                ? SliverToBoxAdapter(child: _buildEmptyState())
                : SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _gridColumns,
                      crossAxisSpacing: Responsive.scale(
                        context,
                        8.0,
                        12.0,
                        16.0,
                      ),
                      mainAxisSpacing: Responsive.scale(
                        context,
                        8.0,
                        12.0,
                        16.0,
                      ),
                      childAspectRatio: _childAspectRatio,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final activity = _filteredActivities[index];
                        final progress = _progressMap[activity.id];
                        return AdaptivePracticeCard(
                          activity: activity,
                          isUnlocked: activity.isUnlocked,
                          progress: progress,
                          onTap: () => _onActivityTap(activity),
                          index: index,
                        );
                      },
                      childCount: _filteredActivities.length,
                    ),
                  ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: Responsive.scale(context, 24.0, 32.0, 40.0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final progress = _totalLessonsCount > 0
        ? _completedCount / _totalLessonsCount
        : 0.0;
    final isZeroProgress = progress == 0.0;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-0.3, 0.0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
          ),
        ),
        child: Container(
          margin: EdgeInsets.all(
            Responsive.scale(context, 12.0, 16.0, 20.0),
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF667eea),
                Color(0xFF764ba2),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667eea).withAlpha(50),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(
              Responsive.scale(context, 14.0, 16.0, 20.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.amber,
                      size: Responsive.scale(context, 24, 28, 32),
                    ),
                    SizedBox(width: Responsive.scale(context, 6, 8, 10)),
                    Expanded(
                      child: Text(
                        'Tu Progreso',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: Responsive.scale(context, 15, 17, 19),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Responsive.scale(context, 12, 14, 16)),
                _buildSidebarProgressBar(),
                SizedBox(height: Responsive.scale(context, 6, 8, 10)),
                if (isZeroProgress)
                  Text(
                    '¡Vamos a empezar!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: Responsive.scale(context, 12, 13, 14),
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  Text(
                    '$_completedCount / $_totalLessonsCount',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: Responsive.scale(context, 13, 14, 15),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                SizedBox(height: Responsive.scale(context, 12, 14, 16)),
                Row(
                  children: [
                    Expanded(
                      child: _buildSidebarStat(
                        icon: Icons.local_fire_department_rounded,
                        value: '$_loginStreak',
                        label: 'Días seguidos',
                        color: Colors.orangeAccent,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildSidebarStat(
                        icon: Icons.star_rounded,
                        value: '$_practiceStars',
                        label: 'Estrellas',
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildSidebarStat(
                        icon: Icons.lock_open_rounded,
                        value: '$_unlockedCount',
                        label: 'Desbloqueadas',
                        color: Colors.cyanAccent,
                      ),
                    ),
                  ],
                ),
                if (_nextLesson != null) ...[
                  SizedBox(height: Responsive.scale(context, 12, 14, 16)),
                  _buildNextLessonCard(),
                ],
                if (_completionPercentage >= 100) ...[
                  SizedBox(height: Responsive.scale(context, 8, 10, 12)),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.scale(context, 10, 12, 14),
                      vertical: Responsive.scale(context, 6, 8, 10),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.celebration, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Todo completado!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: Responsive.scale(context, 10, 11, 12),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarProgressBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: _completionPercentage / 100),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                children: [
                  Container(
                    height: 8,
                    color: Colors.white.withAlpha(30),
                  ),
                  Container(
                    width: constraints.maxWidth * value,
                    height: 8,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white, Color(0xBBFFFFFF)],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNextLessonCard() {
    final lesson = _nextLesson!;
    return GestureDetector(
      onTap: () => _openLesson(lesson),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.scale(context, 10, 12, 14),
          vertical: Responsive.scale(context, 8, 10, 12),
        ),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withAlpha(40)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Próxima lección',
                    style: TextStyle(
                      color: Colors.white.withAlpha(180),
                      fontSize: Responsive.scale(context, 9, 10, 11),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lesson.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Lección $_nextLessonIndex de $_totalLessonsCount',
                    style: TextStyle(
                      color: Colors.white.withAlpha(160),
                      fontSize: Responsive.scale(context, 9, 10, 11),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white54,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: Responsive.scale(context, 8, 10, 12),
        horizontal: Responsive.scale(context, 6, 8, 10),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: Responsive.scale(context, 18, 20, 22)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: Responsive.scale(context, 14, 16, 18),
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withAlpha(210),
              fontSize: Responsive.scale(context, 9, 10, 11),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingProgressButton() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: GestureDetector(
        onTap: _showProgressBottomSheet,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF667eea),
                Color(0xFF764ba2),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667eea).withAlpha(60),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 0,
                  end: _completionPercentage / 100,
                ),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return CircularProgressIndicator(
                    value: value,
                    strokeWidth: 3,
                    backgroundColor: Colors.white.withAlpha(30),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  );
                },
              ),
              Text(
                '${_completionPercentage.toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBottomSheet() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF667eea),
            Color(0xFF764ba2),
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(60),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tu Progreso',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_completedCount de $_totalCount completadas',
                      style: TextStyle(
                        color: Colors.white.withAlpha(200),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              _buildCircularProgressCompact(_completionPercentage),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildBottomSheetStat(
                  icon: Icons.check_circle_rounded,
                  value: '$_completedCount',
                  label: 'Completadas',
                  color: Colors.greenAccent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildBottomSheetStat(
                  icon: Icons.star_rounded,
                  value: '$_practiceStars',
                  label: 'Estrellas',
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildBottomSheetStat(
                  icon: Icons.lock_open_rounded,
                  value: '$_unlockedCount',
                  label: 'Desbloqueadas',
                  color: Colors.cyanAccent,
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _buildCircularProgressCompact(double percentage) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: percentage / 100),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return CircularProgressIndicator(
                value: value,
                strokeWidth: 5,
                backgroundColor: Colors.white.withAlpha(30),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              );
            },
          ),
          Text(
            '${percentage.toInt()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheetStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withAlpha(160),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLessonFilter() {
    final lessonIds = _activities.map((a) => a.lessonId).toSet().toList();
    final totalFilters = lessonIds.length + 1;

    _startFilterAutoScroll();

    return SizedBox(
      height: 50,
      child: ListView.builder(
        controller: _filterScrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: totalFilters,
        itemBuilder: (context, index) {
          return index == 0
              ? _buildFilterChip(
                  label: 'Todas',
                  icon: Icons.grid_view_rounded,
                  isSelected: _selectedLessonFilter == null,
                  onTap: () {
                    _stopFilterAutoScroll();
                    setState(() => _selectedLessonFilter = null);
                  },
                )
              : _buildFilterChip(
                  label: _activities.firstWhere((a) => a.lessonId == lessonIds[index - 1]).title.split(':').last.trim(),
                  icon: Icons.menu_book_rounded,
                  isSelected: _selectedLessonFilter == lessonIds[index - 1],
                  onTap: () {
                    _stopFilterAutoScroll();
                    setState(() {
                      _selectedLessonFilter =
                          _selectedLessonFilter == lessonIds[index - 1] ? null : lessonIds[index - 1];
                    });
                  },
                );
        },
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.scale(context, 12, 14, 16),
            vertical: Responsive.scale(context, 8, 10, 12),
          ),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [
                      Color(0xFF667eea),
                      Color(0xFF764ba2),
                    ],
                  )
                : null,
            color: isSelected ? null : context.appColors.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : context.appColors.border,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF667eea).withAlpha(40),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: Responsive.scale(context, 14, 16, 18),
                color: isSelected ? Colors.white : context.appColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: Responsive.scale(context, 11, 12, 13),
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : context.appColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.appColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 48,
                color: context.appColors.textTertiary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay actividades disponibles',
              style: context.cardTitle.copyWith(
                color: context.appColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Completa más lecciones para desbloquear actividades',
              style: context.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
