package com.oreo.engine.orchestration.pipelines;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.oreo.engine.orchestration.model.OrchestrationRequest;
import com.oreo.engine.orchestration.model.OrchestrationResponse;
import com.oreo.engine.orchestration.schemas.ProfilerOutputSchema;
import dev.langchain4j.model.chat.ChatLanguageModel;
import dev.langchain4j.service.AiServices;
import dev.langchain4j.service.SystemMessage;
import dev.langchain4j.service.UserMessage;
import dev.langchain4j.service.V;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
public class DynamicProfilerPipeline {

    private final ChatLanguageModel primaryChatModel;
    private final ObjectMapper objectMapper;
    private ProfilerAiService profilerAiService;

    interface ProfilerAiService {
        @SystemMessage("""
                You are an AI learning counselor. Guide the user through a 4-phase interview.
                Phase 1 (Anchor): Ask about their goal.
                Phase 2 (Friction): Ask about past learning blockers. Use observational language, not emotional.
                  Do NOT ask "what frustrated you" — instead ask "where did you get stuck or lose interest?"
                Phase 3 (Scenario): Ask about their problem-solving style.
                Phase 4 (Pivot): Summarize and ask for permission to build a plan.
                
                On EVERY response, you must return a strictly formatted JSON object matching the provided schema.
                
                [Conversation History]:
                {{history}}
                """)
        ProfilerOutputSchema chat(@V("history") String history, @UserMessage String userMessage);
    }

    public DynamicProfilerPipeline(ChatLanguageModel primaryChatModel, ObjectMapper objectMapper) {
        this.primaryChatModel = primaryChatModel;
        this.objectMapper = objectMapper;
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
