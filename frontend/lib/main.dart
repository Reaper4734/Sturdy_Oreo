import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/presentation/auth_screen.dart';
import 'features/onboarding/presentation/micro_interview_screen.dart';
import 'features/onboarding/presentation/persona_reveal_screen.dart';
import 'features/dashboard/presentation/command_center_screen.dart';
import 'features/survey/presentation/mastery_survey_screen.dart';
import 'features/knowledge_hub/presentation/knowledge_hub_screen.dart';
import 'features/settings/presentation/profile_settings_screen.dart';
import 'features/exam/presentation/proctored_exam_screen.dart';
import 'features/exam/models/proctored_exam_model.dart';
import 'features/exam/presentation/widgets/exam_configuration_dialog.dart';
// Removed LearningLabScreen
import 'shared/providers/workspace_providers.dart';
import 'shared/providers/theme_provider.dart';
import 'shared/widgets/responsive_scaffold.dart';

void main() {
  runApp(
    const ProviderScope(
      child: OreoApp(),
    ),
  );
}

class OreoApp extends ConsumerStatefulWidget {
  const OreoApp({super.key});

  @override
  ConsumerState<OreoApp> createState() => _OreoAppState();
}

class _OreoAppState extends ConsumerState<OreoApp> {
  int _selectedIndex = 0;
  int _examDurationMinutes = 30;
  MarkingScheme _examMarkingScheme = MarkingScheme.hybridUniversity;
  bool _examConfigured = false;

  bool _hasCheckedWorkspaces = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (authState.isAuthenticated && !_hasCheckedWorkspaces) {
      _hasCheckedWorkspaces = true;
      Future.microtask(() {
        ref.read(workspaceListProvider.notifier).loadWorkspaces().then((_) {
          final list = ref.read(workspaceListProvider);
          if (list.isNotEmpty && ref.read(activeWorkspaceIdProvider) == null) {
            ref.read(activeWorkspaceIdProvider.notifier).state = list.first.id;
          }
          if (list.isEmpty && mounted) {
            setState(() {
              _selectedIndex = 1;
            });
          }
        });
      });
    } else if (!authState.isAuthenticated) {
      _hasCheckedWorkspaces = false;
    }

    Widget homeWidget;
    if (authState.isLoading) {
      homeWidget = const Scaffold(
        backgroundColor: AppColors.bgCanvas,
        body: Center(child: CircularProgressIndicator()),
      );
    } else if (!authState.isAuthenticated) {
      homeWidget = const AuthScreen();
    } else {
      homeWidget = ResponsiveScaffold(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        child: _buildCurrentScreen(),
      );
    }

    final themeMode = switch (ref.watch(themeModeProvider)) {
      'Light' => ThemeMode.light,
      'System' => ThemeMode.system,
      _ => ThemeMode.dark,
    };

    return MaterialApp(
      title: 'Oreo Platform',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: homeWidget,
    );
  }

  Widget _buildCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return CommandCenterScreen(
          onNavigateToStudio: () {
            setState(() {
              _selectedIndex = 2; // Learning Studio
            });
          },
        );
      case 1:
        return MicroInterviewScreen(
          onInterviewComplete: () {
            setState(() {
              _selectedIndex = 2; // Move to Screen 02: Persona & Path Negotiation
            });
          },
        );
      case 2:
        return PersonaRevealScreen(
          onConfirmPersona: () {
            setState(() {
              _selectedIndex = 0; // Move to Screen 03: Command Center Dashboard
            });
          },
        );
      case 3:
        return MasterySurveyScreen(
          onReturnToDashboard: () {
            setState(() {
              _selectedIndex = 0;
            });
          },
        );
      case 4:
        return KnowledgeHubScreen(
          onNavigateToWorkspace: () {
            setState(() {
              _selectedIndex = 2; // Route to Workspace
            });
          },
        );
      case 5:
        return const ProfileSettingsScreen();
      case 6:
        final activeWs = ref.watch(activeWorkspaceProvider);
        final courseTitle = (activeWs?.title.isNotEmpty == true)
            ? activeWs!.title
            : ((activeWs?.subject.isNotEmpty == true) ? activeWs!.subject : 'Software Architecture Capstone');
        if (!_examConfigured) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: ExamConfigurationDialog(
                courseTitle: courseTitle,
                onStartExam: (duration, scheme) {
                  setState(() {
                    _examDurationMinutes = duration;
                    _examMarkingScheme = scheme;
                    _examConfigured = true;
                  });
                },
              ),
            ),
          );
        }
        return ProctoredExamScreen(
          durationMinutes: _examDurationMinutes,
          markingScheme: _examMarkingScheme,
          onExit: () {
            setState(() {
              _selectedIndex = 0;
              _examConfigured = false;
            });
          },
        );

      default:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.construction, size: 48, color: AppColors.accentAmber),
              const SizedBox(height: 16),
              Text(
                'Screen 0${_selectedIndex + 1} Under Development',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.fgPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Switch to Icon 1 (Micro-Interview) or Icon 2 (Persona & Path) on the left rail.',
                style: TextStyle(color: AppColors.fgSecondary),
              ),
            ],
          ),
        );
    }
  }
}
