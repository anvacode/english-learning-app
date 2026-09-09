import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/connectivity_service.dart';
import '../theme/app_colors.dart';

/// Banner animado que informa al usuario sobre el estado de conexión.
///
/// Se muestra en la parte superior de la pantalla:
/// - Offline: banner persistente color ámbar con mensaje amigable
/// - Online (recién restaurado): banner verde temporal que desaparece en 3s
class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivityService, _) {
        final isOnline = connectivityService.isOnline;
        final wasJustRestored = connectivityService.wasJustRestored;

        // No mostrar nada si está online y no es una restauración reciente
        if (isOnline && !wasJustRestored) {
          return const SizedBox.shrink();
        }

        final isRestored = wasJustRestored;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          color: isRestored ? AppColors.success : AppColors.warning,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                Icon(
                  isRestored
                      ? Icons.cloud_done_rounded
                      : Icons.cloud_off_rounded,
                  color: isRestored ? Colors.white : Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isRestored
                        ? 'Conexión restaurada'
                        : 'Sin conexión — Tu progreso se guarda localmente',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isRestored)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 20,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
