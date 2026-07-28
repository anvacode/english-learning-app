import 'dart:math' show Random;

import 'package:flutter/material.dart';

import '../logic/activity_result_service.dart';
import '../models/activity_result.dart';
import '../models/matching_item.dart';
import '../services/audio_service.dart';
import '../theme/app_colors_extension.dart';
import '../theme/text_styles.dart';
import '../utils/responsive.dart';
import '../widgets/lesson_image.dart';
import '../widgets/responsive_container.dart';
import '../widgets/speaker_button.dart';

class MatchingExerciseScreen extends StatefulWidget {
  final String lessonId;
  final String title;
  final List<MatchingItem> items;
  final VoidCallback? onComplete; // Optional callback for flow orchestration
  final double progressOffset; // Progress offset when used in flow (0.0-1.0)
  final double progressScale; // Progress scale when used in flow (0.0-1.0)

  const MatchingExerciseScreen({
    super.key,
    required this.lessonId,
    required this.title,
    required this.items,
    this.onComplete,
    this.progressOffset = 0.0,
    this.progressScale = 1.0,
  });

  @override
  State<MatchingExerciseScreen> createState() => _MatchingExerciseScreenState();
}

class _MatchingExerciseScreenState extends State<MatchingExerciseScreen> {
  // Track matched pairs
  late Set<String> _matchedIds;

  // Current selection state
  String? _selectedImageId;
  String? _selectedWord;

  // Feedback state
  String? _feedbackMessage;
  bool? _lastCorrect;

  // Audio service
  final AudioService _audioService = AudioService();

  // Shuffled words for randomization
  late List<String> _shuffledWords;

  @override
  void initState() {
    super.initState();
    _matchedIds = {};
    _resetSelection();
    _audioService.initialize();
    _shuffleWords();
  }

  /// Mezcla las palabras para que no aparezcan en el mismo orden que las imágenes
  void _shuffleWords() {
    _shuffledWords = widget.items.map((item) => item.correctWord).toList();
    _shuffledWords.shuffle(Random());
  }

  void _resetSelection() {
    setState(() {
      _selectedImageId = null;
      _selectedWord = null;
      _feedbackMessage = null;
      _lastCorrect = null;
    });
  }

  void _selectImage(String itemId) {
    setState(() {
      _selectedImageId = itemId;
      _feedbackMessage = null;
    });
  }

  void _selectWord(String word) {
    setState(() {
      _selectedWord = word;
      _feedbackMessage = null;
    });
  }

