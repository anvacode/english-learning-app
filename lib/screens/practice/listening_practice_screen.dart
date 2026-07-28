import 'dart:math' show Random;

import 'package:flutter/material.dart';

import '../../data/lessons_data.dart';
import '../../logic/activity_result_service.dart';
import '../../logic/practice_service.dart';
import '../../logic/star_service.dart';
import '../../models/activity_result.dart';
import '../../models/lesson_item.dart';
import '../../services/audio_service.dart';
import '../../theme/app_colors_extension.dart';
import '../../theme/text_styles.dart';
import '../../utils/responsive.dart';
import '../../widgets/animated_progress_bar.dart';
import '../../widgets/lesson_image.dart';

/// Pantalla de práctica de listening:
/// - Reproduce una palabra en inglés
/// - Muestra imágenes/opciones visuales
/// - El usuario selecciona la respuesta correcta
class ListeningPracticeScreen extends StatefulWidget {
  final String lessonId;

  const ListeningPracticeScreen({super.key, required this.lessonId});

  @override
  State<ListeningPracticeScreen> createState() =>
      _ListeningPracticeScreenState();
}

class _ListeningPracticeScreenState extends State<ListeningPracticeScreen>
    with SingleTickerProviderStateMixin {
  late List<LessonItem> _items;
  late int _currentIndex;
  late List<String> _currentOptions;

  int? _selectedIndex;
  bool _answered = false;
  bool? _isCorrect;

  int _correctCount = 0;
  int _totalCount = 0;

  final AudioService _audioService = AudioService();

  // Animation
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeLesson();
    _audioService.initialize();

    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Auto-play first word after a delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _playCurrentWord();
    });
  }

  void _initializeLesson() {
    // Find the lesson
    final lesson = lessonsList.firstWhere(
      (l) => l.id == widget.lessonId,
      orElse: () => lessonsList.first,
    );

    _items = List.from(lesson.items);
    _items.shuffle(Random());
    _currentIndex = 0;
    _generateOptions();
  }

  void _generateOptions() {
    if (_currentIndex >= _items.length) return;

    final currentItem = _items[_currentIndex];
    final correctAnswer = currentItem.options[currentItem.correctAnswerIndex];

    // Get all possible wrong answers from the same lesson
    final allOptions = _items
        .where((item) => item.id != currentItem.id)
        .map((item) => item.options[item.correctAnswerIndex])
        .toSet()
        .toList();

    allOptions.shuffle(Random());

    // Take 2-3 wrong answers
    final wrongAnswers = allOptions.take(2).toList();

    // Combine with correct answer and shuffle
    _currentOptions = [correctAnswer, ...wrongAnswers];
    _currentOptions.shuffle(Random());
  }

  Future<void> _playCurrentWord() async {
    if (_currentIndex >= _items.length || _isPlaying) return;

    setState(() {
      _isPlaying = true;
    });

    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    final currentItem = _items[_currentIndex];
    final wordToSpeak = currentItem.options[currentItem.correctAnswerIndex];

    await _audioService.speak(wordToSpeak);

    if (mounted) {
      setState(() {
        _isPlaying = false;
      });
    }
  }

  Future<void> _selectOption(int index) async {
    if (_answered) return;

    await _audioService.playClickSound();

    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _checkAnswer() async {
    if (_selectedIndex == null || _answered) return;

    final currentItem = _items[_currentIndex];
    final correctAnswer = currentItem.options[currentItem.correctAnswerIndex];
    final selectedAnswer = _currentOptions[_selectedIndex!];
    final isCorrect = selectedAnswer == correctAnswer;

    // Play feedback sound
    if (isCorrect) {
      await _audioService.playCorrectSound();
    } else {
      await _audioService.playWrongSound();
    }

    // Save result
    await ActivityResultService.saveActivityResult(
      ActivityResult(
        lessonId: widget.lessonId,
        itemId: '${currentItem.id}_listening',
        isCorrect: isCorrect,
        timestamp: DateTime.now(),
      ),
    );

    setState(() {
      _answered = true;
      _isCorrect = isCorrect;
      _totalCount++;
      if (isCorrect) _correctCount++;
    });
  }

  Future<void> _nextQuestion() async {
    if (_currentIndex < _items.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedIndex = null;
        _answered = false;
        _isCorrect = null;
        _generateOptions();
      });

      // Auto-play next word
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) _playCurrentWord();
    } else {
      // Finish activity
      await _finishActivity();
    }
  }

  Future<void> _finishActivity() async {
    // Award stars based on performance
    final accuracy = _correctCount / _totalCount;
    int stars = 0;

    if (accuracy >= 0.9) {
      stars = 15;
    } else if (accuracy >= 0.7) {
      stars = 10;
    } else if (accuracy >= 0.5) {
      stars = 5;
    }

    // Update practice progress
    final activityId = '${widget.lessonId}_listening';
    await PracticeService.updateProgress(
      activityId: activityId,
      totalExercises: _items.length,
      exercisesCompleted: _correctCount,
      starsEarned: stars,
      newScore: _correctCount,
    );

    if (stars > 0) {
      await StarService.addStars(
        stars,
        'listening_practice',
        lessonId: widget.lessonId,
        description: 'Práctica de Listening completada',
      );
    }

    if (!mounted) return;

    // Show results dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('¡Actividad Completada!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.headphones, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            Text(
              'Respuestas correctas: $_correctCount/$_totalCount',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Precisión: ${(accuracy * 100).round()}%',
              style: const TextStyle(fontSize: 16),
            ),
            if (stars > 0) ...[
              const SizedBox(height: 16),
              Text(
                '¡+$stars estrellas!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Salir'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _initializeLesson();
                _currentIndex = 0;
                _correctCount = 0;
                _totalCount = 0;
                _selectedIndex = null;
                _answered = false;
                _isCorrect = null;
              });
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) _playCurrentWord();
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex >= _items.length) {
      return Scaffold(
        appBar: AppBar(
          title: Text('🎧 Listening Practice', style: context.appBarTitle),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final currentItem = _items[_currentIndex];
    final progress = (_currentIndex + 1) / _items.length;
    final buttonSize = Responsive.scale(context, 80.0, 100.0, 120.0);
    final iconSize = Responsive.scale(context, 40.0, 50.0, 60.0);
    final hPadding = Responsive.horizontalPadding(context);
    final isDesktop = !Responsive.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('🎧 Listening Practice', style: context.appBarTitle),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: hPadding),
            child: Center(
              child: Text(
                '$_correctCount/$_totalCount',
                style: TextStyle(
                  fontSize: Responsive.scale(context, 14, 16, 18),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          AnimatedProgressBar(
            progress: progress,
            color: Colors.blue,
            label: '${_currentIndex + 1}/${_items.length}',
          ),
          Expanded(
            child: isDesktop
                ? _buildDesktopLayout(context, currentItem, buttonSize, iconSize)
                : _buildMobileLayout(context, currentItem, buttonSize, iconSize),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    LessonItem currentItem,
    double buttonSize,
    double iconSize,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(Responsive.scale(context, 16, 20, 24)),
      child: Column(
        children: [
          Text(
            'Escucha y selecciona la respuesta correcta',
            style: context.headline3,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: Responsive.scale(context, 16, 24, 28)),
          _buildAudioButton(context, buttonSize, iconSize),
          SizedBox(height: Responsive.scale(context, 24, 32, 36)),
          if (_answered) ...[
            _buildFeedback(context),
            SizedBox(height: Responsive.scale(context, 16, 24, 28)),
          ],
          _buildOptionsGrid(context, currentItem),
          SizedBox(height: Responsive.scale(context, 16, 24, 28)),
          _buildActionButton(context),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    LessonItem currentItem,
    double buttonSize,
    double iconSize,
  ) {
    return Padding(
      padding: EdgeInsets.all(Responsive.scale(context, 24, 28, 32)),
      child: Column(
        children: [
          Text(
            'Escucha y selecciona la respuesta correcta',
            style: context.headline3,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: Responsive.scale(context, 16, 20, 24)),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildAudioButton(context, buttonSize, iconSize),
                        if (_answered) ...[
                          SizedBox(height: Responsive.scale(context, 16, 20, 24)),
                          _buildFeedback(context),
                        ],
                      ],
                    ),
                  ),
                ),
                SizedBox(width: Responsive.scale(context, 32, 40, 48)),
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildOptionsGrid(context, currentItem),
                      SizedBox(height: Responsive.scale(context, 20, 24, 28)),
                      _buildActionButton(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioButton(BuildContext context, double buttonSize, double iconSize) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withAlpha(77),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: IconButton(
          onPressed: _answered ? null : _playCurrentWord,
          icon: Icon(
            _isPlaying ? Icons.volume_up : Icons.headphones,
            size: iconSize,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildFeedback(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.scale(context, 16, 20, 24),
        vertical: Responsive.scale(context, 8, 10, 12),
      ),
      decoration: BoxDecoration(
        color: _isCorrect! ? Colors.green[100] : Colors.red[100],
        borderRadius: BorderRadius.circular(Responsive.borderRadius(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isCorrect! ? Icons.check_circle : Icons.cancel,
            color: _isCorrect! ? Colors.green : Colors.red,
            size: Responsive.scale(context, 18, 20, 22),
          ),
          SizedBox(width: Responsive.scale(context, 6, 8, 10)),
          Text(
            _isCorrect! ? '¡Correcto!' : 'Incorrecto',
            style: TextStyle(
              fontSize: Responsive.scale(context, 14, 15, 16),
              fontWeight: FontWeight.bold,
              color: _isCorrect! ? Colors.green[900] : Colors.red[900],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsGrid(BuildContext context, LessonItem currentItem) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = Responsive.gridColumns(context, mobile: 2, tablet: 3, desktop: 3);
        final spacing = Responsive.gridSpacing(context);
        final aspectRatio = Responsive.cardAspectRatio(context);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: aspectRatio,
          ),
          itemCount: _currentOptions.length,
          itemBuilder: (context, index) {
            final option = _currentOptions[index];
            final correctAnswer = currentItem.options[currentItem.correctAnswerIndex];
            final isSelected = _selectedIndex == index;
            final isCorrectOption = option == correctAnswer;

            final optionItem = _items.firstWhere(
              (item) => item.options[item.correctAnswerIndex] == option,
              orElse: () => currentItem,
            );

            Color borderColor;
            if (_answered) {
              if (isCorrectOption) {
                borderColor = Colors.green;
              } else if (isSelected) {
                borderColor = Colors.red;
              } else {
                borderColor = context.appColors.border;
              }
            } else {
              borderColor = isSelected ? Colors.blue : context.appColors.border;
            }

            return GestureDetector(
              onTap: _answered ? null : () => _selectOption(index),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: borderColor,
                    width: isSelected || (_answered && isCorrectOption) ? 4 : 2,
                  ),
                  borderRadius: BorderRadius.circular(Responsive.borderRadius(context)),
                  color: context.appColors.cardBackground,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(Responsive.scale(context, 6, 8, 10)),
                        child: LessonImage(
                          imagePath: optionItem.stimulusImageAsset,
                          fallbackColor: optionItem.stimulusColor,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(Responsive.scale(context, 3, 4, 5)),
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: Responsive.scale(context, 11, 12, 13),
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActionButton(BuildContext context) {
    if (!_answered && _selectedIndex != null) {
      return Center(
        child: SizedBox(
          width: Responsive.scale(context, 200, 240, 280),
          height: Responsive.buttonHeight(context) * 0.8,
          child: ElevatedButton(
            onPressed: _checkAnswer,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Responsive.borderRadius(context)),
              ),
            ),
            child: Text(
              'Verificar',
              style: context.buttonText,
            ),
          ),
        ),
      );
    } else if (_answered) {
      return Center(
        child: SizedBox(
          width: Responsive.scale(context, 200, 240, 280),
          height: Responsive.buttonHeight(context) * 0.8,
          child: ElevatedButton(
            onPressed: _nextQuestion,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Responsive.borderRadius(context)),
              ),
            ),
            child: Text(
              _currentIndex < _items.length - 1 ? 'Siguiente' : 'Ver Resultados',
              style: context.buttonText,
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
