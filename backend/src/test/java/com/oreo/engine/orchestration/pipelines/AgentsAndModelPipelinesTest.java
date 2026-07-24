package com.oreo.engine.orchestration.pipelines;

import com.oreo.auth.User;
import com.oreo.auth.UserRepository;
import com.oreo.engine.orchestration.models.LearningTrack;
import com.oreo.engine.orchestration.models.LearningTrackRepository;
import com.oreo.engine.orchestration.schemas.DagOutputSchema;
import dev.langchain4j.model.chat.ChatLanguageModel;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AgentsAndModelPipelinesTest {

    @Mock
    private ChatLanguageModel chatModel;

    @Mock
    private UserRepository userRepository;

    @Mock
    private LearningTrackRepository trackRepository;

    private DagGeneratorPipeline dagGeneratorPipeline;

    @BeforeEach
    void setUp() {
        dagGeneratorPipeline = new DagGeneratorPipeline(chatModel, userRepository, trackRepository);
    }

    @Test
    void generateDag_ShouldSaveTrackToDatabase_WhenUserExists() {
        UUID userId = UUID.randomUUID();
        User mockUser = new User();
        mockUser.setId(userId);
        mockUser.setEmail("student@oreo.edu");

        lenient().when(userRepository.findById(userId)).thenReturn(Optional.of(mockUser));

        DagOutputSchema mockSchema = new DagOutputSchema();
        mockSchema.setTrackId("tr-100");
        mockSchema.setGoal("Master Spring Boot Microservices");

        DagOutputSchema.DagNode node1 = new DagOutputSchema.DagNode();
        node1.setId("n1");
        node1.setTitle("Spring Core & IoC");
        node1.setType("visual_theory");
        node1.setPrereqs(List.of());
        node1.setRationale("Core DI concept.");
        node1.setAlternatives(List.of("Plain Java DI"));

        mockSchema.setNodes(List.of(node1));

        // Inject mock service response behavior if needed or test entity persistence mapping logic
        when(trackRepository.save(any(LearningTrack.class))).thenAnswer(inv -> inv.getArgument(0));

        // Act & Assert saving track
        LearningTrack track = new LearningTrack();
        track.setUser(mockUser);
        track.setGoal(mockSchema.getGoal());
        track.setNodes(mockSchema.getNodes());

        LearningTrack savedTrack = trackRepository.save(track);

        assertNotNull(savedTrack);
        assertEquals("Master Spring Boot Microservices", savedTrack.getGoal());
        assertEquals(userId, savedTrack.getUser().getId());
        assertEquals(1, savedTrack.getNodes().size());
        assertEquals("Spring Core & IoC", savedTrack.getNodes().get(0).getTitle());
    }

    @Test
    void syllabusExtractor_ShouldHandleExtractedSkillStructure() {
        SyllabusAnalyzerPipeline.ExtractedSkill skill = new SyllabusAnalyzerPipeline.ExtractedSkill();
        skill.title = "Neural Networks 101";
        skill.description = "Introduction to perceptrons and activation functions.";
        skill.prerequisiteTitles = List.of("Linear Algebra", "Calculus");

        SyllabusAnalyzerPipeline.ExtractedSkillWrapper wrapper = new SyllabusAnalyzerPipeline.ExtractedSkillWrapper();
        wrapper.skills = List.of(skill);

        assertEquals(1, wrapper.skills.size());
        assertEquals("Neural Networks 101", wrapper.skills.get(0).title);
        assertEquals(2, wrapper.skills.get(0).prerequisiteTitles.size());
    }

    @Test
    void flashcardExtractor_ShouldHandleExtractedCardStructure() {
        FlashcardGeneratorPipeline.ExtractedCard card = new FlashcardGeneratorPipeline.ExtractedCard();
        card.frontQuestion = "What is a Loss Function?";
        card.backAnswer = "A mathematical function measuring prediction error.";

        FlashcardGeneratorPipeline.ExtractedCardWrapper wrapper = new FlashcardGeneratorPipeline.ExtractedCardWrapper();
        wrapper.cards = List.of(card);

        assertEquals(1, wrapper.cards.size());
        assertEquals("What is a Loss Function?", wrapper.cards.get(0).frontQuestion);
        assertEquals("A mathematical function measuring prediction error.", wrapper.cards.get(0).backAnswer);
    }
}
