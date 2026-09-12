enum QuestionType { shortPopup, longMcq, codeTerminal, subjective }

class QuestionnaireOption {
  final String id;
  final String text;
  final bool isCorrect;
  final String? explanation;

  const QuestionnaireOption({
    required this.id,
    required this.text,
    this.isCorrect = false,
    this.explanation,
  });
}

class CodeTestCase {
  final String id;
  final String description;
  final String expectedOutput;
  final String userOutput;
  final bool isPassed;

  const CodeTestCase({
    required this.id,
    required this.description,
    required this.expectedOutput,
    required this.userOutput,
    required this.isPassed,
  });
}

class QuestionItem {
  final String id;
  final String questionText;
  final String topicTag;
  final QuestionType type;
  final List<QuestionnaireOption> options;
  final String? codeInitialTemplate;
  final String? codeSolution;
  final String? expectedOutput;
  final List<CodeTestCase> testCases;
  final String? language;
  final String? hint;

  const QuestionItem({
    required this.id,
    required this.questionText,
    required this.topicTag,
    required this.type,
    this.options = const [],
    this.codeInitialTemplate,
    this.codeSolution,
    this.expectedOutput,
    this.testCases = const [],
    this.language,
    this.hint,
  });
}

class TestResultSummary {
  final int totalQuestions;
  final int correctAnswers;
  final double scorePercent;
  final String masteryTier;
  final int recommendedIntervalDays;
  final int xpEarned;

  const TestResultSummary({
    required this.totalQuestions,
    required this.correctAnswers,
    required this.scorePercent,
    required this.masteryTier,
    required this.recommendedIntervalDays,
    required this.xpEarned,
  });
}
