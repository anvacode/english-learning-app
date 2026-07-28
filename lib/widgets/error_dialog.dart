import 'package:flutter/material.dart';
import '../theme/app_colors_extension.dart';
import '../utils/responsive.dart';

/// Diálogo de error moderno y atractivo.
/// 
/// Muestra un modal centrado con diseño amigable para notificar errores
/// o problemas al usuario de manera clara y visible.
class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;

  const ErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
  });

  /// Muestra el diálogo de error de manera estática.
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ErrorDialog(
        title: title,
        message: message,
        actionText: actionText,
        onAction: onAction,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = Responsive.scale(context, 320, 360, 400);
    final iconSize = Responsive.scale(context, 64, 80, 88);
    final titleSize = Responsive.scale(context, 20, 22, 24);
    final messageSize = Responsive.scale(context, 14, 15, 16);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Responsive.scale(context, 20, 24, 28)),
      ),
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: EdgeInsets.all(Responsive.scale(context, 20, 24, 28)),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.red[50]!,
              Colors.orange[50]!,
            ],
          ),
          borderRadius: BorderRadius.circular(Responsive.scale(context, 20, 24, 28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: Colors.red[100],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withAlpha(76),
                    blurRadius: Responsive.scale(context, 12, 16, 20),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: iconSize * 0.6,
                color: Colors.red[700],
              ),
            ),
            SizedBox(height: Responsive.scale(context, 16, 20, 24)),

            Text(
              title,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: Colors.red[900],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Responsive.scale(context, 10, 12, 14)),

            Container(
              padding: EdgeInsets.all(Responsive.scale(context, 12, 16, 20)),
              decoration: BoxDecoration(
                color: context.appColors.cardBackground,
                borderRadius: BorderRadius.circular(Responsive.scale(context, 10, 12, 14)),
                border: Border.all(
                  color: Colors.red[200]!,
                  width: 1.5,
                ),
              ),
              child: Text(
                message,
                style: TextStyle(
                  fontSize: messageSize,
                  color: context.appColors.textPrimary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: Responsive.scale(context, 16, 20, 24)),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: context.appColors.border, width: 2),
                      padding: EdgeInsets.symmetric(vertical: Responsive.scale(context, 12, 14, 16)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Responsive.scale(context, 10, 12, 14)),
                      ),
                    ),
                    child: Text(
                      'Cerrar',
                      style: TextStyle(
                        fontSize: Responsive.scale(context, 14, 16, 18),
                        fontWeight: FontWeight.w600,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                
                if (actionText != null && onAction != null) ...[
                  SizedBox(width: Responsive.scale(context, 10, 12, 14)),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onAction!();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        padding: EdgeInsets.symmetric(vertical: Responsive.scale(context, 12, 14, 16)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Responsive.scale(context, 10, 12, 14)),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        actionText!,
                        style: TextStyle(
                          fontSize: Responsive.scale(context, 14, 16, 18),
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper para mostrar errores rápidamente
class ErrorHelper {
  /// Muestra un error simple con mensaje
  static void showError(BuildContext context, String message) {
    ErrorDialog.show(
      context,
      title: '¡Oops!',
      message: message,
    );
  }

  /// Muestra un error de conexión
  static void showConnectionError(BuildContext context) {
    ErrorDialog.show(
      context,
      title: 'Error de Conexión',
      message: 'No se pudo conectar. Por favor verifica tu conexión a internet e intenta de nuevo.',
      actionText: 'Reintentar',
      onAction: () {
        // Aquí se puede implementar lógica de reintento
      },
    );
  }

  /// Muestra un error de estrellas insuficientes
  static void showInsufficientStarsError(
    BuildContext context, {
    required int required,
    required int available,
  }) {
    ErrorDialog.show(
      context,
      title: 'Estrellas Insuficientes',
      message: 'Necesitas $required ⭐ para esta compra.\nActualmente tienes $available ⭐.\n\n¡Completa más lecciones para ganar estrellas!',
    );
  }

  /// Muestra un error genérico con título personalizado
  static void showCustomError(
    BuildContext context, {
    required String title,
    required String message,
    String? actionText,
    VoidCallback? onAction,
  }) {
    ErrorDialog.show(
      context,
      title: title,
      message: message,
      actionText: actionText,
      onAction: onAction,
    );
  }
}
