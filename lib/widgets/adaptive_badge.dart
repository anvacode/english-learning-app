import 'package:flutter/material.dart';
import '../theme/color_palette.dart';
import '../utils/responsive.dart';

class ResponsiveBadgeGrid extends StatelessWidget {
  final List<Widget> badges;

  const ResponsiveBadgeGrid({required this.badges, super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = Responsive.gridColumns(
          context,
          mobile: 2,
          tablet: 3,
          desktop: 4,
          wide: 5,
        );
        const mainAxisSpacing = 8.0;
        const crossAxisSpacing = 8.0;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: badges,
        );
      },
    );
  }
}

class PracticeCardBadge extends StatelessWidget {
  final bool isUnlocked;
  final IconData iconData;

  const PracticeCardBadge({
    required this.isUnlocked,
    required this.iconData,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final badgeSize = Responsive.scale(context, 48.0, 40.0, 40.0);
    final iconSize = Responsive.scale(context, 24.0, 20.0, 20.0);
    final padding = Responsive.scale(context, 8.0, 6.0, 6.0);

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: badgeSize,
        minHeight: badgeSize,
      ),
      child: Container(
        width: badgeSize,
        height: badgeSize,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: isUnlocked ? BadgeColors.unlockedLight : BadgeColors.lockedDefault,
          shape: BoxShape.circle,
          border: Border.all(
            color: isUnlocked ? BadgeColors.unlockedBorder : BadgeColors.lockedBorder,
            width: 1.5,
          ),
        ),
        child: Icon(
          iconData,
          size: iconSize,
          color: isUnlocked ? BadgeColors.unlockedText : BadgeColors.lockedText,
        ),
      ),
    );
  }
}
