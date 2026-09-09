import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/star_transaction.dart';
import '../services/sync_service.dart';

/// Servicio para manejar el sistema de estrellas.
/// 
/// Gestiona la ganancia, gasto y historial de estrellas del usuario.
/// Persiste todas las transacciones en SharedPreferences.
class StarService {
  static const String _transactionsKey = 'star_transactions';
  static const String _totalStarsKey = 'total_stars';
  static const String _lastDailyResetKey = 'last_daily_reset';
  static const String _dailyEarningsKey = 'daily_stars_earned';
  static const String _lastLoginDateKey = 'last_login_date';
  static const String _loginStreakKey = 'login_streak';
  
  // Notificador para actualización en tiempo real del contador de estrellas
  static final ValueNotifier<int> starCountNotifier = ValueNotifier<int>(0);

  // Mutex para evitar race conditions en operaciones concurrentes
  static Future<void>? _lock;

  /// Ejecuta una función de forma exclusiva (mutex).
  static Future<T> _withLock<T>(Future<T> Function() fn) async {
    while (_lock != null) {
      await _lock!;
    }
    final completer = Completer<void>();
    _lock = completer.future;
    try {
      return await fn();
    } finally {
      _lock = null;
      completer.complete();
    }
  }

  /// Obtiene el total de estrellas del usuario.
  /// 
  /// Calcula el total sumando todas las transacciones guardadas.
  /// Si no hay transacciones, retorna 0.
  static Future<int> getTotalStars() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Intentar obtener el total guardado (para optimización)
    final cachedTotal = prefs.getInt(_totalStarsKey);
    if (cachedTotal != null) {
      // Verificar que el cache esté sincronizado
      final transactions = await getTransactionHistory();
      final calculatedTotal = transactions.fold<int>(
        0,
        (sum, transaction) => sum + transaction.amount,
      );
      
      // Si hay discrepancia, recalcular y guardar
      if (cachedTotal != calculatedTotal) {
        await prefs.setInt(_totalStarsKey, calculatedTotal);
        return calculatedTotal;
      }
      
      return cachedTotal;
    }
    
    // Si no hay cache, calcular desde transacciones
    final transactions = await getTransactionHistory();
    final total = transactions.fold<int>(
      0,
      (sum, transaction) => sum + transaction.amount,
    );
    
    // Guardar cache
    await prefs.setInt(_totalStarsKey, total);
    
