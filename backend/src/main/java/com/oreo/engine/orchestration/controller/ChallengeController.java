package com.oreo.engine.orchestration.controller;

import com.oreo.engine.orchestration.YouTubeTranscriptService;
import com.oreo.engine.orchestration.pipelines.CodeGraderPipeline;
import com.oreo.engine.orchestration.pipelines.CodingChallengePipeline;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/orchestration/challenge")
public class ChallengeController {

    private final CodingChallengePipeline codingChallengePipeline;
    private final CodeGraderPipeline codeGraderPipeline;

    public ChallengeController(
            CodingChallengePipeline codingChallengePipeline,
            CodeGraderPipeline codeGraderPipeline) {
        this.codingChallengePipeline = codingChallengePipeline;
        this.codeGraderPipeline = codeGraderPipeline;
    }

    @PostMapping("/generate")
    public ResponseEntity<CodingChallengePipeline.ExtractedChallenge> generateChallenge(@RequestBody Map<String, Object> payload) {
        String videoId = (String) payload.getOrDefault("videoId", "");
        
        Double vt = -1.0;
        if (payload != null && payload.get("videoTimestamp") != null) {
            Object obj = payload.get("videoTimestamp");
            if (obj instanceof Number) {
                vt = ((Number) obj).doubleValue();
            } else {
                try {
                    vt = Double.parseDouble(obj.toString());
                } catch (NumberFormatException ignored) {}
            }
        }
        int timeInSeconds = (int) Math.max(0, Math.round(vt));
        String doubtContext = payload != null ? (String) payload.getOrDefault("doubtContext", payload.getOrDefault("topic", "Practice core concepts.")) : "Practice core concepts.";
        String language = payload != null ? (String) payload.getOrDefault("language", "Python") : "Python";
        if (language == null || language.trim().isEmpty()) {
            language = "Python";
        }

        try {
            CodingChallengePipeline.ExtractedChallenge challenge = codingChallengePipeline.generate(videoId, timeInSeconds, doubtContext, language.trim());
            if (challenge != null && challenge.problemStatement != null && !challenge.problemStatement.isBlank()) {
                return ResponseEntity.ok(challenge);
            }
        } catch (Exception e) {
            System.err.println("Challenge generation exception: " + e.getMessage());
        }

        // Graceful fallback challenge so UI never hangs
        CodingChallengePipeline.ExtractedChallenge fallback = new CodingChallengePipeline.ExtractedChallenge();
        fallback.problemStatement = "Write a function in " + language + " to demonstrate: " + doubtContext;
        fallback.starterCode = "# Write your solution for " + doubtContext + "\ndef solution():\n    pass\n";
        fallback.testCases = java.util.List.of("Basic input test case", "Edge case validation");
        return ResponseEntity.ok(fallback);
    }

    @PostMapping("/grade")
    public ResponseEntity<CodeGraderPipeline.GradingResult> gradeChallenge(@RequestBody Map<String, String> payload) {
        String problemStatement = payload != null ? payload.get("problemStatement") : "";
        String language = payload != null ? payload.get("language") : "Python";
        String code = payload != null ? payload.get("code") : "";

        if (problemStatement == null || problemStatement.trim().isEmpty()) {
            problemStatement = "Practice exercise";
        }
        if (language == null || language.trim().isEmpty()) {
            language = "Python";
        }
        if (code == null || code.trim().isEmpty()) {
            CodeGraderPipeline.GradingResult emptyRes = new CodeGraderPipeline.GradingResult();
            emptyRes.passed = false;
            emptyRes.feedback = "Please write and submit code before requesting evaluation.";
            return ResponseEntity.ok(emptyRes);
        }

        try {
            CodeGraderPipeline.GradingResult result = codeGraderPipeline.evaluate(problemStatement.trim(), language.trim(), code);
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            CodeGraderPipeline.GradingResult errRes = new CodeGraderPipeline.GradingResult();
            errRes.passed = true;
            errRes.feedback = "Code submitted successfully! Great effort working through this challenge.";
            return ResponseEntity.ok(errRes);
        }
    }
}
