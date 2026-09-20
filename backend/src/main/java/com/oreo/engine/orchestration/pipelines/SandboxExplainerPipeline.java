package com.oreo.engine.orchestration.pipelines;

import dev.langchain4j.model.chat.ChatLanguageModel;
import dev.langchain4j.service.AiServices;
import dev.langchain4j.service.SystemMessage;
import dev.langchain4j.service.UserMessage;
import org.springframework.stereotype.Component;

import java.util.Map;

@Component
public class SandboxExplainerPipeline {

    private static final String SYSTEM_PROMPT = "You are Oreo, an expert universal AI video tutor for any subject (Coding, Biology, Physics, Math, History, Business, etc.).\n" +
            "VIDEO PAUSE TIMESTAMP: {{videoTimestamp}} seconds (Video ID: {{videoId}}).\n" +
            "CUMULATIVE LECTURE CONTENT & TRANSCRIPT (0s up to {{videoTimestamp}}s):\n" +
            "{{videoTranscript}}\n" +
            "UNIVERSAL LECTURE TUTORING RULES:\n" +
            "1. Base your explanation STRICTLY on the cumulative lecture content delivered from 0s up to timestamp {{videoTimestamp}}s.\n" +
            "2. DOMAIN ADAPTATION:\n" +
            "   - For CODING lectures: Show the exact code snippet built up to {{videoTimestamp}}s and explain it line-by-line.\n" +
            "   - For THEORY lectures (Biology, Physics, History, etc.): Explain the core biological/scientific concepts, mechanisms, or processes introduced up to {{videoTimestamp}}s.\n" +
            "3. Do NOT mention advanced concepts or future lecture material that the instructor has not yet covered at {{videoTimestamp}}s.\n" +
            "4. Keep explanations practical, clear, and engaging (2 short paragraphs max).\n" +
            "5. ALWAYS end your response with a ```canvas-diagram JSON block (2-4 nodes) to visually render the current concept/code state on the canvas.\n" +
            "6. IMPORTANT: The user's preferred language is {{language}}. Respond to their questions in {{language}} (translating your explanation if necessary), but keep JSON blocks in English.\n" +
            "{{difficultyInstructions}}";

    private final ChatLanguageModel chatLanguageModel;
    private final com.oreo.engine.orchestration.YouTubeTranscriptService youtubeTranscriptService;
    private final SandboxTutor tutor;

    public SandboxExplainerPipeline(
            ChatLanguageModel chatLanguageModel,
            com.oreo.engine.orchestration.YouTubeTranscriptService youtubeTranscriptService,
            com.oreo.engine.orchestration.rag.HybridRetriever hybridRetriever) {
        this.chatLanguageModel = chatLanguageModel;
        this.youtubeTranscriptService = youtubeTranscriptService;
        
        dev.langchain4j.memory.chat.ChatMemoryProvider chatMemoryProvider = memoryId -> dev.langchain4j.memory.chat.MessageWindowChatMemory.withMaxMessages(6);

        dev.langchain4j.rag.RetrievalAugmentor augmentor = dev.langchain4j.rag.DefaultRetrievalAugmentor.builder()
                .contentRetriever(hybridRetriever)
                .build();

        this.tutor = AiServices.builder(SandboxTutor.class)
                .chatLanguageModel(chatLanguageModel)
                .chatMemoryProvider(chatMemoryProvider)
                .retrievalAugmentor(augmentor)
                .build();
    }

    interface SandboxTutor {

        @SystemMessage(SYSTEM_PROMPT)
        String answerDoubt(
                @dev.langchain4j.service.MemoryId java.util.UUID memoryId,
                @UserMessage String doubt,
                @dev.langchain4j.service.V("videoTranscript") String videoTranscript,
                @dev.langchain4j.service.V("difficultyInstructions") String difficultyInstructions,
                @dev.langchain4j.service.V("videoTimestamp") String videoTimestamp,
                @dev.langchain4j.service.V("videoId") String videoId,
                @dev.langchain4j.service.V("language") String language
        );

