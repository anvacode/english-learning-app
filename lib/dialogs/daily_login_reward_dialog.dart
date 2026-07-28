import 'package:flutter/material.dart';

import '../theme/app_colors_extension.dart';

/// Diálogo que muestra las recompensas del login diario.
/// 
/// Muestra:
/// - Estrellas ganadas por login diario
/// - Bono de racha si aplica
/// - Información de la racha actual
class DailyLoginRewardDialog extends StatefulWidget {
  final int starsEarned;
  final int loginStreak;
  final int streakBonus;

  const DailyLoginRewardDialog({
    super.key,
    required this.starsEarned,
    required this.loginStreak,
    required this.streakBonus,
  });

  /// Muestra el diálogo de recompensas diarias.
  static Future<void> show(
    BuildContext context, {
    required int starsEarned,
    required int loginStreak,
    required int streakBonus,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => DailyLoginRewardDialog(
        starsEarned: starsEarned,
        loginStreak: loginStreak,
        streakBonus: streakBonus,
      ),
    );
  }

  @override
  State<DailyLoginRewardDialog> createState() => _DailyLoginRewardDialogState();
}

class _DailyLoginRewardDialogState extends State<DailyLoginRewardDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _starController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _starAnimation;

  @override
  void initState() {
    super.initState();

    // Animación de escala del diálogo
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeOutBack,
      ),
    );

    // Animación de estrellas
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _starAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _starController,
        curve: Curves.easeOut,
      ),
    );

    // Iniciar animaciones
    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _starController.forward();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _starController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            maxWidth: MediaQuery.of(context).size.width * 0.85,
          ),
          padding: const EdgeInsets.all(24.0),
           decoration: BoxDecoration(
             borderRadius: BorderRadius.circular(24),
             gradient: context.isDarkMode
                 ? null
                 : LinearGradient(
                     begin: Alignment.topLeft,
                     end: Alignment.bottomRight,
                     colors: [
                       Colors.amber[50]!,
                       Colors.orange[50]!,
                     ],
                   ),
             color: context.isDarkMode ? context.appColors.cardBackground : null,
           ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Emoji de celebración
                const Text(
                  '🌟',
                  style: TextStyle(fontSize: 64),
                ),
                const SizedBox(height: 16),

                // Título
                const Text(
                  '¡Bienvenido de nuevo!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Mensaje de login diario
                Text(
                  'Has iniciado sesión ${widget.loginStreak} ${widget.loginStreak == 1 ? 'día' : 'días'} seguidos',
                   style: TextStyle(
                     fontSize: 16,
                     fontWeight: FontWeight.w600,
                     color: context.appColors.textPrimary,
                   ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Estrellas ganadas
                AnimatedBuilder(
                  animation: _starAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _starAnimation.value,
                      child: Transform.scale(
                        scale: _starAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber[100],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.amber[400]!,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: Colors.amber[700],
                                    size: 28,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '+${widget.starsEarned}',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber[900],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                               Text(
                                 'Estrellas ganadas',
                                 style: TextStyle(
                                   fontSize: 12,
                                   color: context.appColors.textSecondary,
                                 ),
                               ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Bono de racha si aplica
                if (widget.streakBonus > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.green[300]!,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '🔥',
                          style: TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Bono de racha: +${widget.streakBonus} ⭐',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[900],
                              ),
                            ),
                            Text(
                              'Racha de ${widget.loginStreak} días',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Mensaje motivacional
                 Container(
                   padding: const EdgeInsets.all(12),
                   decoration: BoxDecoration(
                     color: context.appColors.surface,
                     borderRadius: BorderRadius.circular(12),
                   ),
                  child: Text(
                    widget.loginStreak >= 7
                        ? '¡Increíble! Sigue así 🎉'
                        : widget.loginStreak >= 3
                            ? '¡Vas muy bien! Continúa aprendiendo 💪'
                            : '¡Sigue aprendiendo cada día! 📚',
                     style: TextStyle(
                       fontSize: 14,
                       fontWeight: FontWeight.w500,
                       color: context.appColors.textPrimary,
                     ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 24),

                // Botón de continuar
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      '¡Empezar!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
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
