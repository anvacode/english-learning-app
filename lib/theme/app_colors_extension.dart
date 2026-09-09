import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Colores semánticos que varían entre el tema claro y el tema oscuro.
///
/// Permite que cualquier widget obtenga colores adaptados al tema activo
/// mediante `context.appColors`, en lugar de usar los valores estáticos
/// (solo claros) de [AppColors].
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color background;
  final Color surface;
  final Color cardBackground;
  final Color surfaceVariant;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color border;
  final Color divider;

  /// Gradiente usado en la barra de navegación, drawer y encabezados.
  final LinearGradient primaryGradient;

  /// Gradiente sutil de fondo para pantallas.
  final LinearGradient backgroundGradient;

  /// Color de sombra adaptado al tema.
  final Color shadow;

  const AppColorsExtension({
    required this.background,
    required this.surface,
    required this.cardBackground,
    required this.surfaceVariant,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.border,
    required this.divider,
    required this.primaryGradient,
    required this.backgroundGradient,
    required this.shadow,
  });

  /// Paleta clara: coincide con los valores históricos de [AppColors].
  static const AppColorsExtension light = AppColorsExtension(
    background: Color(0xFFF5F7FA),
    surface: Colors.white,
    cardBackground: Colors.white,
    surfaceVariant: Color(0xFFEDF2F7),
    textPrimary: Color(0xFF2D3748),
    textSecondary: Color(0xFF4A5568),
    textTertiary: Color(0xFF718096),
    border: Color(0xFFE2E8F0),
    divider: Color(0xFFEDF2F7),
    primaryGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.primary, AppColors.primaryLight],
    ),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFF5F7FA), Color(0xFFE8EEF7)],
    ),
    shadow: Color(0x1A000000),
  );

  /// Paleta oscura "azul noche": fondos azul-marinado profundos con
  /// superficies elevadas y texto claro de alto contraste.
  static const AppColorsExtension dark = AppColorsExtension(
    background: Color(0xFF0C1222),
    surface: Color(0xFF141C33),
    cardBackground: Color(0xFF1A2340),
    surfaceVariant: Color(0xFF232D4F),
    textPrimary: Color(0xFFEDF0FA),
    textSecondary: Color(0xFFAAB3D1),
    textTertiary: Color(0xFF7C86A8),
    border: Color(0xFF2B3556),
    divider: Color(0xFF232C49),
    primaryGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1D2B53), Color(0xFF2E4372)],
    ),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF0C1222), Color(0xFF10182E)],
    ),
    shadow: Color(0x66000000),
  );

  @override
  AppColorsExtension copyWith({
    Color? background,
    Color? surface,
    Color? cardBackground,
    Color? surfaceVariant,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? border,
    Color? divider,
    LinearGradient? primaryGradient,
    LinearGradient? backgroundGradient,
    Color? shadow,
  }) {
    return AppColorsExtension(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      cardBackground: cardBackground ?? this.cardBackground,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      primaryGradient: primaryGradient ?? this.primaryGradient,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppColorsExtension lerp(AppColorsExtension? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      primaryGradient:
          LinearGradient.lerp(primaryGradient, other.primaryGradient, t)!,
      backgroundGradient:
          LinearGradient.lerp(backgroundGradient, other.backgroundGradient, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

/// Acceso cómodo a los colores semánticos del tema activo.
extension AppColorsContext on BuildContext {
  AppColorsExtension get appColors {
    // Si el tema no registra la extensión (tests, previews con un
    // MaterialApp genérico), se usa la paleta clara como fallback.
    final ext = Theme.of(this).extension<AppColorsExtension>();
    return ext ?? AppColorsExtension.light;
  }

  /// `true` si el tema activo es oscuro.
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
