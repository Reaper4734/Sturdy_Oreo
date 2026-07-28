package com.oreo.engine.orchestration.pipelines;

import com.oreo.engine.orchestration.schemas.PersonaProfileSchema;
import dev.langchain4j.model.chat.ChatLanguageModel;
import dev.langchain4j.service.AiServices;
import dev.langchain4j.service.SystemMessage;
import dev.langchain4j.service.UserMessage;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class PersonaPipeline {

    interface PersonaAiService {
        @SystemMessage("""
                You are an expert learning persona architect.
                
                Given a description of the learner's domain, subject, and inferred psychological metrics, generate a comprehensive Persona Profile in strict JSON format.
                
                RULES:
                - "renderMode" should be "default"
                - "title" should be a catchy archetype (e.g., "The Architect", "The Pragmatist")
                - "subtitle" should summarize the provided persona context
                - "summary" should be a 1-sentence encouraging summary of their learning style
                - "traits" should be 2 to 4 short phrases characterizing them
                - "metrics" MUST include all 5 cognitive metrics scaled from 0.1 to 1.0 based on the input
                - "blueprintNodes" MUST include 2 to 4 phases of learning progression (e.g. "Day 1-3", "Day 4-7")
                
                OUTPUT:
                Return ONLY the raw JSON object. No markdown formatting.
                """)
        PersonaProfileSchema generatePersona(@UserMessage String prompt);
    }

    private final PersonaAiService aiService;

    public PersonaPipeline(ChatLanguageModel chatLanguageModel) {
        this.aiService = AiServices.builder(PersonaAiService.class)
                .chatLanguageModel(chatLanguageModel)
                .build();
    }

    public PersonaProfileSchema generatePersona(String personaContext) {
        String prompt = "Generate a persona profile for a learner described as follows: " + personaContext;
        
        PersonaProfileSchema schema = null;
        for (int attempt = 1; attempt <= 2; attempt++) {
            try {
                schema = aiService.generatePersona(prompt);
                break;
            } catch (Exception e) {
                if (attempt == 2) {
                    throw new RuntimeException("Failed to generate Persona after 2 attempts: " + e.getMessage(), e);
                }
            }
        }
        
        return schema;
    }
}
