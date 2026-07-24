package com.oreo.engine.orchestration.pipelines;

import dev.langchain4j.model.chat.ChatLanguageModel;
import dev.langchain4j.service.AiServices;
import dev.langchain4j.service.SystemMessage;
import dev.langchain4j.service.UserMessage;
import org.springframework.stereotype.Component;

@Component
public class CodeGraderPipeline {

    private final Grader grader;

    public CodeGraderPipeline(ChatLanguageModel chatLanguageModel) {
        this.grader = AiServices.create(Grader.class, chatLanguageModel);
    }

    public static class GradingResult {
        public boolean passed;
        public String feedback;
        public String optimizedCode;
    }

    interface Grader {
        @SystemMessage({
                "You are an expert automated code grader.",
                "Evaluate the student's submitted code against the problem statement.",
                "1. If the logic is correct and fulfills the requirements, set 'passed' to true.",
                "2. If the logic is incorrect, has syntax errors, or fails edge cases, set 'passed' to false.",
                "3. Provide targeted, educational feedback in 'feedback'. Do not just give the answer immediately if they failed.",
                "4. Optionally provide 'optimizedCode' if there's a better way to write it.",
                "Return the exact requested JSON format."
        })
        @UserMessage({
                "Problem Statement: {{problem}}",
                "Language: {{language}}",
                "Student Code:\n{{code}}",
                "Evaluate the submission."
        })
        GradingResult grade(
                @dev.langchain4j.service.V("problem") String problem,
                @dev.langchain4j.service.V("language") String language,
                @dev.langchain4j.service.V("code") String code
        );
    }

    public GradingResult evaluate(String problem, String language, String code) {
        return grader.grade(problem, language, code);
    }
}
