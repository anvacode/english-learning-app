import 'package:flutter/material.dart';
import '../../models/diagnostic_result.dart';
import '../../theme/app_colors_extension.dart';
import '../../widgets/app_scaffold.dart';
import '../home_screen.dart';

class DiagnosticResultScreen extends StatefulWidget {
  final DiagnosticResult result;

  const DiagnosticResultScreen({super.key, required this.result});

  @override
  State<DiagnosticResultScreen> createState() => _DiagnosticResultScreenState();
}

class _DiagnosticResultScreenState extends State<DiagnosticResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isIntermediate => widget.result.level == 'intermediate';

  Color get _levelColor => _isIntermediate ? Colors.orange : Colors.green;

  String get _levelEmoji => _isIntermediate ? '📚' : '🌱';

  String get _levelName => _isIntermediate ? 'Intermediate' : 'Beginner';

  String get _levelDescription => _isIntermediate
      ? '¡Muy bien! Puedes continuar con lecciones más avanzadas.'
      : '¡Perfecto para empezar! Aprenderás los fundamentos.';

  List<String> get _recommendedLessons => _isIntermediate
      ? ['Daily Routines', 'Weather', 'Food', 'Family']
      : ['Colors', 'Animals', 'Numbers', 'Fruits'];

  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentIndex: -1,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
             colors: [_levelColor.withAlpha(40), context.appColors.background],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildResultCard(),
                  const SizedBox(height: 24),
                  _buildScoreCard(),
                  const SizedBox(height: 24),
                  _buildRecommendations(),
                  const SizedBox(height: 32),
                  _buildContinueButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
       decoration: BoxDecoration(
         color: context.appColors.cardBackground,
         borderRadius: BorderRadius.circular(28),
         boxShadow: [
           BoxShadow(
             color: _levelColor.withAlpha(40),
             blurRadius: 30,
             offset: const Offset(0, 15),
           ),
         ],
       ),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: _levelColor.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(_levelEmoji, style: const TextStyle(fontSize: 60)),
            ),
          ),
          const SizedBox(height: 24),
           Text(
             '🎉 Great Job!',
             style: TextStyle(
               fontSize: 32,
               fontWeight: FontWeight.bold,
               color: context.appColors.textPrimary,
             ),
           ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: _levelColor.withAlpha(25),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Text(
              _levelName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _levelColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
           Text(
             _levelDescription,
             style: TextStyle(fontSize: 16, color: context.appColors.textSecondary),
             textAlign: TextAlign.center,
           ),
        ],
      ),
    );
  }

  Widget _buildScoreCard() {
    return Container(
      width: double.infinity,
       padding: const EdgeInsets.all(24),
       decoration: BoxDecoration(
         color: context.appColors.cardBackground,
         borderRadius: BorderRadius.circular(20),
         boxShadow: [
           BoxShadow(
             color: context.appColors.shadow,
             blurRadius: 15,
             offset: const Offset(0, 8),
           ),
         ],
       ),
       child: Row(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           const Icon(Icons.star, color: Colors.amber, size: 32),
           const SizedBox(width: 12),
           Text(
             '${widget.result.score} / ${widget.result.totalQuestions}',
             style: TextStyle(
               fontSize: 36,
               fontWeight: FontWeight.bold,
               color: _levelColor,
             ),
           ),
           const SizedBox(width: 12),
           Text(
             'correct',
             style: TextStyle(fontSize: 18, color: context.appColors.textSecondary),
           ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    return Container(
      width: double.infinity,
       padding: const EdgeInsets.all(24),
       decoration: BoxDecoration(
         color: context.appColors.cardBackground,
         borderRadius: BorderRadius.circular(20),
         boxShadow: [
           BoxShadow(
             color: context.appColors.shadow,
             blurRadius: 15,
             offset: const Offset(0, 8),
           ),
         ],
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Row(
             children: [
               Icon(Icons.playlist_play, color: _levelColor, size: 24),
               const SizedBox(width: 10),
               Text(
                 'Recommended Lessons',
                 style: TextStyle(
                   fontSize: 18,
                   fontWeight: FontWeight.bold,
                   color: context.appColors.textPrimary,
                 ),
               ),
             ],
           ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _recommendedLessons.map((lesson) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _levelColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  lesson,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _levelColor,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _navigateToHome,
        style: ElevatedButton.styleFrom(
          backgroundColor: _levelColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 6,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Let's Go!",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 12),
            Icon(Icons.arrow_forward, size: 28),
          ],
        ),
      ),
    );
  }
}
