import 'package:flutter/material.dart';
import '../../theme/app_colors_extension.dart';
import 'diagnostic_test_screen.dart';

class DiagnosticIntroScreen extends StatefulWidget {
  const DiagnosticIntroScreen({super.key});

  @override
  State<DiagnosticIntroScreen> createState() => _DiagnosticIntroScreenState();
}

class _DiagnosticIntroScreenState extends State<DiagnosticIntroScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startTest() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const DiagnosticTestScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildIcon(),
                        const SizedBox(height: 32),
                        _buildTitle(),
                        const SizedBox(height: 16),
                        _buildDescription(),
                        const SizedBox(height: 40),
                        _buildInfoCards(),
                        const SizedBox(height: 48),
                        _buildStartButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        shape: BoxShape.circle,
         boxShadow: [
           BoxShadow(
             color: context.appColors.shadow,
             blurRadius: 30,
             offset: const Offset(0, 15),
           ),
         ],
      ),
      child: const Center(child: Text('📝', style: TextStyle(fontSize: 60))),
    );
  }

   Widget _buildTitle() {
     return Text(
       'Prueba de Nivel',
       style: TextStyle(
         fontSize: 32,
         fontWeight: FontWeight.bold,
         color: Colors.white,
         shadows: [
           Shadow(color: context.appColors.shadow, blurRadius: 10, offset: const Offset(0, 4)),
         ],
       ),
       textAlign: TextAlign.center,
     );
   }

  Widget _buildDescription() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: const Text(
        'Esta prueba nos ayudará a conocer tu nivel de inglés para recomendarte las lecciones más adecuadas.',
        style: TextStyle(fontSize: 18, color: Colors.white, height: 1.5),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildInfoCards() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildInfoItem(Icons.timer_outlined, '~3 min'),
        const SizedBox(width: 24),
        _buildInfoItem(Icons.quiz_outlined, '10 preguntas'),
        const SizedBox(width: 24),
        _buildInfoItem(Icons.bar_chart_outlined, '3 niveles'),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(30)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _startTest,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF667eea),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
           elevation: 8,
           shadowColor: context.appColors.shadow,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Comenzar prueba',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 12),
            Icon(Icons.arrow_forward_rounded, size: 24),
          ],
        ),
      ),
    );
  }
}
