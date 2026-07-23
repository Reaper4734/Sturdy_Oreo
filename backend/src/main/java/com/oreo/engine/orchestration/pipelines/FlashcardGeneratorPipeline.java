package com.oreo.engine.orchestration.pipelines;

import dev.langchain4j.model.chat.ChatLanguageModel;
import dev.langchain4j.service.AiServices;
import dev.langchain4j.service.SystemMessage;
import dev.langchain4j.service.UserMessage;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class FlashcardGeneratorPipeline {

    private final QAExtractor extractor;

    public FlashcardGeneratorPipeline(ChatLanguageModel chatLanguageModel) {
        this.extractor = AiServices.create(QAExtractor.class, chatLanguageModel);
    }

    public static class ExtractedCard {
        public String frontQuestion;
        public String backAnswer;
    }

    public static class ExtractedCardWrapper {
        public List<ExtractedCard> cards;
    }

    interface QAExtractor {
        @SystemMessage({
                "You are an AI assistant that extracts key educational facts from a conversation transcript.",
                "Generate highly concise Anki-style flashcards.",
                "Ensure the 'frontQuestion' is a single clear question, and the 'backAnswer' is a short, direct answer.",
                "CRITICAL: Regardless of the language of the transcript, you MUST translate and generate ALL flashcards in English."
        })
        @UserMessage("Generate flashcards for this transcript snippet: {{text}}")
        ExtractedCardWrapper extractCards(@dev.langchain4j.service.V("text") String text);
    }

    public List<ExtractedCard> generateFlashcards(String transcriptSnippet) {
        return extractor.extractCards(transcriptSnippet).cards;
    }
}
