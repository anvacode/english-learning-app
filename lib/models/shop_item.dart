/// Modelo que representa un ítem de la tienda.
/// 
/// Define los ítems que los usuarios pueden comprar con estrellas.
class ShopItem {
  final String id;
  final String name;
  final String description;
  final int price;
  final ShopItemType type;
  final String icon; // Emoji o ícono
  final String? imageAsset; // Ruta de imagen si aplica
  final Map<String, dynamic>? metadata; // Datos adicionales según el tipo

  const ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.type,
    required this.icon,
    this.imageAsset,
    this.metadata,
  });

  /// Convierte ShopItem a JSON para persistencia.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'type': type.toString().split('.').last,
      'icon': icon,
      if (imageAsset != null) 'imageAsset': imageAsset,
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Crea una instancia de ShopItem desde JSON.
  factory ShopItem.fromJson(Map<String, dynamic> json) {
    return ShopItem(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: json['price'] as int,
      type: ShopItemType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => ShopItemType.other,
      ),
      icon: json['icon'] as String,
      imageAsset: json['imageAsset'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// Tipos de ítems disponibles en la tienda.
enum ShopItemType {
  avatar,      // Avatares personalizados
  effect,      // Efectos visuales
  content,     // Contenido extra
  powerup,     // Power-ups temporales
  other,       // Otros ítems
}
