import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_colors_extension.dart';

/// Temas visuales de la aplicación.
///
/// Define un [lightTheme] (el diseño original) y un [darkTheme] moderno
/// estilo "azul noche" que se aplica a toda la app. Ambos usan la fuente
/// Fredoka y comparten la misma estructura de componentes para que el
/// cambio de tema sea consistente y animado.
class AppTheme {
  AppTheme._();

  /// Tema claro (diseño original de la app).
  static ThemeData get lightTheme => _build(
        brightness: Brightness.light,
        scheme: _lightScheme,
        ext: AppColorsExtension.light,
      );

  /// Tema oscuro "azul noche".
  static ThemeData get darkTheme => _build(
        brightness: Brightness.dark,
        scheme: _darkScheme,
        ext: AppColorsExtension.dark,
      );

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.primaryLighter,
    onPrimaryContainer: AppColors.primaryDark,
    secondary: AppColors.secondary,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.secondaryLight,
    onSecondaryContainer: AppColors.secondaryDark,
    tertiary: AppColors.info,
    onTertiary: Colors.white,
    error: AppColors.error,
    onError: Colors.white,
    errorContainer: AppColors.errorLight,
    onErrorContainer: AppColors.errorDark,
    surface: Colors.white,
    onSurface: AppColors.textPrimary,
    surfaceContainerHighest: AppColors.surfaceContainerHighest,
    onSurfaceVariant: AppColors.textSecondary,
    outline: AppColors.border,
    outlineVariant: AppColors.divider,
    shadow: Color(0x1A000000),
    surfaceTint: AppColors.primary,
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF6EA8FF),
    onPrimary: Color(0xFF0A1B3D),
    primaryContainer: Color(0xFF27406E),
    onPrimaryContainer: Color(0xFFD3E2FF),
    secondary: Color(0xFFFF9E80),
    onSecondary: Color(0xFF3E1500),
    secondaryContainer: Color(0xFF6B3A25),
    onSecondaryContainer: Color(0xFFFFD9C9),
    tertiary: Color(0xFF4DD0E1),
    onTertiary: Color(0xFF00363D),
    error: Color(0xFFEF9A9A),
    onError: Color(0xFF4A0B0B),
    errorContainer: Color(0xFF7F2B2B),
    onErrorContainer: Color(0xFFFFDAD4),
    surface: Color(0xFF141C33),
    onSurface: Color(0xFFEDF0FA),
    surfaceContainerHighest: Color(0xFF232D4F),
    onSurfaceVariant: Color(0xFFAAB3D1),
    outline: Color(0xFF2B3556),
    outlineVariant: Color(0xFF232C49),
    shadow: Color(0x66000000),
    surfaceTint: Color(0xFF6EA8FF),
  );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required AppColorsExtension ext,
  }) {
    final isDark = brightness == Brightness.dark;

    // Tipografía Fredoka con los colores del tema activo.
    final baseTextTheme = GoogleFonts.fredokaTextTheme(
      ThemeData(brightness: brightness).textTheme,
    );
    final textTheme = baseTextTheme.apply(
      bodyColor: ext.textPrimary,
      displayColor: ext.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: GoogleFonts.fredoka().fontFamily,
      textTheme: textTheme,
      scaffoldBackgroundColor: ext.background,
      canvasColor: ext.surface,
      extensions: <ThemeExtension<dynamic>>[ext],

      // ---------------------------------------------
      // Componentes
      // ---------------------------------------------
      appBarTheme: AppBarTheme(
        backgroundColor: ext.surface,
        foregroundColor: ext.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: ext.textPrimary,
        ),
        iconTheme: IconThemeData(color: ext.textPrimary),
      ),

      cardTheme: CardThemeData(
        color: ext.cardBackground,
        elevation: isDark ? 1 : 2,
        shadowColor: ext.shadow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: ext.cardBackground,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: ext.textPrimary,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: ext.textSecondary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: ext.cardBackground,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: ext.cardBackground,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? ext.surfaceVariant : ext.textPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isDark ? ext.textPrimary : Colors.white,
        ),
        actionTextColor: scheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: ext.divider,
        thickness: 1,
        space: 1,
      ),

      iconTheme: IconThemeData(color: ext.textPrimary),
      primaryIconTheme: const IconThemeData(color: Colors.white),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDark ? Colors.white : Colors.white;
          }
          return isDark ? ext.textTertiary : Colors.grey.shade400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return isDark ? ext.surfaceVariant : Colors.grey.shade300;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor:
            isDark ? ext.surfaceVariant : AppColors.primaryLighter,
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withAlpha(30),
        valueIndicatorColor: scheme.primary,
        valueIndicatorTextStyle: const TextStyle(color: Colors.white),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: isDark ? ext.surfaceVariant : AppColors.primaryLighter,
        circularTrackColor: isDark ? ext.surfaceVariant : AppColors.primaryLighter,
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: ext.textTertiary,
        indicatorColor: scheme.primary,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: ext.surfaceVariant,
        selectedColor: scheme.primaryContainer,
        disabledColor: ext.surfaceVariant,
        labelStyle: textTheme.bodyMedium?.copyWith(color: ext.textPrimary),
        secondaryLabelStyle:
            textTheme.bodyMedium?.copyWith(color: scheme.onPrimaryContainer),
        side: BorderSide(color: ext.border),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? ext.surfaceVariant : AppColors.background,
        labelStyle: TextStyle(color: ext.textSecondary),
        hintStyle: TextStyle(color: ext.textTertiary),
        prefixIconColor: ext.textTertiary,
        suffixIconColor: ext.textTertiary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ext.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ext.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: isDark ? 0 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: scheme.primary),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),

      listTileTheme: ListTileThemeData(
        iconColor: ext.textSecondary,
        textColor: ext.textPrimary,
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? ext.surfaceVariant : ext.textPrimary,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(
          color: isDark ? ext.textPrimary : Colors.white,
          fontSize: 12,
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: ext.cardBackground,
        surfaceTintColor: Colors.transparent,
        textStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
