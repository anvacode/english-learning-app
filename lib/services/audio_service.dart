import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para manejar audio, text-to-speech y efectos de sonido.
///
/// Proporciona funcionalidad para:
/// - Text-to-speech (TTS) para pronunciación de palabras
/// - Efectos de sonido (correcto, incorrecto, clic)
/// - Configuración de audio (auto-speak, volumen, etc.)
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  FlutterTts? _flutterTts;
  // AudioPlayer para efectos de sonido
  final AudioPlayer _soundPlayer = AudioPlayer();

  // Configuración por defecto
  bool _autoSpeakEnabled = true;
  bool _soundsEnabled = true;
  String _language = 'en-US';
  double _pitch = 1.0;
  double _rate = 0.5;

  bool _isInitialized = false;

  /// Inicializa el servicio de audio.
  ///
  /// Debe llamarse antes de usar cualquier funcionalidad de audio.
  Future<void> initialize() async {
    if (_isInitialized) return;

    _flutterTts = FlutterTts();

    // Configurar TTS
    await _flutterTts!.setLanguage(_language);
    await _flutterTts!.setSpeechRate(_rate);
    await _flutterTts!.setPitch(_pitch);
    await _flutterTts!.setVolume(1.0);

    // Cargar preferencias guardadas
    await _loadPreferences();

    _isInitialized = true;
  }

  /// Carga las preferencias de audio desde SharedPreferences.
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _autoSpeakEnabled = prefs.getBool('audio_auto_speak') ?? true;
    _soundsEnabled = prefs.getBool('audio_sounds_enabled') ?? true;
    _pitch = prefs.getDouble('audio_pitch') ?? 1.0;
    _rate = prefs.getDouble('audio_rate') ?? 0.5;
  }

  /// Guarda las preferencias de audio en SharedPreferences.
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('audio_auto_speak', _autoSpeakEnabled);
    await prefs.setBool('audio_sounds_enabled', _soundsEnabled);
    await prefs.setDouble('audio_pitch', _pitch);
    await prefs.setDouble('audio_rate', _rate);
  }

  /// Establece el idioma para TTS.
  ///
  /// [language] debe ser un código de idioma válido (ej: 'en-US', 'es-ES').
  Future<void> setLanguage(String language) async {
    _language = language;
    if (_flutterTts != null) {
      await _flutterTts!.setLanguage(language);
    }
  }

  /// Establece el pitch (tono) para TTS.
  ///
  /// [pitch] debe estar entre 0.5 y 2.0. Valor por defecto: 1.0.
  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 2.0);
    if (_flutterTts != null) {
      await _flutterTts!.setPitch(_pitch);
    }
    await _savePreferences();
  }

  /// Establece la velocidad de habla para TTS.
  ///
  /// [rate] debe estar entre 0.0 y 1.0. Valor por defecto: 0.5 (lento para niños).
  Future<void> setRate(double rate) async {
    _rate = rate.clamp(0.0, 1.0);
    if (_flutterTts != null) {
      await _flutterTts!.setSpeechRate(_rate);
    }
    await _savePreferences();
  }

  /// Habilita o deshabilita el auto-speak.
  ///
  /// Cuando está habilitado, las palabras se pronuncian automáticamente
  /// cuando aparece una nueva pregunta.
  Future<void> setAutoSpeak(bool enabled) async {
    _autoSpeakEnabled = enabled;
    await _savePreferences();
  }

  /// Habilita o deshabilita los efectos de sonido.
  Future<void> setSoundsEnabled(bool enabled) async {
    _soundsEnabled = enabled;
    await _savePreferences();
  }

  /// Pronuncia un texto usando TTS.
  ///
  /// [text] es el texto a pronunciar.
  /// Retorna un Future que se completa cuando termina la pronunciación.
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_flutterTts != null && text.isNotEmpty) {
      await _flutterTts!.speak(text);
    }
  }

  /// Detiene la pronunciación actual.
  Future<void> stop() async {
    if (_flutterTts != null) {
      await _flutterTts!.stop();
    }
  }

  /// Pronuncia automáticamente un texto si auto-speak está habilitado.
  ///
  /// Útil para pronunciar palabras cuando aparece una nueva pregunta.
  Future<void> autoSpeak(String text) async {
    if (_autoSpeakEnabled) {
      await speak(text);
    }
  }

  /// Reproduce un sonido de respuesta correcta.
  ///
  /// Usa un tono ascendente agradable para niños.
  /// NOTA: Requiere archivo assets/sounds/correct.mp3
  Future<void> playCorrectSound() async {
    if (!_soundsEnabled) return;

    try {
      await _soundPlayer.play(AssetSource('sounds/correct.mp3'));
    } catch (e) {
      debugPrint('Audio correct sound not available: $e');
    }
  }

  /// Reproduce un sonido de respuesta incorrecta.
  ///
  /// Usa un tono suave y alentador.
  /// NOTA: Requiere archivo assets/sounds/wrong.mp3
  Future<void> playWrongSound() async {
    if (!_soundsEnabled) return;

    try {
      await _soundPlayer.play(AssetSource('sounds/wrong.mp3'));
    } catch (e) {
      debugPrint('Audio wrong sound not available: $e');
    }
  }

  /// Reproduce un sonido de clic de botón.
  /// NOTA: Requiere archivo assets/sounds/click.mp3
  Future<void> playClickSound() async {
    if (!_soundsEnabled) return;

    try {
      await _soundPlayer.play(AssetSource('sounds/click.mp3'));
    } catch (e) {
      debugPrint('Audio click sound not available: $e');
    }
  }

  /// Libera los recursos del AudioPlayer
  void dispose() {
    _soundPlayer.dispose();
  }

  /// Libera la instancia singleton (llamar al cerrar la app)
  static void disposeInstance() {
    _instance.dispose();
  }

  // Getters para el estado actual
  bool get autoSpeakEnabled => _autoSpeakEnabled;
  bool get soundsEnabled => _soundsEnabled;
  double get pitch => _pitch;
  double get rate => _rate;
  String get language => _language;
}
