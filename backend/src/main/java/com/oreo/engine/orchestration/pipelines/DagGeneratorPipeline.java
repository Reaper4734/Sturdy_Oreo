package com.oreo.engine.orchestration.pipelines;

import com.oreo.engine.orchestration.schemas.DagOutputSchema;
import dev.langchain4j.model.chat.ChatLanguageModel;
import dev.langchain4j.service.AiServices;
import dev.langchain4j.service.SystemMessage;
import dev.langchain4j.service.UserMessage;
import com.oreo.auth.User;
import com.oreo.auth.UserRepository;
import com.oreo.engine.orchestration.models.LearningTrack;
import com.oreo.engine.orchestration.models.LearningTrackRepository;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class DagGeneratorPipeline {

    private final ChatLanguageModel primaryChatModel;
    private final UserRepository userRepository;
    private final LearningTrackRepository trackRepository;
    private DagAiService dagAiService;

    interface DagAiService {
        @SystemMessage("""
                You are a curriculum designer. Given a learner's cognitive profile and goal, generate a
                personalized learning track as a DAG (Directed Acyclic Graph).
                
                Rules:
                - Low Resilience (EQ) -> break into 15-20 micro-nodes with early wins
                - High Resilience (EQ) -> 5-8 large project-based nodes
                - Visual learner (IQ) -> set node type to "visual_theory" or "interactive"
                - Textual learner (IQ) -> set node type to "article" or "documentation"
                - Each node must have a unique ID (e.g. n1), title, type, prereqs list, rationale, and alternatives
                - prereqs must form a valid DAG (no cycles)
                - rationale: a 1-sentence explanation of WHY this node matters for the student's goal
                - alternatives: 2-3 topic alternatives the student could swap this node for
                
                Return the exact JSON matching the schema provided.
                """)
        DagOutputSchema generateDag(@UserMessage String userProfileAndGoal);
    }

    public DagGeneratorPipeline(ChatLanguageModel primaryChatModel, UserRepository userRepository, LearningTrackRepository trackRepository) {
        this.primaryChatModel = primaryChatModel;
        this.userRepository = userRepository;
        this.trackRepository = trackRepository;
        this.dagAiService = AiServices.builder(DagAiService.class)
                .chatLanguageModel(primaryChatModel)
                .build();
    }

    public DagOutputSchema generate(String goal, String persona, UUID userId) {
        String userProfile = "[Goal]: " + goal + "\n" +
                             "[Context]: {persona=" + persona + "}";

        // 2. Call LLM Pipeline with structured output mapping
        DagOutputSchema schema = dagAiService.generateDag(userProfile);

        User user = userRepository.findById(userId).orElse(null);
        if (user != null) {
            LearningTrack track = new LearningTrack();
            track.setUser(user);
            track.setGoal(schema.getGoal() != null ? schema.getGoal() : goal);
            track.setNodes(schema.getNodes());
            trackRepository.save(track);
        }

        return schema;
    }
}
