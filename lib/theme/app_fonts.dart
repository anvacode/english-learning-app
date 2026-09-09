import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppFonts {
  static const String family = 'Fredoka';

  static TextStyle base({
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    Color? color,
  }) {
    return GoogleFonts.fredoka(
      fontSize: fontSize ?? 16,
      fontWeight: fontWeight ?? FontWeight.normal,
      height: height,
      color: color,
    );
  }
}
