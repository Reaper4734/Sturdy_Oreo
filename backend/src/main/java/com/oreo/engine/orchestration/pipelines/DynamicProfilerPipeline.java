package com.oreo.engine.orchestration.pipelines;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.oreo.engine.orchestration.schemas.ProfilerOutputSchema;
import dev.langchain4j.model.chat.ChatLanguageModel;
import dev.langchain4j.service.AiServices;
import dev.langchain4j.service.SystemMessage;
import dev.langchain4j.service.UserMessage;
import dev.langchain4j.service.V;
import org.springframework.stereotype.Service;


@Service
public class DynamicProfilerPipeline {

    private ProfilerAiService profilerAiService;

    interface ProfilerAiService {
        @SystemMessage("""
                You are an AI learning counselor. Guide the user through a 4-phase interview.
                Phase 1 (Anchor): Ask about their broad learning goals, and explicitly identify the EXACT 'subject' they want to learn today (e.g. "Python", "Data Structures", "Accounting").
                Phase 2 (Friction): Ask about past learning blockers. Use observational language, not emotional.
                  Do NOT ask "what frustrated you" — instead ask "where did you get stuck or lose interest?"
                Phase 3 (Scenario): Ask about their problem-solving style.
                Phase 4 (Pivot): Summarize and ask for permission to build a plan.

                IMPORTANT: When filling the JSON schema, the 'domain' field MUST be categorized as a broad Industry (e.g., "Computer Science", "Finance"), but the 'subject' field MUST be the specific topic they want to learn (e.g., "Python", "Accounting").

                On EVERY response, you must return a strictly formatted JSON object matching the provided schema.

                [Conversation History]:
                {{history}}
                """)
        ProfilerOutputSchema chat(@V("history") String history, @UserMessage String userMessage);
    }

    public DynamicProfilerPipeline(ChatLanguageModel primaryChatModel, ObjectMapper objectMapper) {
        this.profilerAiService = AiServices.builder(ProfilerAiService.class)
                .chatLanguageModel(primaryChatModel)
                .build();
    }

    public ProfilerOutputSchema run(String history, String userInput) {
        // 2. Call LLM Pipeline with structured output mapping
        return profilerAiService.chat(history, userInput);
    }
}
