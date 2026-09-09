import 'package:flutter/material.dart';

/// Paleta de colores moderna y divertida para la aplicación.
///
/// Diseño optimizado para niños con colores brillantes, vibrantes y acogedores.
/// Mantiene la legibilidad y profesionalismo mientras es divertido y atractivo.
class AppColors {
  // ============================================
  // COLORES PRIMARIOS - Azul vibrante y amigable
  // ============================================
  static const Color primaryDark = Color(0xFF1565C0); // Azul royal
  static const Color primary = Color(0xFF2196F3); // Azul brillante
  static const Color primaryLight = Color(0xFF64B5F6); // Azul cielo
  static const Color primaryLighter = Color(0xFFBBDEFB); // Azul muy claro

  // ============================================
  // COLORES SECUNDARIOS - Coral/Naranja energético
  // ============================================
  static const Color secondary = Color(0xFFFF7043); // Coral vibrante
  static const Color secondaryLight = Color(0xFFFFAB91); // Coral claro
  static const Color secondaryDark = Color(0xFFE64A19); // Coral oscuro

  // ============================================
  // COLORES DE ÉXITO - Verde lima fresco
  // ============================================
  static const Color success = Color(0xFF66BB6A); // Verde lima
  static const Color successLight = Color(0xFF81C784); // Verde claro
  static const Color successDark = Color(0xFF43A047); // Verde bosque

  // ============================================
  // COLORES DE ADVERTENCIA - Amarillo dorado
  // ============================================
  static const Color warning = Color(0xFFFFCA28); // Amarillo dorado
  static const Color warningLight = Color(0xFFFFE082); // Amarillo claro
  static const Color warningDark = Color(0xFFFFB300); // Ámbar

  // ============================================
  // COLORES DE ERROR - Rosa/Rojo suave
  // ============================================
  static const Color error = Color(0xFFEF5350); // Rojo coral suave
  static const Color errorLight = Color(0xFFE57373); // Rojo claro
  static const Color errorDark = Color(0xFFD32F2F); // Rojo intenso

  // ============================================
  // COLORES DE INFORMACIÓN - Turquesa
  // ============================================
  static const Color info = Color(0xFF26C6DA); // Turquesa brillante
  static const Color infoLight = Color(0xFF4DD0E1); // Turquesa claro
  static const Color infoDark = Color(0xFF00ACC1); // Turquesa oscuro

  // ============================================
  // COLORES DE FONDO - Suaves y acogedores
  // ============================================
  static const Color background = Color(0xFFF5F7FA); // Gris azulado muy claro
  static const Color surface = Colors.white; // Blanco puro
  static const Color surfaceVariant = Color(0xFFEDF2F7); // Gris muy claro
  static const Color surfaceContainerHighest = Color(0xFFF5F5F5); // Muy claro, casi blanco
  static const Color cardBackground = Colors.white; // Fondo de tarjetas

  // ============================================
  // COLORES DE TEXTO - Buen contraste
  // ============================================
  static const Color textPrimary = Color(0xFF2D3748); // Gris oscuro
  static const Color textSecondary = Color(0xFF4A5568); // Gris medio
  static const Color textTertiary = Color(0xFF718096); // Gris claro
  static const Color textDisabled = Color(0xFFA0AEC0); // Gris muy claro
  static const Color textOnDark = Colors.white; // Texto sobre fondo oscuro

  // ============================================
  // BORDES Y DIVISORES
  // ============================================
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFEDF2F7);
  static const Color borderLight = Color(0xFFF7FAFC);

  // ============================================
  // COLORES ESPECIALES PARA NIÑOS
  // ============================================
  static const Color starGold = Color(0xFFFFD700); // Oro brillante
  static const Color starGoldLight = Color(0xFFFFE55C); // Oro claro
  static const Color purpleMagic = Color(0xFF9C27B0); // Púrpura mágico
  static const Color pinkFun = Color(0xFFFF69B4); // Rosa divertido
  static const Color orangeSun = Color(0xFFFF9800); // Naranja sol
  static const Color tealOcean = Color(0xFF009688); // Verde azulado océano
  static const Color rainbowRed = Color(0xFFFF5252); // Rojo arcoíris
  static const Color rainbowOrange = Color(0xFFFFAB40); // Naranja arcoíris
  static const Color rainbowYellow = Color(0xFFFFD740); // Amarillo arcoíris
  static const Color rainbowGreen = Color(0xFF69F0AE); // Verde arcoíris
  static const Color rainbowBlue = Color(0xFF40C4FF); // Azul arcoíris
  static const Color rainbowPurple = Color(0xFF7C4DFF); // Púrpura arcoíris

  // ============================================
  // GRADIENTES PREARMADOS
  // ============================================
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryLight],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [success, successLight],
  );

  static const LinearGradient rainbowGradient = LinearGradient(
    colors: [
      rainbowRed,
      rainbowOrange,
      rainbowYellow,
      rainbowGreen,
      rainbowBlue,
      rainbowPurple,
    ],
  );

  static const LinearGradient skyGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF87CEEB), Color(0xFFE0F7FA)],
  );

  static const LinearGradient sunsetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF7043), Color(0xFFFFAB91), Color(0xFFFFCCBC)],
  );

  // ============================================
  // SOMBRAS MODERNAS
  // ============================================
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: primary.withAlpha(10),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get mediumShadow => [
    BoxShadow(
      color: primary.withAlpha(20),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: -5,
    ),
  ];

  static List<BoxShadow> get strongShadow => [
    BoxShadow(
      color: primary.withAlpha(30),
      blurRadius: 30,
      offset: const Offset(0, 12),
      spreadRadius: -10,
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withAlpha(8),
      blurRadius: 16,
      offset: const Offset(0, 4),
      spreadRadius: -4,
    ),
  ];

  static List<BoxShadow> get floatingShadow => [
    BoxShadow(
      color: primary.withAlpha(25),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: -8,
    ),
  ];

  // ============================================
  // COLORES POR CONTEXTO
  // ============================================
  static const Color lessonHeader = primary;
  static const Color badgeColor = starGold;
  static const Color buttonPrimary = primary;
  static const Color buttonSecondary = secondary;
  static const Color interactive = primary;
  static const Color disabled = Color(0xFFE2E8F0);
  static const Color disabledText = Color(0xFFA0AEC0);

  // ============================================
  // GETTERS DE COMPATIBILIDAD (no romper código existente)
  // ============================================
  /// Color de acento - usa secondary para compatibilidad
  static Color get accent => secondary;
  static Color get accentLight => secondaryLight;

  // ============================================
  // MÉTODOS UTILITARIOS
  // ============================================
  static Color withAlpha(Color color, int alpha) {
    return color.withAlpha(alpha);
  }

  static Color lighten(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness(
      (hsl.lightness + amount).clamp(0.0, 1.0),
    );
    return hslLight.toColor();
  }

  static Color darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  /// Obtiene un color aleatorio divertido para niños
  static Color getRandomFunColor() {
    final colors = [
      primary,
      secondary,
      success,
      warning,
      info,
      purpleMagic,
      pinkFun,
      orangeSun,
      tealOcean,
    ];
    return colors[DateTime.now().millisecond % colors.length];
  }
}
