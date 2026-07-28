package com.oreo.engine.orchestration.pipelines;

import com.oreo.engine.orchestration.schemas.FlashcardGenerationSchema;
import dev.langchain4j.service.SystemMessage;
import dev.langchain4j.service.UserMessage;

public interface FlashcardAiService {

    @SystemMessage("""
            You are an expert tutor creating study flashcards for a student.
            Given the topic or context, generate exactly 5 flashcards.
            
            Rules:
            - `front` should be a concise question, concept, or term.
            - `back` should be the detailed answer, definition, or explanation.
            - `topicTag` should be a short 1-2 word string categorizing the flashcard.
            - `type` should be exactly "basic", "fillBlank", or "codeSnippet".
            - `tags` should be an array of strings providing context.
            - Provide output matching the JSON schema precisely.
            """)
    FlashcardGenerationSchema generateFlashcards(@UserMessage String topic);
}
