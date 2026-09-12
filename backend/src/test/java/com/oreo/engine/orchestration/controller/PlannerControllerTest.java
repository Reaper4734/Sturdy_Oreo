package com.oreo.engine.orchestration.controller;

import com.oreo.engine.orchestration.model.LearningPlan;
import com.oreo.engine.orchestration.pipelines.PlannerAssistant;
import com.oreo.engine.orchestration.pipelines.ChatSummarizer;
import com.oreo.engine.orchestration.repository.LearningPlanRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.simp.SimpMessagingTemplate;

import java.time.LocalDate;
import java.util.*;
import java.util.concurrent.CompletableFuture;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class PlannerControllerTest {

    @Mock
    private PlannerAssistant plannerAssistant;
    
    @Mock
    private ChatSummarizer chatSummarizer;

    @Mock
    private LearningPlanRepository learningPlanRepository;

    @InjectMocks
    private PlannerController plannerController;

    private LearningPlan mockPlan;

    @BeforeEach
    void setUp() {
        mockPlan = new LearningPlan();
        mockPlan.setId(UUID.randomUUID());
        mockPlan.setUserId(UUID.randomUUID());
        
        LearningPlan.PlanData data = new LearningPlan.PlanData();
        List<LearningPlan.Milestone> milestones = new ArrayList<>();
        
        LearningPlan.Milestone m1 = new LearningPlan.Milestone();
        List<LearningPlan.Task> tasks = new ArrayList<>();
        
        LearningPlan.Task t1 = new LearningPlan.Task();
        t1.setId("task-1");
        t1.setCompleted(false);
        t1.setDeadlineDate(LocalDate.now().minusDays(1)); // Overdue
        
        LearningPlan.Task t2 = new LearningPlan.Task();
        t2.setId("task-2");
        t2.setCompleted(true);
        t2.setDeadlineDate(LocalDate.now().plusDays(2));
        
        tasks.add(t1);
        tasks.add(t2);
        m1.setTasks(tasks);
        milestones.add(m1);
        data.setMilestones(milestones);
        mockPlan.setPlanData(data);
    }

    @Test
    void testReschedulePlan_ShiftsIncompleteDeadlinesForward() {
        // Arrange
        when(learningPlanRepository.findByUserId(any(UUID.class))).thenReturn(Optional.of(mockPlan));
        when(learningPlanRepository.save(any(LearningPlan.class))).thenAnswer(i -> i.getArgument(0));
        
        LocalDate originalOverdueDate = mockPlan.getPlanData().getMilestones().get(0).getTasks().get(0).getDeadlineDate();
        LocalDate originalFutureDate = mockPlan.getPlanData().getMilestones().get(0).getTasks().get(1).getDeadlineDate();
        
        // Act
        ResponseEntity<LearningPlan> response = plannerController.reschedulePlan(mockPlan.getUserId().toString());
        
        // Assert
        assertNotNull(response.getBody());
        LearningPlan updatedPlan = response.getBody();
        LearningPlan.Task shiftedTask = updatedPlan.getPlanData().getMilestones().get(0).getTasks().get(0);
        LearningPlan.Task unmodifiedTask = updatedPlan.getPlanData().getMilestones().get(0).getTasks().get(1);
        
        // Incomplete task should be shifted +2 days from its original date (-1 + 2 = +1 day from today)
        assertEquals(LocalDate.now().plusDays(1), shiftedTask.getDeadlineDate());
        assertNotEquals(originalOverdueDate, shiftedTask.getDeadlineDate());
        
        // Completed task should NOT be modified
        assertEquals(originalFutureDate, unmodifiedTask.getDeadlineDate());
    }

    @Test
    void testAdaptPlan_SynchronousExecution_InjectsRemedialTask() {
        // Arrange
        String failedTaskId = "task-1";

        when(learningPlanRepository.findByUserId(any(UUID.class))).thenReturn(Optional.of(mockPlan));
        when(learningPlanRepository.save(any(LearningPlan.class))).thenAnswer(i -> i.getArgument(0));

        LearningPlan.Task aiGeneratedTask = new LearningPlan.Task();
        aiGeneratedTask.setTitle("AI Generated Remedial Concept");
        when(plannerAssistant.generateRemedialTask(anyString())).thenReturn(aiGeneratedTask);

        Map<String, String> payload = new HashMap<>();
        payload.put("failedTaskId", failedTaskId);
        payload.put("failedQuestion", "What is Java?");
        payload.put("userAnswer", "A type of coffee.");

        // Act
        ResponseEntity<LearningPlan> response = plannerController.adaptPlan(mockPlan.getUserId().toString(), payload);

        // Assert the HTTP response is 200 OK directly
        assertEquals(200, response.getStatusCode().value());
        assertNotNull(response.getBody());
        LearningPlan adaptedPlan = response.getBody();
        assertTrue(adaptedPlan.getPlanData().getMilestones().get(0).getTasks().size() > 2,
                "Remedial task should be injected into the milestone");
    }
}
