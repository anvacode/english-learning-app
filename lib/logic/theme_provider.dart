import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gestiona el modo de tema de la aplicación (claro / oscuro / sistema).
///
/// El modo elegido se persiste en [SharedPreferences] y se aplica al
/// [MaterialApp] mediante [ThemeMode]. Sigue el mismo patrón de
/// persistencia que `AudioService`.
class ThemeProvider extends ChangeNotifier {
  static const String _prefsKey = 'theme_mode';

  ThemeMode _mode = ThemeMode.system;
  bool _loaded = false;

  ThemeProvider() {
    _loadFromPrefs();
  }

  /// Modo de tema actual.
  ThemeMode get mode => _mode;

  /// `true` cuando ya se cargó la preferencia guardada.
  bool get loaded => _loaded;

  /// `true` si el usuario fijó explícitamente el tema oscuro.
  bool get isDarkMode => _mode == ThemeMode.dark;

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_prefsKey);
    _mode = _parseMode(value);
    _loaded = true;
    notifyListeners();
  }

  /// Recarga la preferencia (útil tras restablecer los datos de la app).
  Future<void> reload() => _loadFromPrefs();

  /// Cambia el modo de tema y lo persiste.
  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, _serializeMode(mode));
  }

  static ThemeMode _parseMode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  static String _serializeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
