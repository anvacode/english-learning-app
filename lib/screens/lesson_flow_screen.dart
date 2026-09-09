import 'package:flutter/material.dart';

import '../data/lessons_data.dart';
import '../logic/activity_result_service.dart';
import '../logic/badge_service.dart';
import '../logic/lesson_completion_service.dart';
import '../logic/mastery_evaluator.dart';
import '../logic/star_service.dart';
import '../models/badge.dart' as achievement;
import '../models/lesson.dart';
import '../models/lesson_exercise.dart';
import '../models/matching_item.dart';
import '../services/firestore_progress_service.dart';
import '../theme/text_styles.dart';
import 'lesson_completion_screen.dart';
import 'lesson_screen.dart';
import 'matching_exercise_screen.dart';
// Spelling movido a práctica - ya no se usa en el flujo de lecciones
// import 'spelling_exercise_screen.dart';

class LessonFlowScreen extends StatefulWidget {
  final Lesson lesson;
  final List<LessonExercise> exercises;

  const LessonFlowScreen({
    super.key,
    required this.lesson,
    required this.exercises,
  });

  @override
  State<LessonFlowScreen> createState() => _LessonFlowScreenState();
}

class _LessonFlowScreenState extends State<LessonFlowScreen> {
  late int _currentExerciseIndex;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFlowProgress();
  }

  /// Carga el progreso del flujo desde SharedPreferences
  Future<void> _loadFlowProgress() async {
    try {
      // Determinar qué ejercicio debe mostrarse basándose en los resultados guardados
      int exerciseToShow = 0;

      // Verificar si las preguntas múltiples están completadas
      final results = await ActivityResultService.getActivityResults();
      final lessonResults = results
          .where((r) => r.lessonId == widget.lesson.id)
          .toList();

      // Contar cuántas preguntas únicas correctas hay
      final completedQuestionIds = <String>{};
      for (final result in lessonResults) {
        if (result.isCorrect && result.itemId != 'matching_exercise') {
          completedQuestionIds.add(result.itemId);
        }
      }

      // Si todas las preguntas están completadas, ir al matching (ejercicio 1)
      if (completedQuestionIds.length >= widget.lesson.items.length) {
        // Verificar si matching también está completo
        final matchingComplete = lessonResults.any(
          (r) => r.itemId == 'matching_exercise' && r.isCorrect,
        );

        if (matchingComplete) {
          // Todo está completo - mostrar feedback y salir
          exerciseToShow = widget.exercises.length; // Forzar completado
        } else {
          // Preguntas completas, matching pendiente
          exerciseToShow = 1; // Ir al matching
        }
      } else {
        // Preguntas incompletas, empezar desde el principio
        exerciseToShow = 0;
      }

      if (mounted) {
        setState(() {
          _currentExerciseIndex = exerciseToShow;
          _isLoading = false;
        });
      }

      // Si todo está completo, mostrar feedback inmediatamente
      if (_currentExerciseIndex >= widget.exercises.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _onLessonComplete();
          }
        });
      }
    } catch (e) {
      // En caso de error, empezar desde el principio sin mostrar el error
      if (mounted) {
        setState(() {
          _currentExerciseIndex = 0;
          _isLoading = false;
        });
      }
    }
  }

  void _onExerciseComplete() {
    // Move to next exercise
    if (_currentExerciseIndex < widget.exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
      });
    } else {
      // All exercises complete - show success and return
      _onLessonComplete();
    }
  }

  Future<void> _onLessonComplete() async {
    // Check if lesson was already completed before
    final wasAlreadyCompleted = await LessonCompletionService.isLessonCompleted(
      widget.lesson.id,
    );

    int starsForCompletion = 0;

    // Only award stars if this is the first time completing the lesson
    if (!wasAlreadyCompleted) {
      starsForCompletion = 20;
      await StarService.addStars(
        starsForCompletion,
        'lesson_complete',
        lessonId: widget.lesson.id,
        description: 'Completaste la lección "${widget.lesson.title}"',
      );

      FirestoreProgressService().saveLessonProgress(
        lessonId: widget.lesson.id,
        starsEarned: starsForCompletion,
        accuracy: 100.0,
      );
    }

    // Save lesson completion (updates the record)
    await LessonCompletionService.saveCompletion(widget.lesson.id);
    MasteryEvaluator.invalidateCache();
    BadgeService.invalidateCache();

    // Check for badge
    final badgeJustAwarded = await BadgeService.checkAndAwardBadge(
      widget.lesson,
    );
    achievement.Badge? badgeToShow;
    if (badgeJustAwarded) {
      final badge = await BadgeService.getBadge(widget.lesson);
      badgeToShow = badge;
    } else {
      final badge = await BadgeService.getBadge(widget.lesson);
      if (badge != null && badge.unlocked) {
        badgeToShow = badge;
      }
    }

    // Navigate to completion screen
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LessonCompletionScreen(
            lessonTitle: widget.lesson.title,
            starsEarned: starsForCompletion,
            correctAnswers: widget.lesson.items.length,
            totalQuestions: widget.lesson.items.length,
            badgeIcon: badgeToShow?.icon,
            badgeTitle: badgeToShow?.title,
            isPerfectScore: true,
            onContinue: () {
              // Return to lessons screen
              Navigator.pop(context, true);
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar loading mientras se determina el ejercicio correcto
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.lesson.title, style: context.appBarTitle),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Si el índice excede los ejercicios, significa que todo está completo
    if (_currentExerciseIndex >= widget.exercises.length) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.lesson.title, style: context.appBarTitle),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Finalizando lección...'),
            ],
          ),
        ),
      );
    }

    final exercise = widget.exercises[_currentExerciseIndex];
    final exerciseCount = widget.exercises.length;

    // Calculate progress offset and scale based on current exercise
    // If there are 2 exercises: MC is 0.0-0.5, Matching is 0.5-1.0
    final progressScale = 1.0 / exerciseCount;
    final progressOffset = _currentExerciseIndex * progressScale;

    // Build the appropriate exercise screen based on type
    Widget exerciseScreen;
    switch (exercise.type) {
      case ExerciseType.multipleChoice:
        exerciseScreen = _MultipleChoiceExerciseWrapper(
          key: ValueKey('mc-$_currentExerciseIndex'),
          lesson: widget.lesson,
          onComplete: _onExerciseComplete,
          progressOffset: progressOffset,
          progressScale: progressScale,
        );
        break;

      case ExerciseType.matching:
        exerciseScreen = _MatchingExerciseWrapper(
          key: ValueKey('matching-$_currentExerciseIndex'),
          lesson: widget.lesson,
          onComplete: _onExerciseComplete,
          progressOffset: progressOffset,
          progressScale: progressScale,
        );
        break;

      // Spelling movido a sección de Práctica
      case ExerciseType.spelling:
      case ExerciseType.listening:
      case ExerciseType.speaking:
        // Por ahora, usar multiple choice como fallback
        exerciseScreen = const Center(
          child: Text('Spelling ahora está en la sección de Práctica'),
        );
        break;
    }

    return Scaffold(body: exerciseScreen);
  }
}

