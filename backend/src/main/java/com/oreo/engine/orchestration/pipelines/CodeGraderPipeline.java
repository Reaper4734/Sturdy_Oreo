package com.oreo.engine.orchestration.pipelines;

import dev.langchain4j.model.chat.ChatLanguageModel;
import dev.langchain4j.service.AiServices;
import dev.langchain4j.service.SystemMessage;
import dev.langchain4j.service.UserMessage;
import org.springframework.stereotype.Component;

@Component
public class CodeGraderPipeline {

    private final Grader grader;
    private final LocalExecutionService executionService;

    public CodeGraderPipeline(ChatLanguageModel chatLanguageModel, LocalExecutionService executionService) {
        this.executionService = executionService;
        this.grader = AiServices.create(Grader.class, chatLanguageModel);
    }

    public static class GradingResult {
        public boolean passed;
        public String feedback;
        public String optimizedCode;
    }

    interface Grader {
        @SystemMessage({
                "You are an expert automated code tutor.",
                "The student's code has already been executed securely.",
                "1. If 'executionPassed' is true, praise the student and optionally provide 'optimizedCode'. Set 'passed' to true.",
                "2. If 'executionPassed' is false, analyze the 'executionStderr' or 'executionStdout'. Set 'passed' to false.",
                "3. Provide targeted, educational feedback explaining the error in plain English in the 'feedback' field.",
                "Return the exact requested JSON format."
        })
        @UserMessage({
                "Problem Statement: {{problem}}",
                "Language: {{language}}",
                "Student Code:\n{{code}}",
                "--- Execution Results ---",
                "Execution Passed: {{executionPassed}}",
                "Stdout: {{stdout}}",
                "Stderr: {{stderr}}",
                "Evaluate the submission and tutor the student."
        })
        GradingResult grade(
                @dev.langchain4j.service.V("problem") String problem,
                @dev.langchain4j.service.V("language") String language,
                @dev.langchain4j.service.V("code") String code,
                @dev.langchain4j.service.V("executionPassed") boolean executionPassed,
                @dev.langchain4j.service.V("stdout") String stdout,
                @dev.langchain4j.service.V("stderr") String stderr
        );
    }

    public GradingResult evaluate(String problem, String language, String code) {
        // Step 1: Real Code Execution via Local ProcessBuilder
        LocalExecutionService.ExecutionResult execResult = executionService.executeCode(language, code);
        
        // Step 2: AI Tutoring on the actual execution results
        return grader.grade(problem, language, code, execResult.passed, execResult.stdout, execResult.stderr);
    }
}
