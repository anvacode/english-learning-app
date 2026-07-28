import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/auth_provider.dart';
import '../../services/diagnostic_service.dart';
import '../../theme/app_colors_extension.dart';
import '../../utils/responsive.dart';
import '../../widgets/responsive_snack_bar.dart';
import '../admin_dashboard_screen.dart';
import '../diagnostic/diagnostic_intro_screen.dart';
import '../home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isNavigating = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isNavigating) return;

    setState(() => _isLoading = true);

    try {
      await context.read<AuthProvider>().createUserWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted && !_isNavigating) {
        _isNavigating = true;
        final authProvider = context.read<AuthProvider>();

        if (authProvider.isAdmin) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
            (route) => false,
          );
          return;
        }

        final diagnosticCompleted =
            await DiagnosticService.isDiagnosticCompleted();

        if (!context.mounted) return;

        if (diagnosticCompleted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const DiagnosticIntroScreen(),
            ),
            (route) => false,
          );
          return;
        }

        if (!context.mounted) return;
        ResponsiveSnackBar.showSuccess(
          context,
          message: '¡Cuenta creada exitosamente!',
        );
      }
    } catch (e) {
      if (mounted) {
        ResponsiveSnackBar.showError(
          context,
          message: 'Error: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isNavigating) return;
    setState(() => _isLoading = true);

    try {
      await context.read<AuthProvider>().signInWithGoogle();

      if (mounted && !_isNavigating) {
        _isNavigating = true;
        final authProvider = context.read<AuthProvider>();

        if (authProvider.isAdmin) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
            (route) => false,
          );
          return;
        }

        final diagnosticCompleted =
            await DiagnosticService.isDiagnosticCompleted();

        if (!context.mounted) return;

        if (diagnosticCompleted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const DiagnosticIntroScreen(),
            ),
            (route) => false,
          );
          return;
        }

        if (!context.mounted) return;
        ResponsiveSnackBar.showSuccess(
          context,
          message: '¡Registro con Google exitoso!',
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
           Container(
             decoration: BoxDecoration(
               gradient: context.appColors.backgroundGradient,
             ),
           ),
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF667eea).withValues(alpha: 0.4),
                    const Color(0xFF667eea).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF764ba2).withValues(alpha: 0.35),
                    const Color(0xFF764ba2).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 120,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFf093fb).withValues(alpha: 0.3),
                    const Color(0xFFf093fb).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                     icon: Icon(Icons.arrow_back, color: context.appColors.textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.scale(context, 16, 24, 32),
                        vertical: Responsive.scale(context, 8, 12, 16),
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 420),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                               decoration: BoxDecoration(
                                 color: context.appColors.cardBackground.withValues(alpha: 0.25),
                                 borderRadius: BorderRadius.circular(20),
                                 border: Border.all(
                                   color: Colors.white.withValues(alpha: 0.4),
                                   width: 1,
                                 ),
                                 boxShadow: [
                                   BoxShadow(
                                     color: context.appColors.shadow,
                                     blurRadius: 20,
                                     offset: const Offset(0, 8),
                                   ),
                                 ],
                               ),
                              child: Padding(
                                padding: EdgeInsets.all(Responsive.scale(context, 16, 20, 24)),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '¡Crea tu cuenta!',
                                         style: TextStyle(
                                           fontSize: Responsive.scale(context, 20, 22, 24),
                                           fontWeight: FontWeight.bold,
                                           color: context.appColors.textPrimary,
                                         ),
                                       ),
                                       SizedBox(height: Responsive.scale(context, 4, 5, 6)),
                                       Text(
                                         'Guarda tu progreso y accede desde cualquier dispositivo',
                                         style: TextStyle(
                                           fontSize: Responsive.scale(context, 12, 13, 14),
                                           color: context.appColors.textPrimary,
                                         ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: Responsive.scale(context, 16, 18, 20)),
                                       Container(
                                         decoration: BoxDecoration(
                                           color: context.appColors.cardBackground.withValues(alpha: 0.6),
                                           borderRadius: BorderRadius.circular(12),
                                           border: Border.all(
                                             color: Colors.white.withValues(alpha: 0.5),
                                           ),
                                         ),
                                         child: TextFormField(
                                           controller: _emailController,
                                           decoration: InputDecoration(
                                             labelText: 'Email',
                                             labelStyle: TextStyle(color: context.appColors.textPrimary),
                                            prefixIcon: Icon(Icons.email, color: const Color(0xFF667eea)),
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.symmetric(
                                              horizontal: Responsive.scale(context, 14, 16, 18),
                                              vertical: Responsive.scale(context, 12, 14, 16),
                                            ),
                                          ),
                                          keyboardType: TextInputType.emailAddress,
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Por favor ingresa tu email';
                                            }
                                            if (!value.contains('@')) {
                                              return 'Email inválido';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                       SizedBox(height: Responsive.scale(context, 10, 12, 14)),
                                       Container(
                                         decoration: BoxDecoration(
                                           color: context.appColors.cardBackground.withValues(alpha: 0.6),
                                           borderRadius: BorderRadius.circular(12),
                                           border: Border.all(
                                             color: Colors.white.withValues(alpha: 0.5),
                                           ),
                                         ),
                                         child: TextFormField(
                                           controller: _passwordController,
                                           decoration: InputDecoration(
                                             labelText: 'Contraseña',
                                             labelStyle: TextStyle(color: context.appColors.textPrimary),
                                             prefixIcon: Icon(Icons.lock, color: const Color(0xFF667eea)),
                                             suffixIcon: IconButton(
                                               icon: Icon(
                                                 _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                                 color: context.appColors.textPrimary,
                                               ),
                                              onPressed: () {
                                                setState(() {
                                                  _obscurePassword = !_obscurePassword;
                                                });
                                              },
                                            ),
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.symmetric(
                                              horizontal: Responsive.scale(context, 14, 16, 18),
                                              vertical: Responsive.scale(context, 12, 14, 16),
                                            ),
                                          ),
                                          obscureText: _obscurePassword,
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Por favor ingresa una contraseña';
                                            }
                                            if (value.length < 6) {
                                              return 'Mínimo 6 caracteres';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      SizedBox(height: Responsive.scale(context, 10, 12, 14)),
                                       Container(
                                         decoration: BoxDecoration(
                                           color: context.appColors.cardBackground.withValues(alpha: 0.6),
                                           borderRadius: BorderRadius.circular(12),
                                           border: Border.all(
                                             color: Colors.white.withValues(alpha: 0.5),
                                           ),
                                         ),
                                         child: TextFormField(
                                           controller: _confirmPasswordController,
                                           decoration: InputDecoration(
                                             labelText: 'Confirmar Contraseña',
                                             labelStyle: TextStyle(color: context.appColors.textPrimary),
                                             prefixIcon: Icon(Icons.lock_outline, color: const Color(0xFF667eea)),
                                             suffixIcon: IconButton(
                                               icon: Icon(
                                                 _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                                 color: context.appColors.textPrimary,
                                               ),
                                              onPressed: () {
                                                setState(() {
                                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                                });
                                              },
                                            ),
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.symmetric(
                                              horizontal: Responsive.scale(context, 14, 16, 18),
                                              vertical: Responsive.scale(context, 12, 14, 16),
                                            ),
                                          ),
                                          obscureText: _obscureConfirmPassword,
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Por favor confirma tu contraseña';
                                            }
                                            if (value != _passwordController.text) {
                                              return 'Las contraseñas no coinciden';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      SizedBox(height: Responsive.scale(context, 14, 16, 18)),
                                      Container(
                                        width: double.infinity,
                                        height: Responsive.scale(context, 44, 46, 48),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: ElevatedButton(
                                          onPressed: _isLoading ? null : _handleRegister,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            foregroundColor: Colors.white,
                                            shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: _isLoading
                                              ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : Text(
                                                  'Crear Cuenta',
                                                  style: TextStyle(
                                                    fontSize: Responsive.scale(context, 14, 15, 16),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      SizedBox(height: Responsive.scale(context, 12, 14, 16)),
                                      Row(
                                        children: [
                                           Expanded(child: Divider(color: context.appColors.border.withValues(alpha: 0.5))),
                                           Padding(
                                             padding: EdgeInsets.symmetric(
                                               horizontal: Responsive.scale(context, 10, 12, 14),
                                             ),
                                             child: Text(
                                               'o regístrate con',
                                               style: TextStyle(
                                                 color: context.appColors.textSecondary,
                                                 fontSize: Responsive.scale(context, 12, 13, 14),
                                               ),
                                             ),
                                           ),
                                           Expanded(child: Divider(color: context.appColors.border.withValues(alpha: 0.5))),
                                        ],
                                      ),
                                      SizedBox(height: Responsive.scale(context, 12, 14, 16)),
                                       Container(
                                         width: double.infinity,
                                         height: Responsive.scale(context, 44, 46, 48),
                                         decoration: BoxDecoration(
                                           color: context.appColors.cardBackground.withValues(alpha: 0.7),
                                           borderRadius: BorderRadius.circular(12),
                                           border: Border.all(
                                             color: Colors.white.withValues(alpha: 0.5),
                                           ),
                                         ),
                                        child: OutlinedButton.icon(
                                          onPressed: _isLoading ? null : _handleGoogleSignIn,
                                          style: OutlinedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            side: BorderSide.none,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          icon: Container(
                                            width: 20,
                                            height: 20,
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
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                           label: Text(
                                             'Continuar con Google',
                                             style: TextStyle(
                                               color: context.appColors.textPrimary,
                                               fontWeight: FontWeight.w600,
                                               fontSize: Responsive.scale(context, 13, 14, 15),
                                             ),
                                           ),
                                        ),
                                      ),
                                      SizedBox(height: Responsive.scale(context, 12, 14, 16)),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                           Text(
                                             '¿Ya tienes cuenta?',
                                             style: TextStyle(
                                               color: context.appColors.textPrimary,
                                               fontSize: Responsive.scale(context, 12, 13, 14),
                                             ),
                                           ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: Text(
                                              'Inicia Sesión',
                                              style: TextStyle(
                                                color: const Color(0xFF667eea),
                                                fontWeight: FontWeight.bold,
                                                fontSize: Responsive.scale(context, 12, 13, 14),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
