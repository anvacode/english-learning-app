import 'package:shared_preferences/shared_preferences.dart';

/// Servicio que gestiona el estado del tutorial interactivo y estático.
///
/// Usa SharedPreferences para recordar si el usuario ya vio el tutorial
/// y si completó el tour interactivo.
class TutorialService {
  static const String _tutorialCompletedKey = 'tutorial_completed';
  static const String _interactiveTutorialShownKey = 'interactive_tutorial_shown';
  static const String _requestInteractiveTutorialKey = 'request_interactive_tutorial';

  /// Solicita que el tour interactivo se muestre en el próximo HomeScreen.
  static Future<void> requestInteractiveTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_requestInteractiveTutorialKey, true);
  }

  /// Verifica si hay una solicitud pendiente del tour interactivo.
  static Future<bool> wasInteractiveTutorialRequested() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_requestInteractiveTutorialKey) ?? false;
  }

  /// Limpia la solicitud del tour interactivo después de mostrarlo.
  static Future<void> clearInteractiveTutorialRequest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_requestInteractiveTutorialKey, false);
  }

  /// Verifica si el tutorial estático fue completado (visto hasta el final).
  static Future<bool> isTutorialCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tutorialCompletedKey) ?? false;
  }

  /// Marca el tutorial como completado.
  static Future<void> markTutorialCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialCompletedKey, true);
  }

  /// Reinicia el estado del tutorial (útil para testing o reset).
  static Future<void> resetTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialCompletedKey, false);
    await prefs.setBool(_interactiveTutorialShownKey, false);
  }

  /// Verifica si el tour interactivo (coach marks) ya fue mostrado.
  static Future<bool> wasInteractiveTutorialShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_interactiveTutorialShownKey) ?? false;
  }

  /// Marca el tour interactivo como mostrado.
  static Future<void> markInteractiveTutorialShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_interactiveTutorialShownKey, true);
  }

  /// Reinicia solo el tour interactivo.
  static Future<void> resetInteractiveTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_interactiveTutorialShownKey, false);
  }
}
