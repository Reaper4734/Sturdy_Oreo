package com.oreo.engine.orchestration.pipelines;

import com.fasterxml.jackson.databind.ObjectMapper;
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

    public ProfilerOutputSchema run(String history, String userInput) {
        // 2. Call LLM Pipeline with structured output mapping
        return profilerAiService.chat(history, userInput);
    }
}
