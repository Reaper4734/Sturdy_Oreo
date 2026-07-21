package com.oreo.engine.orchestration.pipelines;

import com.oreo.engine.orchestration.model.OrchestrationRequest;
import com.oreo.engine.orchestration.model.OrchestrationResponse;
import com.oreo.engine.orchestration.schemas.DagOutputSchema;
import dev.langchain4j.model.chat.ChatLanguageModel;
import dev.langchain4j.service.AiServices;
import jakarta.annotation.PostConstruct;
import org.springframework.stereotype.Service;

@Service
public class DagGeneratorPipeline {

    private final ChatLanguageModel primaryChatModel;
    private DagAiService dagAiService;

    public DagGeneratorPipeline(ChatLanguageModel primaryChatModel) {
        this.primaryChatModel = primaryChatModel;
    }

    @PostConstruct
    public void init() {
        this.dagAiService = AiServices.builder(DagAiService.class)
                .chatLanguageModel(primaryChatModel)
                .build();
    }

    public OrchestrationResponse run(OrchestrationRequest request) {
        
        String userProfile = "[Goal]: " + request.getUserInput() + "\n" +
                             "[Context]: " + (request.getContext() != null ? request.getContext().toString() : "None");

        // 2. Call LLM Pipeline with structured output mapping
        DagOutputSchema output = dagAiService.generateDag(userProfile);

        // 3. Return formatted response (we pass the raw POJO since the TrackService will consume it)
        return OrchestrationResponse.builder()
                .payload(output)
                .build();
    }
}
