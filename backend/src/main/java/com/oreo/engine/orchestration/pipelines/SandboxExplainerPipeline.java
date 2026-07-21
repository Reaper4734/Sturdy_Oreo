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
                "Explain the user's doubt clearly based on that context."
        })
        String answerDoubt(@UserMessage String doubt, @dev.langchain4j.service.V("transcript") String transcript);
    }

    public OrchestrationResponse run(OrchestrationRequest request) {
        String transcript = "No video context provided.";
        if (request.getContext() != null && request.getContext().containsKey("transcript")) {
            transcript = (String) request.getContext().get("transcript");
        }

        String answer = tutor.answerDoubt(request.getUserInput(), transcript);
        return OrchestrationResponse.builder()
                .payload(Map.of("explanation", answer))
                .build();
    }
}
