import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/responsive.dart';
import 'app_colors.dart';
import 'app_colors_extension.dart';

/// Estilos de texto modernos y amigables para niños.
///
/// Tipografía optimizada para legibilidad en todas las edades,
/// con tamaños responsive y colores atractivos.
class AppTextStyles {
  // ============================================
  // ESTILOS BASE
  // ============================================

  /// Título principal - Grande y llamativo
  static TextStyle headline1(BuildContext context) {
    return GoogleFonts.fredoka(
      fontSize: Responsive.scale(context, 28, 32, 36),
      fontWeight: FontWeight.bold,
      color: context.appColors.textPrimary,
      height: 1.2,
      letterSpacing: -0.5,
    );
  }

  /// Título secundario
  static TextStyle headline2(BuildContext context) {
    return GoogleFonts.fredoka(
      fontSize: Responsive.scale(context, 24, 28, 32),
      fontWeight: FontWeight.bold,
      color: context.appColors.textPrimary,
      height: 1.3,
      letterSpacing: -0.3,
    );
  }

  /// Título terciario
  static TextStyle headline3(BuildContext context) {
    return GoogleFonts.fredoka(
      fontSize: Responsive.scale(context, 20, 24, 28),
      fontWeight: FontWeight.w700,
      color: context.appColors.textPrimary,
      height: 1.3,
    );
  }

  // ============================================
  // ESTILOS DE TARJETAS Y CONTENIDO
  // ============================================

  /// Título de tarjetas - Destacado pero no tan grande
  static TextStyle cardTitle(BuildContext context) {
    return GoogleFonts.fredoka(
      fontSize: Responsive.scale(context, 18, 20, 22),
      fontWeight: FontWeight.bold,
      color: context.appColors.textPrimary,
      height: 1.2,
    );
  }

  /// Subtítulo de tarjetas
  static TextStyle cardSubtitle(BuildContext context) {
    return GoogleFonts.fredoka(
      fontSize: Responsive.scale(context, 14, 15, 16),
      fontWeight: FontWeight.w600,
      color: context.appColors.textSecondary,
      height: 1.3,
    );
  }

  // ============================================
  // ESTILOS DE CUERPO
  // ============================================

  /// Texto base - Legible y claro
  static TextStyle bodyText(BuildContext context) {
    return GoogleFonts.fredoka(
      fontSize: Responsive.baseFontSize(context),
      fontWeight: FontWeight.normal,
      color: context.appColors.textPrimary,
      height: 1.6,
    );
  }

  /// Texto base grande
  static TextStyle bodyTextLarge(BuildContext context) {
    return GoogleFonts.fredoka(
      fontSize: Responsive.scale(context, 16, 17, 18),
      fontWeight: FontWeight.normal,
      color: context.appColors.textPrimary,
      height: 1.6,
    );
  }

  /// Texto secundario (descripciones)
  static TextStyle bodyText2(BuildContext context) {
    return GoogleFonts.fredoka(
      fontSize: Responsive.scale(context, 14, 15, 16),
      fontWeight: FontWeight.normal,
      color: context.appColors.textSecondary,
      height: 1.5,
    );
  }

  /// Texto pequeño (etiquetas, hints)
  static TextStyle caption(BuildContext context) {
    return GoogleFonts.fredoka(
      fontSize: Responsive.smallFontSize(context),
      fontWeight: FontWeight.normal,
      color: context.appColors.textTertiary,
      height: 1.4,
    );
  }

  // ============================================
  // ESTILOS DE BOTONES
  // ============================================

  /// Texto de botón estándar
  static TextStyle button(BuildContext context) {
    return GoogleFonts.fredoka(
      fontSize: Responsive.scale(context, 15, 16, 17),
      fontWeight: FontWeight.bold,
      color: Colors.white,
      letterSpacing: 0.5,
      height: 1.2,
    );
  }

  /// Texto de botón grande
  static TextStyle buttonLarge(BuildContext context) {
    return GoogleFonts.fredoka(
      fontSize: Responsive.scale(context, 18, 20, 22),
      fontWeight: FontWeight.bold,
      color: Colors.white,
      letterSpacing: 0.5,
      height: 1.2,
    );
  }

  /// Texto de botón pequeño
  static TextStyle buttonSmall(BuildContext context) {
    return GoogleFonts.fredoka(
      fontSize: Responsive.scale(context, 13, 14, 15),
      fontWeight: FontWeight.w600,
      color: Colors.white,
      letterSpacing: 0.3,
      height: 1.2,
    );
  }

  // ============================================
  // ESTILOS ESPECIALES
  // ============================================

  /// Números grandes (estrellas, puntos)
  static TextStyle largeNumber(BuildContext context) {
    return GoogleFonts.fredoka(
      fontSize: Responsive.scale(context, 36, 40, 44),
      fontWeight: FontWeight.bold,
      color: context.appColors.textPrimary,
      height: 1.0,
    );
  }

