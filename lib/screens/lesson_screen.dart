import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../logic/activity_result_service.dart';
import '../logic/badge_service.dart';
import '../logic/lesson_completion_service.dart';
import '../logic/lesson_controller.dart';
import '../logic/lesson_progress_evaluator.dart';
import '../logic/mastery_evaluator.dart';
import '../logic/star_service.dart';
import '../models/activity_result.dart';
import '../models/badge.dart' as achievement;
import '../models/lesson.dart';
import '../models/lesson_item.dart';
import '../models/matching_item.dart';
import '../services/audio_service.dart';
import '../services/effects_service.dart';
import '../services/firestore_progress_service.dart';
import '../theme/app_colors_extension.dart';
import '../theme/text_styles.dart';
import '../utils/responsive.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/feedback_widget.dart';
import '../widgets/lesson_image.dart';
import '../widgets/sparkles_overlay.dart';
import '../widgets/speaker_button.dart';
import '../widgets/streak_indicator.dart';
import '../widgets/translation_popup.dart';
import 'lesson_completion_screen.dart';
import 'matching_exercise_screen.dart';

class LessonScreen extends StatefulWidget {
  final Lesson lesson;
  final VoidCallback?
  onExerciseCompleted; // Callback when this exercise completes
  final double progressOffset; // Progress offset when used in flow (0.0-1.0)
  final double progressScale; // Progress scale when used in flow (0.0-1.0)

