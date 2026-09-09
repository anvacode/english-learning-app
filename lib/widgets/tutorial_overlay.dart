import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_colors_extension.dart';

/// Representa un paso del tour interactivo.
class TutorialStep {
  final String title;
  final String description;
  final String emoji;

  /// Área de la pantalla que se debe resaltar.
  /// Si es null, no se resalta nada (mensaje centrado).
  final Rect? targetRect;

  /// Color de acento para el borde del spotlight y el botón.
  final Color accentColor;

  const TutorialStep({
    required this.title,
    required this.description,
    required this.emoji,
    this.targetRect,
    this.accentColor = AppColors.primary,
  });
}

/// Dibuja el fondo oscuro con un agujero exacto donde está el target,
/// para que el widget real se vea perfectamente sin taparlo.
class TutorialPainter extends CustomPainter {
  final Rect? hole;
  final Color overlayColor;
  final Color borderColor;

  TutorialPainter({
    this.hole,
    required this.overlayColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = overlayColor;

    if (hole != null) {
      // Dibujar fondo oscuro completo
      final bgPath = Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

      // Crear agujero con bordes redondeados
      final holePath = Path()
        ..addRRect(
          RRect.fromRectAndRadius(hole!, const Radius.circular(20)),
        );

      // Fondo oscuro menos el agujero
      final finalPath = Path.combine(PathOperation.difference, bgPath, holePath);
      canvas.drawPath(finalPath, paint);

      // Borde brillante alrededor del agujero
      final borderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawRRect(
        RRect.fromRectAndRadius(hole!, const Radius.circular(20)),
        borderPaint,
      );
    } else {
      // Sin agujero: fondo oscuro completo
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant TutorialPainter oldDelegate) {
    return oldDelegate.hole != hole ||
        oldDelegate.overlayColor != overlayColor ||
        oldDelegate.borderColor != borderColor;
  }
}

/// Overlay de tutorial que muestra un fondo oscuro con agujero,
/// y una burbuja de diálogo explicativa bien posicionada.
class TutorialOverlay extends StatefulWidget {
  final List<TutorialStep> steps;
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  const TutorialOverlay({
    super.key,
    required this.steps,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with TickerProviderStateMixin {
  int _currentIndex = 0;

  late AnimationController _pulseController;
  late AnimationController _slideController;
  late AnimationController _bounceController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _slideController.forward();
    _bounceController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentIndex < widget.steps.length - 1) {
      _slideController.reverse().then((_) {
        if (!mounted) return;
        setState(() {
          _currentIndex++;
        });
        _bounceController.forward(from: 0);
        _slideController.forward();
      });
    } else {
      widget.onComplete();
    }
  }

  void _previousStep() {
    if (_currentIndex > 0) {
      _slideController.reverse().then((_) {
        if (!mounted) return;
        setState(() {
          _currentIndex--;
        });
        _bounceController.forward(from: 0);
        _slideController.forward();
      });
    }
  }

  TutorialStep get _currentStep => widget.steps[_currentIndex];
  bool get _isLastStep => _currentIndex == widget.steps.length - 1;
  bool get _isFirstStep => _currentIndex == 0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final safeTop = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    final step = _currentStep;
    final target = step.targetRect;

    // Calcular agujero con padding de pulso
    Rect? holeRect;
    if (target != null) {
      final pulseScale = 1.0 + (_pulseController.value * 0.03);
      final extra = 8.0 * pulseScale;
      holeRect = Rect.fromLTRB(
        target.left - extra,
        target.top - extra,
        target.right + extra,
        target.bottom + extra,
      );
    }

    return GestureDetector(
      onTap: () {},
      behavior: HitTestBehavior.opaque,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Fondo oscuro con agujero usando CustomPainter
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return CustomPaint(
                  size: size,
                  painter: TutorialPainter(
                    hole: holeRect,
                    overlayColor: Colors.black.withAlpha(180),
                    borderColor: step.accentColor.withAlpha(220),
                  ),
                );
              },
            ),

            // Burbuja explicativa
            _buildTooltip(size, safeTop, safeBottom),

            // Indicadores de progreso (arriba)
            Positioned(
              top: safeTop + 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.steps.length, (index) {
                  final isActive = index == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.white : Colors.white.withAlpha(80),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // Botón Saltar (arriba a la derecha)
            Positioned(
              top: safeTop + 8,
              right: 12,
              child: TextButton(
                onPressed: widget.onSkip,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withAlpha(40),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Saltar',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),

            // Controles inferiores
            Positioned(
              bottom: safeBottom + 12,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  if (!_isFirstStep)
                    TextButton.icon(
                      onPressed: _previousStep,
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      label: const Text(
                        'Atrás',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withAlpha(30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 90),

                  const Spacer(),

                  ElevatedButton.icon(
                    onPressed: _nextStep,
                    icon: Icon(
                      _isLastStep ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                      color: step.accentColor,
                      size: 20,
                    ),
                    label: Text(
                      _isLastStep ? '¡A jugar!' : 'Siguiente',
                      style: TextStyle(color: step.accentColor),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: step.accentColor,
                      elevation: 4,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTooltip(Size size, double safeTop, double safeBottom) {
    final step = _currentStep;
    final target = step.targetRect;

    // Zonas reservadas
    const bottomReserved = 90.0; // botones inferiores
    const topReserved = 60.0;    // indicadores + botón saltar
    const tooltipGap = 20.0;     // separación del target

    double? top;
    double? bottom;

    if (target != null) {
      final spaceAbove = target.top - safeTop - topReserved;
      final spaceBelow = size.height - target.bottom - safeBottom - bottomReserved;

      if (spaceBelow > spaceAbove && spaceBelow > 120) {
        // Hay más espacio ABAJO → burbuja DEBAJO del target
        top = target.bottom + tooltipGap;
      } else if (spaceAbove > 120) {
        // Hay más espacio ARRIBA → burbuja ARRIBA del target
        bottom = size.height - target.top + tooltipGap;
      } else {
        // No cabe bien ni arriba ni abajo → centrar en pantalla
        top = safeTop + topReserved + 30;
      }
    } else {
      // Sin target → centrar en zona segura media
      top = safeTop + topReserved + 40;
    }

    final tooltipContent = SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: context.appColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: step.accentColor.withAlpha(100),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: context.appColors.shadow,
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: step.accentColor.withAlpha(25),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Emoji animado
            AnimatedBuilder(
              animation: _bounceController,
              builder: (context, child) {
                final bounce = _bounceCurve(_bounceController.value);
                return Transform.translate(
                  offset: Offset(0, -bounce * 10),
                  child: child,
                );
              },
              child: Text(
                step.emoji,
                style: const TextStyle(fontSize: 44),
              ),
            ),
            const SizedBox(height: 6),
            // Título
            Text(
              step.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: step.accentColor,
              ),
            ),
            const SizedBox(height: 4),
            // Descripción
            Text(
              step.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: context.appColors.textPrimary,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );

    // Envolver en Center + ConstrainedBox para que en desktop/web
    // la burbuja no ocupe todo el ancho, sino que se vea angosta y centrada
    final tooltipWidget = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: tooltipContent,
      ),
    );

    if (top != null) {
      return Positioned(
        top: top,
        left: 0,
        right: 0,
        child: tooltipWidget,
      );
    } else if (bottom != null) {
      return Positioned(
        bottom: bottom,
        left: 0,
        right: 0,
        child: tooltipWidget,
      );
    }
    return tooltipWidget;
  }

  /// Curva de rebote personalizada para el emoji.
  double _bounceCurve(double t) {
    if (t < 0.35) {
      return t / 0.35;
    } else if (t < 0.6) {
      return 1.0 - ((t - 0.35) / 0.25) * 0.5;
    } else if (t < 0.8) {
      return 0.5 + ((t - 0.6) / 0.2) * 0.25;
    } else {
      return 0.75 - ((t - 0.8) / 0.2) * 0.75;
    }
  }
}
