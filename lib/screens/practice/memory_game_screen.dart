import 'dart:async';
import 'dart:math' show Random;

import 'package:flutter/material.dart';

import '../../data/lessons_data.dart';
import '../../logic/activity_result_service.dart';
import '../../logic/practice_service.dart';
import '../../logic/star_service.dart';
import '../../models/activity_result.dart';
import '../../services/audio_service.dart';
import '../../theme/app_colors_extension.dart';
import '../../theme/text_styles.dart';
import '../../utils/responsive.dart';
import '../../widgets/animated_progress_bar.dart';
import '../../widgets/lesson_image.dart';

class MemoryCard {
  final String id;
  final String imagePath;
  final Color? color;
  final String word;
  final bool isColorCard;
  bool isFlipped;
  bool isMatched;
  
  MemoryCard({
    required this.id,
    required this.imagePath,
    required this.word,
    this.color,
    this.isColorCard = false,
    this.isFlipped = false,
    this.isMatched = false,
  });
}

/// Pantalla de juego de memoria:
/// - Encuentra los pares de cartas (imagen + palabra)
/// - Entrena la memoria visual y el vocabulario
class MemoryGameScreen extends StatefulWidget {
  final String lessonId;
  
  const MemoryGameScreen({
    super.key,
    required this.lessonId,
  });
  
  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen> with SingleTickerProviderStateMixin {
  late List<MemoryCard> _cards;
  List<int> _flippedIndices = [];
  bool _isProcessing = false;
  
  int _moves = 0;
  int _matches = 0;
  Timer? _timer;
  int _elapsedSeconds = 0;
  
  final AudioService _audioService = AudioService();
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _initializeGame();
    _audioService.initialize();
    _startTimer();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }
  
