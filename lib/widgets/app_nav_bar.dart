import 'package:flutter/material.dart';

import '../theme/app_colors_extension.dart';
import '../theme/app_icons.dart';
import '../utils/responsive.dart';
import '../widgets/star_display.dart';

class AppNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTabChanged;

  const AppNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
  });

  @override
  State<AppNavBar> createState() => _AppNavBarState();
}

class _AppNavBarState extends State<AppNavBar> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final iconSize = Responsive.scale(context, 22.0, 24.0, 26.0);

    return Container(
      decoration: BoxDecoration(
        gradient: context.appColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: context.appColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.scale(context, 12.0, 16.0, 20.0),
            vertical: Responsive.scale(context, 10.0, 12.0, 14.0),
          ),
          child: Row(
            children: [
              if (context.isMobile)
                _buildMobileMenuButton(context)
              else
                const SizedBox.shrink(),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'English Learning',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.scale(context, 18.0, 20.0, 22.0),
                    ),
                  ),
                ),
              ),
              if (!context.isMobile)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildNavItem(context, 0, iconSize),
                    SizedBox(width: context.isMobile ? 16 : 32),
                    _buildNavItem(context, 1, iconSize),
                    SizedBox(width: context.isMobile ? 16 : 32),
                    _buildNavItem(context, 2, iconSize),
                    SizedBox(width: context.isMobile ? 16 : 32),
                    _buildNavItem(context, 3, iconSize),
                  ],
                ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.scale(context, 8.0, 10.0, 12.0),
                      vertical: Responsive.scale(context, 4.0, 5.0, 6.0),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(
                        Responsive.scale(context, 16.0, 18.0, 20.0),
                      ),
                    ),
                    child: StarDisplay(
                      iconSize: Responsive.scale(context, 16.0, 18.0, 20.0),
                      fontSize: Responsive.scale(context, 12.0, 14.0, 16.0),
                      textColor: Colors.white,
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

  Widget _buildNavItem(BuildContext context, int index, double iconSize) {
    final isSelected = widget.currentIndex == index;
    final isHovered = _hoveredIndex == index;
    final selectedIcons = [
      AppIcons.home,
      AppIcons.book,
      AppIcons.game,
      AppIcons.settings,
    ];
    final unselectedIcons = [
      Icons.home_outlined,
      Icons.menu_book_outlined,
      Icons.sports_esports_outlined,
      Icons.settings_outlined,
    ];

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _hoveredIndex = index;
        });
      },
      onExit: (_) {
        setState(() {
          _hoveredIndex = null;
        });
      },
      child: GestureDetector(
        onTap: () {
          widget.onTabChanged(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(context.isMobile ? 8 : 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withAlpha(40)
                : isHovered
                    ? Colors.white.withAlpha(20)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 200),
            scale: isHovered ? 1.1 : 1.0,
            child: Icon(
              isSelected ? selectedIcons[index] : unselectedIcons[index],
              color: isSelected
                  ? Colors.white
                  : isHovered
                      ? Colors.white.withAlpha(220)
                      : Colors.white.withAlpha(150),
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileMenuButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Scaffold.of(context).openDrawer();
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.menu,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