/// Wrapper for multiple choice exercise within the flow
class _MultipleChoiceExerciseWrapper extends StatefulWidget {
  final Lesson lesson;
  final VoidCallback onComplete;
  final double progressOffset;
  final double progressScale;

  const _MultipleChoiceExerciseWrapper({
    super.key,
    required this.lesson,
    required this.onComplete,
    required this.progressOffset,
    required this.progressScale,
  });

  @override
  State<_MultipleChoiceExerciseWrapper> createState() =>
      _MultipleChoiceExerciseWrapperState();
}

class _MultipleChoiceExerciseWrapperState
    extends State<_MultipleChoiceExerciseWrapper> {
  @override
  Widget build(BuildContext context) {
    return LessonScreen(
      key: UniqueKey(),
      lesson: widget.lesson,
      onExerciseCompleted: widget.onComplete,
      progressOffset: widget.progressOffset,
      progressScale: widget.progressScale,
    );
  }
}

/// Wrapper for matching exercise within the flow
class _MatchingExerciseWrapper extends StatefulWidget {
  final Lesson lesson;
  final VoidCallback onComplete;
  final double progressOffset;
  final double progressScale;

  const _MatchingExerciseWrapper({
    super.key,
    required this.lesson,
    required this.onComplete,
    required this.progressOffset,
    required this.progressScale,
  });

