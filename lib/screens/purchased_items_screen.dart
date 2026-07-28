import 'package:flutter/material.dart';

import '../logic/user_profile_service.dart';
import '../models/shop_item.dart';
import '../services/effects_service.dart';
import '../services/powerup_service.dart';
import '../services/shop_service.dart';
import '../theme/app_colors_extension.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/responsive_snack_bar.dart';

/// Pantalla para ver y gestionar los ítems comprados.
/// 
/// Permite al usuario ver todos sus ítems comprados y activar/desactivar
/// temas, efectos y ver el estado de power-ups.
class PurchasedItemsScreen extends StatefulWidget {
  const PurchasedItemsScreen({super.key});

  @override
  State<PurchasedItemsScreen> createState() => _PurchasedItemsScreenState();
}

class _PurchasedItemsScreenState extends State<PurchasedItemsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ShopItem> _purchasedItems = [];
  bool _isLoading = true;
  
  // Estado de ítems activos
  Set<String> _activeEffects = {};
  int _currentAvatarId = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final items = await ShopService.getPurchasedItems();
    final activeEffects = await EffectsService.getActiveEffects();
    final profile = await UserProfileService.loadProfile();
    
    setState(() {
      _purchasedItems = items;
      _activeEffects = activeEffects;
      _currentAvatarId = profile.avatarId;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<ShopItem> _getItemsByType(ShopItemType type) {
    return _purchasedItems.where((item) => item.type == type).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentIndex: -1,
      child: Column(
        children: [
          const SizedBox(height: 16),
          const Text(
            'Mis Ítems',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.face), text: 'Avatares'),
              Tab(icon: Icon(Icons.auto_awesome), text: 'Efectos'),
              Tab(icon: Icon(Icons.flash_on), text: 'Power-ups'),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAvatarsTab(),
                      _buildEffectsTab(),
                      _buildPowerUpsTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarsTab() {
    final avatars = _getItemsByType(ShopItemType.avatar);
    
    if (avatars.isEmpty) {
      return _buildEmptyState(
        icon: Icons.face,
        message: 'No tienes avatares comprados',
        hint: 'Visita la tienda para comprar avatares especiales',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: avatars.length,
      itemBuilder: (context, index) {
        final avatar = avatars[index];
        final avatarId = avatar.metadata?['avatarId'] as int? ?? 8;
        final isActive = _currentAvatarId == avatarId;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isActive
                ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
                : BorderSide.none,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: AvatarWidget(avatarId: avatarId, size: 50),
            title: Text(
              avatar.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(avatar.description),
            trailing: isActive
                ? Chip(
                    label: const Text('Activo'),
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  )
                : ElevatedButton(
                    onPressed: () => _activateAvatar(avatarId),
                    child: const Text('Usar'),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildEffectsTab() {
    final effects = _getItemsByType(ShopItemType.effect);
    
    if (effects.isEmpty) {
      return _buildEmptyState(
        icon: Icons.auto_awesome,
        message: 'No tienes efectos comprados',
        hint: 'Visita la tienda para comprar efectos visuales',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: effects.length,
      itemBuilder: (context, index) {
        final effect = effects[index];
        final effectId = effect.metadata?['effectId'] as String?;
        final isActive = effectId != null && _activeEffects.contains(effectId);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SwitchListTile(
            contentPadding: const EdgeInsets.all(12),
            secondary: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isActive ? Colors.amber[100] : context.appColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(effect.icon, style: const TextStyle(fontSize: 28)),
              ),
            ),
            title: Text(
              effect.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(effect.description),
            value: isActive,
            onChanged: (value) => _toggleEffect(effectId!, value),
          ),
        );
      },
    );
  }

  Widget _buildPowerUpsTab() {
    final powerUps = _getItemsByType(ShopItemType.powerup);
    
    if (powerUps.isEmpty) {
      return _buildEmptyState(
        icon: Icons.flash_on,
        message: 'No tienes power-ups comprados',
        hint: 'Visita la tienda para comprar power-ups',
      );
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: PowerUpService.getActivePowerUpsInfo(),
      builder: (context, snapshot) {
        final activePowerUps = snapshot.data ?? [];
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: powerUps.length,
          itemBuilder: (context, index) {
            final powerUp = powerUps[index];
            final activeInfo = activePowerUps.firstWhere(
              (p) => p['id'] == powerUp.id,
              orElse: () => {},
            );
            final isActive = activeInfo.isNotEmpty;
            final remainingTime = activeInfo['remainingTime'] as String?;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: isActive
                    ? const BorderSide(color: Colors.orange, width: 2)
                    : BorderSide.none,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: isActive
                            ? LinearGradient(
                                colors: [Colors.orange[400]!, Colors.amber[600]!],
                              )
                            : null,
                        color: isActive ? null : context.appColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          powerUp.icon,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            powerUp.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            powerUp.description,
                            style: TextStyle(
                              color: context.appColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          if (isActive && remainingTime != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '⏱️ $remainingTime restante',
                                style: TextStyle(
                                  color: Colors.orange[900],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isActive)
                      const Icon(
                        Icons.check_circle,
                        color: Colors.orange,
                        size: 28,
                      )
                    else
                      Icon(
                        Icons.timer_off,
                        color: context.appColors.textSecondary,
                        size: 28,
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String hint,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: context.appColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.appColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hint,
              style: TextStyle(
                fontSize: 14,
                color: context.appColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _activateAvatar(int avatarId) async {
    try {
      await UserProfileService.updateAvatar(avatarId);
      setState(() {
        _currentAvatarId = avatarId;
      });
      if (mounted) {
        ResponsiveSnackBar.showSuccess(
          context,
          message: 'Avatar actualizado',
        );
      }
    } catch (e) {
      if (mounted) {
        ResponsiveSnackBar.showError(
          context,
          message: 'Error: $e',
        );
      }
    }
  }

  Future<void> _toggleEffect(String effectId, bool active) async {
    try {
      await EffectsService.setEffectActive(effectId, active);
      setState(() {
        if (active) {
          _activeEffects.add(effectId);
        } else {
          _activeEffects.remove(effectId);
        }
      });
      if (mounted) {
        ResponsiveSnackBar.showSuccess(
          context,
          message: active ? 'Efecto activado' : 'Efecto desactivado',
        );
      }
    } catch (e) {
      if (mounted) {
        ResponsiveSnackBar.showError(
          context,
          message: 'Error: $e',
        );
      }
    }
  }
}
