import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../utils/responsive.dart';
import 'responsive_snack_bar.dart';

class AuthStatusWidget extends StatefulWidget {
  const AuthStatusWidget({super.key});

  @override
  State<AuthStatusWidget> createState() => _AuthStatusWidgetState();
}

class _AuthStatusWidgetState extends State<AuthStatusWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Pulsa unas veces al aparecer y se detiene (evita animación infinita).
    _animationController.repeat(reverse: true, count: 3);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isAuthenticated) {
          return _buildAuthenticatedWidget(context, authProvider);
        } else if (authProvider.isGuest) {
          return _buildGuestWidget(context);
        } else {
          return _buildUnauthenticatedWidget(context);
        }
      },
    );
  }

  Widget _buildCardContainer({
    required BuildContext context,
    required List<Color> gradientColors,
    required Widget child,
  }) {
    return Card(
      elevation: 8,
      shadowColor: gradientColors.first.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.scale4(context, 14, 16, 18, 20),
          vertical: Responsive.scale4(context, 10, 12, 14, 16),
        ),
        child: child,
      ),
    );
  }

  Widget _buildIconContainer({
    required BuildContext context,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(Responsive.scale4(context, 8, 9, 10, 11)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: Responsive.scale4(context, 26, 28, 30, 32),
      ),
    );
  }

  Widget _buildTextContent({
    required BuildContext context,
    required String title,
    String? subtitle,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: Responsive.scale4(context, 14, 15, 16, 17),
              height: 1.2,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: Responsive.scale4(context, 11, 12, 13, 14),
                height: 1.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogoutButton({
    required BuildContext context,
    required AuthProvider authProvider,
  }) {
    return InkWell(
      onTap: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cerrar Sesión'),
            content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Cerrar Sesión'),
              ),
            ],
          ),
        );

        if (confirm == true && context.mounted) {
          await context.read<AuthProvider>().signOut();
          if (context.mounted) {
            ResponsiveSnackBar.showInfo(
              context,
              message: 'Sesión cerrada',
              backgroundColor: Colors.orange,
            );
          }
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.all(Responsive.scale4(context, 4, 6, 8, 10)),
        child: Icon(
          Icons.logout,
          color: Colors.white,
          size: Responsive.scale4(context, 20, 22, 24, 26),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: EdgeInsets.symmetric(
            vertical: Responsive.scale4(context, 10, 12, 14, 16),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Responsive.scale4(context, 6, 8, 8, 10)),
          ),
          elevation: 0,
        ),
        icon: Icon(icon, size: Responsive.scale4(context, 16, 18, 20, 22)),
        label: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: Responsive.scale4(context, 12, 13, 14, 15),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedSyncIcon({
    required BuildContext context,
  }) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: Container(
        padding: EdgeInsets.all(Responsive.scale4(context, 6, 7, 8, 9)),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Icon(
          Icons.cloud_done,
          color: Colors.white,
          size: Responsive.scale4(context, 24, 26, 28, 30),
        ),
      ),
    );
  }

  Widget _buildSyncBadge({
    required BuildContext context,
  }) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _pulseAnimation.value,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'Sincronizado',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthenticatedWidget(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    final user = authProvider.user;
    final isMobile = context.isMobile;

    return _buildCardContainer(
      context: context,
      gradientColors: [Colors.green.shade400, Colors.green.shade600],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = isMobile || constraints.maxWidth < 320;

          if (isCompact) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildAnimatedSyncIcon(context: context),
                    SizedBox(width: Responsive.scale4(context, 12, 14, 16, 18)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Cuenta Sincronizada',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: Responsive.scale4(context, 14, 15, 16, 17),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? 'Usuario',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: Responsive.scale4(context, 11, 12, 13, 14),
                              height: 1.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildSyncBadge(context: context),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: _buildLogoutButton(context: context, authProvider: authProvider),
                ),
              ],
            );
          }

          return Row(
            children: [
              _buildAnimatedSyncIcon(context: context),
              SizedBox(width: Responsive.scale4(context, 12, 14, 16, 18)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Cuenta Sincronizada',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: Responsive.scale4(context, 14, 15, 16, 17),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.email ?? 'Usuario',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: Responsive.scale4(context, 11, 12, 13, 14),
                        height: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    _buildSyncBadge(context: context),
                  ],
                ),
              ),
              SizedBox(width: Responsive.scale4(context, 8, 10, 12, 14)),
              _buildLogoutButton(context: context, authProvider: authProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGuestWidget(BuildContext context) {
    return _buildCardContainer(
      context: context,
      gradientColors: [Colors.orange.shade400, Colors.orange.shade600],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildIconContainer(context: context, icon: Icons.person_outline),
              SizedBox(width: Responsive.scale4(context, 12, 14, 16, 18)),
              _buildTextContent(
                context: context,
                title: 'Modo Invitado',
                subtitle: 'Tu progreso no se sincroniza',
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildActionButton(
            context: context,
            icon: Icons.cloud_upload,
            label: 'Guardar mi Progreso',
            backgroundColor: Colors.white,
            foregroundColor: Colors.orange.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildUnauthenticatedWidget(BuildContext context) {
    return _buildCardContainer(
      context: context,
      gradientColors: [Colors.blue.shade400, Colors.blue.shade600],
      child: Column(
        children: [
          Row(
            children: [
              _buildIconContainer(context: context, icon: Icons.lock_outline),
              SizedBox(width: Responsive.scale4(context, 12, 14, 16, 18)),
              _buildTextContent(
                context: context,
                title: '¡Guarda tu progreso en la nube!',
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildActionButton(
            context: context,
            icon: Icons.login,
            label: 'Iniciar Sesión / Registrarse',
            backgroundColor: Colors.white,
            foregroundColor: Colors.blue.shade700,
          ),
        ],
      ),
    );
  }
}
