package com.oreo.engine.orchestration.pipelines;

import com.oreo.engine.orchestration.model.OrchestrationRequest;
import com.oreo.engine.orchestration.model.OrchestrationResponse;
import dev.langchain4j.data.segment.TextSegment;
import dev.langchain4j.memory.chat.MessageWindowChatMemory;
import dev.langchain4j.model.chat.ChatLanguageModel;
import dev.langchain4j.model.embedding.EmbeddingModel;
import dev.langchain4j.rag.content.retriever.EmbeddingStoreContentRetriever;
import dev.langchain4j.service.AiServices;
import dev.langchain4j.service.SystemMessage;
import dev.langchain4j.service.UserMessage;
import dev.langchain4j.store.embedding.EmbeddingStore;
import org.springframework.stereotype.Component;

import java.util.Map;

@Component
public class QuizEvaluatorPipeline {

    private final QuizGrader grader;

    public QuizEvaluatorPipeline(ChatLanguageModel chatLanguageModel, 
                                 EmbeddingStore<TextSegment> embeddingStore, 
                                 EmbeddingModel embeddingModel) {
        
        // RAG setup to retrieve textbook content when grading
        EmbeddingStoreContentRetriever contentRetriever = EmbeddingStoreContentRetriever.builder()
                .embeddingStore(embeddingStore)
                .embeddingModel(embeddingModel)
                .maxResults(3)
                .minScore(0.7)
                .build();

        this.grader = AiServices.builder(QuizGrader.class)
                .chatLanguageModel(chatLanguageModel)
                .contentRetriever(contentRetriever)
                .chatMemory(MessageWindowChatMemory.withMaxMessages(10))
                .build();
    }

    interface QuizGrader {
        @SystemMessage({
                "You are an expert AI grader.",
                "Review the student's answer against the retrieved context materials.",
                "Return a strict JSON response with keys: 'grade' (PASS or FAIL), and 'feedback' (a 1-sentence explanation)."
        })
        String gradeAnswer(@UserMessage String studentAnswer);
    }

    public OrchestrationResponse run(OrchestrationRequest request) {
        String jsonGrade = grader.gradeAnswer(request.getUserInput());
        
        // In a full implementation, we'd parse the JSON and update the LearnerPersona in DB here.
        
        return OrchestrationResponse.builder()
                .payload(Map.of("evaluation", jsonGrade))
                .build();
    }
}
