package com.oreo.engine.orchestration.pipelines;

import dev.langchain4j.service.SystemMessage;
import dev.langchain4j.service.UserMessage;
import lombok.Data;
import java.util.List;

public interface AssessmentAssistant {

    @Data
    class AssessmentPayload {
        private List<MCQ> multipleChoiceQuestions;
        private List<SubjectiveQuestion> subjectiveQuestions;
    }

    @Data
    class MCQ {
        private String question;
        private List<String> options;
        private String correctAnswer;
        private String explanation;
    }

    @Data
    class SubjectiveQuestion {
        private String question;
        private String gradingRubric;
    }

    @Data
    class EvaluationResult {
        private int score;
        private String feedback;
        private boolean passed;
    }

    @SystemMessage({
        "You are an expert examiner.",
        "Generate a challenging assessment based on the provided topic.",
        "Return EXACTLY 3 Multiple Choice Questions and 2 Subjective Questions.",
        "Output MUST strictly match the requested JSON schema."
    })
    AssessmentPayload generateAssessment(@UserMessage String topic);

    @SystemMessage({
        "You are a strict but fair professor grading a student's answer.",
        "Evaluate the student's answer against the original question.",
        "Return a score from 0 to 100, detailed feedback, and a boolean 'passed' (true if score >= 50).",
        "Output MUST strictly match the requested JSON schema."
    })
    EvaluationResult evaluateAnswer(@UserMessage String gradingPrompt);
}
