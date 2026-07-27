package com.oreo.engine.orchestration.pipelines;

import com.oreo.engine.orchestration.model.OrchestrationRequest;
import com.oreo.engine.orchestration.model.OrchestrationResponse;
import com.oreo.engine.orchestration.schemas.DagOutputSchema;
import dev.langchain4j.model.chat.ChatLanguageModel;
import dev.langchain4j.service.AiServices;
import jakarta.annotation.PostConstruct;
import org.springframework.stereotype.Service;
import com.fasterxml.jackson.databind.ObjectMapper;

@Service
public class RoadmapUpdatePipeline {

    private final ChatLanguageModel primaryChatModel;
    private RoadmapUpdateAiService roadmapUpdateAiService;
    private final ObjectMapper objectMapper;

    public RoadmapUpdatePipeline(ChatLanguageModel primaryChatModel, ObjectMapper objectMapper) {
        this.primaryChatModel = primaryChatModel;
        this.objectMapper = objectMapper;
    }

    @PostConstruct
    public void init() {
        this.roadmapUpdateAiService = AiServices.builder(RoadmapUpdateAiService.class)
                .chatLanguageModel(primaryChatModel)
                .build();
    }

    public OrchestrationResponse run(OrchestrationRequest request, DagOutputSchema currentDag) {
        try {
            String currentDagJson = objectMapper.writeValueAsString(currentDag);
            
            String prompt = "[User Request]: " + request.getUserInput() + "\n\n" +
                            "[Current DAG]:\n" + currentDagJson;

            DagOutputSchema newDag = roadmapUpdateAiService.updateDag(prompt);

            return OrchestrationResponse.builder()
                    .payload(newDag)
                    .build();
        } catch (Exception e) {
            throw new RuntimeException("Failed to update roadmap", e);
        }
    }
}
