import 'package:shared_preferences/shared_preferences.dart';

import '../models/shop_item.dart';
import 'shop_service.dart';

/// Servicio para gestionar los power-ups de la aplicación.
/// 
/// Maneja los power-ups comprados, su activación y expiración.
class PowerUpService {
  static const String _activePowerUpsKey = 'active_powerups';
  static const String _powerUpExpirationPrefix = 'powerup_expiration_';
  
  /// Obtiene los power-ups comprados por el usuario
  static Future<List<ShopItem>> getPurchasedPowerUps() async {
    final purchasedItems = await ShopService.getPurchasedItems();
    return purchasedItems.where((item) => item.type == ShopItemType.powerup).toList();
  }
  
  /// Verifica si un power-up está comprado
  static Future<bool> isPowerUpPurchased(String powerUpId) async {
    final purchasedPowerUps = await getPurchasedPowerUps();
    return purchasedPowerUps.any((item) => item.id == powerUpId);
  }
  
  /// Activa un power-up con duración específica
  static Future<void> activatePowerUp(String powerUpId, int durationDays) async {
    // Verificar que el power-up esté comprado
    final isPurchased = await isPowerUpPurchased(powerUpId);
    if (!isPurchased) {
      throw StateError('El power-up "$powerUpId" no ha sido comprado');
    }
    
    final prefs = await SharedPreferences.getInstance();
    
    // Calcular fecha de expiración
    final expirationDate = DateTime.now().add(Duration(days: durationDays));
    
    // Guardar fecha de expiración
    await prefs.setString(
      '$_powerUpExpirationPrefix$powerUpId',
      expirationDate.toIso8601String(),
    );
    
    // Agregar a la lista de power-ups activos
    final activePowerUps = await getActivePowerUpIds();
    activePowerUps.add(powerUpId);
    await prefs.setStringList(_activePowerUpsKey, activePowerUps.toList());
  }
  
  /// Obtiene los IDs de power-ups activos
  static Future<Set<String>> getActivePowerUpIds() async {
    final prefs = await SharedPreferences.getInstance();
    final activeList = prefs.getStringList(_activePowerUpsKey);
    return activeList?.toSet() ?? {};
  }
  
  /// Verifica si un power-up está activo (no expirado)
  static Future<bool> isPowerUpActive(String powerUpId) async {
    final prefs = await SharedPreferences.getInstance();
    final expirationString = prefs.getString('$_powerUpExpirationPrefix$powerUpId');
    
    if (expirationString == null) return false;
    
    try {
      final expirationDate = DateTime.parse(expirationString);
      final isActive = DateTime.now().isBefore(expirationDate);
      
      // Si expiró, limpiar
      if (!isActive) {
        await _deactivatePowerUp(powerUpId);
      }
      
      return isActive;
    } catch (e) {
      return false;
    }
  }
  
  /// Obtiene la fecha de expiración de un power-up
  static Future<DateTime?> getPowerUpExpiration(String powerUpId) async {
    final prefs = await SharedPreferences.getInstance();
    final expirationString = prefs.getString('$_powerUpExpirationPrefix$powerUpId');
    
    if (expirationString == null) return null;
    
    try {
      return DateTime.parse(expirationString);
    } catch (e) {
      return null;
    }
  }
  
  /// Obtiene el tiempo restante de un power-up en formato legible
  static Future<String?> getRemainingTime(String powerUpId) async {
    final expiration = await getPowerUpExpiration(powerUpId);
    if (expiration == null) return null;
    
    final now = DateTime.now();
    if (now.isAfter(expiration)) return null;
    
    final difference = expiration.difference(now);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'Menos de 1 minuto';
    }
  }
  
  /// Desactiva un power-up (interno)
  static Future<void> _deactivatePowerUp(String powerUpId) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Remover fecha de expiración
    await prefs.remove('$_powerUpExpirationPrefix$powerUpId');
    
    // Remover de la lista de activos
    final activePowerUps = await getActivePowerUpIds();
    activePowerUps.remove(powerUpId);
    await prefs.setStringList(_activePowerUpsKey, activePowerUps.toList());
  }
  
  /// Verifica si el multiplicador de estrellas está activo
  static Future<bool> isDoubleStarsActive() async {
    return await isPowerUpActive('powerup_double_stars');
  }
  
  /// Obtiene el multiplicador de estrellas actual
  static Future<double> getStarMultiplier() async {
    final isDoubleActive = await isDoubleStarsActive();
    return isDoubleActive ? 2.0 : 1.0;
  }
  
  /// Aplica el multiplicador a una cantidad de estrellas
  static Future<int> applyMultiplier(int baseStars) async {
    final multiplier = await getStarMultiplier();
    return (baseStars * multiplier).round();
  }
  
  /// Obtiene información del power-up para mostrar en UI
  static Map<String, dynamic> getPowerUpInfo(String powerUpId) {
    switch (powerUpId) {
      case 'powerup_double_stars':
        return {
          'name': 'Doble Estrellas',
          'description': 'Gana el doble de estrellas',
          'icon': '⚡',
          'duration': 3,
          'multiplier': 2.0,
        };
      default:
        return {
          'name': 'Power-up',
          'description': 'Power-up especial',
          'icon': '⚡',
          'duration': 1,
          'multiplier': 1.0,
        };
    }
  }
  
  /// Obtiene todos los power-ups activos con su información
  static Future<List<Map<String, dynamic>>> getActivePowerUpsInfo() async {
    final activePowerUps = await getActivePowerUpIds();
    final List<Map<String, dynamic>> result = [];
    
    for (final powerUpId in activePowerUps) {
      final isActive = await isPowerUpActive(powerUpId);
      if (isActive) {
        final info = getPowerUpInfo(powerUpId);
        final remaining = await getRemainingTime(powerUpId);
        result.add({
          ...info,
          'id': powerUpId,
          'remainingTime': remaining,
        });
      }
    }
    
    return result;
  }
  
  /// Limpia todos los power-ups (solo para testing)
  static Future<void> clearAllPowerUps() async {
    final prefs = await SharedPreferences.getInstance();
    final activePowerUps = await getActivePowerUpIds();
    
    for (final powerUpId in activePowerUps) {
      await prefs.remove('$_powerUpExpirationPrefix$powerUpId');
    }
    
    await prefs.remove(_activePowerUpsKey);
  }
}
