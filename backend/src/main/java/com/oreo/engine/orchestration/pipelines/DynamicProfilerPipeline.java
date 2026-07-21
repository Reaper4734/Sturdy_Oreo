package com.oreo.engine.orchestration.pipelines;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.oreo.engine.orchestration.model.OrchestrationRequest;
import com.oreo.engine.orchestration.model.OrchestrationResponse;
import com.oreo.engine.orchestration.schemas.ProfilerOutputSchema;
import dev.langchain4j.model.chat.ChatLanguageModel;
import dev.langchain4j.service.AiServices;
import jakarta.annotation.PostConstruct;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
public class DynamicProfilerPipeline {

    private final ChatLanguageModel primaryChatModel;
    private final ObjectMapper objectMapper;
    private ProfilerAiService profilerAiService;

    public DynamicProfilerPipeline(ChatLanguageModel primaryChatModel, ObjectMapper objectMapper) {
        this.primaryChatModel = primaryChatModel;
        this.objectMapper = objectMapper;
    }

    @PostConstruct
    public void init() {
        // LangChain4j dynamically implements the interface and wires the fallback model
        this.profilerAiService = AiServices.builder(ProfilerAiService.class)
                .chatLanguageModel(primaryChatModel)
                .build();
    }

    public OrchestrationResponse run(OrchestrationRequest request) {
        // 1. Extract context / history (mocking sliding window for now)
        String history = (request.getContext() != null && request.getContext().containsKey("history"))
                ? request.getContext().get("history").toString()
                : "No prior history.";

        // 2. Call LLM Pipeline with structured output mapping
        ProfilerOutputSchema output = profilerAiService.chat(history, request.getUserInput());

        // 3. Convert InternalState to Map for the generic OrchestrationResponse
        Map<String, Object> stateMap = objectMapper.convertValue(output.getInternalState(), Map.class);

        // 4. Return formatted response
        return OrchestrationResponse.builder()
                .replyToUser(output.getReplyToUser())
                .internalState(stateMap)
                .build();
    }
}
