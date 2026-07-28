import 'dart:math';
import 'package:flutter/material.dart';
import '../../data/lessons_data.dart';
import '../../models/lesson_item.dart';
import '../../services/speech_recognition_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_colors_extension.dart';
import '../../utils/responsive.dart';

/// Pantalla de práctica de pronunciación
/// El niño practica pronunciando palabras en inglés y recibe feedback con estrellas
class PronunciationPracticeScreen extends StatefulWidget {
  const PronunciationPracticeScreen({super.key});

  @override
  State<PronunciationPracticeScreen> createState() =>
      _PronunciationPracticeScreenState();
}

class _PronunciationPracticeScreenState
    extends State<PronunciationPracticeScreen> {
  final SpeechRecognitionService _speechService = SpeechRecognitionService();

  bool _isLoading = true;
  bool _isListening = false;
  bool _hasResult = false;

  List<LessonItem> _practiceWords = [];
  int _currentIndex = 0;

  PronunciationResult? _lastResult;
  String _statusMessage = 'Presiona el micrófono y pronuncia la palabra';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);

    // Inicializar servicio de reconocimiento
    final initialized = await _speechService.initialize();

    if (!initialized) {
      setState(() {
        _statusMessage = '❌ No se pudo acceder al micrófono';
        _isLoading = false;
      });
      return;
    }

    // Seleccionar 3-5 palabras aleatorias de todas las lecciones
    _practiceWords = _selectRandomWords();

    setState(() => _isLoading = false);
  }

  List<LessonItem> _selectRandomWords() {
    final allItems = <LessonItem>[];
    for (final lesson in lessonsList) {
      allItems.addAll(lesson.items);
    }

    // Seleccionar 3-5 palabras aleatorias
    final random = Random();
    final count = 3 + random.nextInt(3); // 3, 4 o 5 palabras

    if (allItems.length <= count) return allItems;

    final selected = <LessonItem>[];
    final indices = <int>{};

    while (indices.length < count) {
      indices.add(random.nextInt(allItems.length));
    }

    for (final index in indices) {
      selected.add(allItems[index]);
    }

    return selected;
  }

  Future<void> _startListening() async {
    if (_practiceWords.isEmpty) return;

    setState(() {
      _isListening = true;
      _hasResult = false;
      _statusMessage = '🎤 Escuchando...';
    });

    final currentWord = _practiceWords[_currentIndex];
    final targetWord = currentWord.options[currentWord.correctAnswerIndex];

    // Escuchar y evaluar
    final result = await _speechService.listenAndEvaluate(targetWord);

    if (mounted) {
      setState(() {
        _isListening = false;
        _hasResult = true;
        _lastResult = result;
        _statusMessage = result.message;
      });
    }
  }

  void _nextWord() {
    if (_currentIndex < _practiceWords.length - 1) {
      setState(() {
        _currentIndex++;
        _hasResult = false;
        _lastResult = null;
        _statusMessage = 'Presiona el micrófono y pronuncia la palabra';
      });
    } else {
      // Mostrar resultados finales
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 ¡Práctica completada!'),
        content: Text(
          'Has practicado ${_practiceWords.length} palabras.\n\n'
          '¡Sigue practicando para mejorar tu pronunciación!',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Terminar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _restartPractice();
            },
            child: const Text('Practicar de nuevo'),
          ),
        ],
      ),
    );
  }

  void _restartPractice() {
    setState(() {
      _practiceWords = _selectRandomWords();
      _currentIndex = 0;
      _hasResult = false;
      _lastResult = null;
      _statusMessage = 'Presiona el micrófono y pronuncia la palabra';
    });
  }

  Widget _buildStarRating(int rating) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: index < rating ? AppColors.starGold : context.appColors.textTertiary,
          size: 40,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Práctica de Pronunciación')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_practiceWords.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Práctica de Pronunciación')),
        body: const Center(
          child: Text('No hay palabras disponibles para practicar'),
        ),
      );
    }

    final currentWord = _practiceWords[_currentIndex];
    final targetWord = currentWord.options[currentWord.correctAnswerIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('🎤 Práctica de Pronunciación'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${_currentIndex + 1}/${_practiceWords.length}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(Responsive.scale(context, 16, 24, 32)),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: (_currentIndex + 1) / _practiceWords.length,
                backgroundColor: context.appColors.surfaceVariant,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              SizedBox(height: Responsive.scale(context, 24, 32, 36)),
              Container(
                width: Responsive.scale(context, 160, 200, 220),
                height: Responsive.scale(context, 160, 200, 220),
                decoration: BoxDecoration(
                  color: context.appColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(Responsive.scale(context, 16, 20, 24)),
                  boxShadow: [
                    BoxShadow(
                      color: context.appColors.shadow,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Responsive.scale(context, 16, 20, 24)),
                  child: currentWord.stimulusImageAsset != null
                      ? Image.asset(
                          currentWord.stimulusImageAsset!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: currentWord.stimulusColor,
                              child: Icon(Icons.image, size: Responsive.scale(context, 60, 80, 90), color: Colors.white),
                            );
                          },
                        )
                      : Container(
                          color: currentWord.stimulusColor,
                          child: Icon(Icons.image, size: Responsive.scale(context, 60, 80, 90), color: Colors.white),
                        ),
                ),
              ),
              SizedBox(height: Responsive.scale(context, 24, 32, 36)),
              Text(
                targetWord,
                style: TextStyle(
                  fontSize: Responsive.scale(context, 36, 42, 48),
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: Responsive.scale(context, 6, 8, 10)),
              Text(
                'Pronuncia esta palabra',
                style: TextStyle(fontSize: Responsive.scale(context, 14, 16, 18), color: context.appColors.textSecondary),
              ),
              SizedBox(height: Responsive.scale(context, 28, 40, 44)),
              if (_hasResult && _lastResult != null) ...[
                _buildStarRating(_lastResult!.starRating),
                SizedBox(height: Responsive.scale(context, 12, 16, 20)),
                Text(
                  _lastResult!.message,
                  style: TextStyle(
                    fontSize: Responsive.scale(context, 18, 20, 22),
                    fontWeight: FontWeight.bold,
                    color: _lastResult!.isCorrect ? Colors.green[700] : Colors.orange[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                if (!_lastResult!.isCorrect) ...[
                  SizedBox(height: Responsive.scale(context, 6, 8, 10)),
                  Text(
                    'Escuchado: "${_lastResult!.recognizedText}"',
                    style: TextStyle(
                      fontSize: Responsive.scale(context, 14, 16, 18),
                      color: context.appColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                SizedBox(height: Responsive.scale(context, 24, 32, 36)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!_lastResult!.isCorrect)
                      ElevatedButton.icon(
                        onPressed: _startListening,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.scale(context, 20, 24, 28),
                            vertical: Responsive.scale(context, 10, 12, 14),
                          ),
                        ),
                      ),
                    if (!_lastResult!.isCorrect) SizedBox(width: Responsive.scale(context, 12, 16, 20)),
                    ElevatedButton.icon(
                      onPressed: _nextWord,
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(
                        _currentIndex < _practiceWords.length - 1 ? 'Siguiente' : 'Finalizar',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.scale(context, 20, 24, 28),
                          vertical: Responsive.scale(context, 10, 12, 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                GestureDetector(
                  onTap: _isListening ? null : _startListening,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: Responsive.scale(context, 100, 120, 140),
                    height: Responsive.scale(context, 100, 120, 140),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening ? Colors.red : AppColors.primary,
                      boxShadow: [
                        BoxShadow(
                          color: (_isListening ? Colors.red : AppColors.primary).withAlpha(100),
                          blurRadius: _isListening ? 30 : 15,
                          spreadRadius: _isListening ? 10 : 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      size: Responsive.scale(context, 48, 60, 72),
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: Responsive.scale(context, 16, 24, 28)),
                Text(
                  _statusMessage,
                  style: TextStyle(
                    fontSize: Responsive.scale(context, 16, 18, 20),
                    color: context.appColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _speechService.dispose();
    super.dispose();
  }
}
