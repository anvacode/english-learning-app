import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Modelo para el resultado del reconocimiento de voz
class PronunciationResult {
  final String recognizedText;
  final double confidence;
  final int starRating;
  final bool isCorrect;
  final String message;

  PronunciationResult({
    required this.recognizedText,
    required this.confidence,
    required this.starRating,
    required this.isCorrect,
    required this.message,
  });
}

/// Servicio para reconocimiento de voz y evaluación de pronunciación
class SpeechRecognitionService {
  static final SpeechRecognitionService _instance =
      SpeechRecognitionService._internal();
  factory SpeechRecognitionService() => _instance;
  SpeechRecognitionService._internal();

  static bool _disposed = false;

  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  String _lastWords = '';

  // Stream controller para resultados en tiempo real
  final StreamController<String> _wordsController =
      StreamController<String>.broadcast();
  Stream<String> get wordsStream => _wordsController.stream;

  /// Inicializa el servicio de reconocimiento de voz
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Solicitar permiso de micrófono
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        debugPrint('Permiso de micrófono denegado');
        return false;
      }

      // Inicializar speech_to_text
      _isInitialized = await _speech.initialize(
        onError: (error) => debugPrint('Error de reconocimiento: $error'),
        onStatus: (status) => debugPrint('Estado: $status'),
      );

      return _isInitialized;
    } catch (e) {
      debugPrint('Error inicializando SpeechRecognitionService: $e');
      return false;
    }
  }

  /// Verifica si el servicio está escuchando
  bool get isListening => _isListening;

  /// Verifica si está inicializado
  bool get isInitialized => _isInitialized;

  /// Inicia la escucha para reconocer una palabra
  Future<void> startListening() async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return;
    }

    if (_isListening) {
      await stopListening();
    }

    _lastWords = '';
    _isListening = true;

    try {
      await _speech.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          _wordsController.add(_lastWords);
        },
        listenFor: const Duration(seconds: 5),
        pauseFor: const Duration(seconds: 2),
        localeId: 'en_US',
      );
    } catch (e) {
      debugPrint('Error al iniciar escucha: $e');
      _isListening = false;
    }
  }

  /// Detiene la escucha
  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }

  /// Escucha y evalúa la pronunciación de una palabra objetivo
  Future<PronunciationResult> listenAndEvaluate(
    String targetWord, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        return PronunciationResult(
          recognizedText: '',
          confidence: 0.0,
          starRating: 0,
          isCorrect: false,
          message: '❌ No se pudo inicializar el micrófono',
        );
      }
    }

    // Limpiar resultado anterior
    _lastWords = '';

    // Iniciar escucha con timeout
    await startListening();

    // Esperar el tiempo especificado
    await Future.delayed(timeout);

    // Detener escucha
    await stopListening();

    // Si no se reconoció nada
    if (_lastWords.isEmpty) {
      return PronunciationResult(
        recognizedText: '',
        confidence: 0.0,
        starRating: 0,
        isCorrect: false,
        message: '🔇 No se detectó voz. Intenta hablar más fuerte.',
      );
    }

    // Evaluar la pronunciación
    return _evaluatePronunciation(_lastWords, targetWord);
  }

  /// Escucha y evalúa la pronunciación de una frase (tiempo más largo)
  Future<PronunciationResult> listenAndEvaluatePhrase(
    String targetPhrase, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        return PronunciationResult(
          recognizedText: '',
          confidence: 0.0,
          starRating: 0,
          isCorrect: false,
          message: '❌ No se pudo inicializar el micrófono',
        );
      }
    }

    _lastWords = '';
    _isListening = true;

    try {
      await _speech.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          _wordsController.add(_lastWords);
        },
        listenFor: timeout,
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_US',
      );

      await Future.delayed(timeout);
      await stopListening();

      if (_lastWords.isEmpty) {
        return PronunciationResult(
          recognizedText: '',
          confidence: 0.0,
          starRating: 0,
          isCorrect: false,
          message: '🔇 No se detectó voz. Intenta hablar más claro y fuerte.',
        );
      }

      return _evaluatePhrase(_lastWords, targetPhrase);
    } catch (e) {
      debugPrint('Error evaluando frase: $e');
      return PronunciationResult(
        recognizedText: '',
        confidence: 0.0,
        starRating: 0,
        isCorrect: false,
        message: '❌ Error al evaluar. Intenta de nuevo.',
      );
    }
  }

  /// Evalúa la pronunciación de una frase con algoritmo más tolerante
  PronunciationResult _evaluatePhrase(String recognized, String target) {
    final normalizedRecognized = _normalizeText(recognized);
    final normalizedTarget = _normalizeText(target);

    double similarity;

    // Para frases, usamos word-based similarity (más tolerante)
    final recognizedWords = normalizedRecognized.split(' ');
    final targetWords = normalizedTarget.split(' ');

    final matchingWords = recognizedWords
        .where(
          (word) => targetWords.any(
            (target) => _calculateSimilarity(word, target) >= 0.7,
          ),
        )
        .length;

    if (targetWords.isEmpty) {
      similarity = 0.0;
    } else {
      // Combinar similarity de palabras con Levenshtein general
      final wordSimilarity = matchingWords / targetWords.length;
      final levenshteinSimilarity = _calculateSimilarity(
        normalizedRecognized,
        normalizedTarget,
      );

      // Peso mayor para las palabras que coinciden
      similarity = (wordSimilarity * 0.7) + (levenshteinSimilarity * 0.3);
    }

    final starRating = _calculateStarRating(similarity);
    final isCorrect = similarity >= 0.7;
    final message = _generatePhraseFeedbackMessage(
      starRating,
      isCorrect,
      recognized,
      target,
    );

    return PronunciationResult(
      recognizedText: recognized,
      confidence: similarity,
      starRating: starRating,
      isCorrect: isCorrect,
      message: message,
    );
  }

  /// Genera feedback específico para frases
  String _generatePhraseFeedbackMessage(
    int starRating,
    bool isCorrect,
    String recognized,
    String target,
  ) {
    if (isCorrect) {
      switch (starRating) {
        case 5:
          return '🌟 ¡Perfecto! ¡Excellent pronunciation!';
        case 4:
          return '⭐ ¡Muy bien! Great job!';
        case 3:
          return '👍 ¡Bien! Keep practicing!';
        default:
          return '✅ ¡Correcto!';
      }
    } else {
      final recognizedWords = recognized.toLowerCase().split(' ').length;
      final targetWords = target.toLowerCase().split(' ').length;

      if (recognizedWords < targetWords * 0.5) {
        return '💬 Intenta decir todas las palabras de la frase';
      } else if (recognizedWords > targetWords * 1.5) {
        return '💬 Hablaste muy rápido. Intenta más lento';
      } else {
        return '💪 ¡Casi! Intenta mejorar la pronunciación';
      }
    }
  }

  /// Evalúa la pronunciación comparando el texto reconocido con el objetivo
  PronunciationResult _evaluatePronunciation(String recognized, String target) {
    // Normalizar ambos textos
    final normalizedRecognized = _normalizeText(recognized);
    final normalizedTarget = _normalizeText(target);

    // Calcular similitud
    final similarity = _calculateSimilarity(
      normalizedRecognized,
      normalizedTarget,
    );

    // Determinar rating de estrellas (1-5)
    final starRating = _calculateStarRating(similarity);

    // Determinar si es correcto (80%+ similaridad)
    final isCorrect = similarity >= 0.8;

    // Generar mensaje de retroalimentación
    final message = _generateFeedbackMessage(starRating, isCorrect);

    return PronunciationResult(
      recognizedText: recognized,
      confidence: similarity,
      starRating: starRating,
      isCorrect: isCorrect,
      message: message,
    );
  }

  /// Normaliza el texto para comparación
  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Quitar puntuación
        .replaceAll(RegExp(r'\s+'), ' '); // Normalizar espacios
  }

  /// Calcula la similitud entre dos textos (0.0 a 1.0)
  double _calculateSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    // Calcular distancia de Levenshtein
    final distance = _levenshteinDistance(s1, s2);
    final maxLength = s1.length > s2.length ? s1.length : s2.length;

    return 1.0 - (distance / maxLength);
  }

  /// Calcula la distancia de Levenshtein entre dos strings
  int _levenshteinDistance(String s1, String s2) {
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    final List<List<int>> matrix = List.generate(
      s1.length + 1,
      (i) => List<int>.filled(s2.length + 1, 0),
    );

    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1, // eliminación
          matrix[i][j - 1] + 1, // inserción
          matrix[i - 1][j - 1] + cost, // sustitución
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[s1.length][s2.length];
  }

  /// Calcula el rating de estrellas (1-5) basado en la similitud
  int _calculateStarRating(double similarity) {
    if (similarity >= 0.95) return 5;
    if (similarity >= 0.8) return 4;
    if (similarity >= 0.6) return 3;
    if (similarity >= 0.4) return 2;
    return 1;
  }

  /// Genera un mensaje de retroalimentación basado en el rating
  String _generateFeedbackMessage(int starRating, bool isCorrect) {
    if (isCorrect) {
      switch (starRating) {
        case 5:
          final messages = [
            '🌟 ¡Perfecto! ¡Excelente pronunciación!',
            '🎉 ¡Increíble! Suenas como un nativo',
            '🏆 ¡Fantástico! Lo hiciste genial',
          ];
          return messages[Random().nextInt(messages.length)];
        case 4:
          final messages = [
            '⭐ ¡Muy bien! Casi perfecto',
            '👏 ¡Excelente trabajo!',
            '💪 ¡Muy buena pronunciación!',
          ];
          return messages[Random().nextInt(messages.length)];
        default:
          return '✅ ¡Correcto!';
      }
    } else {
      switch (starRating) {
        case 3:
          return '👍 ¡Bien! Sigue practicando';
        case 2:
          return '💪 ¡Casi! Intenta de nuevo';
        case 1:
          return '🔄 Sigue practicando, ¡tú puedes!';
        default:
          return '🎤 Intenta hablar más claro';
      }
    }
  }

  /// Libera recursos
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _wordsController.close();
    if (_isListening) {
      _speech.stop();
    }
  }

  /// Libera la instancia singleton (llamar al cerrar la app)
  static void disposeInstance() {
    _instance.dispose();
  }
}
