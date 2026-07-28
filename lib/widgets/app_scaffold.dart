import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../screens/lessons_screen.dart';
import '../screens/practice/practice_hub_screen.dart';
import '../screens/settings_screen.dart';
import '../theme/app_colors_extension.dart';
import '../theme/app_icons.dart';
import '../utils/responsive.dart';
import '../widgets/star_display.dart';
import 'app_nav_bar.dart';

class AppScaffold extends StatelessWidget {
  final int currentIndex;
  final Widget child;
  final Color? backgroundColor;

  const AppScaffold({
    super.key,
    required this.currentIndex,
    required this.child,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      drawer: context.isMobile ? _buildDrawer(context) : null,
      body: Column(
        children: [
          AppNavBar(
            currentIndex: currentIndex,
            onTabChanged: (index) {
              _navigateToTab(context, index);
            },
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final labels = ['Home', 'Lecciones', 'Práctica', 'Ajustes'];
    final selectedIcons = [AppIcons.home, AppIcons.book, AppIcons.game, AppIcons.settings];
    final unselectedIcons = [Icons.home_outlined, Icons.menu_book_outlined, Icons.sports_esports_outlined, Icons.settings_outlined];

    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: context.appColors.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'English Learning',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: StarDisplay(
                        iconSize: 16,
                        fontSize: 14,
                        textColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: Colors.white.withAlpha(30), height: 1),
              SizedBox(height: 8),
              ...List.generate(4, (index) {
                final isSelected = currentIndex == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        Future.delayed(const Duration(milliseconds: 250), () {
                          if (context.mounted) {
                            _navigateToTab(context, index);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white.withAlpha(40) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? selectedIcons[index] : unselectedIcons[index],
                              color: isSelected ? Colors.white : Colors.white.withAlpha(200),
                              size: 24,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              labels[index],
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white.withAlpha(200),
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToTab(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget targetScreen;
    switch (index) {
      case 0:
        targetScreen = const HomeScreen();
        break;
      case 1:
        targetScreen = const LessonsScreen();
        break;
      case 2:
        targetScreen = const PracticeHubScreen();
        break;
      case 3:
        targetScreen = const SettingsScreen();
        break;
      default:
        return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => targetScreen),
      (route) => false,
    );
  }
}
