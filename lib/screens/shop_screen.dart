import 'package:flutter/material.dart';

import '../logic/star_service.dart';
import '../models/shop_item.dart';
import '../services/shop_service.dart';
import '../theme/app_colors_extension.dart';
import '../utils/responsive.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/error_dialog.dart';
import '../widgets/responsive_snack_bar.dart';

/// Pantalla de la tienda de estrellas.
/// 
/// Muestra todos los ítems disponibles para comprar
/// y permite a los usuarios gastar sus estrellas.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with SingleTickerProviderStateMixin {
  int _totalStars = 0;
  Set<String> _purchasedIds = {};
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
      // Pulsa unas veces al entrar y se detiene (evita animación infinita).
    )..repeat(reverse: true, count: 3);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final total = await StarService.getTotalStars();
    final purchased = await ShopService.getPurchasedItemIds();
    setState(() {
      _totalStars = total;
      _purchasedIds = purchased;
      _isLoading = false;
    });
  }

  Future<void> _purchaseItem(ShopItem item) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Text(item.icon, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Confirmar compra',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.description,
                style: TextStyle(color: context.appColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Precio:',
                      style: TextStyle(
                        fontSize: 16,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${item.price} ⭐',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tu balance:',
                    style: TextStyle(fontSize: 14, color: context.appColors.textSecondary),
                  ),
                  Text(
                    '$_totalStars ⭐',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancelar',
                style: TextStyle(color: context.appColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Comprar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      await ShopService.purchaseItem(item);
      await _loadData();

      if (mounted) {
        String message;
        if (item.type == ShopItemType.avatar) {
          message = '¡Avatar activado! Puedes verlo en tu perfil';
        } else {
          message = '¡${item.name} comprado exitosamente!';
        }
        
        ResponsiveSnackBar.showSuccess(context, message: message);
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('StateError: ', '');
        
        if (errorMessage.contains('Insufficient stars')) {
          ErrorHelper.showInsufficientStarsError(
            context,
            required: item.price,
            available: _totalStars,
          );
        } else {
          ErrorHelper.showCustomError(
            context,
            title: 'Error en la Compra',
            message: errorMessage,
          );
        }
      }
    }
  }

  void _showBalanceModal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: child,
                );
              },
              child: Text(
                '⭐',
                style: TextStyle(
                  fontSize: Responsive.scale(context, 48, 56, 64),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tu Balance',
              style: TextStyle(
                fontSize: Responsive.scale(context, 16, 18, 20),
                fontWeight: FontWeight.w600,
                color: context.appColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_totalStars',
              style: TextStyle(
                fontSize: Responsive.scale(context, 36, 40, 44),
                fontWeight: FontWeight.bold,
                color: Colors.amber[800],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.scale(context, 24, 28, 32),
                  vertical: Responsive.scale(context, 12, 14, 16),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Cerrar',
                style: TextStyle(
                  fontSize: Responsive.scale(context, 14, 15, 16),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = ShopService.getAvailableItems();
    final hPadding = Responsive.horizontalPadding(context);

    return AppScaffold(
      currentIndex: -1,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Header compacto con botón de balance
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(hPadding, 16, hPadding, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.shopping_bag_rounded,
                                color: Theme.of(context).colorScheme.primary,
                                size: Responsive.scale(context, 28, 32, 36),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Tienda',
                                style: TextStyle(
                                  fontSize: Responsive.scale(context, 20, 24, 26),
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: _showBalanceModal,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: Responsive.scale(context, 12, 14, 16),
                                vertical: Responsive.scale(context, 8, 10, 12),
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber[100],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.amber[300]!,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '⭐',
                                    style: TextStyle(
                                      fontSize: Responsive.scale(context, 16, 18, 20),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$_totalStars',
                                    style: TextStyle(
                                      fontSize: Responsive.scale(context, 16, 18, 20),
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber[900],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Grid de items
                SliverPadding(
                  padding: EdgeInsets.all(hPadding),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: Responsive.gridColumns(
                        context,
                        mobile: 2,
                        tablet: 3,
                        desktop: 4,
                        wide: 4,
                      ),
                      crossAxisSpacing: Responsive.gridSpacing(context),
                      mainAxisSpacing: Responsive.gridSpacing(context),
                      childAspectRatio: Responsive.scale(context, 1.0, 1.15, 1.25),
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = items[index];
                        final isPurchased = _purchasedIds.contains(item.id);
                        final canAfford = _totalStars >= item.price;

                        return _ShopItemCard(
                          item: item,
                          isPurchased: isPurchased,
                          canAfford: canAfford,
                          onPurchase: () => _purchaseItem(item),
                        );
                      },
                      childCount: items.length,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Widget que representa una tarjeta de ítem de la tienda.
class _ShopItemCard extends StatefulWidget {
  final ShopItem item;
  final bool isPurchased;
  final bool canAfford;
  final VoidCallback onPurchase;

  const _ShopItemCard({
    required this.item,
    required this.isPurchased,
    required this.canAfford,
    required this.onPurchase,
  });

  @override
  State<_ShopItemCard> createState() => _ShopItemCardState();
}

class _ShopItemCardState extends State<_ShopItemCard> {
  bool _isHovered = false;

  List<Color> _getGradientColors() {
    if (widget.isPurchased) {
      return [
        const Color(0xFF4CAF50),
        const Color(0xFF66BB6A),
      ];
    }
    
    switch (widget.item.type) {
      case ShopItemType.avatar:
        return [
          const Color(0xFF42A5F5),
          const Color(0xFF1E88E5),
        ];
      case ShopItemType.effect:
        return [
          const Color(0xFFEC407A),
          const Color(0xFFD81B60),
        ];
      case ShopItemType.powerup:
        return [
          const Color(0xFFFFA726),
          const Color(0xFFFB8C00),
        ];
      case ShopItemType.content:
        return [
          const Color(0xFF66BB6A),
          const Color(0xFF43A047),
        ];
      default:
        return [
          const Color(0xFF9E9E9E),
          const Color(0xFF757575),
        ];
    }
  }

  Color _getAccentColor() {
    if (widget.isPurchased) return const Color(0xFF4CAF50);
    
    switch (widget.item.type) {
      case ShopItemType.avatar:
        return const Color(0xFF1E88E5);
      case ShopItemType.effect:
        return const Color(0xFFD81B60);
      case ShopItemType.powerup:
        return const Color(0xFFFB8C00);
      case ShopItemType.content:
        return const Color(0xFF43A047);
      default:
        return const Color(0xFF757575);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = _getGradientColors();
    final accentColor = _getAccentColor();
    final hasHover = Responsive.hasHover(context);

    return MouseRegion(
      onEnter: hasHover ? (_) => setState(() => _isHovered = true) : null,
      onExit: hasHover ? (_) => setState(() => _isHovered = false) : null,
      child: AnimatedScale(
        scale: _isHovered ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: _isHovered ? 0.4 : 0.25),
                blurRadius: _isHovered ? 20 : 12,
                offset: Offset(0, _isHovered ? 8 : 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(Responsive.scale(context, 6, 8, 10)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: Responsive.scale(context, 48, 56, 64),
                  height: Responsive.scale(context, 48, 56, 64),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      widget.item.icon,
                      style: TextStyle(
                        fontSize: Responsive.scale(context, 28, 32, 36),
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: Responsive.scale(context, 4, 6, 8)),
                
                Text(
                  widget.item.name,
                  style: TextStyle(
                    fontSize: Responsive.scale(context, 13, 14, 15),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: Responsive.scale(context, 2, 3, 4)),
                
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.scale(context, 8, 10, 12),
                    vertical: Responsive.scale(context, 2, 3, 4),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.item.price} ⭐',
                    style: TextStyle(
                      fontSize: Responsive.scale(context, 12, 13, 14),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                
                SizedBox(height: Responsive.scale(context, 4, 6, 8)),
                
                if (widget.isPurchased)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      vertical: Responsive.scale(context, 4, 5, 6),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: accentColor,
                          size: Responsive.scale(context, 14, 16, 18),
                        ),
                        SizedBox(width: Responsive.scale(context, 4, 5, 6)),
                        Text(
                          'Obtenido',
                          style: TextStyle(
                            fontSize: Responsive.scale(context, 11, 12, 13),
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.canAfford ? widget.onPurchase : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.canAfford ? Colors.white : Colors.white.withValues(alpha: 0.5),
                        foregroundColor: widget.canAfford ? accentColor : Colors.grey[600],
                        disabledBackgroundColor: Colors.white.withValues(alpha: 0.5),
                        disabledForegroundColor: Colors.grey[600],
                        elevation: widget.canAfford ? 4 : 0,
                        padding: EdgeInsets.symmetric(
                          vertical: Responsive.scale(context, 4, 5, 6),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        widget.canAfford ? 'Comprar' : 'Sin estrellas',
                        style: TextStyle(
                          fontSize: Responsive.scale(context, 11, 12, 13),
                          fontWeight: FontWeight.bold,
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
