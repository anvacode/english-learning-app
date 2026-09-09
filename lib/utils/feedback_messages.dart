import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/responsive_snack_bar.dart';

/// Sistema de mensajes de retroalimentación divertidos y llamativos para niños.
///
/// Proporciona mensajes variados, coloridos y motivadores para diferentes
/// situaciones en la app.
class FeedbackMessages {
  static final Random _random = Random();

  // ============================================
  // MENSAJES PARA RESPUESTAS CORRECTAS
  // ============================================

  static const List<String> _correctMessages = [
    '🌟 ¡Increíble!',
    '🎉 ¡Lo lograste!',
    '⭐ ¡Excelente!',
    '🏆 ¡Eres un campeón!',
    '🚀 ¡Fantástico!',
    '🌈 ¡Perfecto!',
    '🎨 ¡Brillante!',
    '🏅 ¡Magnífico!',
    '✨ ¡Genial!',
    '🎵 ¡Maravilloso!',
    '🦸 ¡Súper héroe!',
    '🌟 ¡Asombroso!',
    '🎊 ¡Fantástico trabajo!',
    '⭐ ¡Eres una estrella!',
    '🏆 ¡Campeón!',
  ];

  static const List<String> _correctEncouragements = [
    '¡Sigue así! 🚀',
    '¡Vas muy bien! ⭐',
    '¡Eres muy inteligente! 🧠',
    '¡Lo estás haciendo genial! 🌟',
    '¡Eres un genio! 💡',
    '¡Increíble trabajo! 🎨',
    '¡Eres super! 🦸',
    '¡Vas por buen camino! 🛤️',
    '¡Eres muy listo! 📚',
    '¡Eres una máquina! 🤖',
  ];

  // ============================================
  // MENSAJES PARA INTENTOS INCORRECTOS
  // ============================================

  static const List<String> _tryAgainMessages = [
    '💪 ¡Casi! Intenta de nuevo',
    '🤔 Piénsalo bien...',
    '🔄 Otra oportunidad',
    '💭 ¿Estás seguro?',
    '🎯 ¡Tú puedes!',
    '🌟 ¡No te rindas!',
    '🚀 Inténtalo otra vez',
    '🎨 Todavía puedes lograrlo',
    '💪 ¡Eres fuerte!',
    '🤗 ¡Ánimo!',
  ];

  static const List<String> _hintMessages = [
    '🤔 Piensa en la imagen...',
    '💭 Escucha bien la palabra',
    '🎯 Mira con atención',
    '🧠 Confía en tu memoria',
    '✨ Tú puedes hacerlo',
  ];

  // ============================================
  // MENSAJES PARA COMPLETAR LECCIONES
  // ============================================

  static const List<String> _lessonCompleteMessages = [
    '🎊 ¡Lección completada!',
    '🏆 ¡Eres un campeón!',
    '⭐ ¡Excelente trabajo!',
    '🌟 ¡Lo lograste!',
    '🚀 ¡Eres increíble!',
    '🎉 ¡Fantástico!',
  ];

  static const List<String> _lessonPerfectMessages = [
    '🏆 ¡PERFECTO! ¡100%!',
    '⭐⭐⭐ ¡Tres estrellas!',
    '🌟 ¡Eres un maestro!',
    '🎨 ¡Obra de arte!',
    '🚀 ¡Eres un genio!',
  ];

  // ============================================
  // MENSAJES DE AUTENTICACIÓN
  // ============================================

  static const Map<String, Map<String, String>> _authMessages = {
    'login_success': {
      'title': '🎉 ¡Bienvenido de vuelta!',
      'message': '¡Qué bueno verte otra vez!',
    },
    'register_success': {
      'title': '🌟 ¡Cuenta creada!',
      'message': '¡Bienvenido a la aventura de aprender inglés!',
    },
    'logout_success': {
      'title': '👋 ¡Hasta pronto!',
      'message': '¡Vuelve pronto para seguir aprendiendo!',
    },
    'google_signin_success': {
      'title': '🎉 ¡Inicio de sesión exitoso!',
      'message': '¡Listo para aprender!',
    },
    'guest_welcome': {
      'title': '👋 ¡Bienvenido!',
      'message': '¡Diviértete aprendiendo inglés!',
    },
    'password_reset': {
      'title': '📧 ¡Email enviado!',
      'message': 'Revisa tu correo para restablecer tu contraseña',
    },
  };

  static const Map<String, Map<String, String>> _authErrors = {
    'email_in_use': {
      'title': '📧 Email ya registrado',
      'message': 'Este correo ya existe. ¿Quieres iniciar sesión?',
    },
    'wrong_password': {
      'title': '🔒 Contraseña incorrecta',
      'message': 'Verifica tu contraseña e intenta de nuevo',
    },
    'user_not_found': {
      'title': '👤 Usuario no encontrado',
      'message': 'No existe una cuenta con este email. ¿Quieres registrarte?',
    },
    'weak_password': {
      'title': '🔑 Contraseña débil',
      'message': 'Usa al menos 6 caracteres para mayor seguridad',
    },
    'invalid_email': {
      'title': '📧 Email inválido',
      'message': 'Por favor ingresa un correo electrónico válido',
    },
    'network_error': {
      'title': '📡 Error de conexión',
      'message': 'Verifica tu internet e intenta de nuevo',
    },
    'too_many_attempts': {
      'title': '⏰ Espera un momento',
      'message': 'Demasiados intentos. Intenta más tarde',
    },
    'unknown_error': {
      'title': '❌ Ups, algo salió mal',
      'message': 'Por favor intenta de nuevo en un momento',
    },
  };

