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
    private final SandboxTutor tutor;

    public SandboxExplainerPipeline(ChatLanguageModel chatLanguageModel) {
        this.chatLanguageModel = chatLanguageModel;
        this.tutor = AiServices.builder(SandboxTutor.class)
                .chatLanguageModel(chatLanguageModel)
                // In a full implementation, we would add ChatMemoryProvider here for context
                .build();
    }

    interface SandboxTutor {
        @SystemMessage({
                "You are an AI Tutor attached to an interactive whiteboard.",
                "The user is watching a video. Here is what the video was saying when they paused it: {{transcript}}",
                "Explain the user's doubt clearly based on that context.",
                "{{difficultyInstructions}}"
        })
        String answerDoubt(@UserMessage String doubt, @dev.langchain4j.service.V("transcript") String transcript, @dev.langchain4j.service.V("difficultyInstructions") String difficultyInstructions);
    }

    @io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker(name = "geminiCircuitBreaker", fallbackMethod = "fallbackRun")
    public OrchestrationResponse run(OrchestrationRequest request) {
        String transcript = "No video context provided.";
        if (request.getContext() != null && request.getContext().containsKey("transcript")) {
            transcript = (String) request.getContext().get("transcript");
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

        String answer = tutor.answerDoubt(request.getUserInput(), transcript, difficultyInstructions);
        return OrchestrationResponse.builder()
                .payload(Map.of("explanation", answer))
                .build();
    }

    public OrchestrationResponse fallbackRun(OrchestrationRequest request, Throwable t) {
        // Fallback response when Gemini API is down, rate-limited, or timing out.
        return OrchestrationResponse.builder()
                .payload(Map.of("explanation", "The AI Tutor is currently experiencing high traffic and is taking a quick break to recharge! Please try again in a few moments."))
                .build();
    }
}