  Future<void> _attemptMatch() async {
    if (_selectedImageId == null || _selectedWord == null) return;

    // Play click sound
    await _audioService.playClickSound();

    // Find the matching item
    final item = widget.items.firstWhere(
      (i) => i.id == _selectedImageId,
      orElse: () => widget.items.first,
    );
    final isCorrect = item.correctWord == _selectedWord;

    if (isCorrect) {
      // Play correct sound
      await _audioService.playCorrectSound();

      // Lock the pair
      setState(() {
        _matchedIds.add(_selectedImageId!);
        _lastCorrect = true;
        _feedbackMessage = '✓ ¡Correcto!';
      });

      // Check if all pairs are matched
      if (_matchedIds.length == widget.items.length) {
        _onExerciseComplete();
      } else {
        // Reset selection after success
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            _resetSelection();
          }
        });
      }
    } else {
      // Play wrong sound
      await _audioService.playWrongSound();

      // Incorrect attempt
      setState(() {
        _lastCorrect = false;
        _feedbackMessage = '✗ Intenta de nuevo';
      });
    }
  }

  Future<void> _onExerciseComplete() async {
    // Save the result
    final result = ActivityResult(
      lessonId: widget.lessonId,
      itemId: 'matching_exercise',
      isCorrect: true,
      timestamp: DateTime.now(),
    );

    await ActivityResultService.saveActivityResult(result);

    // Exercise completed successfully
    // Evaluate lesson progress happens automatically when next item is attempted

    // If onComplete callback is provided (flow mode), call it
    if (widget.onComplete != null) {
      if (mounted) {
        widget.onComplete!();
      }
    } else {
      // Standalone mode: show completion dialog and return
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('¡Felicidades!'),
            content: const Text('Completaste el ejercicio de matching.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(
                    context,
                    true,
                  ); // Return to lessons with true flag
                },
                child: const Text('Continuar'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hPadding = Responsive.scale(context, 12, 16, 20);
    final vPadding = Responsive.scale(context, 10, 14, 18);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: TextStyle(
                fontSize: Responsive.scale(context, 16, 18, 20),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Emparejar palabras con imágenes',
              style: TextStyle(
                fontSize: Responsive.scale(context, 11, 12, 13),
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
      body: ResponsiveContainer(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(hPadding, vPadding, hPadding, vPadding * 0.6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value:
                          widget.progressOffset +
                          (_matchedIds.length / widget.items.length) *
                              widget.progressScale,
                      backgroundColor: context.appColors.surfaceVariant,
                      color: Colors.deepPurple,
                      minHeight: Responsive.scale(context, 6, 8, 10),
                    ),
                    SizedBox(height: Responsive.scale(context, 6, 8, 10)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_matchedIds.length} / ${widget.items.length} parejas',
                          style: TextStyle(
                            fontSize: Responsive.scale(context, 13, 14, 15),
                            fontWeight: FontWeight.w600,
                            color: context.appColors.textPrimary,
                          ),
                        ),
                        if (_matchedIds.length == widget.items.length)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: Responsive.scale(context, 10, 12, 14),
                              vertical: Responsive.scale(context, 4, 5, 6),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '¡Completado!',
                              style: TextStyle(
                                fontSize: Responsive.scale(context, 12, 13, 14),
                                fontWeight: FontWeight.bold,
                                color: Colors.green[800],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    if (width < 600) {
                      return _buildMobileLayout(context, hPadding, vPadding);
                    } else {
                      return _buildTabletDesktopLayout(context, hPadding, vPadding);
                    }
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(hPadding, vPadding * 0.6, hPadding, vPadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_feedbackMessage != null)
                      Padding(
                        padding: EdgeInsets.only(bottom: Responsive.scale(context, 8, 10, 12)),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.scale(context, 16, 20, 24),
                            vertical: Responsive.scale(context, 8, 10, 12),
                          ),
                          decoration: BoxDecoration(
                            color: _lastCorrect! ? Colors.green[50] : Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _lastCorrect! ? Colors.green[200]! : Colors.red[200]!,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _lastCorrect! ? Icons.check_circle : Icons.cancel,
                                color: _lastCorrect! ? Colors.green[700] : Colors.red[700],
                                size: Responsive.scale(context, 18, 20, 22),
                              ),
                              SizedBox(width: Responsive.scale(context, 8, 10, 12)),
                              Text(
                                _feedbackMessage!,
                                style: TextStyle(
                                  fontSize: Responsive.scale(context, 14, 15, 16),
                                  fontWeight: FontWeight.bold,
                                  color: _lastCorrect! ? Colors.green[700] : Colors.red[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      height: Responsive.buttonHeight(context) * 0.9,
                      child: ElevatedButton(
                        onPressed:
                            (_selectedImageId != null && _selectedWord != null)
                            ? _attemptMatch
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          disabledBackgroundColor: context.appColors.surfaceVariant,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Responsive.borderRadius(context)),
                          ),
                          elevation: (_selectedImageId != null && _selectedWord != null) ? 4 : 0,
                        ),
                        child: Text(
                          'Emparejar',
                          style: context.buttonText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, double hPadding, double vPadding) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPadding),
      child: Column(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: Responsive.scale(context, 8, 10, 12)),
                  child: Text(
                    'Imágenes',
                    style: TextStyle(
                      fontSize: Responsive.scale(context, 13, 14, 15),
                      fontWeight: FontWeight.w600,
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: widget.items.length <= 4 ? 2 : 3,
                      crossAxisSpacing: Responsive.scale(context, 8, 10, 12),
                      mainAxisSpacing: Responsive.scale(context, 8, 10, 12),
                    ),
                    itemCount: widget.items.length,
                    itemBuilder: (context, index) {
                      final item = widget.items[index];
                      return _buildImageCard(item);
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: Responsive.scale(context, 12, 16, 20)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: Responsive.scale(context, 8, 10, 12)),
                  child: Text(
                    'Palabras',
                    style: TextStyle(
                      fontSize: Responsive.scale(context, 13, 14, 15),
                      fontWeight: FontWeight.w600,
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: Responsive.scale(context, 8, 10, 12),
                      mainAxisSpacing: Responsive.scale(context, 8, 10, 12),
                    ),
                    itemCount: _shuffledWords.length,
                    itemBuilder: (context, index) {
                      final word = _shuffledWords[index];
                      return _buildWordCard(word);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletDesktopLayout(BuildContext context, double hPadding, double vPadding) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPadding),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: Responsive.scale(context, 10, 12, 14)),
                  child: Text(
                    'Imágenes',
                    style: TextStyle(
                      fontSize: Responsive.scale(context, 14, 15, 16),
                      fontWeight: FontWeight.w600,
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: widget.items
                          .map((item) => _buildImageCard(item))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: Responsive.scale(context, 16, 20, 24)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: Responsive.scale(context, 10, 12, 14)),
                  child: Text(
                    'Palabras',
                    style: TextStyle(
                      fontSize: Responsive.scale(context, 14, 15, 16),
                      fontWeight: FontWeight.w600,
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: _shuffledWords
                          .map((word) => _buildWordCard(word))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(MatchingItem item) {
    final isMatched = _matchedIds.contains(item.id);
    final isSelected = _selectedImageId == item.id;

    return AnimatedScale(
      scale: isMatched ? 0.95 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: AnimatedOpacity(
        opacity: isMatched ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: Responsive.scale(context, 4, 5, 6)),
          child: GestureDetector(
            onTap: isMatched ? null : () => _selectImage(item.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              height: Responsive.scale(context, 85, 90, 95),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? Colors.deepPurple : context.appColors.border,
                  width: isSelected ? 3 : 1.5,
                ),
                borderRadius: BorderRadius.circular(Responsive.borderRadius(context)),
                color: isMatched ? Colors.green[50] : context.appColors.cardBackground,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.deepPurple.withAlpha(76),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: context.appColors.shadow,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Responsive.borderRadius(context) - 2),
                    child: LessonImage(
                      imagePath: item.imagePath,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  if (isMatched)
                    Center(
                      child: Container(
                        width: Responsive.scale(context, 40, 44, 48),
                        height: Responsive.scale(context, 40, 44, 48),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withAlpha(100),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: Responsive.scale(context, 24, 28, 32),
                          ),
                        ),
                      ),
                    ),
                  if (isSelected && !isMatched)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.deepPurple,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.touch_app,
                          color: Colors.white,
                          size: Responsive.scale(context, 16, 18, 20),
                        ),
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

  Widget _buildWordCard(String word) {
    final isSelected = _selectedWord == word;
    final isUsedInMatch = _matchedIds.any(
      (id) =>
          widget.items
              .firstWhere((i) => i.id == id, orElse: () => widget.items.first)
              .correctWord ==
          word,
    );

    return AnimatedScale(
      scale: isUsedInMatch ? 0.95 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: AnimatedOpacity(
        opacity: isUsedInMatch ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: SizedBox(
          width: double.infinity,
          height: Responsive.scale(context, 52, 56, 60),
          child: ElevatedButton(
            onPressed: isUsedInMatch ? null : () => _selectWord(word),
            style: ElevatedButton.styleFrom(
              backgroundColor: isSelected ? Colors.deepPurple : context.appColors.cardBackground,
              disabledBackgroundColor: Colors.green[100],
              elevation: isSelected ? 4 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Responsive.borderRadius(context)),
                side: isSelected
                    ? BorderSide(color: Colors.deepPurple.shade700, width: 2)
                    : BorderSide(color: context.appColors.border, width: 1.5),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.scale(context, 12, 16, 20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isUsedInMatch)
                  Icon(
                    Icons.check_circle,
                    color: Colors.green[700],
                    size: Responsive.scale(context, 18, 20, 22),
                  ),
                Expanded(
                  child: Text(
                    word,
                    style: TextStyle(
                      fontSize: Responsive.scale(context, 14, 15, 16),
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : context.appColors.textPrimary,
                    ),
                  ),
                ),
                if (!isUsedInMatch)
                  SpeakerButton(
                    text: word,
                    iconSize: Responsive.scale(context, 16, 18, 20),
                    buttonSize: Responsive.scale(context, 28, 32, 36),
                    iconColor: isSelected ? Colors.white : Colors.deepPurple,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
