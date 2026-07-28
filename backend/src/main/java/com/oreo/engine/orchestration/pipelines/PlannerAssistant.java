package com.oreo.engine.orchestration.pipelines;

import com.oreo.engine.orchestration.model.LearningPlan;
import dev.langchain4j.service.SystemMessage;
import dev.langchain4j.service.UserMessage;

public interface PlannerAssistant {

    @SystemMessage({
        "You are an expert educational AI planner.",
        "Your job is to read the user's chat transcript where they specify their learning goals and time constraints.",
        "You must generate a structured JSON learning plan containing Milestones and Tasks.",
        "You MUST use your web search tool to research real curriculums (e.g. GeeksForGeeks, W3Schools, official docs) so you do not hallucinate.",
        "For each task, you MUST use your searchEducationalVideos tool to find REAL, VERIFIED YouTube URLs. Do not hallucinate links.",
        "Estimate the time for each task realistically.",
        "Return the output STRICTLY matching the JSON schema."
    })
    LearningPlan.PlanData generatePlan(@UserMessage String goalSummary);

    @SystemMessage({
        "You are an expert tutor.",
        "The user just failed a quiz. You will be provided with the question and their incorrect answer.",
        "1. Write a 3-sentence 'Micro-Lesson' in the task 'description' explaining exactly the correct answer and why their specific answer was wrong.",
        "2. Use your YouTubeSearchTool to find a real, highly specific tutorial for the 'resourceUrl'.",
        "Return EXACTLY ONE Task object in JSON format.",
        "Title the task starting with '[Remedial]'."
    })
    LearningPlan.Task generateRemedialTask(@UserMessage String failedContext);
}
