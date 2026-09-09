import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/student.dart';

class StudentService {
  static const String _studentIdKey = 'student_id';

  /// Inicializa o recupera el estudiante local.
  ///
  /// Si es la primera ejecución, genera un nuevo UUID único.
  /// Si ya existe un estudiante guardado, lo recupera.
  ///
  /// Retorna una instancia de [Student] con los datos persisted.
  static Future<Student> initializeStudent() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      String? studentId = prefs.getString(_studentIdKey);

      // Si no existe ID, generar uno nuevo
      if (studentId == null) {
        studentId = const Uuid().v4();
        await prefs.setString(_studentIdKey, studentId);
      }

      return Student(id: studentId);
    } catch (e) {
      debugPrint('Error initializing student: $e');
      // Fallback: return student with temporary ID
      return Student(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      );
    }
  }
}
