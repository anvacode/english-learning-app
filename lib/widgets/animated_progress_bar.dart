import 'package:flutter/material.dart';

import '../theme/app_colors_extension.dart';
import '../utils/responsive.dart';

class AnimatedProgressBar extends StatelessWidget {
  final double progress;
  final Color color;
  final String? label;

  const AnimatedProgressBar({
    super.key,
    required this.progress,
    required this.color,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final height = Responsive.scale(context, 8.0, 10.0, 12.0);
    final borderRadius = BorderRadius.circular(height / 2);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.scale(context, 12, 16, 20),
        vertical: Responsive.scale(context, 8, 10, 12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: height,
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                color: context.appColors.surfaceVariant,
                boxShadow: [
                  BoxShadow(
                    color: context.appColors.shadow,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: borderRadius,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: progress.clamp(0.0, 1.0)),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return FractionallySizedBox(
                      widthFactor: value,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: borderRadius,
                          gradient: LinearGradient(
                            colors: [
                              color.withValues(alpha: 0.8),
                              color,
                              color.withValues(alpha: 0.9),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          if (label != null) ...[
            SizedBox(width: Responsive.scale(context, 10, 12, 16)),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.scale(context, 10, 12, 14),
                vertical: Responsive.scale(context, 4, 5, 6),
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.2)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Text(
                label!,
                style: TextStyle(
                  fontSize: Responsive.scale(context, 12, 13, 14),
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
