package com.oreo.engine.orchestration.pipelines;

import dev.langchain4j.model.chat.ChatLanguageModel;
import dev.langchain4j.service.AiServices;
import dev.langchain4j.service.SystemMessage;
import dev.langchain4j.service.UserMessage;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class CodingChallengePipeline {

    private final ChallengeGenerator generator;

    public CodingChallengePipeline(ChatLanguageModel chatLanguageModel) {
        this.generator = AiServices.create(ChallengeGenerator.class, chatLanguageModel);
    }

    public static class ExtractedChallenge {
        public String problemStatement;
        public String starterCode;
        public List<String> testCases;
    }

    interface ChallengeGenerator {
        @SystemMessage({
                "You are an expert computer science professor.",
                "Generate a single, highly focused coding challenge based on the provided video transcript snippet and student's doubt.",
                "The problem should directly address the student's doubt while testing the concepts from the transcript.",
                "Return the exact requested JSON format.",
                "CRITICAL: Always output in English, even if the transcript is in another language."
        })
        @UserMessage({
                "Transcript: {{transcript}}",
                "Student Doubt: {{doubtContext}}",
                "Language Target: {{language}}",
                "Generate the problem."
        })
        ExtractedChallenge generateChallenge(
                @dev.langchain4j.service.V("transcript") String transcript,
                @dev.langchain4j.service.V("doubtContext") String doubtContext,
                @dev.langchain4j.service.V("language") String language
        );
    }

    public ExtractedChallenge generate(String transcript, String doubtContext, String language) {
        return generator.generateChallenge(transcript, doubtContext, language);
    }
}
