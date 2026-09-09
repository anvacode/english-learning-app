import 'package:flutter/material.dart';

import '../../services/tutorial_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/tutorial_overlay.dart';
import 'tutorial_keys.dart';

/// Widget que envuelve una pantalla (tipicamente HomeScreen) y muestra
/// un tour interactivo paso a paso la primera vez.
///
/// Mide las posiciones reales de los widgets usando GlobalKeys después
/// del primer frame de layout, para que el spotlight siempre esté
/// perfectamente alineado con los elementos.
class InteractiveTutorial extends StatefulWidget {
  final Widget child;
  final VoidCallback onComplete;

  const InteractiveTutorial({
    super.key,
    required this.child,
    required this.onComplete,
  });

  @override
  State<InteractiveTutorial> createState() => _InteractiveTutorialState();
}

class _InteractiveTutorialState extends State<InteractiveTutorial> {
  bool _showOverlay = true;
  bool _isMeasuring = true;
  List<TutorialStep> _steps = [];

  @override
  void initState() {
    super.initState();
    _measureTargets();
  }

  /// Mide la posición exacta de cada widget clave después del layout.
  void _measureTargets() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final steps = <TutorialStep>[
        // Paso 1: Bienvenida (sin target, centrado)
        const TutorialStep(
          title: '¡Bienvenido!',
          description:
              'Esta es tu pantalla de inicio.\nAquí verás todo lo que puedes hacer para aprender inglés de forma divertida.',
          emoji: '🎉',
        ),

        // Paso 2: Estrellas
        _measureStep(
          key: TutorialKeys.starCounter,
          title: 'Tus Estrellas',
          description: 'Gana estrellas al completar lecciones.\n¡Acumula muchas para comprar cosas geniales!',
          emoji: '⭐',
          accentColor: AppColors.starGold,
        ),

        // Paso 3: Tarjeta Lecciones
        _measureStep(
          key: TutorialKeys.lessonsCard,
          title: 'Lecciones',
          description: 'Toca aquí para aprender inglés.\nEncontrarás colores, animales, frutas ¡y mucho más!',
          emoji: '📚',
          accentColor: const Color(0xFF667eea),
        ),

        // Paso 4: Tarjeta Perfil
        _measureStep(
          key: TutorialKeys.profileCard,
          title: 'Tu Perfil',
          description: 'Mira tu foto, tu nombre y cuánto has avanzado.\n¡Puedes cambiar tu avatar!',
          emoji: '👤',
          accentColor: const Color(0xFFf5576c),
        ),

        // Paso 5: Tarjeta Logros
        _measureStep(
          key: TutorialKeys.achievementsCard,
          title: 'Logros',
          description: 'Colecciona medallas especiales.\nCada lección que termines te da una nueva.',
          emoji: '🏆',
          accentColor: const Color(0xFFfa709a),
        ),

        // Paso 6: Tarjeta Tienda
        _measureStep(
          key: TutorialKeys.shopCard,
          title: 'Tienda',
          description: 'Gasta tus estrellas aquí.\nCompra colores, avatares y efectos mágicos.',
          emoji: '🏪',
          accentColor: const Color(0xFFa8edea),
        ),

        // Paso 7: Menú inferior
        _measureStep(
          key: TutorialKeys.bottomNav,
          title: 'Menú de Navegación',
          description: 'Aquí encuentras Lecciones, Práctica y Configuración.\n¡Explora todas las pestañas!',
          emoji: '🧭',
          accentColor: AppColors.tealOcean,
        ),

        // Paso 8: Listo
        const TutorialStep(
          title: '¡Listo para empezar!',
          description: 'Explora, aprende y diviértete.\n¡Toca el botón y a jugar!',
          emoji: '🚀',
          accentColor: AppColors.success,
        ),
      ];

      if (mounted) {
        setState(() {
          _steps = steps;
          _isMeasuring = false;
        });
      }
    });
  }

  /// Mide un widget por su GlobalKey y crea un TutorialStep.
  /// Si el widget no está renderizado, retorna un step centrado.
  TutorialStep _measureStep({
    required GlobalKey key,
    required String title,
    required String description,
    required String emoji,
    required Color accentColor,
  }) {
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return TutorialStep(
        title: title,
        description: description,
        emoji: emoji,
        accentColor: accentColor,
      );
    }

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    return TutorialStep(
      title: title,
      description: description,
      emoji: emoji,
      targetRect: Rect.fromLTWH(
        position.dx,
        position.dy,
        size.width,
        size.height,
      ),
      accentColor: accentColor,
    );
  }

  void _finish() {
    TutorialService.markInteractiveTutorialShown();
    setState(() {
      _showOverlay = false;
    });
    widget.onComplete();
  }

  void _skip() {
    TutorialService.markInteractiveTutorialShown();
    setState(() {
      _showOverlay = false;
    });
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showOverlay)
          _isMeasuring
              ? _buildLoadingOverlay()
              : TutorialOverlay(
                  steps: _steps,
                  onComplete: _finish,
                  onSkip: _skip,
                ),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withAlpha(180),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 4,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Preparando tu tour...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