  void _initializeGame() {
    // Find the lesson
    final lesson = lessonsList.firstWhere(
      (l) => l.id == widget.lessonId,
      orElse: () => lessonsList.first,
    );
    
    // Take first 6 items (12 cards total - 6 pairs)
    final items = lesson.items.take(6).toList();
    
    _cards = [];
    
    // Create pairs: each item creates 2 cards
    for (var item in items) {
      final word = item.options[item.correctAnswerIndex];
      
      // Card 1: Image or Color (no text)
      _cards.add(MemoryCard(
        id: '${item.id}_img',
        imagePath: item.stimulusImageAsset ?? '',
        word: word,
        color: item.stimulusColor,
        isColorCard: item.stimulusImageAsset == null || item.stimulusImageAsset!.isEmpty,
      ));
      
      // Card 2: Text (word on pale background)
      _cards.add(MemoryCard(
        id: '${item.id}_txt',
        imagePath: '',
        word: word,
        color: Colors.blue[100],
        isColorCard: false,
      ));
    }
    
    // Shuffle cards
    _cards.shuffle(Random());
    
    _moves = 0;
    _matches = 0;
    _flippedIndices = [];
  }
  
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }
  
  Future<void> _onCardTap(int index) async {
    if (_isProcessing ||
        _cards[index].isFlipped ||
        _cards[index].isMatched ||
        _flippedIndices.length >= 2) {
      return;
    }
    
    await _audioService.playClickSound();
    
    setState(() {
      _cards[index].isFlipped = true;
      _flippedIndices.add(index);
    });
    
    if (_flippedIndices.length == 2) {
      _isProcessing = true;
      _moves++;
      await _checkMatch();
    }
  }
  
  Future<void> _checkMatch() async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    final firstIndex = _flippedIndices[0];
    final secondIndex = _flippedIndices[1];
    
    final firstCard = _cards[firstIndex];
    final secondCard = _cards[secondIndex];
    
    // Check if they match (same word)
    final isMatch = firstCard.word == secondCard.word;
    
    if (isMatch) {
      await _audioService.playCorrectSound();
      
      setState(() {
        _cards[firstIndex].isMatched = true;
        _cards[secondIndex].isMatched = true;
        _matches++;
      });
      
      // Save result
      await ActivityResultService.saveActivityResult(
        ActivityResult(
          lessonId: widget.lessonId,
          itemId: '${firstCard.word}_memory',
          isCorrect: true,
          timestamp: DateTime.now(),
        ),
      );
      
      // Check if game is complete
      if (_matches == _cards.length ~/ 2) {
        await _finishGame();
      }
    } else {
      await _audioService.playWrongSound();
      
      await Future.delayed(const Duration(milliseconds: 400));
      
      setState(() {
        _cards[firstIndex].isFlipped = false;
        _cards[secondIndex].isFlipped = false;
      });
    }
    
    setState(() {
      _flippedIndices.clear();
      _isProcessing = false;
    });
  }
  
  Future<void> _finishGame() async {
    _timer?.cancel();
    
    // Calculate stars based on performance
    int stars = 10; // Base stars
    
    // Bonus for efficiency (fewer moves)
    final idealMoves = _cards.length ~/ 2 + 2;
    if (_moves <= idealMoves) {
      stars += 10; // Perfect efficiency
    } else if (_moves <= idealMoves + 3) {
      stars += 5; // Good efficiency
    }
    
    // Time bonus (faster = more stars)
    if (_elapsedSeconds < 60) {
      stars += 5;
    }
    
    // Update practice progress - el total de ejercicios es la mitad de las cartas (pares)
    final totalExercises = _cards.length ~/ 2;
    final activityId = '${widget.lessonId}_memory';
    await PracticeService.updateProgress(
      activityId: activityId,
      totalExercises: totalExercises,
      exercisesCompleted: totalExercises, // Todas las parejas completadas
      starsEarned: stars,
      newScore: totalExercises,
    );
    
    await StarService.addStars(
      stars,
      'memory_game',
      lessonId: widget.lessonId,
      description: 'Juego de Memoria completado',
    );
    
    if (!mounted) return;
    
    // Show results dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 ¡Completado!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              'Movimientos: $_moves',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Tiempo: ${_formatTime(_elapsedSeconds)}',
              style: const TextStyle(fontSize: 18),
            ),
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
                _initializeGame();
                _elapsedSeconds = 0;
                _startTimer();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
            ),
            child: const Text('Jugar de Nuevo'),
          ),
        ],
      ),
    );
  }
  
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final progress = _matches / (_cards.length / 2);
    final hPadding = Responsive.horizontalPadding(context);
    final vPadding = Responsive.verticalPadding(context);
    final isDesktop = !Responsive.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('🖼️ Memory Game', style: context.appBarTitle),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: hPadding),
            child: Center(
              child: _buildStatsRow(context),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          AnimatedProgressBar(
            progress: progress,
            color: Colors.purple,
            label: '$_matches/${_cards.length ~/ 2}',
          ),
          Expanded(
            child: isDesktop
                ? _buildDesktopLayout(context, hPadding, vPadding)
                : _buildMobileLayout(context, hPadding, vPadding),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.timer, size: Responsive.scale(context, 16, 18, 20)),
        SizedBox(width: Responsive.scale(context, 3, 4, 5)),
        Text(
          _formatTime(_elapsedSeconds),
          style: TextStyle(
            fontSize: Responsive.scale(context, 14, 15, 16),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: Responsive.scale(context, 10, 12, 16)),
        Icon(Icons.touch_app, size: Responsive.scale(context, 16, 18, 20)),
        SizedBox(width: Responsive.scale(context, 3, 4, 5)),
        Text(
          '$_moves',
          style: TextStyle(
            fontSize: Responsive.scale(context, 14, 15, 16),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, double hPadding, double vPadding) {
    final gridSpacing = Responsive.scale(context, 6, 8, 10);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
      child: Column(
        children: [
          Text(
            '¡Encuentra los pares!',
            style: TextStyle(
              fontSize: Responsive.scale(context, 16, 18, 20),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: Responsive.scale(context, 4, 6, 8)),
          Text(
            'Emparejamientos: $_matches/${_cards.length ~/ 2}',
            style: TextStyle(
              fontSize: Responsive.scale(context, 13, 14, 15),
              color: Colors.purple,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: Responsive.scale(context, 8, 10, 12)),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: gridSpacing,
                mainAxisSpacing: gridSpacing,
                childAspectRatio: 0.85,
              ),
              itemCount: _cards.length,
              itemBuilder: (context, index) => _buildCard(context, index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, double hPadding, double vPadding) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '¡Encuentra los pares!',
                style: TextStyle(
                  fontSize: Responsive.scale(context, 20, 22, 24),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.scale(context, 12, 14, 16),
                  vertical: Responsive.scale(context, 6, 8, 10),
                ),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Emparejamientos: $_matches/${_cards.length ~/ 2}',
                  style: TextStyle(
                    fontSize: Responsive.scale(context, 15, 16, 18),
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.scale(context, 12, 16, 20)),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 800, maxHeight: 350),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: _cards.length,
                  itemBuilder: (context, index) => _buildCard(context, index),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, int index) {
    final card = _cards[index];
    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: card.isMatched
              ? Colors.green[100]
              : card.isFlipped
                  ? context.appColors.cardBackground
                  : Colors.purple,
          borderRadius: BorderRadius.circular(Responsive.borderRadius(context)),
          border: Border.all(
            color: card.isMatched
                ? Colors.green
                : card.isFlipped
                    ? Colors.purple
                    : Colors.purple[700]!,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: context.appColors.shadow,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Responsive.borderRadius(context) - 2),
          child: card.isFlipped || card.isMatched
              ? _buildCardFront(card)
              : _buildCardBack(),
        ),
      ),
    );
  }

  Widget _buildCardFront(MemoryCard card) {
    if (card.imagePath.isNotEmpty) {
      return LessonImage(
        imagePath: card.imagePath,
        fallbackColor: card.color,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    } else if (card.isColorCard) {
      return Container(
        color: card.color,
      );
    } else {
      return Container(
        color: card.color,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(Responsive.scale(context, 3, 4, 6)),
            child: Text(
              card.word,
              style: TextStyle(
                fontSize: Responsive.scale(context, 10, 12, 14),
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildCardBack() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[400]!, Colors.purple[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.question_mark,
          color: Colors.white,
          size: Responsive.scale(context, 20, 24, 28),
        ),
      ),
    );
  }
}