  /// Contador de estrellas
  static TextStyle starCounter(BuildContext context) {
    return GoogleFonts.fredoka(
      fontSize: Responsive.scale(context, 28, 32, 36),
      fontWeight: FontWeight.bold,
      color: AppColors.starGold,
      height: 1.0,
      shadows: [
        Shadow(
          color: Colors.black.withAlpha(20),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Etiquetas y tags
  static TextStyle label(BuildContext context) {
    return GoogleFonts.fredoka(
      fontSize: Responsive.scale(context, 12, 13, 14),
      fontWeight: FontWeight.w600,
      color: context.appColors.textSecondary,
      letterSpacing: 0.3,
    );
  }

  /// Etiqueta destacada
  static TextStyle labelBold(BuildContext context) {
    return GoogleFonts.fredoka(
      fontSize: Responsive.scale(context, 12, 13, 14),
      fontWeight: FontWeight.bold,
      color: context.appColors.textPrimary,
      letterSpacing: 0.3,
    );
  }

  // ============================================
  // ESTILOS DE APP BAR Y NAVEGACIÓN
  // ============================================

  /// Título de AppBar
  static TextStyle appBarTitle(BuildContext context, {Color? color}) {
    return GoogleFonts.fredoka(
      fontSize: Responsive.scale(context, 20, 22, 24),
      fontWeight: FontWeight.bold,
      color: color ?? Colors.white,
      letterSpacing: 0.3,
    );
  }

  /// Texto de navegación inferior
  static TextStyle bottomNavLabel(BuildContext context) {
    return GoogleFonts.fredoka(
      fontSize: Responsive.scale(context, 11, 12, 13),
      fontWeight: FontWeight.w600,
      color: context.appColors.textSecondary,
    );
  }

  // ============================================
  // ESTILOS DE ONBOARDING
  // ============================================

  /// Título de onboarding
  static TextStyle onboardingTitle(BuildContext context) {
    return GoogleFonts.fredoka(
      fontSize: Responsive.scale(context, 28, 32, 36),
      fontWeight: FontWeight.bold,
      color: context.appColors.textPrimary,
      height: 1.2,
      letterSpacing: -0.5,
    );
  }

  /// Descripción de onboarding
  static TextStyle onboardingDescription(BuildContext context) {
    return GoogleFonts.fredoka(
      fontSize: Responsive.scale(context, 16, 17, 18),
      fontWeight: FontWeight.normal,
      color: context.appColors.textSecondary,
      height: 1.6,
    );
  }

  // ============================================
  // ESTILOS DE LECCIÓN
  // ============================================

  /// Pregunta de lección
  static TextStyle lessonQuestion(BuildContext context) {
    return GoogleFonts.fredoka(
      fontSize: Responsive.scale(context, 20, 22, 24),
      fontWeight: FontWeight.bold,
      color: context.appColors.textPrimary,
      height: 1.3,
    );
  }

  /// Opción de respuesta
  static TextStyle optionText(BuildContext context) {
    return GoogleFonts.fredoka(
      fontSize: Responsive.scale(context, 16, 17, 18),
      fontWeight: FontWeight.w600,
      color: context.appColors.textPrimary,
      height: 1.3,
    );
  }

  /// Palabra en inglés
  static TextStyle englishWord(BuildContext context) {
    return GoogleFonts.fredoka(
      fontSize: Responsive.scale(context, 24, 26, 28),
      fontWeight: FontWeight.bold,
      color: AppColors.primary,
      height: 1.2,
    );
  }

  /// Precio en tienda
  static TextStyle price(BuildContext context) {
    return GoogleFonts.fredoka(
      fontSize: Responsive.scale(context, 18, 20, 22),
      fontWeight: FontWeight.bold,
      color: AppColors.starGold,
      height: 1.2,
    );
  }

  /// Texto de lista
  static TextStyle listItem(BuildContext context) {
    return GoogleFonts.fredoka(
      fontSize: Responsive.scale(context, 15, 16, 17),
      fontWeight: FontWeight.w500,
      color: context.appColors.textPrimary,
      height: 1.4,
    );
  }
}

/// Extension para facilitar el uso de estilos en widgets
extension TextStyleExtension on BuildContext {
  TextStyle get headline1 => AppTextStyles.headline1(this);
  TextStyle get headline2 => AppTextStyles.headline2(this);
  TextStyle get headline3 => AppTextStyles.headline3(this);
  TextStyle get cardTitle => AppTextStyles.cardTitle(this);
  TextStyle get cardSubtitle => AppTextStyles.cardSubtitle(this);
  TextStyle get bodyText => AppTextStyles.bodyText(this);
  TextStyle get bodyTextLarge => AppTextStyles.bodyTextLarge(this);
  TextStyle get bodyText2 => AppTextStyles.bodyText2(this);
  TextStyle get caption => AppTextStyles.caption(this);
  TextStyle get buttonText => AppTextStyles.button(this);
  TextStyle get buttonLarge => AppTextStyles.buttonLarge(this);
  TextStyle get buttonSmall => AppTextStyles.buttonSmall(this);
  TextStyle get largeNumber => AppTextStyles.largeNumber(this);
  TextStyle get starCounter => AppTextStyles.starCounter(this);
  TextStyle get label => AppTextStyles.label(this);
  TextStyle get labelBold => AppTextStyles.labelBold(this);
  TextStyle get appBarTitle => AppTextStyles.appBarTitle(this);
  TextStyle get bottomNavLabel => AppTextStyles.bottomNavLabel(this);
  TextStyle get onboardingTitle => AppTextStyles.onboardingTitle(this);
  TextStyle get onboardingDescription =>
      AppTextStyles.onboardingDescription(this);
  TextStyle get lessonQuestion => AppTextStyles.lessonQuestion(this);
  TextStyle get optionText => AppTextStyles.optionText(this);
  TextStyle get englishWord => AppTextStyles.englishWord(this);
  TextStyle get price => AppTextStyles.price(this);
  TextStyle get listItem => AppTextStyles.listItem(this);
}
