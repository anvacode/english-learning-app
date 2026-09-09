import 'package:flutter/material.dart';

import '../../utils/responsive.dart';

class ProgressHeader extends StatefulWidget {
  final int completedLessons;
  final int totalLessons;
  final String? userLevel;
  final bool isVertical;
  final bool isHero;
  final bool isSidebar;

  const ProgressHeader({
    super.key,
    required this.completedLessons,
    required this.totalLessons,
    this.userLevel,
    this.isVertical = false,
    this.isHero = false,
    this.isSidebar = false,
  });

  @override
  State<ProgressHeader> createState() => _ProgressHeaderState();
}

class _ProgressHeaderState extends State<ProgressHeader>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    final progress = widget.totalLessons > 0
        ? widget.completedLessons / widget.totalLessons
        : 0.0;

    _progressAnimation = Tween<double>(begin: 0.0, end: progress).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeOutCubic,
      ),
    );

    _progressController.forward();
  }

  @override
  void didUpdateWidget(ProgressHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.completedLessons != widget.completedLessons ||
        oldWidget.totalLessons != widget.totalLessons) {
      final progress = widget.totalLessons > 0
          ? widget.completedLessons / widget.totalLessons
          : 0.0;

      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: progress,
      ).animate(
        CurvedAnimation(
          parent: _progressController,
          curve: Curves.easeOutCubic,
        ),
      );
      _progressController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.totalLessons > 0
        ? widget.completedLessons / widget.totalLessons
        : 0.0;
    final percentage = (progress * 100).round();

    if (widget.isSidebar) {
      return _buildSidebarLayout(context, percentage);
    }

    if (widget.isHero) {
      return _buildHeroLayout(context, percentage);
    }

    if (widget.isVertical) {
      return _buildVerticalLayout(context, percentage);
    }

    return Container(
      margin: EdgeInsets.all(Responsive.scale(context, 16, 20, 24)),
      padding: EdgeInsets.all(Responsive.scale(context, 18, 22, 26)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF667eea),
            Color(0xFF764ba2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(Responsive.scale(context, 20, 24, 28)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withAlpha(40),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: context.isMobile
          ? _buildMobileLayout(context, percentage)
          : _buildDesktopLayout(context, percentage),
    );
  }

  Widget _buildSidebarLayout(BuildContext context, int percentage) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.scale(context, 14, 16, 18),
        vertical: Responsive.scale(context, 20, 24, 28),
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF667eea),
            Color(0xFF764ba2),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(Responsive.scale(context, 18, 20, 22)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withAlpha(35),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: -3,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSidebarIcon(context),
          SizedBox(height: Responsive.scale(context, 10, 12, 14)),
          Text(
            '$percentage%',
            style: TextStyle(
              color: Colors.white,
              fontSize: Responsive.scale(context, 22, 26, 30),
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'completado',
            style: TextStyle(
              color: Colors.white.withAlpha(160),
              fontSize: Responsive.scale(context, 10, 11, 12),
            ),
          ),
          SizedBox(height: Responsive.scale(context, 10, 12, 14)),
          _buildSidebarProgressBar(context),
          SizedBox(height: Responsive.scale(context, 10, 12, 14)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.scale(context, 8, 10, 12),
              vertical: Responsive.scale(context, 4, 5, 6),
            ),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(Responsive.scale(context, 8, 10, 12)),
            ),
            child: Text(
              '${widget.completedLessons}/${widget.totalLessons}',
              style: TextStyle(
                color: Colors.white,
                fontSize: Responsive.scale(context, 12, 13, 14),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (widget.userLevel != null) ...[
            SizedBox(height: Responsive.scale(context, 10, 12, 14)),
            _buildSidebarLevelIndicator(context),
          ],
        ],
      ),
    );
  }

  Widget _buildSidebarIcon(BuildContext context) {
    final size = Responsive.scale(context, 36, 40, 44);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(color: Colors.white.withAlpha(45), width: 1.5),
      ),
      child: Center(
        child: Text(
          '📈',
          style: TextStyle(fontSize: size * 0.45),
        ),
      ),
    );
  }

  Widget _buildSidebarProgressBar(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: widget.totalLessons > 0 ? widget.completedLessons / widget.totalLessons : 0.0),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(
                    height: 6,
                    color: Colors.white.withAlpha(25),
                  ),
                  Container(
                    width: constraints.maxWidth * value,
                    height: 6,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white, Color(0xBBFFFFFF)],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSidebarLevelIndicator(BuildContext context) {
    String levelText;
    String levelEmoji;
    Color levelColor;

    switch (widget.userLevel) {
      case 'beginner':
        levelText = 'Principiante';
        levelEmoji = '🌱';
        levelColor = const Color(0xFF43e97b);
        break;
      case 'intermediate':
        levelText = 'Intermedio';
        levelEmoji = '🔥';
        levelColor = const Color(0xFFf5576c);
        break;
      case 'advanced':
        levelText = 'Avanzado';
        levelEmoji = '⭐';
        levelColor = const Color(0xFF764ba2);
        break;
      default:
        levelText = 'Sin nivel';
        levelEmoji = '📚';
        levelColor = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.scale(context, 8, 10, 12),
        vertical: Responsive.scale(context, 4, 5, 6),
      ),
      decoration: BoxDecoration(
        color: levelColor.withAlpha(35),
        borderRadius: BorderRadius.circular(Responsive.scale(context, 8, 10, 12)),
        border: Border.all(color: levelColor.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            levelEmoji,
            style: TextStyle(fontSize: Responsive.scale(context, 12, 14, 16)),
          ),
          const SizedBox(width: 4),
          Text(
            levelText,
            style: TextStyle(
              color: Colors.white,
              fontSize: Responsive.scale(context, 10, 11, 12),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalLayout(BuildContext context, int percentage) {
    return Container(
      padding: EdgeInsets.all(Responsive.scale(context, 16, 20, 24)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF667eea),
            Color(0xFF764ba2),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(Responsive.scale(context, 20, 24, 28)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withAlpha(40),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIconContainer(context),
          SizedBox(height: Responsive.scale(context, 12, 14, 16)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.scale(context, 12, 14, 16),
              vertical: Responsive.scale(context, 6, 8, 10),
            ),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(Responsive.scale(context, 12, 14, 16)),
              border: Border.all(color: Colors.white.withAlpha(50), width: 1.5),
            ),
            child: Column(
              children: [
                Text(
                  '$percentage%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: Responsive.scale(context, 24, 28, 32),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'completado',
                  style: TextStyle(
                    color: Colors.white.withAlpha(180),
                    fontSize: Responsive.scale(context, 10, 11, 12),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: Responsive.scale(context, 12, 14, 16)),
          _buildVerticalProgressBar(context),
          SizedBox(height: Responsive.scale(context, 10, 12, 14)),
          Text(
            '${widget.completedLessons}/${widget.totalLessons}',
            style: TextStyle(
              color: Colors.white,
              fontSize: Responsive.scale(context, 14, 16, 18),
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'lecciones',
            style: TextStyle(
              color: Colors.white.withAlpha(180),
              fontSize: Responsive.scale(context, 11, 12, 13),
            ),
          ),
          if (widget.userLevel != null) ...[
            SizedBox(height: Responsive.scale(context, 12, 14, 16)),
            _buildVerticalLevelIndicator(context),
          ],
        ],
      ),
    );
  }

  Widget _buildHeroLayout(BuildContext context, int percentage) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.scale(context, 24, 32, 40),
        vertical: Responsive.scale(context, 20, 24, 28),
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF667eea),
            Color(0xFF764ba2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(Responsive.scale(context, 24, 28, 32)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withAlpha(50),
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Row(
        children: [
          _buildHeroIcon(context),
          SizedBox(width: Responsive.scale(context, 20, 24, 28)),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu progreso',
                  style: TextStyle(
                    color: Colors.white.withAlpha(180),
                    fontSize: Responsive.scale(context, 12, 14, 16),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: Responsive.scale(context, 4, 6, 8)),
                Text(
                  '${widget.completedLessons} de ${widget.totalLessons} lecciones',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: Responsive.scale(context, 20, 24, 28),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: Responsive.scale(context, 14, 16, 18)),
                _buildHeroProgressBar(context),
              ],
            ),
          ),
          SizedBox(width: Responsive.scale(context, 24, 32, 40)),
          _buildHeroPercentage(context, percentage),
          if (widget.userLevel != null) ...[
            SizedBox(width: Responsive.scale(context, 20, 24, 28)),
            _buildHeroLevelIndicator(context),
          ],
        ],
      ),
    );
  }

  Widget _buildHeroIcon(BuildContext context) {
    final size = Responsive.scale(context, 56, 64, 72);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(color: Colors.white.withAlpha(50), width: 2),
      ),
      child: Center(
        child: Text(
          '📈',
          style: TextStyle(fontSize: size * 0.5),
        ),
      ),
    );
  }

  Widget _buildHeroProgressBar(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: widget.totalLessons > 0 ? widget.completedLessons / widget.totalLessons : 0.0),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(Responsive.scale(context, 6, 8, 10)),
              child: Stack(
                children: [
                  Container(
                    height: Responsive.scale(context, 10, 12, 14),
                    color: Colors.white.withAlpha(30),
                  ),
                  Container(
                    width: constraints.maxWidth * value,
                    height: Responsive.scale(context, 10, 12, 14),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xCCFFFFFF),
                          Colors.white,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeroPercentage(BuildContext context, int percentage) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.scale(context, 16, 20, 24),
        vertical: Responsive.scale(context, 12, 14, 16),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(Responsive.scale(context, 16, 18, 20)),
        border: Border.all(color: Colors.white.withAlpha(40), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            '$percentage%',
            style: TextStyle(
              color: Colors.white,
              fontSize: Responsive.scale(context, 28, 32, 36),
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'completado',
            style: TextStyle(
              color: Colors.white.withAlpha(160),
              fontSize: Responsive.scale(context, 10, 11, 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroLevelIndicator(BuildContext context) {
    String levelText;
    String levelEmoji;
    Color levelColor;

    switch (widget.userLevel) {
      case 'beginner':
        levelText = 'Principiante';
        levelEmoji = '🌱';
        levelColor = const Color(0xFF43e97b);
        break;
      case 'intermediate':
        levelText = 'Intermedio';
        levelEmoji = '🔥';
        levelColor = const Color(0xFFf5576c);
        break;
      case 'advanced':
        levelText = 'Avanzado';
        levelEmoji = '⭐';
        levelColor = const Color(0xFF764ba2);
        break;
      default:
        levelText = 'Sin nivel';
        levelEmoji = '📚';
        levelColor = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.scale(context, 14, 16, 18),
        vertical: Responsive.scale(context, 10, 12, 14),
      ),
      decoration: BoxDecoration(
        color: levelColor.withAlpha(40),
        borderRadius: BorderRadius.circular(Responsive.scale(context, 14, 16, 18)),
        border: Border.all(color: levelColor.withAlpha(60), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            levelEmoji,
            style: TextStyle(fontSize: Responsive.scale(context, 22, 26, 30)),
          ),
          SizedBox(height: Responsive.scale(context, 4, 6, 8)),
          Text(
            levelText,
            style: TextStyle(
              color: Colors.white,
              fontSize: Responsive.scale(context, 11, 12, 13),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalProgressBar(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: widget.totalLessons > 0 ? widget.completedLessons / widget.totalLessons : 0.0),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(Responsive.scale(context, 6, 8, 8)),
              child: Stack(
                children: [
                  Container(
                    height: Responsive.scale(context, 10, 12, 14),
                    color: Colors.white.withAlpha(30),
                  ),
                  Container(
                    width: constraints.maxWidth * value,
                    height: Responsive.scale(context, 10, 12, 14),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xCCFFFFFF),
                          Colors.white,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVerticalLevelIndicator(BuildContext context) {
    String levelText;
    String levelEmoji;
    Color levelColor;

    switch (widget.userLevel) {
      case 'beginner':
        levelText = 'Principiante';
        levelEmoji = '🌱';
        levelColor = const Color(0xFF43e97b);
        break;
      case 'intermediate':
        levelText = 'Intermedio';
        levelEmoji = '🔥';
        levelColor = const Color(0xFFf5576c);
        break;
      case 'advanced':
        levelText = 'Avanzado';
        levelEmoji = '⭐';
        levelColor = const Color(0xFF764ba2);
        break;
      default:
        levelText = 'Sin nivel';
        levelEmoji = '📚';
        levelColor = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.scale(context, 10, 12, 14),
        vertical: Responsive.scale(context, 6, 8, 10),
      ),
      decoration: BoxDecoration(
        color: levelColor.withAlpha(40),
        borderRadius: BorderRadius.circular(Responsive.scale(context, 10, 12, 14)),
        border: Border.all(color: levelColor.withAlpha(60), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            levelEmoji,
            style: TextStyle(fontSize: Responsive.scale(context, 18, 20, 22)),
          ),
          SizedBox(height: Responsive.scale(context, 2, 3, 4)),
          Text(
            levelText,
            style: TextStyle(
              color: Colors.white,
              fontSize: Responsive.scale(context, 11, 12, 13),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, int percentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildIconContainer(context),
            SizedBox(width: Responsive.scale(context, 10, 12, 14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tu progreso',
                    style: TextStyle(
                      color: Colors.white.withAlpha(200),
                      fontSize: Responsive.scale(context, 11, 12, 13),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.completedLessons} de ${widget.totalLessons} lecciones',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: Responsive.scale(context, 15, 16, 17),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: Responsive.scale(context, 8, 10, 12)),
            _buildPercentageBadge(context, percentage),
          ],
        ),
        SizedBox(height: Responsive.scale(context, 12, 14, 16)),
        _buildProgressBar(context),
        if (widget.userLevel != null) ...[
          SizedBox(height: Responsive.scale(context, 8, 10, 12)),
          _buildLevelIndicator(context),
        ],
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, int percentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildIconContainer(context),
            SizedBox(width: Responsive.scale(context, 14, 16, 18)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tu progreso',
                    style: TextStyle(
                      color: Colors.white.withAlpha(200),
                      fontSize: Responsive.scale(context, 12, 13, 14),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: Responsive.scale(context, 2, 3, 4)),
                  Text(
                    '${widget.completedLessons} de ${widget.totalLessons} lecciones',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: Responsive.scale(context, 18, 20, 22),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            _buildPercentageBadge(context, percentage),
          ],
        ),
        SizedBox(height: Responsive.scale(context, 16, 18, 20)),
        _buildProgressBar(context),
        if (widget.userLevel != null) ...[
          SizedBox(height: Responsive.scale(context, 12, 14, 16)),
          _buildLevelIndicator(context),
        ],
      ],
    );
  }

  Widget _buildIconContainer(BuildContext context) {
    final size = Responsive.scale(context, 40, 48, 54);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(color: Colors.white.withAlpha(50), width: 2),
      ),
      child: Center(
        child: Text(
          '📈',
          style: TextStyle(fontSize: size * 0.45),
        ),
      ),
    );
  }

  Widget _buildPercentageBadge(BuildContext context, int percentage) {
    if (context.isMobile) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.scale(context, 6, 8, 10),
          vertical: Responsive.scale(context, 4, 5, 6),
        ),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(30),
          borderRadius: BorderRadius.circular(Responsive.scale(context, 8, 10, 12)),
          border: Border.all(color: Colors.white.withAlpha(50)),
        ),
        child: Text(
          '$percentage%',
          style: TextStyle(
            color: Colors.white,
            fontSize: Responsive.scale(context, 13, 14, 15),
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.scale(context, 12, 14, 16),
        vertical: Responsive.scale(context, 8, 10, 12),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(Responsive.scale(context, 12, 14, 16)),
        border: Border.all(color: Colors.white.withAlpha(50), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            '$percentage%',
            style: TextStyle(
              color: Colors.white,
              fontSize: Responsive.scale(context, 18, 20, 22),
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'completado',
            style: TextStyle(
              color: Colors.white.withAlpha(180),
              fontSize: Responsive.scale(context, 9, 10, 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: widget.totalLessons > 0 ? widget.completedLessons / widget.totalLessons : 0.0),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(Responsive.scale(context, 8, 10, 12)),
              child: Stack(
                children: [
                  Container(
                    height: Responsive.scale(context, 12, 14, 16),
                    color: Colors.white.withAlpha(30),
                  ),
                  Container(
                    width: constraints.maxWidth * value,
                    height: Responsive.scale(context, 12, 14, 16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xCCFFFFFF),
                          Colors.white,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLevelIndicator(BuildContext context) {
    String levelText;
    String levelEmoji;
    Color levelColor;

    switch (widget.userLevel) {
      case 'beginner':
        levelText = 'Principiante';
        levelEmoji = '🌱';
        levelColor = const Color(0xFF43e97b);
        break;
      case 'intermediate':
        levelText = 'Intermedio';
        levelEmoji = '🔥';
        levelColor = const Color(0xFFf5576c);
        break;
      case 'advanced':
        levelText = 'Avanzado';
        levelEmoji = '⭐';
        levelColor = const Color(0xFF764ba2);
        break;
      default:
        levelText = 'Sin nivel';
        levelEmoji = '📚';
        levelColor = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.scale(context, 12, 14, 16),
        vertical: Responsive.scale(context, 8, 10, 12),
      ),
      decoration: BoxDecoration(
        color: levelColor.withAlpha(40),
        borderRadius: BorderRadius.circular(Responsive.scale(context, 10, 12, 14)),
        border: Border.all(color: levelColor.withAlpha(60), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            levelEmoji,
            style: TextStyle(fontSize: Responsive.scale(context, 14, 16, 18)),
          ),
          SizedBox(width: Responsive.scale(context, 6, 8, 10)),
          Text(
            'Nivel: $levelText',
            style: TextStyle(
              color: Colors.white,
              fontSize: Responsive.scale(context, 12, 13, 14),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
