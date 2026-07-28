import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logic/theme_provider.dart';
import '../screens/lesson_history_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/purchased_items_screen.dart';
import '../services/audio_service.dart';
import '../theme/app_colors_extension.dart';
import '../utils/responsive.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/responsive_container.dart';
import '../widgets/responsive_snack_bar.dart';
import 'help_screen.dart';
import 'tutorial/tutorial_screen.dart';

/// Pantalla de configuración básica de la aplicación.
///
/// Muestra opciones de configuración y preferencias del usuario.
class SettingsScreen extends StatefulWidget {
  final bool showNavBar;

  const SettingsScreen({
    super.key,
    this.showNavBar = true,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AudioService _audioService = AudioService();
  bool _autoSpeakEnabled = true;
  bool _soundsEnabled = true;
  double _pitch = 1.0;
  double _rate = 0.5;
  bool _notificationsEnabled = true;
  static const String _notificationsKey = 'notifications_enabled';

  @override
  void initState() {
    super.initState();
    _loadAudioSettings();
    _loadNotificationSettings();
  }

  // La pantalla se renderiza de inmediato con los valores por defecto y
  // se actualiza cuando terminan de cargar las preferencias (sin spinner
  // bloqueante).
  Future<void> _loadAudioSettings() async {
    await _audioService.initialize();
    if (!mounted) return;
    setState(() {
      _autoSpeakEnabled = _audioService.autoSpeakEnabled;
      _soundsEnabled = _audioService.soundsEnabled;
      _pitch = _audioService.pitch;
      _rate = _audioService.rate;
    });
  }

  Future<void> _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = ResponsiveContainer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth >= 600;
          
          return SingleChildScrollView(
            padding: EdgeInsets.all(Responsive.scale(context, 12, 16, 20)),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWideScreen ? 900 : double.infinity,
                ),
                child: isWideScreen
                    ? _buildTwoColumnLayout(context)
                    : _buildSingleColumnLayout(context),
              ),
            ),
          );
        },
      ),
    );

    if (widget.showNavBar) {
      return AppScaffold(
        currentIndex: 3,
        child: content,
      );
    }

    return content;
  }

  Widget _buildSingleColumnLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAccountSection(context),
        const SizedBox(height: 32),
        _buildAppearanceSection(context),
        const SizedBox(height: 32),
        _buildAudioSection(context),
        const SizedBox(height: 32),
        _buildPersonalizationSection(context),
        const SizedBox(height: 32),
        _buildAppSection(context),
        const SizedBox(height: 32),
        _buildHelpSection(context),
        const SizedBox(height: 32),
        _buildResetButton(context),
      ],
    );
  }

  Widget _buildTwoColumnLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAccountSection(context),
              const SizedBox(height: 32),
              _buildAppearanceSection(context),
              const SizedBox(height: 32),
              _buildPersonalizationSection(context),
              const SizedBox(height: 32),
              _buildAppSection(context),
            ],
          ),
        ),
        SizedBox(width: Responsive.scale(context, 20, 24, 32)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAudioSection(context),
              const SizedBox(height: 32),
              _buildHelpSection(context),
              const SizedBox(height: 32),
              _buildResetButton(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    return _SettingsSection(
      title: 'Cuenta',
      children: [
        _SettingsTile(
          icon: Icons.person,
          title: 'Perfil',
          subtitle: 'Gestiona tu información personal',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfileScreen(),
              ),
            );
          },
        ),
        _SettingsTile(
          icon: Icons.history,
          title: 'Historial de lecciones',
          subtitle: 'Revisa tu progreso',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LessonHistoryScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAppearanceSection(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return _SettingsSection(
      title: 'Apariencia',
      children: [
        Padding(
          padding: EdgeInsets.all(Responsive.scale(context, 14, 16, 18)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(
                      Responsive.scale(context, 8, 9, 10),
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.palette_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: Responsive.scale(context, 20, 22, 24),
                    ),
                  ),
                  SizedBox(width: Responsive.scale(context, 12, 14, 16)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tema',
                          style: TextStyle(
                            fontSize: Responsive.scale(context, 15, 16, 17),
                            fontWeight: FontWeight.w600,
                            color: context.appColors.textPrimary,
                          ),
                        ),
                        SizedBox(
                          height: Responsive.scale(context, 2, 3, 4),
                        ),
                        Text(
                          'Elige cómo se ve la aplicación',
                          style: TextStyle(
                            fontSize: Responsive.scale(context, 13, 14, 15),
                            color: context.appColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: Responsive.scale(context, 14, 16, 18)),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: context.appColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.appColors.border),
                ),
                child: Row(
                  children: [
                    _ThemeOption(
                      mode: ThemeMode.light,
                      icon: Icons.light_mode_rounded,
                      label: 'Claro',
                      selected: themeProvider.mode == ThemeMode.light,
                      onTap: () => themeProvider.setMode(ThemeMode.light),
                    ),
                    _ThemeOption(
                      mode: ThemeMode.dark,
                      icon: Icons.dark_mode_rounded,
                      label: 'Oscuro',
                      selected: themeProvider.mode == ThemeMode.dark,
                      onTap: () => themeProvider.setMode(ThemeMode.dark),
                    ),
                    _ThemeOption(
                      mode: ThemeMode.system,
                      icon: Icons.settings_suggest_rounded,
                      label: 'Sistema',
                      selected: themeProvider.mode == ThemeMode.system,
                      onTap: () => themeProvider.setMode(ThemeMode.system),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAudioSection(BuildContext context) {
    return _SettingsSection(
      title: 'Audio',
      children: [
        _SettingsTile(
          icon: Icons.record_voice_over,
          title: 'Pronunciación automática',
          subtitle: 'Pronuncia palabras automáticamente',
          trailing: Switch(
            value: _autoSpeakEnabled,
            onChanged: (value) async {
              setState(() {
                _autoSpeakEnabled = value;
              });
              await _audioService.setAutoSpeak(value);
            },
          ),
        ),
        _SettingsTile(
          icon: Icons.volume_up,
          title: 'Efectos de sonido',
          subtitle: 'Activar sonidos de la aplicación',
          trailing: Switch(
            value: _soundsEnabled,
            onChanged: (value) async {
              setState(() {
                _soundsEnabled = value;
              });
              await _audioService.setSoundsEnabled(value);
            },
          ),
        ),
        _buildSliderCard(
          context: context,
          icon: Icons.tune,
          title: 'Tono de voz',
          value: _pitch,
          min: 0.5,
          max: 2.0,
          divisions: 15,
          onChanged: (value) async {
            setState(() {
              _pitch = value;
            });
            await _audioService.setPitch(value);
          },
        ),
        _buildSliderCard(
          context: context,
          icon: Icons.speed,
          title: 'Velocidad de habla',
          value: _rate,
          min: 0.0,
          max: 1.0,
          divisions: 10,
          onChanged: (value) async {
            setState(() {
              _rate = value;
            });
            await _audioService.setRate(value);
          },
        ),
      ],
    );
  }

  Widget _buildSliderCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.all(Responsive.scale(context, 16, 18, 20)),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.appColors.border,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: Responsive.scale(context, 22, 24, 26),
              ),
              SizedBox(width: Responsive.scale(context, 10, 12, 14)),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: Responsive.scale(context, 15, 16, 17),
                    fontWeight: FontWeight.w500,
                    color: context.appColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.scale(context, 10, 12, 14),
                  vertical: Responsive.scale(context, 4, 5, 6),
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: Responsive.scale(context, 13, 14, 15),
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.scale(context, 12, 14, 16)),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: Responsive.scale(context, 4, 5, 6),
              thumbShape: RoundSliderThumbShape(
                enabledThumbRadius: Responsive.scale(context, 8, 9, 10),
              ),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              label: value.toStringAsFixed(1),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalizationSection(BuildContext context) {
    return _SettingsSection(
      title: 'Personalización',
      children: [
        _SettingsTile(
          icon: Icons.shopping_bag,
          title: 'Mis Ítems',
          subtitle: 'Gestiona tus ítems comprados',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PurchasedItemsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAppSection(BuildContext context) {
    return _SettingsSection(
      title: 'Aplicación',
      children: [
        _SettingsTile(
          icon: Icons.notifications,
          title: 'Notificaciones',
          subtitle: 'Gestiona las notificaciones',
          trailing: Switch(
            value: _notificationsEnabled,
            onChanged: (value) async {
              setState(() {
                _notificationsEnabled = value;
              });
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool(_notificationsKey, value);
            },
          ),
        ),
        _SettingsTile(
          icon: Icons.language,
          title: 'Idioma',
          subtitle: 'Español',
          onTap: () {
            ResponsiveSnackBar.showInfo(
              context,
              message: 'Próximamente: Selector de idioma',
            );
          },
        ),
      ],
    );
  }

  Widget _buildHelpSection(BuildContext context) {
    return _SettingsSection(
      title: 'Ayuda',
      children: [
        _SettingsTile(
          icon: Icons.help_outline,
          title: 'Ayuda y soporte',
          subtitle: 'Obtén ayuda sobre la aplicación',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HelpScreen()),
            );
          },
        ),
        _SettingsTile(
          icon: Icons.menu_book_rounded,
          title: 'Ver tutorial',
          subtitle: 'Aprende a usar la app paso a paso',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TutorialScreen(showPlayButton: false),
              ),
            );
          },
        ),
        _SettingsTile(
          icon: Icons.info_outline,
          title: 'Acerca de',
          subtitle: 'Información de la aplicación',
          onTap: () {
            showAboutDialog(
              context: context,
              applicationName: 'English Learning',
              applicationVersion: '2.0.0',
              applicationIcon: Icon(
                Icons.school,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              children: const [
                Text('Aplicación de aprendizaje de inglés para niños.'),
                SizedBox(height: 8),
                Text(
                  'Aprende inglés de forma divertida con lecciones interactivas.',
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildResetButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.scale(context, 12, 16, 20),
      ),
      child: OutlinedButton.icon(
        onPressed: () => _showResetConfirmation(context),
        icon: const Icon(Icons.refresh),
        label: const Text('Restablecer datos'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }

  Future<void> _showResetConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Restablecer datos?'),
        content: const Text(
          'Esta acción eliminará todo tu progreso, estrellas, compras y configuración. '
          'No se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Restablecer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _resetAllData();
      if (!context.mounted) return;
      ResponsiveSnackBar.showSuccess(context, message: 'Datos restablecidos');
    }
  }

  Future<void> _resetAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _loadAudioSettings();
    _loadNotificationSettings();
    if (mounted) {
      await context.read<ThemeProvider>().reload();
    }
  }
}

/// Widget que representa una sección de configuración.
class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: Responsive.scale(context, 16, 18, 20),
            bottom: Responsive.scale(context, 8, 10, 12),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: Responsive.scale(context, 14, 15, 16),
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Card(
          elevation: 2,
          shadowColor: context.appColors.shadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Responsive.scale(context, 12, 14, 16)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Responsive.scale(context, 12, 14, 16)),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}

/// Opción seleccionable del selector de tema (claro / oscuro / sistema).
class _ThemeOption extends StatelessWidget {
  final ThemeMode mode;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.mode,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fontSize = Responsive.scale(context, 13, 14, 15);
    final iconSize = Responsive.scale(context, 18, 19, 20);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(
            vertical: Responsive.scale(context, 10, 11, 12),
          ),
          decoration: BoxDecoration(
            gradient: selected ? context.appColors.primaryGradient : null,
            color: selected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: iconSize,
                  color: selected
                      ? Colors.white
                      : context.appColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? Colors.white
                        : context.appColors.textSecondary,
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

/// Widget que representa un ítem de configuración.
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(Responsive.scale(context, 14, 16, 18)),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: context.appColors.border,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(Responsive.scale(context, 8, 9, 10)),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: Responsive.scale(context, 20, 22, 24),
              ),
            ),
            SizedBox(width: Responsive.scale(context, 12, 14, 16)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: Responsive.scale(context, 15, 16, 17),
                      fontWeight: FontWeight.w600,
                      color: context.appColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: Responsive.scale(context, 2, 3, 4)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: Responsive.scale(context, 13, 14, 15),
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              SizedBox(width: Responsive.scale(context, 8, 10, 12)),
              trailing!,
            ] else if (onTap != null) ...[
              SizedBox(width: Responsive.scale(context, 8, 10, 12)),
              Icon(
                Icons.chevron_right,
                color: context.appColors.textTertiary,
                size: Responsive.scale(context, 20, 22, 24),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
