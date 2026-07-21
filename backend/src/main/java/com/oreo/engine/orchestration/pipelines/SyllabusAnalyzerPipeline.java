package com.oreo.engine.orchestration.pipelines;

import com.oreo.engine.orchestration.model.SkillNode;
import dev.langchain4j.model.chat.ChatLanguageModel;
import dev.langchain4j.service.AiServices;
import dev.langchain4j.service.SystemMessage;
import dev.langchain4j.service.UserMessage;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class SyllabusAnalyzerPipeline {

    private final SyllabusExtractor extractor;

    public SyllabusAnalyzerPipeline(ChatLanguageModel chatLanguageModel) {
        this.extractor = AiServices.create(SyllabusExtractor.class, chatLanguageModel);
    }

    // We define a POJO specifically for LangChain4j structured output mapping
    public static class ExtractedSkill {
        public String title;
        public String description;
        public List<String> prerequisiteTitles;
    }

    interface SyllabusExtractor {
        @SystemMessage({
                "You are an expert curriculum designer.",
                "Extract a logical skill tree from the provided syllabus text.",
                "Return the exact requested JSON format mapping out concepts into manageable nodes.",
                "Ensure advanced topics have the correct prerequisites listed."
        })
        @UserMessage("Generate a learning tree for this text: {{text}}")
        List<ExtractedSkill> extractTree(@dev.langchain4j.service.V("text") String text);
    }

    public List<ExtractedSkill> generateTreeFromText(String syllabusText) {
        return extractor.extractTree(syllabusText);
    }
}
