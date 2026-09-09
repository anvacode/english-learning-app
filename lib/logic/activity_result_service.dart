import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/activity_result.dart';
import '../services/sync_service.dart';

class ActivityResultService {
  static const String _resultsKey = 'activity_results';

  /// Agrega un nuevo resultado de actividad al almacenamiento local.
  /// 
  /// [result] es la instancia de [ActivityResult] a persistir.
  /// Los resultados se guardan como lista JSON en shared_preferences.
  static Future<void> saveActivityResult(ActivityResult result) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Obtener lista actual de resultados
    final jsonString = prefs.getString(_resultsKey);
    final List<dynamic> jsonList = jsonString != null 
        ? jsonDecode(jsonString) 
        : [];
    
    // Agregar nuevo resultado
    jsonList.add(result.toJson());
    
    // Guardar lista actualizada
    await prefs.setString(_resultsKey, jsonEncode(jsonList));
    SyncService().scheduleSync();
  }

  /// Recupera todos los resultados de actividad guardados.
  /// 
  /// Retorna una lista vacía si no hay resultados previos.
  static Future<List<ActivityResult>> getActivityResults() async {
    final prefs = await SharedPreferences.getInstance();
    
    final jsonString = prefs.getString(_resultsKey);
    if (jsonString == null) {
      return [];
    }
    
    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .cast<Map<String, dynamic>>()
          .map((json) => ActivityResult.fromJson(json))
          .toList();
    } catch (e) {
      // Si ocurre un error al deserializar, retornar lista vacía
      return [];
    }
  }

  /// Limpia todos los resultados guardados
  static Future<void> clearActivityResults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_resultsKey);
  }

  /// Calcula métricas de desempeño para una lección específica.
  /// 
  /// Retorna un mapa con:
  /// - 'totalAttempts': número total de intentos
  /// - 'correctAttempts': número de respuestas correctas
  /// - 'accuracyPercentage': porcentaje de precisión (0-100)
  static Future<Map<String, dynamic>> getLessonMetrics(String lessonId) async {
    final allResults = await getActivityResults();
    
    final lessonResults = allResults
        .where((result) => result.lessonId == lessonId)
        .toList();
    
    if (lessonResults.isEmpty) {
      return {
        'totalAttempts': 0,
        'correctAttempts': 0,
        'accuracyPercentage': 0.0,
      };
    }
    
    final correctAttempts = lessonResults
        .where((result) => result.isCorrect)
        .length;
    
    final totalAttempts = lessonResults.length;
    final accuracyPercentage = (correctAttempts / totalAttempts) * 100;
    
    return {
      'totalAttempts': totalAttempts,
      'correctAttempts': correctAttempts,
      'accuracyPercentage': accuracyPercentage,
    };
  }

  /// Calcula métricas globales de todas las lecciones.
  static Future<Map<String, dynamic>> getGlobalMetrics() async {
    final allResults = await getActivityResults();
    
    if (allResults.isEmpty) {
      return {
        'totalAttempts': 0,
        'correctAttempts': 0,
        'accuracyPercentage': 0.0,
      };
    }
    
    final correctAttempts = allResults
        .where((result) => result.isCorrect)
        .length;
    
    final totalAttempts = allResults.length;
    final accuracyPercentage = (correctAttempts / totalAttempts) * 100;
    
    return {
      'totalAttempts': totalAttempts,
      'correctAttempts': correctAttempts,
      'accuracyPercentage': accuracyPercentage,
    };
  }
}
