package com.oreo.engine.orchestration.pipelines;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.oreo.engine.orchestration.schemas.WorkspaceChatOutputSchema;
import dev.langchain4j.model.chat.ChatLanguageModel;
import dev.langchain4j.service.AiServices;
import dev.langchain4j.service.SystemMessage;
import dev.langchain4j.service.UserMessage;
import dev.langchain4j.service.V;
import org.springframework.stereotype.Service;

@Service
public class WorkspaceChatPipeline {

    private final WorkspaceAiService workspaceAiService;

    interface WorkspaceAiService {
        @SystemMessage("""
                You are Oreo AI, an intelligent learning assistant. You are chatting with a student in a Learning Lab Workspace.
                Your goal is to answer their questions, explain concepts clearly, and optionally customize their learning roadmap if they explicitly ask to add, remove, or modify topics.

                Current Workspace Roadmap:
                {{roadmap}}
                
                [Conversation History]:
                {{history}}
                
                CRITICAL INSTRUCTIONS:
                1. If the user is chatting, asking questions, or learning concepts: Answer thoroughly and clearly in 'aiResponse', and leave 'updatedRoadmap' as null.
                2. ONLY if the user explicitly asks to add, remove, or modify roadmap modules/topics: Provide a brief explanation in 'aiResponse' and return the complete updated roadmap in 'updatedRoadmap'.
                """)
        WorkspaceChatOutputSchema chat(@V("history") String history, @V("roadmap") String roadmap, @UserMessage String userMessage);
    }

    public WorkspaceChatPipeline(ChatLanguageModel primaryChatModel) {
        this.workspaceAiService = AiServices.builder(WorkspaceAiService.class)
                .chatLanguageModel(primaryChatModel)
                .build();
    }

    public WorkspaceChatOutputSchema run(String history, String roadmapJson, String userInput) {
        return workspaceAiService.chat(history, roadmapJson, userInput);
    }
}