    return total;
  }

  /// Agrega estrellas al usuario.
  /// 
  /// [amount] es la cantidad de estrellas a agregar (debe ser positivo).
  /// [type] es el tipo de transacción ('lesson_complete', 'daily_login', 'streak_bonus', etc.).
  /// [lessonId] es opcional y se usa si la transacción está relacionada con una lección.
  /// [description] es una descripción legible de la transacción.
  /// [applyMultiplier] indica si se debe aplicar el multiplicador de power-ups (default: true).
  static Future<void> addStars(
    int amount,
    String type, {
    String? lessonId,
    String? description,
    bool applyMultiplier = true,
  }) async {
    await _withLock(() async {
      if (amount <= 0) {
        throw ArgumentError('Amount must be positive');
      }

      // Aplicar multiplicador de power-ups si está activo
      int finalAmount = amount;
      if (applyMultiplier) {
        // Import dinámico para evitar dependencia circular
        final multiplier = await _getStarMultiplier();
        finalAmount = (amount * multiplier).round();
      }

      final prefs = await SharedPreferences.getInstance();
      final transactions = await getTransactionHistory();
      
      // Generar ID único para la transacción
      final transactionId = const Uuid().v4();
      
      // Crear descripción por defecto si no se proporciona
      String finalDescription = description ?? _getDefaultDescription(type, finalAmount, lessonId);
      
      // Agregar indicador de multiplicador si se aplicó
      if (applyMultiplier && finalAmount > amount) {
        finalDescription = '$finalDescription (x2 ⚡)';
      }
      
      // Crear nueva transacción
      final transaction = StarTransaction(
        id: transactionId,
        type: type,
        amount: finalAmount,
        description: finalDescription,
        timestamp: DateTime.now(),
        lessonId: lessonId,
      );
      
      // Agregar a la lista
      transactions.add(transaction);

      // Guardar transacciones
      await _saveTransactions(transactions);

      // Actualizar total en cache
      final currentTotal = await getTotalStars();
      final newTotal = currentTotal + finalAmount;
      await prefs.setInt(_totalStarsKey, newTotal);

      // Notificar cambio en tiempo real
      starCountNotifier.value = newTotal;

      // Disparar sincronización con la nube
      SyncService().syncUserDataDebounced();
    });
  }
  
  /// Obtiene el multiplicador de estrellas actual (para power-ups).
  static Future<double> _getStarMultiplier() async {
    final prefs = await SharedPreferences.getInstance();
    final expirationString = prefs.getString('powerup_expiration_powerup_double_stars');
    
    if (expirationString == null) return 1.0;
    
    try {
      final expirationDate = DateTime.parse(expirationString);
      if (DateTime.now().isBefore(expirationDate)) {
        return 2.0; // Doble estrellas activo
      }
    } catch (e) {
      // Error al parsear fecha
    }
    
    return 1.0;
  }

  /// Gasta estrellas del usuario.
  /// 
  /// [amount] es la cantidad de estrellas a gastar (debe ser positivo).
  /// [itemName] es el nombre del ítem comprado.
  /// 
  /// Lanza una excepción si el usuario no tiene suficientes estrellas.
  static Future<void> spendStars(int amount, String itemName) async {
    await _withLock(() async {
      if (amount <= 0) {
        throw ArgumentError('Amount must be positive');
      }

      final totalStars = await getTotalStars();
      if (totalStars < amount) {
        throw StateError('Insufficient stars. Required: $amount, Available: $totalStars');
      }

      final prefs = await SharedPreferences.getInstance();
      final transactions = await getTransactionHistory();
      
      // Generar ID único para la transacción
      final transactionId = const Uuid().v4();
      
      // Crear transacción de gasto (amount negativo)
      final transaction = StarTransaction(
        id: transactionId,
        type: 'shop_purchase',
        amount: -amount, // Negativo para gastos
        description: 'Compra: $itemName',
        timestamp: DateTime.now(),
        itemName: itemName,
      );
      
      // Agregar a la lista
      transactions.add(transaction);

      // Guardar transacciones
      await _saveTransactions(transactions);

      // Actualizar total en cache
      final newTotal = totalStars - amount;
      await prefs.setInt(_totalStarsKey, newTotal);

      // Notificar cambio en tiempo real
      starCountNotifier.value = newTotal;

      // Disparar sincronización con la nube
      SyncService().syncUserDataDebounced();
    });
  }

  /// Obtiene el historial completo de transacciones.
  /// 
  /// Retorna todas las transacciones ordenadas por fecha (más recientes primero).
  static Future<List<StarTransaction>> getTransactionHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_transactionsKey);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      final transactions = jsonList
          .map((item) => StarTransaction.fromJson(item as Map<String, dynamic>))
          .toList();
      
      // Ordenar por fecha (más recientes primero)
      transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return transactions;
    } catch (e) {
      // Error decoding star transactions: $e
      return [];
    }
  }

  /// Obtiene las estrellas ganadas hoy.
  /// 
  /// Suma todas las transacciones de ganancia del día actual.
  static Future<int> getStarsEarnedToday() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    
    final transactions = await getTransactionHistory();
    
    return transactions
        .where((t) => t.isEarning && t.timestamp.isAfter(todayStart))
        .fold<int>(0, (sum, t) => sum + t.amount);
  }

  /// Resetea las ganancias diarias (llamado a medianoche).
  /// 
  /// Este método debe ser llamado por un sistema de tareas programadas
  /// o al iniciar la app si detecta que es un nuevo día.
  static Future<void> resetDailyEarnings() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    
    // Guardar la fecha del último reset
    await prefs.setString(_lastDailyResetKey, now.toIso8601String());
    
    // Resetear contador diario
    await prefs.setInt(_dailyEarningsKey, 0);
  }

  /// Verifica y resetea las ganancias diarias si es necesario.
  /// 
  /// Debe llamarse al iniciar la app para verificar si es un nuevo día.
  static Future<void> checkAndResetDailyEarnings() async {
    final prefs = await SharedPreferences.getInstance();
    final lastResetString = prefs.getString(_lastDailyResetKey);
    
    if (lastResetString == null) {
      // Primera vez, inicializar
      await resetDailyEarnings();
      return;
    }
    
    final lastReset = DateTime.parse(lastResetString);
    final now = DateTime.now();
    
    // Verificar si es un nuevo día
    if (now.year != lastReset.year ||
        now.month != lastReset.month ||
        now.day != lastReset.day) {
      await resetDailyEarnings();
    }
  }

  /// Obtiene la racha de login del usuario.
  static Future<int> getLoginStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_loginStreakKey) ?? 0;
  }

  /// Actualiza la racha de login.
  /// 
  /// Debe llamarse cuando el usuario inicia sesión.
  /// Incrementa la racha si es un día consecutivo, o la resetea a 1 si no.
  static Future<int> updateLoginStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final lastLoginString = prefs.getString(_lastLoginDateKey);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    int currentStreak = await getLoginStreak();
    
    if (lastLoginString == null) {
      // Primera vez que inicia sesión
      currentStreak = 1;
    } else {
      final lastLogin = DateTime.parse(lastLoginString);
      final lastLoginDate = DateTime(lastLogin.year, lastLogin.month, lastLogin.day);
      
      final daysDifference = today.difference(lastLoginDate).inDays;
      
      if (daysDifference == 0) {
        // Ya inició sesión hoy, no hacer nada
        return currentStreak;
      } else if (daysDifference == 1) {
        // Día consecutivo, incrementar racha
        currentStreak++;
      } else {
        // Racha rota, resetear a 1
        currentStreak = 1;
      }
    }
    
    // Guardar nueva racha y fecha de login
    await prefs.setInt(_loginStreakKey, currentStreak);
    await prefs.setString(_lastLoginDateKey, now.toIso8601String());
    
    return currentStreak;
  }

  /// Procesa el login diario y otorga recompensas.
  /// 
  /// Otorga estrellas por login diario y bonos por racha.
  /// Retorna la cantidad total de estrellas ganadas.
  /// Si ya se otorgaron estrellas hoy, retorna 0.
  static Future<int> processDailyLogin() async {
    await checkAndResetDailyEarnings();
    
    final prefs = await SharedPreferences.getInstance();
    final lastLoginString = prefs.getString(_lastLoginDateKey);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Verificar si ya se procesó el login hoy
    if (lastLoginString != null) {
      final lastLogin = DateTime.parse(lastLoginString);
      final lastLoginDate = DateTime(lastLogin.year, lastLogin.month, lastLogin.day);
      
      // Si ya inició sesión hoy, no otorgar estrellas nuevamente
      if (lastLoginDate.isAtSameMomentAs(today)) {
        return 0; // Ya se otorgaron estrellas hoy
      }
    }
    
    final streak = await updateLoginStreak();
    int totalEarned = 0;
    
    // Recompensa base por login diario
    const dailyLoginReward = 10;
    await addStars(
      dailyLoginReward,
      'daily_login',
      description: 'Login diario',
      applyMultiplier: false, // No aplicar multiplicador a login diario
    );
    totalEarned += dailyLoginReward;
    
    // Bono por racha (5 estrellas extra por cada día de racha después del primero)
    if (streak > 1) {
      final streakBonus = (streak - 1) * 5;
      if (streakBonus > 0) {
        await addStars(
          streakBonus,
          'streak_bonus',
          description: 'Bono de racha ($streak días)',
          applyMultiplier: false, // No aplicar multiplicador a bonos de racha
        );
        totalEarned += streakBonus;
      }
    }
    
    return totalEarned;
  }

  /// Guarda las transacciones en SharedPreferences.
  static Future<void> _saveTransactions(List<StarTransaction> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = transactions.map((t) => t.toJson()).toList();
    await prefs.setString(_transactionsKey, jsonEncode(jsonList));
  }

  /// Genera una descripción por defecto basada en el tipo de transacción.
  static String _getDefaultDescription(String type, int amount, String? lessonId) {
    switch (type) {
      case 'lesson_complete':
        return 'Completaste una lección (+$amount ⭐)';
      case 'perfect_score':
        return 'Puntuación perfecta (+$amount ⭐)';
      case 'daily_login':
        return 'Login diario (+$amount ⭐)';
      case 'streak_bonus':
        return 'Bono de racha (+$amount ⭐)';
      case 'shop_purchase':
        return 'Compra en tienda (-$amount ⭐)';
      default:
        return 'Transacción de estrellas (${amount > 0 ? '+' : ''}$amount ⭐)';
    }
  }

  /// Limpia todas las transacciones (solo para testing).
  static Future<void> clearAllTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_transactionsKey);
    await prefs.remove(_totalStarsKey);
    await prefs.remove(_lastDailyResetKey);
    await prefs.remove(_dailyEarningsKey);
    await prefs.remove(_lastLoginDateKey);
    await prefs.remove(_loginStreakKey);
  }
}
