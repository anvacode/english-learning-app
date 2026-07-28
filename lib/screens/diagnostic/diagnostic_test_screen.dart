import 'package:flutter/material.dart';

import '../../data/diagnostic_questions_data.dart';
import '../../models/diagnostic_question.dart';
import '../../services/diagnostic_service.dart';
import '../../theme/app_colors_extension.dart';
import '../../utils/responsive.dart';
import 'diagnostic_result_screen.dart';

class DiagnosticTestScreen extends StatefulWidget {
  const DiagnosticTestScreen({super.key});

  @override
  State<DiagnosticTestScreen> createState() => _DiagnosticTestScreenState();
}

class _DiagnosticTestScreenState extends State<DiagnosticTestScreen>
    with TickerProviderStateMixin {
  final List<DiagnosticQuestion> _questions = DiagnosticQuestionsData.questions;
  final List<int?> _answers = List.filled(
    DiagnosticQuestionsData.questions.length,
    null,
  );

  int _currentQuestionIndex = 0;
  bool _isSubmitting = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  DiagnosticQuestion get _currentQuestion => _questions[_currentQuestionIndex];

  double get _progress => (_currentQuestionIndex + 1) / _questions.length;

  void _selectAnswer(int index) {
    setState(() {
      _answers[_currentQuestionIndex] = index;
    });
  }

  void _nextQuestion() {
    if (_answers[_currentQuestionIndex] == null) return;

    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
      _animationController.reset();
      _animationController.forward();
    } else {
      _submitTest();
    }
  }

  Future<void> _submitTest() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    final result = DiagnosticService.calculateResult(_answers);
    await DiagnosticService.saveDiagnosticResult(result);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => DiagnosticResultScreen(result: result),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = Responsive.screenHeight(context);
    final emojiSize = Responsive.scale(context, 50.0, 60.0, 70.0);
    final optionSize = Responsive.scale(context, 45.0, 50.0, 60.0);
    final fontSize = Responsive.scale(context, 18.0, 22.0, 26.0);
    final largeFontSize = Responsive.scale(context, 16.0, 18.0, 20.0);
    final spacing = Responsive.scale(context, 12.0, 16.0, 20.0);
    final gridColumns = Responsive.gridColumns(context, mobile: 2, tablet: 2, desktop: 4, wide: 4);
    final isCompact = context.isMobile;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4FC3F7), Color(0xFF2196F3)],
            ),
          ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(isCompact, fontSize, spacing),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: Responsive.maxContainerWidth(context)),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: _buildQuestionCard(
                          emojiSize,
                          optionSize,
                          fontSize,
                          largeFontSize,
                          spacing,
                          gridColumns,
                          isCompact,
                          height,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _buildBottomNavigation(isCompact, fontSize, spacing),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isCompact, double fontSize, double spacing) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing, vertical: Responsive.scale(context, 10, 12, 14)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 12 : 16,
                  vertical: Responsive.scale(context, 6, 8, 10),
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(50),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: Responsive.scale(context, 18, 20, 22)),
                    SizedBox(width: Responsive.scale(context, 6, 8, 10)),
                    Text(
                      '${_currentQuestionIndex + 1} / ${_questions.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: spacing),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.white.withAlpha(50),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              minHeight: Responsive.scale(context, 6, 8, 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(
    double emojiSize,
    double optionSize,
    double fontSize,
    double largeFontSize,
    double spacing,
    int gridColumns,
    bool isCompact,
    double height,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: height * 0.7),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: spacing),
              Text(
                _currentQuestion.mainEmoji,
                style: TextStyle(fontSize: emojiSize),
              ),
              SizedBox(height: spacing * 1.5),
              Container(
                width: double.infinity,
                constraints: BoxConstraints(maxWidth: Responsive.scale(context, 400, 500, 600)),
                padding: EdgeInsets.symmetric(
                  horizontal: spacing * 1.5,
                  vertical: spacing,
                ),
                 decoration: BoxDecoration(
                   color: context.appColors.cardBackground,
                   borderRadius: BorderRadius.circular(Responsive.scale(context, 20, 24, 28)),
                   boxShadow: [
                     BoxShadow(
                       color: context.appColors.shadow,
                       blurRadius: 20,
                       offset: const Offset(0, 10),
                     ),
                   ],
                 ),
                 child: Text(
                   _currentQuestion.question,
                   style: TextStyle(
                     fontSize: largeFontSize,
                     fontWeight: FontWeight.bold,
                     color: context.appColors.textPrimary,
                   ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: spacing * 2),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: gridColumns,
                mainAxisSpacing: spacing,
                crossAxisSpacing: spacing,
                childAspectRatio: 1.8,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(_currentQuestion.options.length, (
                  index,
                ) {
                  return _buildOptionButton(index, optionSize, fontSize);
                }),
              ),
              SizedBox(height: spacing),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton(int index, double size, double fontSize) {
    final isSelected = _answers[_currentQuestionIndex] == index;
    final option = _currentQuestion.options[index];

    return GestureDetector(
      onTap: () => _selectAnswer(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
         decoration: BoxDecoration(
           color: isSelected ? const Color(0xFF4CAF50) : context.appColors.cardBackground,
           borderRadius: BorderRadius.circular(16),
           border: Border.all(
             color: isSelected ? const Color(0xFF4CAF50) : context.appColors.border,
             width: 2,
           ),
           boxShadow: [
             BoxShadow(
               color: isSelected
                   ? const Color(0xFF4CAF50).withAlpha(100)
                   : context.appColors.shadow,
               blurRadius: isSelected ? 12 : 6,
               offset: const Offset(0, 3),
             ),
           ],
         ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              option,
              style: TextStyle(
                fontSize: size * 0.55,
                fontWeight: FontWeight.bold,
                 color: isSelected ? Colors.white : context.appColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(
    bool isCompact,
    double fontSize,
    double spacing,
  ) {
    final hasAnswer = _answers[_currentQuestionIndex] != null;
    final isLastQuestion = _currentQuestionIndex == _questions.length - 1;

    return Padding(
      padding: EdgeInsets.all(spacing),
      child: SizedBox(
        width: double.infinity,
        height: Responsive.buttonHeight(context),
        child: ElevatedButton.icon(
          onPressed: hasAnswer && !_isSubmitting ? _nextQuestion : null,
          icon: _isSubmitting
              ? SizedBox(
                  width: Responsive.scale(context, 18, 20, 22),
                  height: Responsive.scale(context, 18, 20, 22),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  isLastQuestion ? Icons.check : Icons.arrow_forward,
                  size: Responsive.scale(context, 22, 24, 28),
                ),
          label: Text(
            isLastQuestion ? 'Finish!' : 'Next',
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.white,
             disabledBackgroundColor: context.appColors.surfaceVariant,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Responsive.borderRadius(context)),
            ),
            elevation: 6,
          ),
        ),
      ),
    );
  }
}
