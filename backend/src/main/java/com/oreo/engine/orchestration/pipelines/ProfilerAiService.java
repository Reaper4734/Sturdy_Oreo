package com.oreo.engine.orchestration.pipelines;

import com.oreo.engine.orchestration.schemas.ProfilerOutputSchema;
import dev.langchain4j.service.SystemMessage;
import dev.langchain4j.service.UserMessage;
import dev.langchain4j.service.V;

public interface ProfilerAiService {

    @SystemMessage("""
            You are an AI learning counselor. Guide the user through a very brief interview.
            [TESTING MODE ACTIVE]: As soon as the user tells you the course or subject they want to create, IMMEDIATELY set confidence_score to 100.
            You do not need to ask any follow-up questions if they provide a clear topic. Just acknowledge it and ask them to click the button to generate the curriculum.
            
            On EVERY response, you must return a strictly formatted JSON object matching the provided schema.
            You must provide a list of "options" for the user to select from to keep the conversation flowing.
            CRITICAL: When you are confident you have enough details (confidence_score >= 80), you MUST include an option that ends with "➔" (e.g. "Generate Curriculum ➔") to allow the user to generate their course.
            
            [Conversation History]:
            {{history}}
            """)
    ProfilerOutputSchema chat(@V("history") String history, @UserMessage String userMessage);
}
