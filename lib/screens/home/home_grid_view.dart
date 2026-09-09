import 'package:flutter/material.dart';

import '../../utils/responsive.dart';
import '../../widgets/animated_menu_card.dart';
import '../../widgets/floating_particles_background.dart';
import '../../widgets/responsive_container.dart';
import '../achievements_screen.dart';
import '../lessons_screen.dart';
import '../profile/profile_screen.dart';
import '../shop_screen.dart';
import '../tutorial/tutorial_keys.dart';

class HomeGridView extends StatelessWidget {
  const HomeGridView({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingParticlesBackground(
      particleCount: 15,
      child: ResponsiveContainer(
        addHorizontalPadding: false,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(context.horizontalPadding),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: Responsive.gridColumns(context, mobile: 2, tablet: 3, desktop: 4, wide: 5),
              childAspectRatio: Responsive.cardAspectRatio(context),
              crossAxisSpacing: Responsive.gridSpacing(context),
              mainAxisSpacing: Responsive.gridSpacing(context),
              children: [
                AnimatedMenuCard(
                  index: 0,
                  cardKey: TutorialKeys.lessonsCard,
                  emoji: '📚',
                  title: 'Lecciones',
                  subtitle: 'Aprende inglés',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LessonsScreen()),
                    (route) => false,
                  ),
                ),
                AnimatedMenuCard(
                  index: 1,
                  cardKey: TutorialKeys.profileCard,
                  emoji: '👤',
                  title: 'Perfil',
                  subtitle: 'Tu progreso',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    (route) => false,
                  ),
                ),
                AnimatedMenuCard(
                  index: 2,
                  cardKey: TutorialKeys.achievementsCard,
                  emoji: '🏆',
                  title: 'Logros',
                  subtitle: 'Tus medallas',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFfa709a), Color(0xFFfee140)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AchievementsScreen(),
                    ),
                    (route) => false,
                  ),
                ),
                AnimatedMenuCard(
                  index: 3,
                  cardKey: TutorialKeys.shopCard,
                  emoji: '🏪',
                  title: 'Tienda',
                  subtitle: 'Compra items',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFa8edea), Color(0xFFfed6e3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const ShopScreen()),
                    (route) => false,
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
