import 'package:flutter/material.dart';

/// Sistema de diseño responsive para la aplicación.
/// 
/// Proporciona breakpoints, métodos helper y configuración
/// para adaptar la UI a diferentes tamaños de pantalla.
class Responsive {
  static const double mobileMaxWidth = 768;
  static const double tabletMaxWidth = 1024;
  static const double desktopMaxWidth = 1440;
  static const double wideMaxWidth = 1920;

  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static bool isMobile(BuildContext context) =>
      screenWidth(context) < mobileMaxWidth;

  static bool isTablet(BuildContext context) {
    final w = screenWidth(context);
    return w >= mobileMaxWidth && w < tabletMaxWidth;
  }

  static bool isDesktop(BuildContext context) {
    final w = screenWidth(context);
    return w >= tabletMaxWidth && w < desktopMaxWidth;
  }

  static bool isWide(BuildContext context) =>
      screenWidth(context) >= desktopMaxWidth;

  static bool isSmallMobile(BuildContext context) =>
      screenWidth(context) < 375;

  static double horizontalPadding(BuildContext context) {
    if (isMobile(context)) return 16.0;
    if (isTablet(context)) return 24.0;
    if (isDesktop(context)) return 32.0;
    return 40.0;
  }

  static double verticalPadding(BuildContext context) {
    if (isMobile(context)) return 16.0;
    if (isTablet(context)) return 20.0;
    if (isDesktop(context)) return 24.0;
    return 32.0;
  }

  static int gridColumns(BuildContext context, {
    int? mobile,
    int? tablet,
    int? desktop,
    int? wide,
  }) {
    if (isMobile(context)) return mobile ?? 2;
    if (isTablet(context)) return tablet ?? 3;
    if (isDesktop(context)) return desktop ?? 4;
    return wide ?? 5;
  }

  static double gridSpacing(BuildContext context) {
    if (isMobile(context)) return 12.0;
    if (isTablet(context)) return 16.0;
    if (isDesktop(context)) return 20.0;
    return 24.0;
  }

  static double maxContainerWidth(BuildContext context) {
    if (isMobile(context)) return double.infinity;
    if (isTablet(context)) return 900.0;
    if (isDesktop(context)) return 1200.0;
    return 1400.0;
  }

  static double baseFontSize(BuildContext context) {
    if (isMobile(context)) return 16.0;
    if (isTablet(context)) return 18.0;
    if (isDesktop(context)) return 20.0;
    return 22.0;
  }

  static double titleFontSize(BuildContext context) {
    if (isMobile(context)) return 24.0;
    if (isTablet(context)) return 28.0;
    if (isDesktop(context)) return 32.0;
    return 36.0;
  }

  static double subtitleFontSize(BuildContext context) {
    if (isMobile(context)) return 18.0;
    if (isTablet(context)) return 20.0;
    if (isDesktop(context)) return 22.0;
    return 24.0;
  }

  static double smallFontSize(BuildContext context) {
    if (isMobile(context)) return 12.0;
    if (isTablet(context)) return 14.0;
    return 15.0;
  }

  static double iconSize(BuildContext context) {
    if (isMobile(context)) return 24.0;
    if (isTablet(context)) return 28.0;
    if (isDesktop(context)) return 32.0;
    return 36.0;
  }

  static double largeIconSize(BuildContext context) {
    if (isMobile(context)) return 48.0;
    if (isTablet(context)) return 56.0;
    if (isDesktop(context)) return 64.0;
    return 72.0;
  }

  static double buttonHeight(BuildContext context) {
    if (isMobile(context)) return 48.0;
    if (isTablet(context)) return 52.0;
    if (isDesktop(context)) return 56.0;
    return 60.0;
  }

  static double borderRadius(BuildContext context) {
    if (isMobile(context)) return 12.0;
    if (isTablet(context)) return 14.0;
    if (isDesktop(context)) return 16.0;
    return 20.0;
  }

  static double scale(BuildContext context, double mobile, double tablet, double desktop) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    if (isDesktop(context)) return desktop;
    return desktop * 1.1;
  }

  static double scale4(
    BuildContext context,
    double mobile,
    double tablet,
    double desktop,
    double wide,
  ) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    if (isDesktop(context)) return desktop;
    return wide;
  }

  static double cardMaxWidth(BuildContext context) {
    if (isMobile(context)) return double.infinity;
    if (isTablet(context)) return 500.0;
    if (isDesktop(context)) return 600.0;
    return 800.0;
  }

  static Widget builder({
    required BuildContext context,
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
    Widget? wide,
  }) {
    if (isWide(context) && wide != null) return wide;
    if (isDesktop(context) && desktop != null) return desktop;
    if (isTablet(context) && tablet != null) return tablet;
    return mobile;
  }

  static EdgeInsets padding(BuildContext context, {
    double? all,
    double? horizontal,
    double? vertical,
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    final multiplier = isMobile(context)
        ? 1.0
        : isTablet(context)
            ? 1.25
            : isDesktop(context)
                ? 1.5
                : 1.75;

    if (all != null) {
      return EdgeInsets.all(all * multiplier);
    }

    return EdgeInsets.only(
      top: (top ?? vertical ?? 0) * multiplier,
      bottom: (bottom ?? vertical ?? 0) * multiplier,
      left: (left ?? horizontal ?? 0) * multiplier,
      right: (right ?? horizontal ?? 0) * multiplier,
    );
  }

  static bool hasHover(BuildContext context) => !isMobile(context);

  static double cardAspectRatio(BuildContext context) {
    if (isMobile(context)) return 0.9;
    if (isTablet(context)) return 1.0;
    if (isDesktop(context)) return 1.1;
    return 1.2;
  }
}

extension ResponsiveExtension on BuildContext {
  bool get isMobile => Responsive.isMobile(this);
  bool get isTablet => Responsive.isTablet(this);
  bool get isDesktop => Responsive.isDesktop(this);
  bool get isWide => Responsive.isWide(this);
  bool get isSmallMobile => Responsive.isSmallMobile(this);
  double get screenWidth => Responsive.screenWidth(this);
  double get screenHeight => Responsive.screenHeight(this);
  double get horizontalPadding => Responsive.horizontalPadding(this);
  double get verticalPadding => Responsive.verticalPadding(this);
  double get baseFontSize => Responsive.baseFontSize(this);
  double get titleFontSize => Responsive.titleFontSize(this);
  double get subtitleFontSize => Responsive.subtitleFontSize(this);
  double get smallFontSize => Responsive.smallFontSize(this);
  double get cardMaxWidth => Responsive.cardMaxWidth(this);
  double scale(double mobile, double tablet, double desktop) =>
      Responsive.scale(this, mobile, tablet, desktop);
  double scale4(double mobile, double tablet, double desktop, double wide) =>
      Responsive.scale4(this, mobile, tablet, desktop, wide);
}
