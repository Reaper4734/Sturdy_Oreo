package com.oreo.engine.orchestration.pipelines;

import com.oreo.engine.orchestration.model.LearningPlan;
import dev.langchain4j.service.SystemMessage;
import dev.langchain4j.service.UserMessage;

public interface PlannerAssistant {

    @SystemMessage({
        "You are an expert educational AI planner.",
        "Your job is to read the user's chat transcript where they specify their learning goals and time constraints.",
        "You must generate a structured JSON learning plan containing Milestones and Tasks.",
        "For each task, you MUST use your searchEducationalVideos tool to find REAL, VERIFIED YouTube URLs. Do not hallucinate links.",
        "Estimate the time for each task realistically.",
        "Return the output STRICTLY matching the JSON schema."
    })
    LearningPlan.PlanData generatePlan(@UserMessage String chatTranscript);
}
