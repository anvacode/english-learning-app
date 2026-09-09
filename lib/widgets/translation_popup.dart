import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../theme/app_colors_extension.dart';

/// Widget que muestra una traducción en un popup temporal.
/// 
/// Diseñado para mostrar traducciones de palabras cuando el usuario
/// toca una palabra durante las lecciones.
class TranslationPopup extends StatefulWidget {
  final String word;
  final String translation;
  final Offset position;

  const TranslationPopup({
    super.key,
    required this.word,
    required this.translation,
    required this.position,
  });

  /// Muestra el popup de traducción en la posición especificada.
  static void show(
    BuildContext context, {
    required String word,
    required String translation,
    Offset? position,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    // Si no se proporciona posición, usar el centro de la pantalla
    final displayPosition = position ?? 
      Offset(
        MediaQuery.of(context).size.width / 2,
        MediaQuery.of(context).size.height / 2,
      );

    overlayEntry = OverlayEntry(
      builder: (context) => _TranslationOverlay(
        word: word,
        translation: translation,
        position: displayPosition,
        onDismiss: () {
          overlayEntry.remove();
        },
      ),
    );

    overlay.insert(overlayEntry);

    // Auto-cerrar después de 3 segundos
    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  @override
  State<TranslationPopup> createState() => _TranslationPopupState();
}

class _TranslationPopupState extends State<TranslationPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  // Estas animaciones no se usan porque usamos _TranslationOverlay
  // late Animation<double> _scaleAnimation;
  // late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(); // Este widget no se usa directamente
  }
}

/// Overlay interno que muestra el popup de traducción
class _TranslationOverlay extends StatefulWidget {
  final String word;
  final String translation;
  final Offset position;
  final VoidCallback onDismiss;

  const _TranslationOverlay({
    required this.word,
    required this.translation,
    required this.position,
    required this.onDismiss,
  });

  @override
  State<_TranslationOverlay> createState() => _TranslationOverlayState();
}

