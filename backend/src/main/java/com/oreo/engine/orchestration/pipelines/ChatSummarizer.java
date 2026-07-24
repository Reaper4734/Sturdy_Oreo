package com.oreo.engine.orchestration.pipelines;

import dev.langchain4j.service.SystemMessage;
import dev.langchain4j.service.UserMessage;

public interface ChatSummarizer {

    @SystemMessage({
        "You are an expert summarizer.",
        "Extract the user's core learning goals and time constraints from the provided chat transcript.",
        "Output a concise paragraph containing ONLY their goals and available time.",
        "Do not include any conversational filler."
    })
    String summarize(@UserMessage String chatTranscript);
}