  @override
  State<_MatchingExerciseWrapper> createState() =>
      _MatchingExerciseWrapperState();
}

class _MatchingExerciseWrapperState extends State<_MatchingExerciseWrapper> {
  @override
  Widget build(BuildContext context) {
    // Build matching items for animals
    final matchingItems = _buildMatchingItems(widget.lesson.id);

    return MatchingExerciseScreen(
      lessonId: widget.lesson.id,
      title: widget.lesson.title,
      items: matchingItems,
      onComplete: widget.onComplete,
      progressOffset: widget.progressOffset,
      progressScale: widget.progressScale,
    );
  }

  List<MatchingItem> _buildMatchingItems(String lessonId) {
    // Customize matching items based on lesson
    if (lessonId == 'animals') {
      return [
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
        const MatchingItem(
          id: 'chicken',
          imagePath: 'assets/images/animals/chicken.jpg',
          correctWord: 'chicken',
          title: 'Pollo',
        ),
        const MatchingItem(
          id: 'horse',
          imagePath: 'assets/images/animals/horse.jpg',
          correctWord: 'horse',
          title: 'Caballo',
        ),
        const MatchingItem(
          id: 'elephant',
          imagePath: 'assets/images/animals/elephant.jpg',
          correctWord: 'elephant',
          title: 'Elefante',
        ),
        const MatchingItem(
          id: 'bird',
          imagePath: 'assets/images/animals/bird.jpg',
          correctWord: 'bird',
          title: 'Pájaro',
        ),
        const MatchingItem(
          id: 'fish',
          imagePath: 'assets/images/animals/fish.jpg',
          correctWord: 'fish',
          title: 'Pez',
        ),
      ];
    } else if (lessonId == 'family_1') {
      return [
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
    } else if (lessonId == 'numbers') {
      return [
        const MatchingItem(
          id: 'one',
          imagePath: 'assets/images/numbers/one.jpg',
          correctWord: 'one',
          title: 'Uno',
        ),
        const MatchingItem(
          id: 'two',
          imagePath: 'assets/images/numbers/two.jpg',
          correctWord: 'two',
          title: 'Dos',
        ),
        const MatchingItem(
          id: 'three',
          imagePath: 'assets/images/numbers/three.jpg',
          correctWord: 'three',
          title: 'Tres',
        ),
        const MatchingItem(
          id: 'four',
          imagePath: 'assets/images/numbers/four.jpg',
          correctWord: 'four',
          title: 'Cuatro',
        ),
        const MatchingItem(
          id: 'five',
          imagePath: 'assets/images/numbers/five.jpg',
          correctWord: 'five',
          title: 'Cinco',
        ),
        const MatchingItem(
          id: 'six',
          imagePath: 'assets/images/numbers/six.jpg',
          correctWord: 'six',
          title: 'Seis',
        ),
        const MatchingItem(
          id: 'seven',
          imagePath: 'assets/images/numbers/seven.jpg',
          correctWord: 'seven',
          title: 'Siete',
        ),
        const MatchingItem(
          id: 'eight',
          imagePath: 'assets/images/numbers/eight.jpg',
          correctWord: 'eight',
          title: 'Ocho',
        ),
        const MatchingItem(
          id: 'nine',
          imagePath: 'assets/images/numbers/nine.jpg',
          correctWord: 'nine',
          title: 'Nueve',
        ),
        const MatchingItem(
          id: 'ten',
          imagePath: 'assets/images/numbers/ten.jpg',
          correctWord: 'ten',
          title: 'Diez',
        ),
      ];
    } else if (lessonId == 'body_parts') {
      return [
        const MatchingItem(
          id: 'head',
          imagePath: 'assets/images/body_parts/head.jpg',
          correctWord: 'head',
          title: 'Cabeza',
        ),
        const MatchingItem(
          id: 'eye',
          imagePath: 'assets/images/body_parts/eye.jpg',
          correctWord: 'eye',
          title: 'Ojo',
        ),
        const MatchingItem(
          id: 'nose',
          imagePath: 'assets/images/body_parts/nose.jpg',
          correctWord: 'nose',
          title: 'Nariz',
        ),
        const MatchingItem(
          id: 'mouth',
          imagePath: 'assets/images/body_parts/mouth.jpg',
          correctWord: 'mouth',
          title: 'Boca',
        ),
        const MatchingItem(
          id: 'hand',
          imagePath: 'assets/images/body_parts/hand.jpg',
          correctWord: 'hand',
          title: 'Mano',
        ),
        const MatchingItem(
          id: 'foot',
          imagePath: 'assets/images/body_parts/foot.jpg',
          correctWord: 'foot',
          title: 'Pie',
        ),
        const MatchingItem(
          id: 'arm',
          imagePath: 'assets/images/body_parts/arm.jpg',
          correctWord: 'arm',
          title: 'Brazo',
        ),
        const MatchingItem(
          id: 'leg',
          imagePath: 'assets/images/body_parts/leg.jpg',
          correctWord: 'leg',
          title: 'Pierna',
        ),
        const MatchingItem(
          id: 'ear',
          imagePath: 'assets/images/body_parts/ear.jpg',
          correctWord: 'ear',
          title: 'Oreja',
        ),
        const MatchingItem(
          id: 'hair',
          imagePath: 'assets/images/body_parts/hair.jpg',
          correctWord: 'hair',
          title: 'Cabello',
        ),
      ];
    } else if (lessonId == 'clothes') {
      return [
        const MatchingItem(
          id: 'shirt',
          imagePath: 'assets/images/clothes/shirt.jpg',
          correctWord: 'shirt',
          title: 'Camisa',
        ),
        const MatchingItem(
          id: 'pants',
          imagePath: 'assets/images/clothes/pants.jpg',
          correctWord: 'pants',
          title: 'Pantalones',
        ),
        const MatchingItem(
          id: 'dress',
          imagePath: 'assets/images/clothes/dress.jpg',
          correctWord: 'dress',
          title: 'Vestido',
        ),
        const MatchingItem(
          id: 'shoes',
          imagePath: 'assets/images/clothes/shoes.jpg',
          correctWord: 'shoes',
          title: 'Zapatos',
        ),
        const MatchingItem(
          id: 'hat',
          imagePath: 'assets/images/clothes/hat.jpg',
          correctWord: 'hat',
          title: 'Sombrero',
        ),
        const MatchingItem(
          id: 'socks',
          imagePath: 'assets/images/clothes/socks.jpg',
          correctWord: 'socks',
          title: 'Calcetines',
        ),
        const MatchingItem(
          id: 'jacket',
          imagePath: 'assets/images/clothes/jacket.jpg',
          correctWord: 'jacket',
          title: 'Chaqueta',
        ),
        const MatchingItem(
          id: 'skirt',
          imagePath: 'assets/images/clothes/skirt.jpg',
          correctWord: 'skirt',
          title: 'Falda',
        ),
      ];
    } else if (lessonId == 'food_drinks') {
      return [
        const MatchingItem(
          id: 'bread',
          imagePath: 'assets/images/food/bread.jpg',
          correctWord: 'bread',
          title: 'Pan',
        ),
        const MatchingItem(
          id: 'milk',
          imagePath: 'assets/images/food/milk.jpg',
          correctWord: 'milk',
          title: 'Leche',
        ),
        const MatchingItem(
          id: 'water',
          imagePath: 'assets/images/food/water.jpg',
          correctWord: 'water',
          title: 'Agua',
        ),
        const MatchingItem(
          id: 'egg',
          imagePath: 'assets/images/food/egg.jpg',
          correctWord: 'egg',
          title: 'Huevo',
        ),
        const MatchingItem(
          id: 'cheese',
          imagePath: 'assets/images/food/cheese.jpg',
          correctWord: 'cheese',
          title: 'Queso',
        ),
        const MatchingItem(
          id: 'rice',
          imagePath: 'assets/images/food/rice.jpg',
          correctWord: 'rice',
          title: 'Arroz',
        ),
        const MatchingItem(
          id: 'juice',
          imagePath: 'assets/images/food/juice.jpg',
          correctWord: 'juice',
          title: 'Jugo',
        ),
        const MatchingItem(
          id: 'cake',
          imagePath: 'assets/images/food/cake.jpg',
          correctWord: 'cake',
          title: 'Pastel',
        ),
        const MatchingItem(
          id: 'cookie',
          imagePath: 'assets/images/food/cookie.jpg',
          correctWord: 'cookie',
          title: 'Galleta',
        ),
      ];
    } else if (lessonId == 'actions') {
      return [
        const MatchingItem(
          id: 'run',
          imagePath: 'assets/images/actions/run.jpg',
          correctWord: 'run',
          title: 'Correr',
        ),
        const MatchingItem(
          id: 'jump',
          imagePath: 'assets/images/actions/jump.jpg',
          correctWord: 'jump',
          title: 'Saltar',
        ),
        const MatchingItem(
          id: 'eat',
          imagePath: 'assets/images/actions/eat.jpg',
          correctWord: 'eat',
          title: 'Comer',
        ),
        const MatchingItem(
          id: 'sleep',
          imagePath: 'assets/images/actions/sleep.jpg',
          correctWord: 'sleep',
          title: 'Dormir',
        ),
        const MatchingItem(
          id: 'walk',
          imagePath: 'assets/images/actions/walk.jpg',
          correctWord: 'walk',
          title: 'Caminar',
        ),
        const MatchingItem(
          id: 'sit',
          imagePath: 'assets/images/actions/sit.jpg',
          correctWord: 'sit',
          title: 'Sentarse',
        ),
        const MatchingItem(
          id: 'stand',
          imagePath: 'assets/images/actions/stand.jpg',
          correctWord: 'stand',
          title: 'Pararse',
        ),
        const MatchingItem(
          id: 'drink',
          imagePath: 'assets/images/actions/drink.jpg',
          correctWord: 'drink',
          title: 'Beber',
        ),
      ];
    }

    // Para lecciones sin matching items definidos, generar automáticamente desde LessonItem
    return _generateMatchingItemsFromLesson(lessonId);
  }

  /// Genera MatchingItems automáticamente desde los LessonItem de una lección
  List<MatchingItem> _generateMatchingItemsFromLesson(String lessonId) {
    try {
      // Buscar la lección en los datos
      final lesson = lessonsList.firstWhere(
        (l) => l.id == lessonId,
        orElse: () => lessonsList.first,
      );

      // Convertir LessonItem a MatchingItem, solo si tienen imagen
      return lesson.items
          .where(
            (item) =>
                item.stimulusImageAsset != null &&
                item.stimulusImageAsset!.isNotEmpty,
          )
          .map((item) {
            return MatchingItem(
              id: item.id,
              imagePath: item.stimulusImageAsset!,
              correctWord: item.options[item.correctAnswerIndex],
              title: item.title,
            );
          })
          .toList();
    } catch (e) {
      // En caso de error, retornar lista vacía para evitar crash
      return [];
    }
  }
}