  const LessonScreen({
    super.key,
    required this.lesson,
    this.onExerciseCompleted,
    this.progressOffset = 0.0,
    this.progressScale = 1.0,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  // Core state fields (single source of truth)
  int completedCount = 0;
  int totalCount = 0;
  LessonProgressStatus status = LessonProgressStatus.notStarted;
  int currentItemIndex = 0;

  // Completion flag to prevent looping
  bool _exerciseCompleted = false;

  // Temporary UI interaction state (reset per item)
  int? _selectedAnswerIndex;
  bool _answered = false;
  bool? _isCorrect;

  // Randomized options for current item
  late List<String> _randomizedOptions;
  late String _correctAnswerValue; // The correct answer as a string, not index

  // Badge state
  achievement.Badge? _badge;

  // Audio service
  final AudioService _audioService = AudioService();

  // Sparkles effect state
  bool _showSparkles = false;
  Offset? _sparklesCenter;

  // Streak tracking
  int _streak = 0;

  // Confetti effect state
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    totalCount = widget.lesson.items.length;
    _randomizedOptions = [];
    _correctAnswerValue = '';
    // Initialize audio service
    _audioService.initialize();
    // Defer controller initialization to after the frame to avoid assertion errors
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<LessonController>().initializeLesson(totalCount);
      }
    });
    _loadProgressAndPosition();
  }

  Future<void> _loadProgressAndPosition() async {
    final service = LessonProgressService();
    final progress = await service.evaluate(widget.lesson);

    // Load badge
    final badge = await BadgeService.getBadge(widget.lesson);

    // Determine starting question index based on lesson status
    // Key distinction:
    // - notStarted: Always start from question 0 (new attempt)
    // - inProgress: Resume from first incomplete (continuation)
    // - mastered: Start from first incomplete for review
    int firstIncomplete = 0;

    if (progress.status == LessonProgressStatus.notStarted) {
      // New attempt: always start from question 0
      firstIncomplete = 0;
    } else {
      // Resume attempt: find first incomplete from persisted results
      final results = await ActivityResultService.getActivityResults();
      final completedIds = <String>{};
      for (final r in results) {
        if (r.lessonId == widget.lesson.id && r.isCorrect) {
          completedIds.add(r.itemId);
        }
      }

      for (var i = 0; i < widget.lesson.items.length; i++) {
        if (!completedIds.contains(widget.lesson.items[i].id)) {
          firstIncomplete = i;
          break;
        }
      }
      // If all items are completed, start from the last item
      if (completedIds.length == widget.lesson.items.length) {
        firstIncomplete = widget.lesson.items.length - 1;
      }
    }

    setState(() {
      completedCount = progress.completedCount;
      totalCount = progress.totalCount;
      status = progress.status;
      currentItemIndex = firstIncomplete;
      _badge = badge;
      _randomizeOptions();
    });

    // Auto-speak the current word when question appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && currentItemIndex < widget.lesson.items.length) {
        final currentItem = widget.lesson.items[currentItemIndex];
        final wordToSpeak = currentItem.options[currentItem.correctAnswerIndex];
        _audioService.autoSpeak(wordToSpeak);
      }
    });
  }

  /// Randomize options for the current item
  void _randomizeOptions() {
    if (currentItemIndex < widget.lesson.items.length) {
      final currentItem = widget.lesson.items[currentItemIndex];
      // Store the correct answer VALUE before shuffling
      _correctAnswerValue = currentItem.options[currentItem.correctAnswerIndex];
      // Shuffle options
      _randomizedOptions = List<String>.from(currentItem.options);
      _randomizedOptions.shuffle();
    }
  }

  /// Trigger sparkles effect on correct answer
  Future<void> _triggerSparklesEffect() async {
    final shouldShow = await EffectsService.shouldShowSparkles();
    if (mounted && shouldShow) {
      final screenSize = MediaQuery.of(context).size;
      setState(() {
        _showSparkles = true;
        _sparklesCenter = Offset(screenSize.width / 2, screenSize.height / 2);
      });
    }
  }

  /// Trigger confetti effect on streak milestones
  Future<void> _triggerConfettiEffect() async {
    final shouldShow = await EffectsService.shouldShowConfetti();
    if (mounted && shouldShow) {
      setState(() {
        _showConfetti = true;
      });
      // Confetti dura ~3 segundos, resetear después
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        setState(() {
          _showConfetti = false;
        });
      }
    }
  }

  // Save answer first, then evaluate, then setState (persistence order enforced)
  Future<void> _handleOptionTap(int tappedIndex) async {
    if (status == LessonProgressStatus.mastered || _exerciseCompleted) return;

    final currentItem = widget.lesson.items[currentItemIndex];
    final selectedOption = _randomizedOptions[tappedIndex];
    final isCorrect = selectedOption == _correctAnswerValue;

    // Play click sound
    await _audioService.playClickSound();

    final result = ActivityResult(
      lessonId: widget.lesson.id,
      itemId: currentItem.id,
      isCorrect: isCorrect,
      timestamp: DateTime.now(),
    );

    // 1) Persist immediately
    await ActivityResultService.saveActivityResult(result);

    // 2) Evaluate using single source of truth
    final service = LessonProgressService();
    final progress = await service.evaluate(widget.lesson);

    // Capture context before async operation
    if (!mounted) return;
    final lessonController = context.read<LessonController>();

    // 3) Update UI with feedback and progress via Provider
    final shouldRestart = lessonController.submitAnswer(
      itemId: currentItem.id,
      selectedOption: selectedOption,
      isCorrect: isCorrect,
    );

    // Check if lesson should restart due to too many errors (3 per question)
    if (shouldRestart) {
      await _audioService.playWrongSound();

      // Show dialog informing about restart
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('🔄 Reiniciando lección'),
            content: const Text(
              'Has tenido 3 errores en esta pregunta. '
              'Vamos a empezar la lección de nuevo para que puedas practicar más. '
              '¡Tú puedes!',
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                ),
                child: const Text(
                  '¡Vamos!',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      }

      // Restart the lesson
      if (mounted) {
        lessonController.restartLesson();
        setState(() {
          currentItemIndex = 0;
          _selectedAnswerIndex = null;
          _answered = false;
          _isCorrect = null;
          completedCount = 0;
          totalCount = progress.totalCount;
          status = LessonProgressStatus.inProgress;
        });
        _randomizeOptions();
      }
      return;
    }

    setState(() {
      _selectedAnswerIndex = tappedIndex;
      _answered = true;
      _isCorrect = isCorrect;
      completedCount = progress.completedCount;
      totalCount = progress.totalCount;
      status = progress.status;
      // Track streak
      if (isCorrect) {
        _streak++;
      } else {
        _streak = 0;
      }
    });

    // Play feedback sound and show effects
    if (isCorrect) {
      await _audioService.playCorrectSound();
      // Show sparkles effect (always free)
      _triggerSparklesEffect();
      // Show confetti on streak milestones
      if (_streak >= 3) {
        _triggerConfettiEffect();
      }
    } else {
      await _audioService.playWrongSound();

      // Show number of attempts left for this question (subtle indicator)
      final attemptsLeft =
          3 -
          lessonController.getIncorrectAttemptsForCurrentQuestion(
            currentItem.id,
          );
      if (attemptsLeft > 0 && mounted) {
        _showAttemptsIndicator(context, attemptsLeft);
      }
    }

    // 4) Check if exercise is complete using Provider state
    if (lessonController.isLessonCompleted && !_exerciseCompleted) {
      // All items in this exercise are complete - call callback ONCE immediately
      _exerciseCompleted = true; // Prevent looping

      // A lesson is mastered ONLY if the current attempt is perfect (100% correct)
      final isCurrentAttemptPerfect =
          lessonController.correctAnswers == lessonController.totalQuestions;

      // If we are in flow mode (onExerciseCompleted is not null),
      // don't show feedback/dialog yet - let the flow controller handle it
      if (widget.onExerciseCompleted != null) {
        // In flow mode: just signal exercise completion without showing dialog
        // The LessonFlowScreen will show feedback after ALL exercises are done
        if (mounted) {
          widget.onExerciseCompleted!();
        }
      } else {
        // Standalone mode: Show feedback and award stars immediately
        int starsEarned = 0;
        achievement.Badge? badgeToShow;

        if (isCurrentAttemptPerfect) {
          // Check if lesson was already completed before
          final wasAlreadyCompleted =
              await LessonCompletionService.isLessonCompleted(widget.lesson.id);

          // Save lesson completion record (source of truth for mastery)
          await LessonCompletionService.saveCompletion(widget.lesson.id);
          MasteryEvaluator.invalidateCache();
          BadgeService.invalidateCache();

          // Award stars only if this is the first time completing the lesson
          if (!wasAlreadyCompleted) {
            const starsForCompletion = 20; // Base stars for completing a lesson
            await StarService.addStars(
              starsForCompletion,
              'lesson_complete',
              lessonId: widget.lesson.id,
              description: 'Completaste la lección "${widget.lesson.title}"',
            );
            starsEarned = starsForCompletion;

            final accuracy = lessonController.totalQuestions > 0
                ? (lessonController.correctAnswers /
                        lessonController.totalQuestions) *
                    100
                : 0.0;
            FirestoreProgressService().saveLessonProgress(
              lessonId: widget.lesson.id,
              starsEarned: starsEarned,
              accuracy: accuracy,
            );
          }

          // Award badge (only on first perfect completion)
          final badgeJustAwarded = await BadgeService.checkAndAwardBadge(
            widget.lesson,
          );
          if (badgeJustAwarded && mounted) {
            // Reload badge to show it was just awarded
            final badge = await BadgeService.getBadge(widget.lesson);
            setState(() {
              _badge = badge;
            });
            badgeToShow = badge;
          } else if (mounted) {
            // Show existing badge if any
            final badge = await BadgeService.getBadge(widget.lesson);
            if (badge != null && badge.unlocked) {
              badgeToShow = badge;
            }
          }
        } else {
          // Award partial stars for completing lesson items (even if not perfect)
          // This encourages progress even if not perfect
          const starsForProgress = 5;
          await StarService.addStars(
            starsForProgress,
            'lesson_progress',
            lessonId: widget.lesson.id,
            description: 'Progreso en la lección "${widget.lesson.title}"',
          );
          starsEarned = starsForProgress;

          final accuracy = lessonController.totalQuestions > 0
              ? (lessonController.correctAnswers /
                      lessonController.totalQuestions) *
                  100
              : 0.0;
          FirestoreProgressService().saveLessonProgress(
            lessonId: widget.lesson.id,
            starsEarned: starsEarned,
            accuracy: accuracy,
          );
        }

        // Navigate to completion screen
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LessonCompletionScreen(
                lessonTitle: widget.lesson.title,
                starsEarned: starsEarned,
                correctAnswers: lessonController.correctAnswers,
                totalQuestions: lessonController.totalQuestions,
                badgeIcon: badgeToShow?.icon,
                badgeTitle: badgeToShow?.title,
                isPerfectScore: isCurrentAttemptPerfect,
                onContinue: () {
                  // Check if lesson has matching exercise and navigate to it
                  if (widget.lesson.id == 'animals' || widget.lesson.id == 'family_1') {
                    _navigateToMatchingExercise();
                  } else {
                    Navigator.pop(context, true); // Return true to signal state changed
                  }
                },
              ),
            ),
          );
        }
      }
    }
  }

  // Handle advancing to next item or retry
  Future<void> _onNextOrRetry() async {
    // Don't advance if exercise is complete
    if (_exerciseCompleted) return;

    if (_isCorrect == true) {
      // Correct answer: advance to next question sequentially
      // Do NOT use persisted results - they only control initial positioning
      int nextIndex = currentItemIndex + 1;

      // If we've answered all questions, stay at the last one
      if (nextIndex >= widget.lesson.items.length) {
        nextIndex = widget.lesson.items.length - 1;
      }

      setState(() {
        currentItemIndex = nextIndex;
        _selectedAnswerIndex = null;
        _answered = false;
        _isCorrect = null;
        _randomizeOptions(); // Re-randomize for the new item
      });

      // Auto-speak the new word when advancing
      if (nextIndex < widget.lesson.items.length) {
        final nextItem = widget.lesson.items[nextIndex];
        final wordToSpeak = nextItem.options[nextItem.correctAnswerIndex];
        _audioService.autoSpeak(wordToSpeak);
      }
    } else {
      // Incorrect: reset for retry
      // Decrement controller's question index to allow retry of same question
      final lessonController = context.read<LessonController>();
      lessonController.decrementQuestionIndex();

      setState(() {
        _selectedAnswerIndex = null;
        _answered = false;
        _isCorrect = null;
      });
    }
  }

  // Show subtle attempts indicator
  void _showAttemptsIndicator(BuildContext context, int attemptsLeft) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 100,
        left: 0,
        right: 0,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(200),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$attemptsLeft ${attemptsLeft == 1 ? 'intento' : 'intentos'} restantes',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    
    overlay.insert(overlayEntry);
    
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  void _navigateToMatchingExercise() {
    // Build matching items based on lesson
    List<MatchingItem> matchingItems = [];

    if (widget.lesson.id == 'animals') {
      // Animals matching items
      matchingItems = [
        const MatchingItem(
          id: 'dog',
          imagePath: 'assets/images/animals/dog.jpg',
          correctWord: 'dog',
          title: 'Perro',
        ),
        const MatchingItem(
          id: 'cat',
          imagePath: 'assets/images/animals/cat.jpg',
          correctWord: 'cat',
          title: 'Gato',
        ),
        const MatchingItem(
          id: 'cow',
          imagePath: 'assets/images/animals/cow.jpg',
          correctWord: 'cow',
          title: 'Vaca',
        ),
      ];
    } else if (widget.lesson.id == 'family_1') {
      // Family matching items
      matchingItems = [
        const MatchingItem(
          id: 'mother',
          imagePath: 'assets/images/family/mother.jpg',
          correctWord: 'mother',
          title: 'Madre',
        ),
        const MatchingItem(
          id: 'father',
          imagePath: 'assets/images/family/father.jpg',
          correctWord: 'father',
          title: 'Padre',
        ),
        const MatchingItem(
          id: 'brother',
          imagePath: 'assets/images/family/brother.jpg',
          correctWord: 'brother',
          title: 'Hermano',
        ),
        const MatchingItem(
          id: 'sister',
          imagePath: 'assets/images/family/sister.jpg',
          correctWord: 'sister',
          title: 'Hermana',
        ),
        const MatchingItem(
          id: 'grandfather',
          imagePath: 'assets/images/family/grandfather.jpg',
          correctWord: 'grandfather',
          title: 'Abuelo',
        ),
        const MatchingItem(
          id: 'grandmother',
          imagePath: 'assets/images/family/grandmother.jpg',
          correctWord: 'grandmother',
          title: 'Abuela',
        ),
        const MatchingItem(
          id: 'family',
          imagePath: 'assets/images/family/family.jpg',
          correctWord: 'family',
          title: 'Familia',
        ),
      ];
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MatchingExerciseScreen(
          lessonId: widget.lesson.id,
          title: widget.lesson.title,
          items: matchingItems,
        ),
      ),
    ).then((result) {
      // When matching exercise returns, pop this screen with true to signal completion
      if (result == true && mounted) {
        Navigator.pop(context, true);
      }
    });
  }

  Widget _buildMobileLayout(BuildContext context, LessonItem currentItem) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: EdgeInsets.only(top: Responsive.scale(context, 8, 12, 14)),
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Responsive.borderRadius(context)),
                  color: context.appColors.surfaceVariant,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Responsive.borderRadius(context)),
                  child: LessonImage(
                    imagePath: currentItem.stimulusImageAsset,
                    fallbackColor: currentItem.stimulusColor,
                    width: Responsive.scale(context, 180, 200, 220),
                    height: Responsive.scale(context, 180, 200, 220),
                  ),
                ),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.scale(context, 12, 16, 20),
              vertical: Responsive.scale(context, 8, 12, 16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    widget.lesson.question,
                    style: context.bodyTextLarge.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(width: Responsive.scale(context, 6, 8, 10)),
                SpeakerButton(
                  text: currentItem.options[currentItem.correctAnswerIndex],
                  iconSize: Responsive.scale(context, 18, 20, 22),
                  buttonSize: Responsive.scale(context, 32, 36, 40),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () {
                    final word = currentItem.options[currentItem.correctAnswerIndex];
                    final translation = TranslationService.translate(word);
                    TranslationPopup.show(context, word: word, translation: translation);
                  },
                  icon: const Icon(Icons.help_outline),
                  color: Colors.blue[600],
                  iconSize: 24,
                  tooltip: 'Ver traducción',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: context.isMobile ? 8.0 : 4.0),
            child: Column(
              children: List.generate(
                _randomizedOptions.length,
                (index) => Padding(
                  padding: EdgeInsets.symmetric(vertical: Responsive.scale(context, 4, 6, 8)),
                  child: SizedBox(
                    width: double.infinity,
                    height: Responsive.scale(context, 52, 56, 60),
                    child: _buildOptionButton(context, index, status),
                  ),
                ),
              ),
            ),
          ),

          _buildSubmitOrFeedback(context, currentItem, status),

          if (status == LessonProgressStatus.mastered)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '🎉 ¡Lección dominada!',
                    style: context.bodyTextLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (_badge != null)
                    Padding(
                      padding: EdgeInsets.only(top: Responsive.scale(context, 6, 8, 10)),
                      child: Text(
                        'Badge desbloqueado: ${_badge!.icon} ${_badge!.title}',
                        style: context.bodyText2.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context, LessonItem currentItem) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Padding(
          padding: EdgeInsets.all(Responsive.scale(context, 16, 20, 24)),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Responsive.borderRadius(context)),
                        color: context.appColors.surfaceVariant,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(Responsive.borderRadius(context)),
                        child: LessonImage(
                          imagePath: currentItem.stimulusImageAsset,
                          fallbackColor: currentItem.stimulusColor,
                          width: Responsive.scale(context, 180, 200, 220),
                          height: Responsive.scale(context, 180, 200, 220),
                        ),
                      ),
                    ),
                    SizedBox(height: Responsive.scale(context, 16, 20, 24)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            widget.lesson.question,
                            style: context.headline3.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(width: Responsive.scale(context, 8, 12, 16)),
                        SpeakerButton(
                          text: currentItem.options[currentItem.correctAnswerIndex],
                          iconSize: Responsive.scale(context, 20, 24, 28),
                          buttonSize: Responsive.scale(context, 36, 44, 52),
                        ),
                        SizedBox(width: Responsive.scale(context, 6, 8, 12)),
                        IconButton(
                          onPressed: () {
                            final word = currentItem.options[currentItem.correctAnswerIndex];
                            final translation = TranslationService.translate(word);
                            TranslationPopup.show(context, word: word, translation: translation);
                          },
                          icon: const Icon(Icons.help_outline),
                          color: Colors.blue[600],
                          iconSize: Responsive.scale(context, 22, 26, 30),
                          tooltip: 'Ver traducción',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: Responsive.scale(context, 20, 28, 36)),
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ...List.generate(
                        _randomizedOptions.length,
                        (index) => Padding(
                          padding: EdgeInsets.symmetric(vertical: Responsive.scale(context, 6, 8, 10)),
                          child: SizedBox(
                            height: Responsive.scale(context, 52, 56, 60),
                            child: _buildOptionButton(context, index, status),
                          ),
                        ),
                      ),
                      SizedBox(height: Responsive.scale(context, 16, 20, 24)),
                      _buildSubmitOrFeedback(context, currentItem, status),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, LessonItem currentItem) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: Responsive.maxContainerWidth(context)),
        child: Padding(
          padding: EdgeInsets.all(Responsive.scale(context, 20, 28, 36)),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Responsive.borderRadius(context)),
                          color: context.appColors.surfaceVariant,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(Responsive.borderRadius(context)),
                          child: LessonImage(
                            imagePath: currentItem.stimulusImageAsset,
                            fallbackColor: currentItem.stimulusColor,
                            width: Responsive.scale(context, 220, 260, 300),
                            height: Responsive.scale(context, 220, 260, 300),
                          ),
                        ),
                      ),
                      SizedBox(height: Responsive.scale(context, 20, 24, 28)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              widget.lesson.question,
                              style: context.headline3.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(width: Responsive.scale(context, 12, 16, 20)),
                          SpeakerButton(
                            text: currentItem.options[currentItem.correctAnswerIndex],
                            iconSize: Responsive.scale(context, 24, 28, 32),
                            buttonSize: Responsive.scale(context, 44, 52, 60),
                          ),
                          SizedBox(width: Responsive.scale(context, 8, 12, 16)),
                          IconButton(
                            onPressed: () {
                              final word = currentItem.options[currentItem.correctAnswerIndex];
                              final translation = TranslationService.translate(word);
                              TranslationPopup.show(context, word: word, translation: translation);
                            },
                            icon: const Icon(Icons.help_outline),
                            color: Colors.blue[600],
                            iconSize: Responsive.scale(context, 26, 30, 34),
                            tooltip: 'Ver traducción',
                          ),
                        ],
                      ),
                      if (status == LessonProgressStatus.mastered) ...[
                        SizedBox(height: Responsive.scale(context, 24, 28, 32)),
                        Text(
                          '🎉 ¡Lección dominada!',
                          style: context.headline3.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (_badge != null)
                          Padding(
                            padding: EdgeInsets.only(top: Responsive.scale(context, 10, 12, 14)),
                            child: Text(
                              'Badge desbloqueado: ${_badge!.icon} ${_badge!.title}',
                              style: context.bodyTextLarge.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(width: Responsive.scale(context, 32, 40, 48)),
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: Responsive.scale(context, 14, 18, 22),
                        crossAxisSpacing: Responsive.scale(context, 14, 18, 22),
                        childAspectRatio: 3.0,
                        children: List.generate(
                          _randomizedOptions.length,
                          (index) => _buildOptionButton(context, index, status),
                        ),
                      ),
                      SizedBox(height: Responsive.scale(context, 24, 28, 32)),
                      _buildSubmitOrFeedback(context, currentItem, status),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton(BuildContext context, int index, LessonProgressStatus status) {
    final isSelected = _selectedAnswerIndex == index;
    final isAnswered = _answered;
    final isCorrect = _isCorrect == true;
    final isWrong = _isCorrect == false && isSelected;

    Color backgroundColor;
    Color textColor;
    Color iconColor;

    if (isAnswered) {
      if (isCorrect && isSelected) {
        backgroundColor = Colors.green[400]!;
        textColor = Colors.white;
        iconColor = Colors.white;
      } else if (isWrong) {
        backgroundColor = Colors.red[400]!;
        textColor = Colors.white;
        iconColor = Colors.white;
      } else {
        backgroundColor = context.appColors.surfaceVariant;
        textColor = context.appColors.textSecondary;
        iconColor = context.appColors.textSecondary;
      }
    } else {
      if (isSelected) {
        backgroundColor = Colors.deepPurple;
        textColor = Colors.white;
        iconColor = Colors.white;
      } else {
        backgroundColor = context.appColors.surfaceVariant;
        textColor = context.appColors.textPrimary;
        iconColor = Colors.deepPurple;
      }
    }

    return ElevatedButton(
      onPressed: (status == LessonProgressStatus.mastered || isAnswered)
          ? null
          : () {
              setState(() {
                _selectedAnswerIndex = index;
              });
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        disabledBackgroundColor: backgroundColor,
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.scale(context, 12, 16, 20),
          vertical: Responsive.scale(context, 8, 12, 14),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Responsive.borderRadius(context)),
          side: isSelected && !isAnswered
              ? BorderSide(color: Colors.deepPurple.shade700, width: 2)
              : BorderSide.none,
        ),
        elevation: isSelected && !isAnswered ? 4 : 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isAnswered && isSelected) ...[
            Icon(
              isCorrect ? Icons.check_circle : Icons.cancel,
              color: Colors.white,
              size: Responsive.scale(context, 18, 20, 22),
            ),
            SizedBox(width: Responsive.scale(context, 6, 8, 10)),
          ],
          Flexible(
            child: Text(
              _randomizedOptions[index],
              style: TextStyle(
                fontSize: Responsive.scale(context, 14, 15, 16),
                fontWeight: FontWeight.w600,
                color: textColor,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.visible,
              softWrap: true,
              maxLines: 2,
            ),
          ),
          if (!isAnswered && status != LessonProgressStatus.mastered) ...[
            SizedBox(width: Responsive.scale(context, 6, 8, 10)),
            SpeakerButton(
              text: _randomizedOptions[index],
              iconSize: Responsive.scale(context, 14, 16, 18),
              buttonSize: Responsive.scale(context, 24, 28, 32),
              iconColor: iconColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitOrFeedback(BuildContext context, LessonItem currentItem, LessonProgressStatus status) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.scale(context, 12, 16, 20),
        vertical: Responsive.scale(context, 6, 8, 10),
      ),
      child: !_answered
          ? Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: Responsive.scale(context, 280, 320, 360),
                  minHeight: Responsive.scale(context, 48, 54, 58),
                ),
                child: ElevatedButton(
                  onPressed: _selectedAnswerIndex != null && status != LessonProgressStatus.mastered
                      ? () => _handleOptionTap(_selectedAnswerIndex!)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    disabledBackgroundColor: context.appColors.surfaceVariant,
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.scale(context, 24, 32, 40),
                      vertical: Responsive.scale(context, 12, 16, 18),
                    ),
                  ),
                  child: Text('Enviar', style: context.buttonText, textAlign: TextAlign.center),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.lesson.items;

    if (currentItemIndex >= items.length) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Lección', style: context.appBarTitle),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Lección completada')),
      );
    }

    final currentItem = items[currentItemIndex];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.lesson.title,
              style: AppTextStyles.appBarTitle(context).copyWith(
                fontSize: Responsive.scale(context, 16, 18, 20),
              ),
            ),
            Text(
              'Pregunta ${currentItemIndex + 1} de ${items.length}',
              style: GoogleFonts.fredoka(
                fontSize: Responsive.scale(context, 11, 12, 13),
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: StreakIndicator(streak: _streak),
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Consumer<LessonController>(
                    builder: (context, lessonController, _) {
                      final adjustedProgress =
                          widget.progressOffset +
                          (lessonController.progress * widget.progressScale);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(
                            value: adjustedProgress,
                            backgroundColor: context.appColors.surfaceVariant,
                            color: Colors.deepPurple,
                            minHeight: 8,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                status == LessonProgressStatus.notStarted
                                    ? 'No iniciada'
                                    : status == LessonProgressStatus.inProgress
                                    ? 'En progreso'
                                    : 'Dominada',
                                style: context.label,
                              ),
                              Text(
                                '${(adjustedProgress * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: Responsive.scale(context, 11, 12, 13),
                                  color: context.appColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),

                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      if (width < 600) {
                        return _buildMobileLayout(context, currentItem);
                      } else if (width < 1024) {
                        return _buildTabletLayout(context, currentItem);
                      } else {
                        return _buildDesktopLayout(context, currentItem);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_showSparkles && _sparklesCenter != null)
            SparklesOverlay(
              isPlaying: _showSparkles,
              center: _sparklesCenter,
              onComplete: () {
                setState(() {
                  _showSparkles = false;
                });
              },
            ),
          if (_showConfetti)
            ConfettiOverlay(
              isPlaying: _showConfetti,
              onComplete: () {
                setState(() {
                  _showConfetti = false;
                });
              },
            ),
          if (_answered)
            Positioned.fill(
              child: Container(
                color: Colors.black.withAlpha(100),
                child: Center(
                  child: FeedbackWidget(
                    key: ValueKey('feedback-${widget.lesson.id}-$currentItemIndex'),
                    isCorrect: _isCorrect ?? false,
                    attemptNumber: _isCorrect == true
                        ? 1
                        : context.read<LessonController>().getIncorrectAttemptsForCurrentQuestion(currentItem.id),
                    streak: _streak,
                    correctAnswer: _isCorrect == false ? _correctAnswerValue : null,
                    onContinue: _onNextOrRetry,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