class _TranslationOverlayState extends State<_TranslationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      behavior: HitTestBehavior.translucent,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Fondo semi-transparente
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                color: Colors.black.withAlpha(76),
              ),
            ),

            // Popup de traducción
            Positioned(
              left: widget.position.dx - 100, // Centrar aproximadamente
              top: widget.position.dy - 80,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  width: 200,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue[700]!,
                        Colors.blue[500]!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: context.appColors.shadow,
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Palabra en inglés con botón de audio
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.translate,
                            color: Colors.white70,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              widget.word,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Botón de audio
                          IconButton(
                            onPressed: () async {
                              final audio = AudioService();
                              await audio.initialize();
                              await audio.speak(widget.word);
                            },
                            icon: const Icon(
                              Icons.volume_up,
                              color: Colors.white,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                            tooltip: 'Escuchar pronunciación',
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Divisor
                      Container(
                        height: 1,
                        color: Colors.white.withAlpha(76),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Traducción en español
                      Text(
                        widget.translation,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Indicador de que se puede tocar para cerrar
                      Text(
                        'Toca para cerrar',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withAlpha(178),
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget de texto que permite mostrar traducción al tocar.
/// 
/// Wrapper conveniente para texto que necesita traducción al tocar.
class TranslatableText extends StatelessWidget {
  final String text;
  final String translation;
  final TextStyle? style;
  final TextAlign? textAlign;

  const TranslatableText({
    super.key,
    required this.text,
    required this.translation,
    this.style,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        TranslationPopup.show(
          context,
          word: text,
          translation: translation,
        );
      },
      child: Text(
        text,
        style: (style ?? const TextStyle()).copyWith(
          decoration: TextDecoration.underline,
          decorationStyle: TextDecorationStyle.dotted,
          decorationColor: Colors.blue,
        ),
        textAlign: textAlign,
      ),
    );
  }
}

/// Servicio simple de traducción (diccionario básico).
/// 
/// Para una implementación completa, considera usar una API de traducción.
class TranslationService {
  // Diccionario básico inglés-español
  static final Map<String, String> _translations = {
    // Frutas
    'apple': 'manzana',
    'banana': 'plátano',
    'orange': 'naranja',
    'grape': 'uva',
    'strawberry': 'fresa',
    'watermelon': 'sandía',
    'pineapple': 'piña',
    'pear': 'pera',
    
    // Animales
    'dog': 'perro',
    'cat': 'gato',
    'bird': 'pájaro',
    'fish': 'pez',
    'cow': 'vaca',
    'horse': 'caballo',
    'elephant': 'elefante',
    'chicken': 'pollo',
    
    // Colores
    'red': 'rojo',
    'blue': 'azul',
    'green': 'verde',
    'yellow': 'amarillo',
    'black': 'negro',
    'white': 'blanco',
    // 'orange': 'naranja', // Ya definido en Frutas
    'purple': 'morado',
    
    // Números
    'one': 'uno',
    'two': 'dos',
    'three': 'tres',
    'four': 'cuatro',
    'five': 'cinco',
    'six': 'seis',
    'seven': 'siete',
    'eight': 'ocho',
    'nine': 'nueve',
    'ten': 'diez',
    
    // Familia
    'mother': 'madre',
    'father': 'padre',
    'brother': 'hermano',
    'sister': 'hermana',
    'family': 'familia',
    'grandfather': 'abuelo',
    'grandmother': 'abuela',
    
    // Cuerpo
    'head': 'cabeza',
    'eye': 'ojo',
    'nose': 'nariz',
    'mouth': 'boca',
    'ear': 'oreja',
    'hand': 'mano',
    'foot': 'pie',
    'arm': 'brazo',
    'leg': 'pierna',
    'hair': 'cabello',
    
    // Acciones
    'run': 'correr',
    'jump': 'saltar',
    'eat': 'comer',
    'sleep': 'dormir',
    'walk': 'caminar',
    'sit': 'sentarse',
    'stand': 'pararse',
    'drink': 'beber',
    
    // Profesiones
    'doctor': 'médico',
    'teacher': 'profesor/a',
    'firefighter': 'bombero',
    'nurse': 'enfermero/a',
    'pilot': 'piloto',
    'chef': 'chef',
    'police officer': 'policía',
    'dentist': 'dentista',
    
    // Comunes
    'hello': 'hola',
    'goodbye': 'adiós',
    'yes': 'sí',
    'no': 'no',
    'please': 'por favor',
    'thank you': 'gracias',
    'sorry': 'perdón',
    'excuse me': 'disculpe',
    
    // Ropa (intermedio)
    'shirt': 'camisa',
    'pants': 'pantalones',
    'dress': 'vestido',
    'shoes': 'zapatos',
    'hat': 'sombrero',
    'socks': 'calcetines',
    'jacket': 'chaqueta',
    'skirt': 'falda',
    'coat': 'abrigo',
    'sweater': 'suéter',
    'gloves': 'guantes',
    'scarf': 'bufanda',
    'boots': 'botas',
    'sunglasses': 'gafas de sol',
    
    // Comida y bebidas (intermedio)
    'bread': 'pan',
    'milk': 'leche',
    'water': 'agua',
    'egg': 'huevo',
    'cheese': 'queso',
    'rice': 'arroz',
    'juice': 'jugo',
    'cake': 'pastel',
    'pizza': 'pizza',
    'sandwich': 'sándwich',
    'soup': 'sopa',
    'salad': 'ensalada',
    'breakfast': 'desayuno',
    'lunch': 'almuerzo',
    'dinner': 'cena',
    'snack': 'merienda',
    
    // Transporte (intermedio)
    'car': 'carro/auto',
    'bus': 'autobús',
    'train': 'tren',
    'airplane': 'avión',
    'bicycle': 'bicicleta',
    'boat': 'barco',
    'motorcycle': 'motocicleta',
    'helicopter': 'helicóptero',
    
    // Lugares (intermedio)
    'hospital': 'hospital',
    'school': 'escuela',
    'park': 'parque',
    'supermarket': 'supermercado',
    'library': 'biblioteca',
    'restaurant': 'restaurante',
    'bank': 'banco',
    'museum': 'museo',
    
    // Clima y estaciones (intermedio)
    'sunny': 'soleado',
    'rainy': 'lluvioso',
    'cloudy': 'nublado',
    'snowy': 'nevado',
    'windy': 'ventoso',
    'spring': 'primavera',
    'summer': 'verano',
    'fall': 'otoño',
    'winter': 'invierno',
    
    // Emociones (intermedio)
    'happy': 'feliz',
    'sad': 'triste',
    'angry': 'enojado/a',
    'excited': 'emocionado/a',
    'scared': 'asustado/a',
    'tired': 'cansado/a',
    'surprised': 'sorprendido/a',
    'proud': 'orgulloso/a',
    
    // Rutinas diarias (intermedio)
    'wake up': 'despertar',
    'brush teeth': 'cepillar dientes',
    'take a shower': 'ducharse',
    'get dressed': 'vestirse',
    'eat breakfast': 'desayunar',
    'go to school': 'ir a la escuela',
    'do homework': 'hacer tarea',
    'go to bed': 'ir a dormir',
    
    // Materias escolares (intermedio)
    'math': 'matemáticas',
    'science': 'ciencias',
    'english': 'inglés',
    'history': 'historia',
    'art': 'arte',
    'music': 'música',
    'physical education': 'educación física',
    'geography': 'geografía',
    
    // Deportes y hobbies (intermedio)
    'soccer': 'fútbol',
    'basketball': 'baloncesto',
    'tennis': 'tenis',
    'swimming': 'natación',
    'reading': 'lectura',
    'painting': 'pintura',
    'dancing': 'baile',
    'singing': 'canto',
    
    // Adjetivos (avanzado)
    'big': 'grande',
    'small': 'pequeño/a',
    'tall': 'alto/a',
    'short': 'bajo/a',
    'fast': 'rápido/a',
    'slow': 'lento/a',
    'hot': 'caliente',
    'cold': 'frío/a',
    'new': 'nuevo/a',
    'old': 'viejo/a',
    'good': 'bueno/a',
    'bad': 'malo/a',
    'beautiful': 'hermoso/a',
    'ugly': 'feo/a',
    'expensive': 'caro/a',
    'cheap': 'barato/a',
    
    // Preposiciones (avanzado)
    'in': 'en',
    'on': 'sobre',
    'under': 'debajo de',
    'between': 'entre',
    'behind': 'detrás de',
    'in front of': 'delante de',
    'next to': 'al lado de',
    'above': 'encima de',
    'below': 'debajo de',
  };

  /// Obtiene la traducción de una palabra.
  /// 
  /// Retorna la palabra original si no hay traducción disponible.
  static String translate(String word) {
    final lowercaseWord = word.toLowerCase().trim();
    return _translations[lowercaseWord] ?? word;
  }

  /// Verifica si una palabra tiene traducción disponible.
  static bool hasTranslation(String word) {
    final lowercaseWord = word.toLowerCase().trim();
    return _translations.containsKey(lowercaseWord);
  }
}
