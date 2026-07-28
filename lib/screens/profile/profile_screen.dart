import 'package:flutter/material.dart';

import '../../data/lessons_data.dart';
import '../../dialogs/edit_nickname_dialog.dart';
import '../../logic/badge_service.dart';
import '../../logic/mastery_evaluator.dart';
import '../../logic/star_service.dart';
import '../../logic/user_profile_service.dart';
import '../../models/badge.dart' as achievement;
import '../../models/user_profile.dart';
import '../../theme/app_colors_extension.dart';
import '../../theme/text_styles.dart';
import '../../utils/responsive.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/auth_status_widget.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/star_display.dart';
import 'avatar_selection_screen.dart';

/// Pantalla de perfil del usuario.
/// 
/// Muestra información del usuario, estadísticas de progreso
/// y una vista previa de badges.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<UserProfile> _profileFuture;
  late Future<double> _progressFuture;
  late Future<List<achievement.Badge>> _badgesFuture;
  bool _isSaving = false;
  String? _saveMessage;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _profileFuture = UserProfileService.loadProfile();
      _progressFuture = _calculateGlobalProgress();
      _badgesFuture = BadgeService.getBadges(lessonsList);
    });
  }

  Future<double> _calculateGlobalProgress() async {
    if (lessonsList.isEmpty) return 0.0;

    final evaluator = MasteryEvaluator();
    double totalProgress = 0.0;

    for (final lesson in lessonsList) {
      final status = await evaluator.evaluateLesson(lesson.id);

      // Map status to progress value
      final lessonProgress = switch (status) {
        LessonMasteryStatus.notStarted => 0.0,
        LessonMasteryStatus.inProgress => 0.5,
        LessonMasteryStatus.mastered => 1.0,
      };

      totalProgress += lessonProgress;
    }

    return totalProgress / lessonsList.length;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentIndex: -1,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: context.horizontalPadding,
          vertical: Responsive.scale(context, 16, 20, 24),
        ),
        child: Column(
          children: [
            SizedBox(height: Responsive.scale(context, 12, 16, 20)),
            Text(
              'Perfil',
              style: context.headline2,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Responsive.scale(context, 16, 20, 24)),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Responsive.builder(
                context: context,
                mobile: _buildMobileLayout(),
                tablet: _buildTabletLayout(),
                desktop: _buildDesktopLayout(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        const AuthStatusWidget(),
        SizedBox(height: Responsive.scale(context, 20, 24, 28)),
        _buildProfileHeader(),
        SizedBox(height: Responsive.scale(context, 24, 28, 32)),
        _buildStarsSection(),
        SizedBox(height: Responsive.scale(context, 20, 24, 28)),
        _buildProgressSection(),
        SizedBox(height: Responsive.scale(context, 20, 24, 28)),
        _buildBadgesPreview(),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = Responsive.scale(context, 16, 20, 20);
        final rightColumnWidth = (constraints.maxWidth - 250 - spacing).clamp(0.0, double.infinity);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 250,
              child: Column(
                children: [
                  _buildProfileHeader(),
                  SizedBox(height: Responsive.scale(context, 16, 20, 20)),
                  const AuthStatusWidget(),
                ],
              ),
            ),
            SizedBox(width: spacing),
            SizedBox(
              width: rightColumnWidth,
              child: Column(
                children: [
                  _buildStarsSection(),
                  SizedBox(height: Responsive.scale(context, 16, 20, 20)),
                  _buildProgressSection(),
                  SizedBox(height: Responsive.scale(context, 16, 20, 20)),
                  _buildBadgesPreview(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 250,
          child: Column(
            children: [
              _buildProfileHeader(),
              SizedBox(height: Responsive.scale(context, 16, 20, 20)),
              const AuthStatusWidget(),
            ],
          ),
        ),
        SizedBox(width: Responsive.scale(context, 16, 20, 20)),
        Expanded(
          child: Column(
            children: [
              _buildStarsSection(),
              SizedBox(height: Responsive.scale(context, 16, 20, 20)),
              _buildProgressSection(),
            ],
          ),
        ),
        SizedBox(width: Responsive.scale(context, 16, 20, 20)),
        SizedBox(
          width: 280,
          child: _buildBadgesPreview(),
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return FutureBuilder<UserProfile>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const AvatarWidget(avatarId: 0, size: 100);
        }

        final profile = snapshot.data!;
        return Column(
          children: [
            GestureDetector(
              onTap: () => _editAvatar(profile),
              child: AvatarWidget(
                avatarId: profile.avatarId,
                size: context.isMobile ? 100 : (context.isTablet ? 120 : 140),
              ),
            ),
            SizedBox(height: Responsive.scale(context, 12, 16, 20)),
            GestureDetector(
              onTap: () => _editNickname(profile),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      profile.nickname,
                      style: TextStyle(
                        fontSize: context.isMobile ? 24 : (context.isTablet ? 28 : 32),
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: Responsive.scale(context, 6, 8, 8)),
                  Icon(
                    Icons.edit,
                    size: Responsive.scale(context, 18, 20, 20),
                    color: context.appColors.textSecondary,
                  ),
                ],
              ),
            ),
            if (_saveMessage != null) ...[
              const SizedBox(height: 12),
              AnimatedOpacity(
                opacity: _showSuccess ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _showSuccess
                        ? Colors.green[100]
                        : Colors.orange[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isSaving)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      else if (_showSuccess)
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 16,
                        )
                      else
                        const Icon(
                          Icons.error,
                          color: Colors.orange,
                          size: 16,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        _saveMessage!,
                        style: TextStyle(
                          fontSize: 14,
                          color: _showSuccess
                              ? Colors.green[900]
                              : Colors.orange[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildStarsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Responsive.borderRadius(context)),
      ),
      child: Padding(
        padding: EdgeInsets.all(Responsive.scale(context, 16, 20, 24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Estrellas',
                  style: TextStyle(
                    fontSize: Responsive.scale(context, 20, 22, 24),
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                StarDisplay(
                  iconSize: Responsive.scale(context, 28, 30, 32),
                  fontSize: Responsive.scale(context, 24, 25, 26),
                  iconColor: Colors.amber[700],
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<int>(
              future: StarService.getTotalStars(),
              builder: (context, snapshot) {
                final totalStars = snapshot.data ?? 0;
                return FutureBuilder<int>(
                  future: StarService.getStarsEarnedToday(),
                  builder: (context, snapshot) {
                    final todayStars = snapshot.data ?? 0;
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             Text(
                               'Total de estrellas:',
                               style: TextStyle(
                                 fontSize: Responsive.scale(context, 16, 17, 18),
                                 color: context.appColors.textSecondary,
                               ),
                             ),
                            Text(
                              '$totalStars ⭐',
                              style: TextStyle(
                                fontSize: Responsive.scale(context, 18, 19, 20),
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             Text(
                               'Ganadas hoy:',
                               style: TextStyle(
                                 fontSize: Responsive.scale(context, 16, 17, 18),
                                 color: context.appColors.textSecondary,
                               ),
                             ),
                            Text(
                              '$todayStars ⭐',
                              style: TextStyle(
                                fontSize: Responsive.scale(context, 18, 19, 20),
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Responsive.borderRadius(context)),
      ),
      child: Padding(
        padding: EdgeInsets.all(Responsive.scale(context, 16, 20, 24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progreso',
              style: TextStyle(
                fontSize: Responsive.scale(context, 20, 22, 24),
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<double>(
              future: _progressFuture,
              builder: (context, snapshot) {
                final progress = snapshot.data ?? 0.0;
                final percentage = (progress * 100).toStringAsFixed(0);

                return Column(
                  children: [
                     LinearProgressIndicator(
                       value: progress,
                       backgroundColor: context.appColors.surfaceVariant,
                      color: Colors.deepPurple,
                      minHeight: Responsive.scale(context, 10, 12, 14),
                      borderRadius: BorderRadius.circular(Responsive.scale(context, 4, 6, 8)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$percentage% completado',
                      style: TextStyle(
                        fontSize: Responsive.scale(context, 16, 18, 20),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgesPreview() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Responsive.borderRadius(context)),
      ),
      child: Padding(
        padding: EdgeInsets.all(Responsive.scale(context, 16, 20, 24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Badges',
              style: TextStyle(
                fontSize: Responsive.scale(context, 20, 22, 24),
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<achievement.Badge>>(
              future: _badgesFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final badges = snapshot.data ?? [];
                final unlockedBadges = badges.where((b) => b.unlocked).toList();

                if (unlockedBadges.isEmpty) {
                  return Container(
                    padding: EdgeInsets.all(Responsive.scale(context, 12, 16, 20)),
                     decoration: BoxDecoration(
                       color: context.appColors.surfaceVariant,
                       borderRadius: BorderRadius.circular(Responsive.borderRadius(context)),
                     ),
                     child: Text(
                       'Completa lecciones para desbloquear badges',
                       style: TextStyle(
                         fontSize: Responsive.scale(context, 14, 16, 18),
                         color: context.appColors.textSecondary,
                       ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: unlockedBadges.take(6).map((badge) {
                    return Container(
                      width: Responsive.scale(context, 50, 60, 70),
                      height: Responsive.scale(context, 50, 60, 70),
                      decoration: BoxDecoration(
                        color: Colors.amber[100],
                        borderRadius: BorderRadius.circular(Responsive.scale(context, 10, 12, 14)),
                        border: Border.all(
                          color: Colors.amber[400]!,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          badge.icon,
                          style: TextStyle(fontSize: Responsive.scale(context, 28, 32, 36)),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editNickname(UserProfile profile) async {
    final newNickname = await EditNicknameDialog.show(
      context,
      profile.nickname,
    );

    if (newNickname != null && newNickname != profile.nickname) {
      await _saveNickname(newNickname);
    }
  }

  Future<void> _editAvatar(UserProfile profile) async {
    final newAvatarId = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (context) => AvatarSelectionScreen(
          currentAvatarId: profile.avatarId,
        ),
      ),
    );

    if (newAvatarId != null && newAvatarId != profile.avatarId) {
      await _saveAvatar(newAvatarId);
    }
  }

  Future<void> _saveNickname(String nickname) async {
    setState(() {
      _isSaving = true;
      _saveMessage = 'Guardando...';
      _showSuccess = false;
    });

    try {
      await UserProfileService.updateNickname(nickname);
      setState(() {
        _isSaving = false;
        _saveMessage = 'Nickname guardado';
        _showSuccess = true;
      });

      // Recargar datos
      _loadData();

      // Ocultar mensaje después de 2 segundos
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _saveMessage = null;
            _showSuccess = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _isSaving = false;
        _saveMessage = 'Error al guardar';
        _showSuccess = false;
      });

      // Ocultar mensaje de error después de 3 segundos
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _saveMessage = null;
          });
        }
      });
    }
  }

  Future<void> _saveAvatar(int avatarId) async {
    setState(() {
      _isSaving = true;
      _saveMessage = 'Guardando...';
      _showSuccess = false;
    });

    try {
      await UserProfileService.updateAvatar(avatarId);
      setState(() {
        _isSaving = false;
        _saveMessage = 'Avatar guardado';
        _showSuccess = true;
      });

      // Recargar datos
      _loadData();

      // Ocultar mensaje después de 2 segundos
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _saveMessage = null;
            _showSuccess = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _isSaving = false;
        _saveMessage = 'Error al guardar';
        _showSuccess = false;
      });

      // Ocultar mensaje de error después de 3 segundos
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _saveMessage = null;
          });
        }
      });
    }
  }
}
