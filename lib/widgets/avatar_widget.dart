import 'package:flutter/material.dart';

import '../theme/app_colors_extension.dart';

/// Widget que muestra un avatar circular.
/// 
/// Soporta avatares predefinidos (0-7) usando emojis
/// y avatares de tienda (8-10) con emojis especiales.
class AvatarWidget extends StatelessWidget {
  final int avatarId;
  final double size;
  final Color? backgroundColor;

  const AvatarWidget({
    super.key,
    required this.avatarId,
    this.size = 80,
    this.backgroundColor,
  });

  /// Lista de emojis para avatares predefinidos (0-7).
  static const List<String> _avatarEmojis = [
    '👤', // 0 - Persona genérica
    '👦', // 1 - Niño
    '👧', // 2 - Niña
    '🧑', // 3 - Persona adulta
    '👨', // 4 - Hombre
    '👩', // 5 - Mujer
    '🦸', // 6 - Superhéroe
    '🦹', // 7 - Supervillano
  ];
  
  /// Avatares de tienda (8-10) - requieren compra
  static const Map<int, String> _shopAvatarEmojis = {
    8: '⭐', // Avatar Estrella
    9: '🏆', // Avatar Campeón
    10: '🦸', // Avatar Superhéroe (versión premium)
  };
  
  /// Nombres de los avatares de tienda
  static const Map<int, String> shopAvatarNames = {
    8: 'Estrella',
    9: 'Campeón',
    10: 'Superhéroe',
  };
  
  /// Verifica si un avatarId es de tienda
  static bool isShopAvatar(int avatarId) {
    return _shopAvatarEmojis.containsKey(avatarId);
  }
  
  /// Obtiene todos los IDs de avatares de tienda
  static List<int> get shopAvatarIds => _shopAvatarEmojis.keys.toList();

  String get _avatarEmoji {
    // Primero verificar si es un avatar de tienda
    if (_shopAvatarEmojis.containsKey(avatarId)) {
      return _shopAvatarEmojis[avatarId]!;
    }
    // Luego verificar avatares predefinidos
    if (avatarId >= 0 && avatarId < _avatarEmojis.length) {
      return _avatarEmojis[avatarId];
    }
    return _avatarEmojis[0]; // Default
  }

  @override
  Widget build(BuildContext context) {
    final defaultBackgroundColor = backgroundColor ??
        Theme.of(context).colorScheme.primaryContainer;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: defaultBackgroundColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withAlpha(76),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: context.appColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          _avatarEmoji,
          style: TextStyle(fontSize: size * 0.5),
        ),
      ),
    );
  }
}
