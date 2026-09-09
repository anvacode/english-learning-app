import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/diagnostic_questions_data.dart';
import '../models/diagnostic_result.dart';
import '../services/firebase_service.dart';

class DiagnosticService {
  static const String _diagnosticCompletedKey = 'diagnostic_completed';
  static const String _diagnosticLevelKey = 'diagnostic_level';
  static const String _diagnosticResultKey = 'diagnostic_result';

  static Future<bool> isDiagnosticCompleted() async {
    final user = FirebaseService().currentUser;
    if (user != null && FirebaseService().isInitialized) {
      try {
        final doc = await FirebaseService().firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data();
          final profileData = data?['profile'] as Map<String, dynamic>?;
          if (profileData != null && profileData['diagnosticCompleted'] == true) {
            return true;
          }
        }
      } catch (e) {
        // Fallback to local storage
      }
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_diagnosticCompletedKey) ?? false;
  }

  static Future<String?> getUserLevel() async {
    final user = FirebaseService().currentUser;
    if (user != null && FirebaseService().isInitialized) {
      try {
        final doc = await FirebaseService().firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data();
          final profileData = data?['profile'] as Map<String, dynamic>?;
          if (profileData != null) {
            return profileData['diagnosticLevel'] as String?;
          }
        }
      } catch (e) {
        // Fallback to local storage
      }
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_diagnosticLevelKey);
  }

  static Future<DiagnosticResult?> getDiagnosticResult() async {
    final user = FirebaseService().currentUser;
    if (user != null && FirebaseService().isInitialized) {
      try {
        final doc = await FirebaseService().firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data();
          final profileData = data?['profile'] as Map<String, dynamic>?;
          if (profileData != null && profileData['diagnosticResult'] != null) {
            return DiagnosticResult.fromJson(
              profileData['diagnosticResult'] as Map<String, dynamic>,
            );
          }
        }
      } catch (e) {
        // Fallback to local storage
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final resultJson = prefs.getString(_diagnosticResultKey);
    if (resultJson == null) return null;

    try {
      return DiagnosticResult.fromJson(jsonDecode(resultJson));
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveDiagnosticResult(DiagnosticResult result) async {
    final user = FirebaseService().currentUser;
    if (user != null && FirebaseService().isInitialized) {
      try {
        await FirebaseService().firestore
            .collection('users')
            .doc(user.uid)
            .update({
          'profile.diagnosticCompleted': true,
          'profile.diagnosticLevel': result.level,
          'profile.diagnosticResult': result.toJson(),
        });
      } catch (e) {
        // Fallback to local storage
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_diagnosticCompletedKey, true);
    await prefs.setString(_diagnosticLevelKey, result.level);
    await prefs.setString(_diagnosticResultKey, jsonEncode(result.toJson()));
  }

  static DiagnosticResult calculateResult(List<int?> answers) {
    const questions = DiagnosticQuestionsData.questions;

    int correctAnswers = 0;

    for (int i = 0; i < questions.length; i++) {
      if (answers[i] != null && questions[i].isCorrect(answers[i]!)) {
        correctAnswers++;
      }
    }

    String level = correctAnswers >= 5 ? 'intermediate' : 'beginner';

    return DiagnosticResult(
      level: level,
      score: correctAnswers,
      totalQuestions: questions.length,
      basicCorrect: correctAnswers,
      intermediateCorrect: 0,
      advancedCorrect: 0,
      completedAt: DateTime.now(),
    );
  }

  static Future<void> resetDiagnostic() async {
    final user = FirebaseService().currentUser;
    if (user != null && FirebaseService().isInitialized) {
      try {
        await FirebaseService().firestore
            .collection('users')
            .doc(user.uid)
            .update({
          'profile.diagnosticCompleted': false,
          'profile.diagnosticLevel': FieldValue.delete(),
          'profile.diagnosticResult': FieldValue.delete(),
        });
      } catch (e) {
        // Fallback to local storage
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_diagnosticCompletedKey);
    await prefs.remove(_diagnosticLevelKey);
    await prefs.remove(_diagnosticResultKey);
  }
}
