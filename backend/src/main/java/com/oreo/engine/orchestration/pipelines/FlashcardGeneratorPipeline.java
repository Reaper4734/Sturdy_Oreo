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
        @UserMessage("The student is paused at timestamp {{timestamp}}. Analyze the flow of the transcript leading up to this point, identify the specific subtopic currently being discussed, and generate flashcards strictly covering this active topic. Transcript: {{text}}")
        ExtractedCardWrapper extractCards(@dev.langchain4j.service.V("text") String text, @dev.langchain4j.service.V("timestamp") String timestamp);
    }

    interface InitialFlashcardExtractor {
        @SystemMessage({
                "You are an AI assistant that creates initial flashcards for a new learning topic.",
                "Generate exactly 5 highly concise Anki-style flashcards.",
                "Ensure the 'frontQuestion' is a single clear question about the core concepts of the topic, and the 'backAnswer' is a short, direct answer."
        })
        @UserMessage("Generate 5 fundamental flashcards for the topic: {{topic}}")
        ExtractedCardWrapper extractInitialCards(@dev.langchain4j.service.V("topic") String topic);
    }

    private final InitialFlashcardExtractor initialExtractor;

    public FlashcardGeneratorPipeline(ChatLanguageModel chatLanguageModel) {
        this.extractor = AiServices.create(QAExtractor.class, chatLanguageModel);
        this.initialExtractor = AiServices.create(InitialFlashcardExtractor.class, chatLanguageModel);
    }

    public List<ExtractedCard> generateFlashcards(String transcriptSnippet, int timestampInSeconds) {
        String timestampStr = String.format("%02d:%02d", timestampInSeconds / 60, timestampInSeconds % 60);
        return extractor.extractCards(transcriptSnippet, timestampStr).cards;
    }

    public List<ExtractedCard> generateInitialFlashcards(String topic) {
        return initialExtractor.extractInitialCards(topic).cards;
    }
}
