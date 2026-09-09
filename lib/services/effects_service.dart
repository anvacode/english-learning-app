import 'package:shared_preferences/shared_preferences.dart';

import '../models/shop_item.dart';
import 'shop_service.dart';

/// Servicio para gestionar los efectos visuales de la aplicación.
/// 
/// Maneja los efectos comprados (confetti, sparkles) y su estado activo.
class EffectsService {
  static const String _activeEffectsKey = 'active_effects';
  
  /// Obtiene los efectos comprados por el usuario
  static Future<List<ShopItem>> getPurchasedEffects() async {
    final purchasedItems = await ShopService.getPurchasedItems();
    return purchasedItems.where((item) => item.type == ShopItemType.effect).toList();
  }
  
  /// Verifica si un efecto está comprado
  static Future<bool> isEffectPurchased(String effectId) async {
    final purchasedEffects = await getPurchasedEffects();
    return purchasedEffects.any((item) => item.metadata?['effectId'] == effectId);
  }
  
  /// Obtiene los efectos activos
  static Future<Set<String>> getActiveEffects() async {
    final prefs = await SharedPreferences.getInstance();
    final activeList = prefs.getStringList(_activeEffectsKey);
    return activeList?.toSet() ?? {};
  }
  
  /// Verifica si un efecto está activo
  static Future<bool> isEffectActive(String effectId) async {
    final activeEffects = await getActiveEffects();
    return activeEffects.contains(effectId);
  }
  
  /// Activa o desactiva un efecto
  static Future<void> setEffectActive(String effectId, bool active) async {
    // Verificar que el efecto esté comprado
    final isPurchased = await isEffectPurchased(effectId);
    if (!isPurchased) {
      throw StateError('El efecto "$effectId" no ha sido comprado');
    }
    
    final prefs = await SharedPreferences.getInstance();
    final activeEffects = await getActiveEffects();
    
    if (active) {
      activeEffects.add(effectId);
    } else {
      activeEffects.remove(effectId);
    }
    
    await prefs.setStringList(_activeEffectsKey, activeEffects.toList());
  }
  
  /// Activa un efecto automáticamente al comprarlo
  static Future<void> activateOnPurchase(String effectId) async {
    final prefs = await SharedPreferences.getInstance();
    final activeEffects = await getActiveEffects();
    activeEffects.add(effectId);
    await prefs.setStringList(_activeEffectsKey, activeEffects.toList());
  }
  
  /// Verifica si el efecto confetti debe mostrarse.
  /// Los efectos son gratuitos por defecto, siempre activos.
  static Future<bool> shouldShowConfetti() async {
    final isPurchased = await isEffectPurchased('confetti');
    if (!isPurchased) return true; // gratuito por defecto

    final isActive = await isEffectActive('confetti');
    return isActive;
  }

  /// Verifica si el efecto sparkles debe mostrarse.
  /// Los efectos son gratuitos por defecto, siempre activos.
  static Future<bool> shouldShowSparkles() async {
    final isPurchased = await isEffectPurchased('sparkles');
    if (!isPurchased) return true; // gratuito por defecto

    final isActive = await isEffectActive('sparkles');
    return isActive;
  }
  
  /// Obtiene información del efecto para mostrar en UI
  static Map<String, dynamic> getEffectInfo(String effectId) {
    switch (effectId) {
      case 'confetti':
        return {
          'name': 'Confeti',
          'description': 'Confeti dorado al completar lecciones',
          'icon': '✨',
        };
      case 'sparkles':
        return {
          'name': 'Estrellitas',
          'description': 'Estrellitas mágicas en cada respuesta correcta',
          'icon': '💫',
        };
      default:
        return {
          'name': 'Efecto',
          'description': 'Efecto visual',
          'icon': '✨',
        };
    }
  }
}
