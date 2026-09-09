import 'package:flutter/material.dart';
import '../data/lessons_data.dart';
import '../logic/badge_service.dart';
import '../models/badge.dart' as achievement;
import '../theme/app_colors_extension.dart';
import '../theme/text_styles.dart';
import '../utils/responsive.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/responsive_container.dart';

/// Pantalla que muestra todos los badges/insignias del usuario.
///
/// Muestra badges desbloqueados y bloqueados con información
/// sobre cómo desbloquearlos.
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  String _getLessonName(String lessonId) {
    final lesson = lessonsList.firstWhere(
      (l) => l.id == lessonId,
      orElse: () => lessonsList.first,
    );
    return lesson.title;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentIndex: -1,
      child: ResponsiveContainer(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(context.horizontalPadding),
          child: FutureBuilder<List<achievement.Badge>>(
            future: BadgeService.getBadges(lessonsList),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final badges = snapshot.data ?? [];
              final unlockedBadges = badges.where((b) => b.unlocked).toList();
              final lockedBadges = badges.where((b) => !b.unlocked).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Logros',
                    style: context.headline2,
                  ),
                  const SizedBox(height: 24),
                  
                  // Sección de badges desbloqueados
                  Text(
                    '🏆 Badges Obtenidos',
                    style: context.headline3.copyWith(color: Colors.deepPurple),
                  ),
                  SizedBox(height: Responsive.scale(context, 16, 20, 24)),
                  if (unlockedBadges.isEmpty)
                    _buildEmptyState(
                      context,
                      emoji: '🎯',
                      message: 'Domina lecciones para desbloquear badges',
                      color: context.appColors.surfaceVariant,
                    )
                  else
                    _buildBadgeGrid(context, unlockedBadges, true),
                  
                  SizedBox(height: Responsive.scale(context, 32, 40, 48)),
                  
                  // Sección de badges pendientes
                  Text(
                    '🔒 Por Obtener',
                    style: context.headline3.copyWith(color: Colors.deepPurple),
                  ),
                  SizedBox(height: Responsive.scale(context, 16, 20, 24)),
                  if (lockedBadges.isEmpty)
                    _buildEmptyState(
                      context,
                      emoji: '🎉',
                      message: '¡Felicidades! Desbloqueaste todos los badges',
                      color: Colors.green[50]!,
                      textColor: Colors.green,
                    )
                  else
                    _buildBadgeGrid(context, lockedBadges, false),
                  
                  const SizedBox(height: 32),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required String emoji,
    required String message,
    required Color color,
    Color? textColor,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.scale(context, 24, 32, 40)),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(Responsive.borderRadius(context) + 4),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: TextStyle(fontSize: Responsive.scale(context, 56, 64, 72)),
          ),
          SizedBox(height: Responsive.scale(context, 16, 20, 24)),
          Text(
            message,
            style: TextStyle(
              fontSize: Responsive.scale(context, 14, 16, 18),
              fontWeight: FontWeight.w600,
              color: textColor ?? context.appColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeGrid(
    BuildContext context,
    List<achievement.Badge> badges,
    bool isUnlocked,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = Responsive.gridColumns(
          context,
          mobile: 2,
          tablet: 3,
          desktop: 4,
          wide: 5,
        );
        final spacing = Responsive.gridSpacing(context);
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: badges
              .map(
                (badge) => SizedBox(
                  width: itemWidth,
                  child: _BadgeCard(
                    badge: badge,
                    isUnlocked: isUnlocked,
                    lessonName: _getLessonName(badge.lessonId),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

/// Widget que representa una tarjeta de badge.
class _BadgeCard extends StatelessWidget {
  final achievement.Badge badge;
  final bool isUnlocked;
  final String lessonName;

  const _BadgeCard({
    required this.badge,
    required this.isUnlocked,
    required this.lessonName,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = Responsive.scale(context, 48.0, 64.0, 72.0);
    final borderRadius = Responsive.borderRadius(context) + 8;

    return Container(
      padding: EdgeInsets.all(Responsive.scale(context, 12, 16, 24)),
      decoration: BoxDecoration(
        gradient: isUnlocked
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.amber.shade200,
                  Colors.amber.shade400,
                ],
              )
            : null,
        color: isUnlocked ? null : context.appColors.surfaceVariant,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isUnlocked ? Colors.amber.shade600 : context.appColors.border,
          width: isUnlocked ? 4 : 2,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: context.appColors.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: iconSize),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                badge.icon,
                style: TextStyle(fontSize: iconSize),
              ),
            ),
          ),
          SizedBox(height: Responsive.scale(context, 8, 12, 20)),
          
          // Título del badge
          Text(
            badge.title,
            style: TextStyle(
              fontSize: Responsive.scale(context, 12, 16, 18),
              fontWeight: FontWeight.bold,
              color: isUnlocked ? Colors.amber[900] : context.appColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: Responsive.scale(context, 4, 10, 12)),
          
          // Estado o instrucción
          if (isUnlocked)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.scale(context, 12, 14, 16),
                vertical: Responsive.scale(context, 4, 6, 8),
              ),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '✓ Obtenido',
                style: TextStyle(
                  fontSize: Responsive.scale(context, 11, 12, 13),
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            )
          else
            Container(
              padding: EdgeInsets.all(Responsive.scale(context, 8, 10, 12)),
              decoration: BoxDecoration(
                color: context.appColors.cardBackground.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Completa:\n$lessonName',
                style: TextStyle(
                  fontSize: Responsive.scale(context, 10, 11, 12),
                  color: context.appColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}
