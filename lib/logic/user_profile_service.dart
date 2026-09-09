import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../services/sync_service.dart';

/// Servicio para manejar el perfil del usuario.
///
/// Gestiona la carga y guardado del perfil del usuario
/// usando SharedPreferences.
class UserProfileService {
  static const String _profileKey = 'user_profile';

  /// Carga el perfil del usuario desde SharedPreferences.
  ///
  /// Si no existe un perfil guardado, retorna un perfil por defecto.
  static Future<UserProfile> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_profileKey);

    if (jsonString == null || jsonString.isEmpty) {
      // Si no existe perfil, crear uno por defecto y guardarlo
      final defaultProfile = UserProfile.defaultProfile();
      await saveProfile(defaultProfile);
      return defaultProfile;
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return UserProfile.fromJson(json);
    } catch (e) {
      // Si hay error al deserializar, retornar perfil por defecto
      // Error loading user profile: $e
      final defaultProfile = UserProfile.defaultProfile();
      await saveProfile(defaultProfile);
      return defaultProfile;
    }
  }

  /// Guarda el perfil del usuario en SharedPreferences.
  ///
  /// Si [triggerSync] es true, dispara una sincronización con la nube.
  /// Usar triggerSync=false cuando se restaura desde la nube para evitar ciclos.
  static Future<void> saveProfile(
    UserProfile profile, {
    bool triggerSync = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(profile.toJson());
    await prefs.setString(_profileKey, jsonString);

    // Disparar sincronización con la nube (solo si se indica)
    if (triggerSync) {
      SyncService().syncUserDataDebounced();
    }
  }

  /// Actualiza el nickname del usuario.
  static Future<void> updateNickname(String nickname) async {
    final profile = await loadProfile();
    final updatedProfile = profile.copyWith(nickname: nickname);
    await saveProfile(updatedProfile);

    // Disparar sincronización con la nube
    SyncService().syncUserDataDebounced();
  }

  /// Actualiza el avatar del usuario.
  ///
  /// Acepta avatarId de 0-7 (predefinidos) o 8-10 (tienda).
  /// Para avatares de tienda (8-10), se debe verificar que estén comprados
  /// antes de llamar a este método.
  static Future<void> updateAvatar(int avatarId) async {
    if (avatarId < 0 || avatarId > 10) {
      throw ArgumentError('avatarId must be between 0 and 10');
    }
    final profile = await loadProfile();
    final updatedProfile = profile.copyWith(avatarId: avatarId);
    await saveProfile(updatedProfile);

    // Disparar sincronización con la nube
    SyncService().syncUserDataDebounced();
  }

  /// Resetea el perfil a valores por defecto.
  static Future<void> resetProfile() async {
    final defaultProfile = UserProfile.defaultProfile();
    await saveProfile(defaultProfile);

    // Disparar sincronización con la nube
    SyncService().syncUserDataDebounced();
  }
}
