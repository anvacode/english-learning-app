import 'package:flutter/material.dart';

class LessonTheme {
  final String emoji;
  final List<Color> gradientColors;

  const LessonTheme({
    required this.emoji,
    required this.gradientColors,
  });

  LinearGradient get gradient => LinearGradient(
        colors: gradientColors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}

const Map<String, LessonTheme> lessonThemes = {
  // Principiante
  'colors': LessonTheme(
    emoji: '🎨',
    gradientColors: [Color(0xFF667eea), Color(0xFF764ba2)],
  ),
  'fruits': LessonTheme(
    emoji: '🍎',
    gradientColors: [Color(0xFFf093fb), Color(0xFFf5576c)],
  ),
  'animals': LessonTheme(
    emoji: '🐾',
    gradientColors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
  ),
  'classroom': LessonTheme(
    emoji: '📚',
    gradientColors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
  ),
  'family_1': LessonTheme(
    emoji: '👨‍👩‍👧‍👦',
    gradientColors: [Color(0xFFfa709a), Color(0xFFfee140)],
  ),
  'numbers': LessonTheme(
    emoji: '🔢',
    gradientColors: [Color(0xFFa18cd1), Color(0xFFfbc2eb)],
  ),
  'body_parts': LessonTheme(
    emoji: '👁️',
    gradientColors: [Color(0xFFffecd2), Color(0xFFfcb69f)],
  ),
  'clothes': LessonTheme(
    emoji: '👕',
    gradientColors: [Color(0xFFff9a9e), Color(0xFFfecfef)],
  ),
  'food_drinks': LessonTheme(
    emoji: '🍽️',
    gradientColors: [Color(0xFFa1c4fd), Color(0xFFc2e9fb)],
  ),
  'actions': LessonTheme(
    emoji: '🏃',
    gradientColors: [Color(0xFFd4fc79), Color(0xFF96e6a1)],
  ),

  // Intermedio
  'daily_routines': LessonTheme(
    emoji: '⏰',
    gradientColors: [Color(0xFF84fab0), Color(0xFF8fd3f4)],
  ),
  'weather_seasons': LessonTheme(
    emoji: '🌤️',
    gradientColors: [Color(0xFFfbc2eb), Color(0xFFa6c1ee)],
  ),
  'occupations': LessonTheme(
    emoji: '👨‍⚕️',
    gradientColors: [Color(0xFFfdcbf1), Color(0xFFe6dee9)],
  ),
  'transportation': LessonTheme(
    emoji: '🚗',
    gradientColors: [Color(0xFFa6c0fe), Color(0xFFf68084)],
  ),
  'places_city': LessonTheme(
    emoji: '🏙️',
    gradientColors: [Color(0xFFfccb90), Color(0xFFd57eeb)],
  ),
  'meals': LessonTheme(
    emoji: '🍳',
    gradientColors: [Color(0xFFe0c3fc), Color(0xFF8ec5fc)],
  ),
  'clothing_extended': LessonTheme(
    emoji: '👗',
    gradientColors: [Color(0xFFf093fb), Color(0xFFf5576c)],
  ),
  'emotions': LessonTheme(
    emoji: '😊',
    gradientColors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
  ),
  'school_subjects': LessonTheme(
    emoji: '🎓',
    gradientColors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
  ),
  'hobbies_sports': LessonTheme(
    emoji: '⚽',
    gradientColors: [Color(0xFFfa709a), Color(0xFFfee140)],
  ),

  // Avanzado
  'verb_tenses': LessonTheme(
    emoji: '📝',
    gradientColors: [Color(0xFF667eea), Color(0xFF764ba2)],
  ),
  'prepositions': LessonTheme(
    emoji: '📍',
    gradientColors: [Color(0xFFf093fb), Color(0xFFf5576c)],
  ),
  'adjectives_opposites': LessonTheme(
    emoji: '⚖️',
    gradientColors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
  ),
  'questions': LessonTheme(
    emoji: '❓',
    gradientColors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
  ),
  'conversations': LessonTheme(
    emoji: '💬',
    gradientColors: [Color(0xFFfa709a), Color(0xFFfee140)],
  ),
  'numbers_advanced': LessonTheme(
    emoji: '💯',
    gradientColors: [Color(0xFFa18cd1), Color(0xFFfbc2eb)],
  ),
  'time': LessonTheme(
    emoji: '🕐',
    gradientColors: [Color(0xFFffecd2), Color(0xFFfcb69f)],
  ),
  'health': LessonTheme(
    emoji: '❤️‍🩹',
    gradientColors: [Color(0xFFff9a9e), Color(0xFFfecfef)],
  ),
};

LessonTheme getLessonTheme(String lessonId) {
  return lessonThemes[lessonId] ??
      const LessonTheme(
        emoji: '📖',
        gradientColors: [Color(0xFF667eea), Color(0xFF764ba2)],
      );
}
