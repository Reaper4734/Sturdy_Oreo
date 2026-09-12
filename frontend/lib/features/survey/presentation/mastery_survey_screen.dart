import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/providers/workspace_providers.dart';
import '../../../shared/models/mastery_test_model.dart';
import '../../survey/data/http_assessment_repository.dart';
import 'widgets/assessment_survey_layout.dart';

class MasterySurveyScreen extends ConsumerStatefulWidget {
  final VoidCallback? onReturnToDashboard;

  const MasterySurveyScreen({
    super.key,
    this.onReturnToDashboard,
  });

  @override
  ConsumerState<MasterySurveyScreen> createState() => _MasterySurveyScreenState();
}

class _MasterySurveyScreenState extends ConsumerState<MasterySurveyScreen> {
  List<QuestionItem> _dynamicQuestions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    try {
      final repo = ref.read(httpAssessmentRepositoryProvider);
      final activeWs = ref.read(activeWorkspaceProvider);
      final topic = activeWs?.activeLearningContext ?? 'General Computer Science';
      
      final questions = await repo.generateAssessment(topic);
      if (mounted) {
        setState(() {
          _dynamicQuestions = questions;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load assessment: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleCompleteTest() {
    final activeWs = ref.read(activeWorkspaceProvider);
    if (activeWs != null) {
      activeWs.progressPercent = (activeWs.progressPercent + 0.20).clamp(0.0, 1.0);
      triggerAutoSaveFeedback(ref);
    }

    if (widget.onReturnToDashboard != null) {
      widget.onReturnToDashboard!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      color: colors.bgCanvas,
      child: Column(
        children: [
          // --- Screen 05 Top Command Header & Layout Switcher ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: colors.bgActivityBar,
              border: Border(bottom: BorderSide(color: colors.borderSubtle, width: 0.8)),
            ),
            child: Row(
              children: [
                Icon(Icons.assignment_turned_in_outlined, size: 18, color: colors.accentEmerald),
                const SizedBox(width: 8),
                Text(
                  'Post-Tutorial Mastery Test',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.fgPrimary),
                ),
                const Spacer(),
              ],
            ),
          ),

          // --- Main Question Viewport ---
          Expanded(
            child: _isLoading 
                ? Center(child: CircularProgressIndicator(color: colors.accentPrimary))
                : AssessmentSurveyLayout(
                    questions: _dynamicQuestions,
                    onCompleteTest: _handleCompleteTest,
                  ),
          ),
        ],
      ),
    );
  }
}
