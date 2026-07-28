import 'dart:async';

import 'package:flutter/material.dart';

import '../logic/star_service.dart';
import '../theme/app_colors_extension.dart';

/// Widget StarCounter mejorado para mostrar estrellas del usuario.
/// 
/// Características:
/// - Actualización automática mediante polling
/// - Diseño amigable para niños con animaciones
/// - Manejo completo de estados (loading, error, success)
/// - Animación al cambiar el número de estrellas
/// - Reutilizable en cualquier pantalla
/// - Funciona offline con SharedPreferences
class StarCounter extends StatefulWidget {
  /// Tamaño del ícono de estrella. Por defecto: 24.0
  final double iconSize;
  
  /// Tamaño del texto. Por defecto: 18.0
  final double fontSize;
  
  /// Color del ícono. Por defecto: Colors.amber[700]
  final Color? iconColor;
  
  /// Color del texto. Por defecto: color de texto primario del tema
  final Color? textColor;
  
  /// Si muestra un fondo decorativo. Por defecto: true
  final bool showBackground;
  
  /// Intervalo de actualización automática en segundos. Por defecto: 2
  /// Si es 0, desactiva la actualización automática
  final int refreshInterval;
  
  /// Si anima los cambios en el contador. Por defecto: true
  final bool animateChanges;
  
  /// Callback cuando se actualiza el contador (opcional)
  final ValueChanged<int>? onStarsUpdated;

  const StarCounter({
    super.key,
    this.iconSize = 24.0,
    this.fontSize = 18.0,
    this.iconColor,
    this.textColor,
    this.showBackground = true,
    this.refreshInterval = 2,
    this.animateChanges = true,
    this.onStarsUpdated,
  });

  @override
  State<StarCounter> createState() => _StarCounterState();
}

class _StarCounterState extends State<StarCounter>
    with SingleTickerProviderStateMixin {
  int _totalStars = 0;
  int _previousStars = 0;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;
  
  // Animación para el pulso del ícono
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // Animación para el cambio de número
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Configurar animación de pulso
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.elasticOut,
      ),
    );
    
    // Cargar estrellas inicialmente
    _loadStars();
    
    // Configurar actualización automática si está habilitada
    if (widget.refreshInterval > 0) {
      _startAutoRefresh();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  /// Inicia la actualización automática del contador
  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      Duration(seconds: widget.refreshInterval),
      (_) => _loadStars(),
    );
  }

  /// Carga las estrellas desde el servicio
  Future<void> _loadStars() async {
    try {
      final total = await StarService.getTotalStars();
      
      if (mounted) {
        setState(() {
          _previousStars = _totalStars;
          _totalStars = total;
          _isLoading = false;
          _errorMessage = null;
          
          // Si cambió el número y debe animar, ejecutar animación
          if (widget.animateChanges && _previousStars != _totalStars && _previousStars > 0) {
            _pulseController.forward(from: 0);
          }
        });
        
        // Notificar cambio si hay callback
        widget.onStarsUpdated?.call(_totalStars);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error al cargar estrellas';
        });
      }
      // Error loading stars: $e
    }
  }

  /// Refresca manualmente el contador
  Future<void> refresh() async {
    await _loadStars();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.iconColor ?? Colors.amber[700]!;
    final textColor = widget.textColor ?? context.appColors.textPrimary;

    // Estado de carga
    if (_isLoading) {
      return _buildLoadingState(iconColor);
    }

    // Estado de error
    if (_errorMessage != null) {
      return _buildErrorState();
    }

    // Estado normal con datos
    return _buildNormalState(iconColor, textColor);
  }

  /// Construye el estado de carga
  Widget _buildLoadingState(Color iconColor) {
    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.iconSize,
          height: widget.iconSize,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(iconColor),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Cargando...',
          style: TextStyle(
            fontSize: widget.fontSize * 0.8,
            color: context.appColors.textSecondary,
          ),
        ),
      ],
    );

    if (widget.showBackground) {
      return _wrapWithBackground(content);
    }
    return content;
  }

  /// Construye el estado de error
  Widget _buildErrorState() {
    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.error_outline,
          size: widget.iconSize,
          color: Colors.red[400],
        ),
        const SizedBox(width: 8),
        Text(
          '0',
          style: TextStyle(
            fontSize: widget.fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.red[400],
          ),
        ),
      ],
    );

    if (widget.showBackground) {
      return _wrapWithBackground(content);
    }
    return content;
  }

  /// Construye el estado normal con datos
  Widget _buildNormalState(Color iconColor, Color textColor) {
    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ícono de estrella con animación de pulso
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Icon(
                Icons.star,
                size: widget.iconSize,
                color: iconColor,
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        // Número de estrellas con animación de escala
        AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: widget.animateChanges && _pulseController.isAnimating
                  ? _scaleAnimation.value
                  : 1.0,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: child,
                  );
                },
                child: Text(
                  _formatStars(_totalStars),
                  key: ValueKey<int>(_totalStars),
                  style: TextStyle(
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );

    if (widget.showBackground) {
      return _wrapWithBackground(content);
    }
    return content;
  }

  /// Envuelve el contenido con un fondo decorativo
  Widget _wrapWithBackground(Widget content) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber[50]!,
            Colors.amber[100]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.amber[300]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withAlpha(76),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: content,
    );
  }

  /// Formatea el número de estrellas para mostrar (ej: 1.2K, 5.3M)
  String _formatStars(int stars) {
    if (stars < 1000) {
      return stars.toString();
    } else if (stars < 1000000) {
      final k = stars / 1000;
      return k % 1 == 0 ? '${k.toInt()}K' : '${k.toStringAsFixed(1)}K';
    } else {
      final m = stars / 1000000;
      return m % 1 == 0 ? '${m.toInt()}M' : '${m.toStringAsFixed(1)}M';
    }
  }
}

/// Widget compacto de estrellas para usar en AppBar
/// 
/// Versión optimizada sin fondo y con tamaños ajustados para barras
class StarCounterCompact extends StatelessWidget {
  final bool autoRefresh;
  final ValueChanged<int>? onStarsUpdated;

  const StarCounterCompact({
    super.key,
    this.autoRefresh = true,
    this.onStarsUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return StarCounter(
      iconSize: 20,
      fontSize: 16,
      showBackground: false,
      refreshInterval: autoRefresh ? 2 : 0,
      animateChanges: false,
      onStarsUpdated: onStarsUpdated,
    );
  }
}

/// Widget de estrellas con botón de recarga manual
/// 
/// Útil para pantallas donde el usuario quiere ver actualizaciones inmediatas
class StarCounterWithRefresh extends StatefulWidget {
  final double iconSize;
  final double fontSize;
  
  const StarCounterWithRefresh({
    super.key,
    this.iconSize = 24.0,
    this.fontSize = 18.0,
  });

  @override
  State<StarCounterWithRefresh> createState() => _StarCounterWithRefreshState();
}

class _StarCounterWithRefreshState extends State<StarCounterWithRefresh> {
  final GlobalKey<_StarCounterState> _counterKey = GlobalKey<_StarCounterState>();
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await _counterKey.currentState?.refresh();
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StarCounter(
          key: _counterKey,
          iconSize: widget.iconSize,
          fontSize: widget.fontSize,
          refreshInterval: 0, // Desactivar auto-refresh
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: _isRefreshing
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[700]!),
                  ),
                )
              : Icon(
                  Icons.refresh,
                  color: Colors.amber[700],
                ),
          onPressed: _isRefreshing ? null : _handleRefresh,
          tooltip: 'Actualizar estrellas',
        ),
      ],
    );
  }
}
