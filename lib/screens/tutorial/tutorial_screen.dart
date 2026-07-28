import 'package:flutter/material.dart';

import '../../services/tutorial_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_colors_extension.dart';
import '../../utils/responsive.dart';
import '../../widgets/app_scaffold.dart';
import '../home_screen.dart';

/// Pantalla de tutorial estático con tarjetas deslizables.
///
/// Explica las funciones principales de la app de forma visual y clara,
/// usando emojis grandes, texto corto y colores vibrantes.
/// Accesible desde Configuración → "Ver tutorial".
class TutorialScreen extends StatefulWidget {
  final bool showPlayButton;

  const TutorialScreen({
    super.key,
    this.showPlayButton = true,
  });

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_TutorialCardData> _cards = const [
    _TutorialCardData(
      emoji: '🏠',
      title: 'Tu Inicio',
      description:
          'Esta es tu casa en la app. Aquí ves tus estrellas, tus lecciones, tu perfil, logros y la tienda.',
      gradient: LinearGradient(
        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    _TutorialCardData(
      emoji: '📚',
      title: 'Lecciones',
      description:
          'Elige entre 3 niveles: Principiante, Intermedio y Avanzado. Cada lección tiene juegos y preguntas.',
      gradient: LinearGradient(
        colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    _TutorialCardData(
      emoji: '🎮',
      title: 'Práctica',
      description:
          'Juega a emparejar imágenes, practica tu pronunciación con el micrófono y desafía tu memoria.',
      gradient: LinearGradient(
        colors: [Color(0xFFfa709a), Color(0xFFfee140)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    _TutorialCardData(
      emoji: '⭐',
      title: 'Estrellas y Tienda',
      description:
          'Gana estrellas al completar lecciones. Luego gástalas en la tienda para comprar colores y avatares.',
      gradient: LinearGradient(
        colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    _TutorialCardData(
      emoji: '🏅',
      title: 'Logros',
      description:
          'Cada vez que terminas una lección, ganas una medalla especial. ¡Colecciona todas!',
      gradient: LinearGradient(
        colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    _TutorialCardData(
      emoji: '👤',
      title: 'Tu Perfil',
      description:
          'Cambia tu foto, escoge un apodo, revisa tu historial y ajusta el audio a tu gusto.',
      gradient: LinearGradient(
        colors: [Color(0xFFa8edea), Color(0xFFfed6e3)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  ];

  void _nextPage() {
    if (_currentPage < _cards.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _finish() async {
    await TutorialService.markTutorialCompleted();
    if (!mounted) return;
    if (widget.showPlayButton) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _cards.length - 1;

    return AppScaffold(
      currentIndex: -1,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.scale(context, 16, 20, 24),
                vertical: Responsive.scale(context, 10, 12, 14),
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                     style: TextButton.styleFrom(
                       foregroundColor: context.appColors.textSecondary,
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.scale(context, 10, 12, 14),
                        vertical: Responsive.scale(context, 6, 8, 10),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cerrar',
                      style: TextStyle(
                        fontSize: Responsive.scale(context, 15, 16, 17),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_currentPage + 1} / ${_cards.length}',
                    style: TextStyle(
                      fontSize: Responsive.scale(context, 15, 16, 17),
                       fontWeight: FontWeight.bold,
                       color: context.appColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),

            // Tarjetas deslizables
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 600),
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _cards.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return _buildCard(_cards[index]);
                    },
                  ),
                ),
              ),
            ),

            // Indicadores y botón
            Flexible(
              child: Padding(
                padding: EdgeInsets.all(Responsive.scale(context, 20, 24, 28)),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 600),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Indicadores de página
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_cards.length, (index) {
                            final isActive = index == _currentPage;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: isActive ? 24 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                 color: isActive ? AppColors.primary : context.appColors.border,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        ),
                        SizedBox(height: Responsive.scale(context, 16, 20, 24)),

                        // Botón principal
                        SizedBox(
                          width: double.infinity,
                          height: Responsive.scale(context, 48, 52, 56),
                          child: ElevatedButton(
                            onPressed: _nextPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isLastPage ? '¡Empezar a jugar!' : 'Siguiente',
                                  style: TextStyle(
                                    fontSize: Responsive.scale(context, 15, 16, 17),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: Responsive.scale(context, 6, 8, 10)),
                                Icon(
                                  isLastPage ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                                  size: Responsive.scale(context, 18, 20, 22),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Botón para ver tour guiado interactivo (solo en Configuración)
                        if (!widget.showPlayButton && isLastPage)
                          Padding(
                            padding: EdgeInsets.only(top: Responsive.scale(context, 8, 10, 12)),
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await TutorialService.requestInteractiveTutorial();
                                if (!context.mounted) return;
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                                  (route) => false,
                                );
                              },
                              icon: Icon(Icons.touch_app_outlined, size: Responsive.scale(context, 16, 18, 20)),
                              label: Text(
                                'Ver tour guiado interactivo',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: Responsive.scale(context, 13, 14, 15),
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 3,
                                padding: EdgeInsets.symmetric(
                                  horizontal: Responsive.scale(context, 18, 22, 26),
                                  vertical: Responsive.scale(context, 10, 12, 14),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(_TutorialCardData data) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.scale(context, 20, 24, 28),
        vertical: Responsive.scale(context, 10, 12, 14),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: data.gradient,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: (data.gradient.colors.first).withAlpha(60),
              blurRadius: 24,
              offset: const Offset(0, 12),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(Responsive.scale(context, 24, 28, 32)),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(Responsive.scale(context, 20, 24, 28)),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    data.emoji,
                    style: TextStyle(fontSize: Responsive.scale(context, 60, 70, 80)),
                  ),
                ),
                SizedBox(height: Responsive.scale(context, 24, 28, 32)),
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: Responsive.scale(context, 24, 26, 28),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: Responsive.scale(context, 12, 14, 16)),
                Text(
                  data.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: Responsive.scale(context, 15, 16, 18),
                    color: Colors.white.withAlpha(230),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TutorialCardData {
  final String emoji;
  final String title;
  final String description;
  final Gradient gradient;

  const _TutorialCardData({
    required this.emoji,
    required this.title,
    required this.description,
    required this.gradient,
  });
}
