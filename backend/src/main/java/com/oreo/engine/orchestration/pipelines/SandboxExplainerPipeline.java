package com.oreo.engine.orchestration.pipelines;

import com.oreo.engine.orchestration.model.OrchestrationRequest;
import com.oreo.engine.orchestration.model.OrchestrationResponse;
import dev.langchain4j.model.chat.ChatLanguageModel;
import dev.langchain4j.service.AiServices;
import dev.langchain4j.service.SystemMessage;
import dev.langchain4j.service.UserMessage;
import org.springframework.stereotype.Component;

import java.util.Map;

@Component
public class SandboxExplainerPipeline {

    private final ChatLanguageModel chatLanguageModel;
    private final dev.langchain4j.store.embedding.EmbeddingStore<dev.langchain4j.data.segment.TextSegment> embeddingStore;
    private final dev.langchain4j.model.embedding.EmbeddingModel embeddingModel;
    private final com.oreo.engine.orchestration.YouTubeTranscriptService youtubeTranscriptService;
    private final SandboxTutor tutor;

    public SandboxExplainerPipeline(
            ChatLanguageModel chatLanguageModel,
            dev.langchain4j.store.embedding.EmbeddingStore<dev.langchain4j.data.segment.TextSegment> embeddingStore,
            dev.langchain4j.model.embedding.EmbeddingModel embeddingModel,
            com.oreo.engine.orchestration.YouTubeTranscriptService youtubeTranscriptService) {
        this.chatLanguageModel = chatLanguageModel;
        this.embeddingStore = embeddingStore;
        this.embeddingModel = embeddingModel;
        this.youtubeTranscriptService = youtubeTranscriptService;
        
        dev.langchain4j.memory.chat.ChatMemoryProvider chatMemoryProvider = memoryId -> dev.langchain4j.memory.chat.MessageWindowChatMemory.withMaxMessages(6);

        this.tutor = AiServices.builder(SandboxTutor.class)
                .chatLanguageModel(chatLanguageModel)
                .chatMemoryProvider(chatMemoryProvider)
                .build();
    }

    interface SandboxTutor {
        @SystemMessage({
                "You are Oreo, an expert universal AI video tutor for any subject (Coding, Biology, Physics, Math, History, Business, etc.).",
                "VIDEO PAUSE TIMESTAMP: {{videoTimestamp}} seconds (Video ID: {{videoId}}).",
                "CUMULATIVE LECTURE CONTENT & TRANSCRIPT (0s up to {{videoTimestamp}}s):",
                "{{videoTranscript}}",
                "UPLOADED BOOK / KNOWLEDGE BASE: {{ragContext}}",
                "UNIVERSAL LECTURE TUTORING RULES:",
                "1. Base your explanation STRICTLY on the cumulative lecture content delivered from 0s up to timestamp {{videoTimestamp}}s.",
                "2. DOMAIN ADAPTATION:",
                "   - For CODING lectures: Show the exact code snippet built up to {{videoTimestamp}}s and explain it line-by-line.",
                "   - For THEORY lectures (Biology, Physics, History, etc.): Explain the core biological/scientific concepts, mechanisms, or processes introduced up to {{videoTimestamp}}s.",
                "3. Do NOT mention advanced concepts or future lecture material that the instructor has not yet covered at {{videoTimestamp}}s.",
                "4. Keep explanations practical, clear, and engaging (2 short paragraphs max).",
                "5. ALWAYS end your response with a ```canvas-diagram JSON block (2-4 nodes) to visually render the current concept/code state on the canvas.",
                "6. IMPORTANT: The user's preferred language is {{language}}. Respond to their questions in {{language}} (translating your explanation if necessary), but keep JSON blocks in English.",
                "{{difficultyInstructions}}"
        })
        String answerDoubt(
                @dev.langchain4j.service.MemoryId java.util.UUID memoryId,
                @UserMessage String doubt,
                @dev.langchain4j.service.V("videoTranscript") String videoTranscript,
                @dev.langchain4j.service.V("ragContext") String ragContext,
                @dev.langchain4j.service.V("difficultyInstructions") String difficultyInstructions,
                @dev.langchain4j.service.V("videoTimestamp") String videoTimestamp,
                @dev.langchain4j.service.V("videoId") String videoId,
                @dev.langchain4j.service.V("language") String language
        );
    }

