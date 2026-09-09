import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/auth_provider.dart';
import '../services/auth_prompt_service.dart';
import '../theme/app_colors_extension.dart';
import '../widgets/responsive_snack_bar.dart';

/// Diálogo que invita al usuario a crear una cuenta o iniciar sesión.
///
/// Se muestra:
/// - La primera vez después de completar el onboarding
/// - Cada 5 aperturas para usuarios no autenticados
class AuthPromptDialog extends StatefulWidget {
  final bool isFromOnboarding;

  const AuthPromptDialog({super.key, this.isFromOnboarding = false});

  static Future<String?> show(
    BuildContext context, {
    bool isFromOnboarding = false,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) =>
          AuthPromptDialog(isFromOnboarding: isFromOnboarding),
    );
  }

  @override
  State<AuthPromptDialog> createState() => _AuthPromptDialogState();
}

class _AuthPromptDialogState extends State<AuthPromptDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToRegister() async {
    if (_isNavigating) return;
    _isNavigating = true;

    await AuthPromptService.markPromptShownForCurrentCycle();
    await AuthPromptService.markPromptShownAfterOnboarding();
    if (mounted) {
      Navigator.of(context).pop('register');
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading || _isNavigating) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.signInWithGoogle();

      if (mounted) {
        _isNavigating = true;
        await AuthPromptService.markPromptShownForCurrentCycle();
        await AuthPromptService.markPromptShownAfterOnboarding();

        if (!context.mounted) return;

        Navigator.of(context).pop('google');
      }
    } catch (e) {
      if (mounted) {
        if (!e.toString().contains('cancelado')) {
          ResponsiveSnackBar.showError(
            context,
            message: 'Error: ${e.toString()}',
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _continueAsGuest() async {
    if (_isNavigating) return;
    _isNavigating = true;

    await AuthPromptService.markPromptShownForCurrentCycle();
    await AuthPromptService.markPromptShownAfterOnboarding();
    if (mounted) {
      Navigator.of(context).pop('guest');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(scale: _scaleAnimation, child: child),
        );
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.all(24),
           decoration: BoxDecoration(
             gradient: context.isDarkMode
                 ? null
                 : LinearGradient(
                     begin: Alignment.topLeft,
                     end: Alignment.bottomRight,
                     colors: [Colors.deepPurple[50]!, Colors.indigo[50]!],
                   ),
             color: context.isDarkMode ? context.appColors.cardBackground : null,
             borderRadius: BorderRadius.circular(28),
           ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.deepPurple[400]!, Colors.indigo[500]!],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withAlpha(80),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_add_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                '¡Crea tu cuenta!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: context.appColors.surface,
                 borderRadius: BorderRadius.circular(16),
                 border: Border.all(
                   color: Colors.deepPurple[100]!,
                   width: 1.5,
                 ),
               ),
                child: Column(
                  children: [
                    _buildBenefitRow(
                      Icons.cloud_upload_rounded,
                      'Guarda tu progreso',
                    ),
                    const SizedBox(height: 10),
                    _buildBenefitRow(
                      Icons.devices_rounded,
                      'Sincroniza en todos tus dispositivos',
                    ),
                    const SizedBox(height: 10),
                    _buildBenefitRow(
                      Icons.emoji_events_rounded,
                      'Desbloquea logros exclusivos',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.deepPurple[500]!, Colors.indigo[500]!],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withAlpha(60),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: (_isLoading || _isNavigating) ? null : _navigateToRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Crear cuenta',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: (_isLoading || _isNavigating) ? null : _signInWithGoogle,
                   style: OutlinedButton.styleFrom(
                     side: BorderSide(color: Colors.deepPurple[400]!, width: 2),
                     shape: RoundedRectangleBorder(
                       borderRadius: BorderRadius.circular(14),
                     ),
                     backgroundColor: context.appColors.cardBackground,
                   ),
                  icon: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: const Center(
                      child: Text(
                        'G',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  label: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.deepPurple,
                          ),
                        )
                      : Text(
                          'Continuar con Google',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.deepPurple[700],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              TextButton(
                onPressed: (_isLoading || _isNavigating) ? null : _continueAsGuest,
                 child: Text(
                   'Continuar como invitado',
                   style: TextStyle(
                     fontSize: 15,
                     color: context.appColors.textSecondary,
                     fontWeight: FontWeight.w500,
                   ),
                 ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.deepPurple[500]),
        const SizedBox(width: 12),
        Expanded(
           child: Text(
             text,
             style: TextStyle(
               fontSize: 14,
               color: context.appColors.textPrimary,
               fontWeight: FontWeight.w500,
             ),
           ),
        ),
      ],
    );
  }
}

/// Helper para mostrar el diálogo de autenticación
class AuthPromptHelper {
  /// Muestra el prompt de autenticación si es necesario.
  ///
  /// Retorna true si el usuario navegó a auth, false si continuó como invitado.
  static Future<bool> showAuthPromptIfNeeded(
    BuildContext context, {
    required AuthProvider authProvider,
    bool isFromOnboarding = false,
  }) async {
    final shouldShow = await AuthPromptService.shouldShowAuthPrompt(
      isAuthenticated: authProvider.isAuthenticated,
      isGuest: authProvider.isGuest,
    );

    if (!shouldShow) return false;

    if (!context.mounted) return false;

    final result = await AuthPromptDialog.show(
      context,
      isFromOnboarding: isFromOnboarding,
    );

    return result == 'register' || result == 'google';
  }
}
