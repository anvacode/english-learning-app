import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../dialogs/auth_prompt_dialog.dart';
import '../../logic/first_time_service.dart';
import '../../models/onboarding_page.dart';
import '../../services/diagnostic_service.dart';
import '../../services/tutorial_service.dart';
import '../../theme/app_colors_extension.dart';
import '../../utils/responsive.dart';
import '../../widgets/onboarding_page_widget.dart';
import '../auth/register_screen.dart';
import '../diagnostic/diagnostic_intro_screen.dart';
import '../home_screen.dart';

/// Pantalla moderna de onboarding con diseño atractivo y animaciones.
///
/// Muestra 4 slides con ilustraciones, títulos, descripciones y
/// controles de navegación modernos.
class ModernOnboardingScreen extends StatefulWidget {
  const ModernOnboardingScreen({super.key});

  @override
  State<ModernOnboardingScreen> createState() => _ModernOnboardingScreenState();
}

class _ModernOnboardingScreenState extends State<ModernOnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isAnimating = false;

  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();

    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _pageController.addListener(() {
      final page = _pageController.page ?? 0;
      if (page.round() != _currentPage) {
        setState(() {
          _currentPage = page.round();
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    if (_isAnimating) return;

    setState(() {
      _isAnimating = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
      await FirstTimeService.setFirstTimeCompleted();

      // Solicitar que el tour interactivo aparezca al llegar al HomeScreen
      await TutorialService.requestInteractiveTutorial();

      if (!mounted) return;

      // Mostrar el diálogo de autenticación y capturar el resultado
      final result = await AuthPromptDialog.show(context, isFromOnboarding: true);

      if (!mounted) return;

      // Navegar según la elección del usuario
      if (result == 'register') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const RegisterScreen()),
          (route) => false,
        );
      } else if (result == 'google') {
        // Verificar si el usuario completó el diagnóstico
        final diagnosticCompleted = await DiagnosticService.isDiagnosticCompleted();
        if (!mounted) return;

        if (diagnosticCompleted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const DiagnosticIntroScreen()),
            (route) => false,
          );
        }
      } else {
        // 'guest' o null (diálogo cerrado sin botón) → ir a HomeScreen
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const HomeScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOutCubic;

              var tween = Tween(
                begin: begin,
                end: end,
              ).chain(CurveTween(curve: curve));

              return SlideTransition(
                position: animation.drive(tween),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnimating = false;
        });
      }
    }
  }

  void _nextPage() {
    if (_currentPage < OnboardingPages.pages.length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == OnboardingPages.pages.length - 1;
    final isMobile = context.isMobile;
    final buttonFontSize = isMobile ? 18.0 : 20.0;
    final skipFontSize = isMobile ? 16.0 : 18.0;

    return Scaffold(
      body: Stack(
        children: [
          // PageView con las páginas
          PageView.builder(
            controller: _pageController,
            itemCount: OnboardingPages.pages.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return OnboardingPageWidget(
                pageData: OnboardingPages.pages[index],
                isActive: index == _currentPage,
              );
            },
          ),

          // Botón Skip (excepto en última página)
          if (!isLastPage)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: SafeArea(
                child: TextButton(
                  onPressed: _skipOnboarding,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withAlpha(51),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Saltar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: skipFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

          // Controles inferiores (indicadores y botón)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(context.horizontalPadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Indicadores de página
                    PageIndicator(
                      currentPage: _currentPage,
                      pageCount: OnboardingPages.pages.length,
                    ),

                    const SizedBox(height: 32),

                    // Botón Siguiente/Empezar
                    ScaleTransition(
                      scale: _buttonScaleAnimation,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isMobile ? 200 : 240,
                        ),
                        child: SizedBox(
                          height: isMobile ? 48 : 52,
                          child: ElevatedButton(
                            onPressed: _isAnimating ? null : _nextPage,
                            onLongPress: () {
                              _buttonAnimationController.forward();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: OnboardingPages
                                  .pages[_currentPage]
                                  .primaryColor,
                               elevation: 8,
                               shadowColor: context.appColors.shadow,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isLastPage ? '¡Empezar!' : 'Siguiente',
                                  style: TextStyle(
                                    fontSize: buttonFontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  isLastPage
                                      ? Icons.check_circle_rounded
                                      : Icons.arrow_forward_rounded,
                                  size: buttonFontSize + 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
