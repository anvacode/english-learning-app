import 'package:flutter/material.dart';
import '../logic/star_service.dart';
import '../theme/app_colors_extension.dart';

/// Widget reutilizable para mostrar el contador de estrellas.
/// 
/// Muestra un ícono de estrella con el total de estrellas del usuario.
/// Actualiza automáticamente cuando cambia el total.
class StarDisplay extends StatefulWidget {
  /// Tamaño del ícono de estrella. Por defecto: 20.0
  final double iconSize;
  
  /// Tamaño del texto. Por defecto: 16.0
  final double fontSize;
  
  /// Color del ícono. Por defecto: Colors.amber
  final Color? iconColor;
  
  /// Color del texto. Por defecto: color de texto primario del tema
  final Color? textColor;
  
  /// Si muestra solo el ícono sin el número. Por defecto: false
  final bool iconOnly;
  
  /// Si muestra un fondo decorativo. Por defecto: false
  final bool showBackground;

  const StarDisplay({
    super.key,
    this.iconSize = 20.0,
    this.fontSize = 16.0,
    this.iconColor,
    this.textColor,
    this.iconOnly = false,
    this.showBackground = false,
  });

  @override
  State<StarDisplay> createState() => _StarDisplayState();
}

class _StarDisplayState extends State<StarDisplay> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStars();
    // Escuchar cambios en tiempo real
    StarService.starCountNotifier.addListener(_onStarsChanged);
  }
  
  @override
  void dispose() {
    // Remover listener al destruir el widget
    StarService.starCountNotifier.removeListener(_onStarsChanged);
    super.dispose();
  }
  
  void _onStarsChanged() {
    if (mounted) {
      setState(() {
        // El widget se reconstruirá con el nuevo valor
      });
    }
  }

  Future<void> _loadStars() async {
    final total = await StarService.getTotalStars();
    if (mounted) {
      setState(() {
        StarService.starCountNotifier.value = total;
        _isLoading = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recargar estrellas cuando la pantalla vuelve a ser visible
    _loadStars();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.iconColor ?? Colors.amber[700] ?? Colors.amber;
    final textColor = widget.textColor ?? context.appColors.textPrimary;

    if (_isLoading) {
      return SizedBox(
        width: widget.iconSize,
        height: widget.iconSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(iconColor),
        ),
      );
    }

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star,
          size: widget.iconSize,
          color: iconColor,
        ),
        if (!widget.iconOnly) ...[
          const SizedBox(width: 4),
          Text(
            _formatStars(StarService.starCountNotifier.value),
            style: TextStyle(
              fontSize: widget.fontSize,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ],
    );

    if (widget.showBackground) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.amber[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.amber[200]!,
          ),
        ),
        child: content,
      );
    }

    return content;
  }

  /// Formatea el número de estrellas para mostrar (ej: 1.2K, 5.3M)
  String _formatStars(int stars) {
    if (stars < 1000) {
      return stars.toString();
    } else if (stars < 1000000) {
      return '${(stars / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(stars / 1000000).toStringAsFixed(1)}M';
    }
  }
}

/// Widget compacto para mostrar estrellas en AppBar.
/// 
/// Versión optimizada para usar en barras de aplicación.
class StarDisplayCompact extends StatelessWidget {
  const StarDisplayCompact({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: StarService.getTotalStars(),
      builder: (context, snapshot) {
        final stars = snapshot.data ?? 0;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star,
              size: 20,
              color: Colors.amber[700],
            ),
            const SizedBox(width: 4),
            Text(
              stars.toString(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      },
    );
  }
}
