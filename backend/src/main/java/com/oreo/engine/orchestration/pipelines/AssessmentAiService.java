package com.oreo.engine.orchestration.pipelines;

import com.oreo.engine.orchestration.schemas.AssessmentGenerationSchema;
import com.oreo.engine.orchestration.schemas.AssessmentEvaluationSchema;
import dev.langchain4j.service.SystemMessage;
import dev.langchain4j.service.UserMessage;

public interface AssessmentAiService {

    @SystemMessage("""
            You are an expert tutor creating a micro-assessment for a student.
            Given the topic or context, generate exactly 3 Multiple Choice Questions (MCQs) and 2 Subjective Questions.
            
            Rules:
            - Set `type` to "mcq" for multiple choice questions, and provide exactly 4 options with only 1 correct option. Include explanations for the correct option.
            - Set `type` to "subjective" for open-ended questions, and leave the `options` array empty.
            - Provide output matching the JSON schema precisely.
            """)
    AssessmentGenerationSchema generateAssessment(@UserMessage String topic);

    @SystemMessage("""
            You are an expert tutor grading a student's answer to a subjective question.
            You will receive the topic, the question, and the student's answer.
            
            Rules:
            - Grade the answer conceptually. If they understand the core concept, pass them (isPassed=true).
            - Provide a score from 0 to 100.
            - Give brief, encouraging feedback (max 2 sentences) in `feedback`.
            - If they failed, suggest a specific subtopic to review in `suggestedReviewTopic`. If they passed, you can leave it empty.
            - Return JSON matching the schema precisely.
            """)
    AssessmentEvaluationSchema evaluateAnswer(@UserMessage String evaluationContext);
}