    public OrchestrationResponse run(OrchestrationRequest request) {
        Double vt = -1.0;
        if (request.getContext() != null && request.getContext().containsKey("videoTimestamp")) {
            vt = (Double) request.getContext().get("videoTimestamp");
        }
        String videoTimestampStr = vt >= 0 ? String.format("%.1f", vt) : "0.0";

        String videoId = "unknown";
        if (request.getContext() != null && request.getContext().containsKey("videoId")) {
            videoId = (String) request.getContext().get("videoId");
        }

        String language = "en";
        if (request.getContext() != null && request.getContext().containsKey("language")) {
            language = (String) request.getContext().get("language");
        }

        String videoTranscript = "";
        if (request.getContext() != null && request.getContext().containsKey("transcript")) {
            String t = (String) request.getContext().get("transcript");
            if (t != null && !t.isBlank()) {
                videoTranscript = t;
            }
        }
        if (videoTranscript.isBlank() && !videoId.equals("unknown")) {
            int timeInSeconds = (int) Math.max(0, Math.round(vt));
            videoTranscript = youtubeTranscriptService.getMultilingualCumulativeTranscript(videoId, timeInSeconds, language)
                    .orElse("Video " + videoId + " segment at timestamp " + videoTimestampStr + "s.");
        }

        String ragContext = "No uploaded documents found for this query.";

        // Perform RAG Retrieval from Vector DB
        try {
            String userQuery = request.getUserInput();
            dev.langchain4j.data.embedding.Embedding queryEmbedding = embeddingModel.embed(userQuery).content();
            
            dev.langchain4j.store.embedding.EmbeddingSearchRequest searchRequest = dev.langchain4j.store.embedding.EmbeddingSearchRequest.builder()
                    .queryEmbedding(queryEmbedding)
                    .maxResults(2)
                    .minScore(0.0)
                    .build();

            dev.langchain4j.store.embedding.EmbeddingSearchResult<dev.langchain4j.data.segment.TextSegment> searchResult = embeddingStore.search(searchRequest);
            var matches = searchResult.matches();
            
            if (matches != null && !matches.isEmpty()) {
                StringBuilder sb = new StringBuilder();
                for (var match : matches) {
                    String fn = match.embedded().metadata().getString("filename");
                    if (fn != null) {
                        sb.append("[File: ").append(fn).append("] ");
                    }
                    sb.append(match.embedded().text()).append("\n");
                }
                ragContext = sb.toString();
                if (ragContext.length() > 1200) {
                    ragContext = ragContext.substring(0, 1200) + "... [truncated for brevity]";
                }
            }
        } catch (Exception e) {
            System.err.println("RAG Search Error in SandboxExplainerPipeline: " + e.getMessage());
            e.printStackTrace();
        }

        int difficultyLevel = 3; // Default intermediate
        if (request.getContext() != null && request.getContext().containsKey("difficultyLevel")) {
            difficultyLevel = (Integer) request.getContext().get("difficultyLevel");
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
            String answer = tutor.answerDoubt(request.getUserId(), request.getUserInput(), videoTranscript, ragContext, difficultyInstructions, videoTimestampStr, videoId, language);
            return OrchestrationResponse.builder()
                    .payload(Map.of("explanation", answer))
                    .build();
        } catch (Exception e) {
            return fallbackRun(request, e);
        }
    }

    public OrchestrationResponse fallbackRun(OrchestrationRequest request, Throwable t) {
        // Fallback response when Gemini API is down, rate-limited, or timing out.
        System.err.println("Circuit Breaker triggered in SandboxExplainerPipeline: " + t.getMessage());
        t.printStackTrace();
        return OrchestrationResponse.builder()
                .payload(Map.of("explanation", "The AI Tutor is currently experiencing high traffic and is taking a quick break to recharge! Please try again in a few moments."))
                .build();
    }
}
