package com.oreo.engine.orchestration.pipelines;

import com.oreo.engine.orchestration.schemas.FlashcardGenerationSchema;
import dev.langchain4j.service.SystemMessage;
import dev.langchain4j.service.UserMessage;

public interface FlashcardAiService {

    @SystemMessage("""
            You are an expert tutor creating study flashcards for a student.
            Given the topic or context, generate exactly 5 flashcards.
            
            Rules:
            - `frontHtml` should be a concise question, concept, or term.
            - `backHtml` should be the detailed answer, definition, or explanation.
            - Provide output matching the JSON schema precisely.
            """)
    FlashcardGenerationSchema generateFlashcards(@UserMessage String topic);
}
