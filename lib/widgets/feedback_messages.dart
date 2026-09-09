import 'dart:math';

class FeedbackMessages {
  static const List<String> _correctMessages = [
    '¡Excelente! 🌟',
    '¡Muy bien! 🎉',
    '¡Perfecto! ⭐',
    '¡Correcto! 👏',
    '¡Buen trabajo! 💪',
    '¡Lo lograste! 🏆',
    '¡Increíble! ✨',
    '¡Genial! 🎯',
    '¡Fantástico! 🌈',
    '¡Asombroso! 🚀',
    '¡Bravo! 👑',
    '¡Súper! 💫',
    '¡Eres un crack! 🎸',
    '¡De maravilla! 🌸',
    '¡Espectacular! 🎆',
  ];

  static const List<String> _encouragementMessages = [
    '¡Sigue así!',
    '¡Eres genial!',
    '¡Sigue aprendiendo!',
    '¡Vas muy bien!',
    '¡Cada vez mejor!',
    '¡No pares!',
    '¡Eres imparable!',
    '¡Qué talento!',
  ];

  static const List<String> _streakMessages = [
    '¡3 seguidas! 🔥🔥🔥',
    '¡Racha de fuego! 🔥',
    '¡No hay quien te pare! 💪',
    '¡Eres una máquina! ⚡',
    '¡IMPARABLE! 🌟',
    '¡Eres una estrella! ⭐⭐⭐',
    '¡Racha perfecta! 💎',
    '¡Nadie te gana! 🏆',
    '¡Esto es increíble! 🎆',
    '¡Modo experto activado! 🎮',
  ];

  static const List<String> _tryAgainMessages = [
    '¡Inténtalo de nuevo! 💪',
    '¡No te rindas! 🌟',
    '¡Tú puedes! 🎯',
    '¡Ánimo! ⭐',
    '¡Sigue intentando! 💫',
    '¡Casi lo tienes! 🤏',
    '¡Un poco más de atención! 👀',
    '¡La próxima será! 🍀',
  ];

  static const List<String> _brokenStreakMessages = [
    '¡No pasa nada! 💪 Las rachas se reconstruyen',
    '¡Tranquilo! Todos tenemos un mal momento 😊',
    '¡A seguir intentando! 🌟',
    '¡Cada error es aprendizaje! 📚',
    '¡Vamos que tú puedes! 🚀',
  ];

  static const List<String> _completionMessages = [
    '¡Lección completada! Eres increíble 🏆',
    '¡Lo lograste! Sigue así campeón 🎉',
    '¡Misión cumplida! Estás aprendiendo mucho 🌟',
    '¡Fantástico trabajo! Cada día eres mejor 💪',
    '¡Eres una estrella del inglés! ⭐',
  ];

  static String getCorrectMessage({bool includeEncouragement = false}) {
    final random = Random();
    final correctMsg =
        _correctMessages[random.nextInt(_correctMessages.length)];

    if (includeEncouragement) {
      final encouragementMsg =
          _encouragementMessages[random.nextInt(_encouragementMessages.length)];
      return '$correctMsg $encouragementMsg';
    }

    return correctMsg;
  }

  static String getStreakMessage(int streak) {
    if (streak < 3) return '';
    final random = Random();
    final index = streak <= 10
        ? (streak - 3) % _streakMessages.length
        : random.nextInt(_streakMessages.length);
    return _streakMessages[index];
  }

  static String getBrokenStreakMessage() {
    final random = Random();
    return _brokenStreakMessages[random.nextInt(_brokenStreakMessages.length)];
  }

  static String getTryAgainMessage({required int attemptNumber}) {
    final random = Random();

    if (attemptNumber == 1) {
      return _tryAgainMessages[random.nextInt(_tryAgainMessages.length)];
    } else if (attemptNumber == 2) {
      return '¡Casi lo tienes! 🎯';
    } else {
      return '¡Tú puedes! 💪';
    }
  }

  static String getCompletionMessage() {
    final random = Random();
    return _completionMessages[random.nextInt(_completionMessages.length)];
  }

  static String getEmojiForStreak(int streak) {
    if (streak >= 10) return '👑';
    if (streak >= 7) return '🏆';
    if (streak >= 5) return '💎';
    if (streak >= 3) return '🔥';
    return '⭐';
  }
}
