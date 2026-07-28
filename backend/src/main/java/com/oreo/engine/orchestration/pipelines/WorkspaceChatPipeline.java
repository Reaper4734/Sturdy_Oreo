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
                You are Oreo AI, an intelligent learning assistant. You are chatting with a user who is currently in a Learning Lab Workspace.
                Your goal is to answer their questions about the curriculum, help them learn, and optionally customize their learning roadmap if they ask to add, remove, or change topics.

                Current Workspace Roadmap:
                {{roadmap}}
                
                [Conversation History]:
                {{history}}
                
                If the user asks to modify the roadmap, return the modified roadmap in the 'updatedRoadmap' field of the JSON output. 
                If the user is just asking a question, answer it in 'aiResponse' and return the existing roadmap exactly as is in 'updatedRoadmap'.
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