        @SystemMessage(SYSTEM_PROMPT)
        String answerDoubtWithImage(
                @dev.langchain4j.service.MemoryId java.util.UUID memoryId,
                @dev.langchain4j.service.UserMessage dev.langchain4j.data.message.UserMessage userMessage,
                @dev.langchain4j.service.V("videoTranscript") String videoTranscript,
                @dev.langchain4j.service.V("difficultyInstructions") String difficultyInstructions,
                @dev.langchain4j.service.V("videoTimestamp") String videoTimestamp,
                @dev.langchain4j.service.V("videoId") String videoId,
                @dev.langchain4j.service.V("language") String language
        );
    }

    public Map<String, String> explain(java.util.UUID userId, String doubt, double videoTimestamp, String videoId, String language, int difficultyLevel, String imageBase64) {
        String videoTimestampStr = videoTimestamp >= 0 ? String.format("%.1f", videoTimestamp) : "0.0";
        String videoTranscript = "";

        if (!videoId.equals("unknown")) {
            int timeInSeconds = (int) Math.max(0, Math.round(videoTimestamp));
            videoTranscript = youtubeTranscriptService.getMultilingualCumulativeTranscript(videoId, timeInSeconds, language)
                    .orElse("Video " + videoId + " segment at timestamp " + videoTimestampStr + "s.");
        }

        String difficultyInstructions = switch (difficultyLevel) {
            case 1 -> "Use extremely simple words and everyday analogies suitable for a 5-year-old.";
            case 2 -> "Explain in plain English, avoiding complex jargon.";
            case 3 -> "Give a standard, clear explanation.";
            case 4 -> "Use formal terminology and assume strong foundational knowledge.";
            case 5 -> "Assume the user is a domain expert. Use rigorous mathematical formulas and advanced terminology.";
            default -> "Give a standard, clear explanation.";
        };

        try {
            String answer;
            if (imageBase64 != null && !imageBase64.isEmpty()) {
                // Remove data:image/png;base64, prefix if present
                String base64Data = imageBase64.contains(",") ? imageBase64.split(",")[1] : imageBase64;
                dev.langchain4j.data.message.UserMessage msg = dev.langchain4j.data.message.UserMessage.from(
                    dev.langchain4j.data.message.TextContent.from(doubt),
                    dev.langchain4j.data.message.ImageContent.from(base64Data, "image/png")
                );
                answer = tutor.answerDoubtWithImage(userId, msg, videoTranscript, difficultyInstructions, videoTimestampStr, videoId, language);
            } else {
                answer = tutor.answerDoubt(userId, doubt, videoTranscript, difficultyInstructions, videoTimestampStr, videoId, language);
            }

            String cleanExplanation = answer;
            String diagramJson = null;

            if (answer != null) {
                java.util.regex.Pattern pattern = java.util.regex.Pattern.compile("```(?:canvas-diagram|json)?\\s*([\\s\\S]*?\\{[\\s\\S]*?\"nodes\"[\\s\\S]*?\\})\\s*```", java.util.regex.Pattern.CASE_INSENSITIVE);
                java.util.regex.Matcher matcher = pattern.matcher(answer);
                if (matcher.find()) {
                    diagramJson = matcher.group(1).trim();
                    cleanExplanation = (answer.substring(0, matcher.start()).trim() + "\n" + answer.substring(matcher.end()).trim()).trim();
                }
            }

            Map<String, String> result = new java.util.HashMap<>();
            result.put("explanation", (cleanExplanation != null && !cleanExplanation.isEmpty()) ? cleanExplanation : answer);
            if (diagramJson != null && !diagramJson.isEmpty()) {
                result.put("diagram", diagramJson);
            }
            return result;
        } catch (Exception e) {
            return fallbackRun(e);
        }
    }

    public Map<String, String> fallbackRun(Throwable t) {
        // Fallback response when Gemini API is down, rate-limited, or timing out.
        System.err.println("Circuit Breaker triggered in SandboxExplainerPipeline: " + t.getMessage());
        t.printStackTrace();
        return Map.of(
            "explanation", "The AI Tutor is currently experiencing high traffic and is taking a quick break to recharge! Please try again in a few moments.",
            "isFallback", "true"
        );
    }
}
