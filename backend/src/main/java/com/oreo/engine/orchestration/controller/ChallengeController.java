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
        String doubtContext = (String) payload.getOrDefault("doubtContext", "I want to practice concepts taught here.");
        String language = (String) payload.getOrDefault("language", "Python");

        CodingChallengePipeline.ExtractedChallenge challenge = codingChallengePipeline.generate(videoId, timeInSeconds, doubtContext, language);
        return ResponseEntity.ok(challenge);
    }

    @PostMapping("/grade")
    public ResponseEntity<CodeGraderPipeline.GradingResult> gradeChallenge(@RequestBody Map<String, String> payload) {
        String problemStatement = payload.getOrDefault("problemStatement", "");
        String language = payload.getOrDefault("language", "Python");
        String code = payload.getOrDefault("code", "");

        CodeGraderPipeline.GradingResult result = codeGraderPipeline.evaluate(problemStatement, language, code);
        return ResponseEntity.ok(result);
    }
}