  // ============================================
  // MENSAJES DE PROGRESO Y LOGROS
  // ============================================

  static const List<String> _streakMessages = [
    '🔥 ¡Racha de {days} días!',
    '⚡ ¡Vas con todo!',
    '🌟 ¡No paras de aprender!',
    '🚀 ¡Eres imparable!',
  ];

  static const List<String> _badgeUnlockedMessages = [
    '🏆 ¡Nueva insignia desbloqueada!',
    '⭐ ¡Logro conseguido!',
    '🎉 ¡Eres una estrella!',
    '🌟 ¡Increíble progreso!',
  ];

  static const List<String> _levelUpMessages = [
    '🆙 ¡Subiste de nivel!',
    '🚀 ¡Nuevo nivel alcanzado!',
    '⭐ ¡Eres más fuerte ahora!',
    '🌟 ¡Sigue creciendo!',
  ];

  // ============================================
  // MÉTODOS PARA OBTENER MENSAJES
  // ============================================

  /// Obtiene un mensaje aleatorio para respuesta correcta
  static String getCorrectMessage({bool includeEncouragement = false}) {
    final message = _correctMessages[_random.nextInt(_correctMessages.length)];
    if (includeEncouragement && _random.nextBool()) {
      final encouragement =
          _correctEncouragements[_random.nextInt(
            _correctEncouragements.length,
          )];
      return '$message\n$encouragement';
    }
    return message;
  }

  /// Obtiene un mensaje para intentar de nuevo
  static String getTryAgainMessage({int attemptNumber = 1}) {
    if (attemptNumber == 1) {
      return _tryAgainMessages[_random.nextInt(_tryAgainMessages.length)];
    } else if (attemptNumber == 2) {
      return _hintMessages[_random.nextInt(_hintMessages.length)];
    } else {
      return '💭 Último intento. ¡Tú puedes!';
    }
  }

  /// Obtiene mensaje para lección completada
  static String getLessonCompleteMessage({bool isPerfect = false}) {
    if (isPerfect) {
      return _lessonPerfectMessages[_random.nextInt(
        _lessonPerfectMessages.length,
      )];
    }
    return _lessonCompleteMessages[_random.nextInt(
      _lessonCompleteMessages.length,
    )];
  }

  /// Obtiene mensaje de autenticación exitosa
  static Map<String, String> getAuthSuccessMessage(String type) {
    return _authMessages[type] ??
        {'title': '✅ ¡Éxito!', 'message': 'Operación completada correctamente'};
  }

  /// Obtiene mensaje de error de autenticación
  static Map<String, String> getAuthErrorMessage(String errorCode) {
    // Mapear códigos de error de Firebase a nuestros mensajes
    final Map<String, String> firebaseToLocal = {
      'email-already-in-use': 'email_in_use',
      'wrong-password': 'wrong_password',
      'user-not-found': 'user_not_found',
      'weak-password': 'weak_password',
      'invalid-email': 'invalid_email',
      'network-request-failed': 'network_error',
      'too-many-requests': 'too_many_attempts',
    };

    final localKey = firebaseToLocal[errorCode] ?? 'unknown_error';
    return _authErrors[localKey] ?? _authErrors['unknown_error']!;
  }

  /// Obtiene mensaje para racha de días
  static String getStreakMessage(int days) {
    if (days >= 7) {
      return '🔥🔥 ¡Racha de $days días! ¡Eres imparable!';
    } else if (days >= 3) {
      return '🔥 ¡Racha de $days días! ¡Vas muy bien!';
    }
    final message = _streakMessages[_random.nextInt(_streakMessages.length)];
    return message.replaceAll('{days}', days.toString());
  }

  /// Obtiene mensaje para insignia desbloqueada
  static String getBadgeUnlockedMessage() {
    return _badgeUnlockedMessages[_random.nextInt(
      _badgeUnlockedMessages.length,
    )];
  }

  /// Obtiene mensaje para subir de nivel
  static String getLevelUpMessage() {
    return _levelUpMessages[_random.nextInt(_levelUpMessages.length)];
  }

  /// Obtiene mensaje motivacional aleatorio
  static String getMotivationalMessage() {
    final messages = [
      '💪 ¡Nunca te rindas!',
      '🌟 ¡Tú puedes lograrlo!',
      '🚀 ¡Sigue adelante!',
      '⭐ ¡Eres capaz de todo!',
      '🎨 ¡Cada intento te hace mejor!',
      '🏆 ¡El esfuerzo vale la pena!',
      '🌈 ¡Los errores te ayudan a aprender!',
      '💡 ¡Tu cerebro está creciendo!',
    ];
    return messages[_random.nextInt(messages.length)];
  }
}

/// Extensiones para facilitar el uso de mensajes
extension FeedbackMessagesExtension on BuildContext {
  void showSuccessSnackbar(String message) {
    ResponsiveSnackBar.showSuccess(this, message: message);
  }

  void showErrorSnackbar(String message) {
    ResponsiveSnackBar.showError(this, message: message);
  }

  void showInfoSnackbar(String message) {
    ResponsiveSnackBar.showInfo(this, message: message);
  }
}
