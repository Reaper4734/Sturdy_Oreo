package com.oreo.engine.orchestration.pipelines;

import com.oreo.engine.orchestration.model.OrchestrationRequest;
import com.oreo.engine.orchestration.model.OrchestrationResponse;
import dev.langchain4j.model.chat.ChatLanguageModel;
import dev.langchain4j.service.AiServices;
import dev.langchain4j.service.SystemMessage;
import dev.langchain4j.service.UserMessage;
import org.springframework.stereotype.Component;

import java.util.Map;

@Component
public class SmartNudgePipeline {

    private final ChatLanguageModel chatLanguageModel;
    private final NudgeAgent nudgeAgent;

    public SmartNudgePipeline(ChatLanguageModel chatLanguageModel) {
        this.chatLanguageModel = chatLanguageModel;
        this.nudgeAgent = AiServices.builder(NudgeAgent.class)
                .chatLanguageModel(chatLanguageModel)
                .build();
    }

    interface NudgeAgent {
        @SystemMessage({
                "You are an AI learning coach.",
                "The student has been idle for several minutes.",
                "Generate a short, engaging, 1-sentence nudge to get their attention back to the canvas.",
                "Do not be aggressive. Be encouraging or mildly playful."
        })
        String generateNudge(@UserMessage String context);
    }

    public OrchestrationResponse run(OrchestrationRequest request) {
        String nudgeMessage = nudgeAgent.generateNudge("Student is idle. Current topic is unknown.");
        return OrchestrationResponse.builder()
                .payload(Map.of("intervention_type", "nudge", "message", nudgeMessage))
                .build();
    }
}
