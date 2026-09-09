import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../dialogs/auth_prompt_dialog.dart';
import '../logic/auth_provider.dart';
import '../services/auth_prompt_service.dart';
import '../services/diagnostic_service.dart';
import '../services/firestore_progress_service.dart';
import '../services/tutorial_service.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/connection_banner.dart';
import 'auth/register_screen.dart';
import 'diagnostic/diagnostic_intro_screen.dart';
import 'home/home_grid_view.dart';
import 'lessons_screen.dart';
import 'practice/practice_hub_screen.dart';
import 'settings_screen.dart';
import 'tutorial/interactive_tutorial.dart';

class HomeScreen extends StatefulWidget {
  final bool showTutorial;

  const HomeScreen({
    super.key,
    this.showTutorial = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final int _currentIndex = 0;
  bool _authPromptChecked = false;
  bool _diagnosticChecked = false;
  bool _isNavigating = false;
  bool _showInteractiveTutorial = false;

  final List<Widget> _screens = [
    const HomeGridView(),
    const LessonsScreen(showNavBar: false),
    const PracticeHubScreen(showNavBar: false),
    const SettingsScreen(showNavBar: false),
  ];

  @override
  void initState() {
    super.initState();
    _checkTutorialRequest();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FirestoreProgressService().registerSession();
      _checkAuthAndDiagnostic();
    });
  }

  Future<void> _checkTutorialRequest() async {
    final requested = await TutorialService.wasInteractiveTutorialRequested();
    if (requested && mounted) {
      await TutorialService.clearInteractiveTutorialRequest();
      setState(() {
        _showInteractiveTutorial = true;
      });
    }
  }

  Future<void> _checkAuthAndDiagnostic() async {
    if (_authPromptChecked && _diagnosticChecked) return;
    if (_isNavigating) return;

    final authProvider = context.read<AuthProvider>();

    if (!_authPromptChecked) {
      final shouldShow = await AuthPromptService.shouldShowAuthPrompt(
        isAuthenticated: authProvider.isAuthenticated,
        isGuest: authProvider.isGuest,
      );

      if (shouldShow && mounted && !_isNavigating) {
        final result = await AuthPromptDialog.show(context);
        
        if (!mounted) return;
        
        if (result == 'register') {
          _isNavigating = true;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const RegisterScreen()),
            (route) => false,
          );
          return;
        } else if (result == 'google') {
        }
      }
      _authPromptChecked = true;
    }

    if (!_diagnosticChecked && authProvider.isAuthenticated && !_isNavigating) {
      final diagnosticCompleted =
          await DiagnosticService.isDiagnosticCompleted();

      if (!diagnosticCompleted && mounted && !_isNavigating) {
        _isNavigating = true;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const DiagnosticIntroScreen(),
          ),
        );
      }
      _diagnosticChecked = true;
    } else {
      _diagnosticChecked = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget screen = AppScaffold(
      currentIndex: _currentIndex,
      child: Column(
        children: [
          const ConnectionBanner(),
          Expanded(child: _screens[_currentIndex]),
        ],
      ),
    );

    if ((widget.showTutorial || _showInteractiveTutorial) && _currentIndex == 0) {
      screen = InteractiveTutorial(
        child: screen,
        onComplete: () {
          setState(() {
            _showInteractiveTutorial = false;
          });
        },
      );
    }

    return screen;
  }
}
