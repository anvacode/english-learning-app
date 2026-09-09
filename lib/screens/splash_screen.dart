import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../dialogs/daily_login_reward_dialog.dart';
import '../logic/auth_provider.dart';
import '../logic/first_time_service.dart';
import '../logic/star_service.dart';
import '../logic/student_service.dart';
import '../screens/admin_dashboard_screen.dart';
import '../services/tutorial_service.dart';
import 'home_screen.dart';
import 'onboarding/modern_onboarding_screen.dart';

/// Pantalla de splash que se muestra al iniciar la aplicación.
///
/// Muestra el logo con animación fade-in durante 3 segundos,
/// inicializa el estudiante, luego verifica si es la primera vez
/// del usuario y navega a OnboardingScreen o HomeScreen según corresponda.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Configurar animación fade-in
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    // Iniciar animación
    _animationController.forward();

    // Inicializar estudiante y navegar después de 3 segundos
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    await StudentService.initializeStudent();

    final authProvider = context.read<AuthProvider>();

    // Wait for auth state to be ready (no fixed delay, use the authReady future)
    await authProvider.authReady;

    // Verificar estados
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = await FirstTimeService.isFirstTime();
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

    // Flujo de navegación:
    // 1. Primera vez o onboarding no completado → Onboarding
    // 2. Onboarding completado → Home

    // Si ya completó el onboarding, procesar recompensa diaria
    if (!isFirstTime && onboardingCompleted) {
      // Solo usuarios autenticados (email/Google) reciben recompensa diaria
      if (authProvider.isAuthenticated) {
        final starsEarned = await StarService.processDailyLogin();
        final streakAfter = await StarService.getLoginStreak();
        final streakBonus = streakAfter > 1 ? (streakAfter - 1) * 5 : 0;

        if (starsEarned > 0 && mounted) {
          await DailyLoginRewardDialog.show(
            context,
            starsEarned: starsEarned,
            loginStreak: streakAfter,
            streakBonus: streakBonus,
          );
        }
      }
    }

    // Verificar si se debe mostrar el tour interactivo
    final showInteractiveTutorial = !isFirstTime &&
        onboardingCompleted &&
        !(await TutorialService.wasInteractiveTutorialShown());

    // Esperar tiempo mínimo para mostrar splash
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Determinar pantalla destino
    Widget destination;
    if (authProvider.isAdmin) {
      destination = const AdminDashboardScreen();
    } else if (!isFirstTime && onboardingCompleted) {
      destination = HomeScreen(showTutorial: showInteractiveTutorial);
    } else {
      destination = const ModernOnboardingScreen();
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.school,
                  size: 100,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(height: 32),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
