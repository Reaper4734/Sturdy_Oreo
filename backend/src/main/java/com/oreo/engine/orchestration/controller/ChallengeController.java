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
        Double vt = payload.containsKey("videoTimestamp") ? Double.parseDouble(payload.get("videoTimestamp").toString()) : -1.0;
        int timeInSeconds = (int) Math.max(0, Math.round(vt));
        String doubtContext = (String) payload.getOrDefault("doubtContext", payload.getOrDefault("topic", "Practice core concepts."));
        String language = (String) payload.get("language");
        if (language == null || language.trim().isEmpty()) {
            throw new IllegalArgumentException("Target programming language is required for challenge generation.");
        }

        CodingChallengePipeline.ExtractedChallenge challenge = codingChallengePipeline.generate(videoId, timeInSeconds, doubtContext, language.trim());
        return ResponseEntity.ok(challenge);
    }

    @PostMapping("/grade")
    public ResponseEntity<CodeGraderPipeline.GradingResult> gradeChallenge(@RequestBody Map<String, String> payload) {
        String problemStatement = payload.get("problemStatement");
        String language = payload.get("language");
        String code = payload.get("code");

        if (problemStatement == null || problemStatement.trim().isEmpty()) {
            throw new IllegalArgumentException("Problem statement is required for grading.");
        }
        if (language == null || language.trim().isEmpty()) {
            throw new IllegalArgumentException("Language is required for grading.");
        }
        if (code == null || code.trim().isEmpty()) {
            throw new IllegalArgumentException("Submitted code is required for grading.");
        }

        CodeGraderPipeline.GradingResult result = codeGraderPipeline.evaluate(problemStatement.trim(), language.trim(), code);
        return ResponseEntity.ok(result);
    }
}
