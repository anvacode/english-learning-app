import 'package:flutter/material.dart';

import '../../models/shop_item.dart';
import '../../services/shop_service.dart';
import '../../theme/app_colors_extension.dart';
import '../../utils/responsive.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/avatar_widget.dart';

/// Pantalla para seleccionar un avatar.
/// 
/// Muestra un grid de 8 avatares predefinidos y los avatares
/// comprados de la tienda, permitiendo al usuario seleccionar uno.
class AvatarSelectionScreen extends StatefulWidget {
  final int currentAvatarId;

  const AvatarSelectionScreen({
    super.key,
    required this.currentAvatarId,
  });

  @override
  State<AvatarSelectionScreen> createState() => _AvatarSelectionScreenState();
}

class _AvatarSelectionScreenState extends State<AvatarSelectionScreen> {
  late int _selectedAvatarId;
  List<ShopItem> _purchasedAvatars = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedAvatarId = widget.currentAvatarId;
    _loadPurchasedAvatars();
  }

  Future<void> _loadPurchasedAvatars() async {
    final purchasedItems = await ShopService.getPurchasedItems();
    final avatars = purchasedItems
        .where((item) => item.type == ShopItemType.avatar)
        .toList();
    
    setState(() {
      _purchasedAvatars = avatars;
      _isLoading = false;
    });
  }

  void _confirmSelection() {
    Navigator.of(context).pop(_selectedAvatarId);
  }

  @override
  Widget build(BuildContext context) {
    final gridColumns = Responsive.gridColumns(context, mobile: 3, tablet: 4, desktop: 6);
    final titleSize = Responsive.scale(context, 20, 22, 24);
    final sectionTitleSize = Responsive.scale(context, 14, 15, 16);
    final padding = Responsive.scale(context, 16, 20, 24);
    
    return AppScaffold(
      currentIndex: -1,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  children: [
                    SizedBox(height: Responsive.scale(context, 12, 16, 20)),
                    Text(
                      'Seleccionar Avatar',
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    SizedBox(height: Responsive.scale(context, 12, 16, 20)),
                    
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Avatares básicos',
                         style: TextStyle(
                           fontSize: sectionTitleSize,
                           fontWeight: FontWeight.w600,
                           color: context.appColors.textSecondary,
                         ),
                      ),
                    ),
                    SizedBox(height: Responsive.scale(context, 10, 12, 12)),
                    
                    SizedBox(
                      height: gridColumns <= 3 ? 280 : (gridColumns <= 4 ? 240 : 200),
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: gridColumns,
                          crossAxisSpacing: Responsive.scale(context, 10, 12, 12),
                          mainAxisSpacing: Responsive.scale(context, 10, 12, 12),
                        ),
                        itemCount: 8,
                        itemBuilder: (context, index) {
                          return _buildAvatarTile(index, isShopAvatar: false);
                        },
                      ),
                    ),
                    
                    if (_purchasedAvatars.isNotEmpty) ...[
                      SizedBox(height: Responsive.scale(context, 20, 24, 24)),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: Responsive.scale(context, 18, 20, 20)),
                            SizedBox(width: Responsive.scale(context, 6, 8, 8)),
                            Text(
                              'Avatares especiales',
                              style: TextStyle(
                                fontSize: sectionTitleSize,
                                fontWeight: FontWeight.w600,
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: Responsive.scale(context, 10, 12, 12)),
                      
                      SizedBox(
                        height: gridColumns <= 3 ? 280 : (gridColumns <= 4 ? 240 : 200),
                        child: GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: gridColumns,
                            crossAxisSpacing: Responsive.scale(context, 10, 12, 12),
                            mainAxisSpacing: Responsive.scale(context, 10, 12, 12),
                          ),
                          itemCount: _purchasedAvatars.length,
                          itemBuilder: (context, index) {
                            final avatar = _purchasedAvatars[index];
                            final avatarId = avatar.metadata?['avatarId'] as int? ?? 8;
                            return _buildAvatarTile(avatarId, isShopAvatar: true, shopItem: avatar);
                          },
                        ),
                      ),
                    ],
                    
                    SizedBox(height: Responsive.scale(context, 20, 24, 24)),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _confirmSelection,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: Responsive.scale(context, 14, 16, 16)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Responsive.borderRadius(context)),
                          ),
                        ),
                        child: Text(
                          'Confirmar',
                          style: TextStyle(
                            fontSize: Responsive.scale(context, 16, 17, 18),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAvatarTile(int avatarId, {required bool isShopAvatar, ShopItem? shopItem}) {
    final isSelected = _selectedAvatarId == avatarId;
    final avatarSize = Responsive.scale(context, 40, 45, 50);
    final borderRadius = Responsive.scale(context, 12, 14, 16);
    final borderWidth = isSelected ? Responsive.scale(context, 3, 4, 4) : Responsive.scale(context, 2, 2, 2);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAvatarId = avatarId;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
           color: isSelected
               ? Theme.of(context).colorScheme.primaryContainer
               : isShopAvatar
                   ? Colors.amber[50]
                   : context.appColors.surfaceVariant,
           borderRadius: BorderRadius.circular(borderRadius),
           border: Border.all(
             color: isSelected
                 ? Theme.of(context).colorScheme.primary
                 : isShopAvatar
                     ? Colors.amber[300]!
                     : context.appColors.border,
            width: borderWidth,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withAlpha(76),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Center(
              child: AvatarWidget(
                avatarId: avatarId,
                size: avatarSize,
                backgroundColor: Colors.transparent,
              ),
            ),
            if (isSelected)
              Positioned(
                top: Responsive.scale(context, 3, 4, 4),
                right: Responsive.scale(context, 3, 4, 4),
                child: Container(
                  padding: EdgeInsets.all(Responsive.scale(context, 1, 2, 2)),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: Responsive.scale(context, 12, 14, 14),
                  ),
                ),
              ),
            if (isShopAvatar && !isSelected)
              Positioned(
                top: Responsive.scale(context, 3, 4, 4),
                right: Responsive.scale(context, 3, 4, 4),
                child: Container(
                  padding: EdgeInsets.all(Responsive.scale(context, 1, 2, 2)),
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.star,
                    color: Colors.white,
                    size: Responsive.scale(context, 10, 12, 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
