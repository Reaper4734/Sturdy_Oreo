package com.oreo.engine.orchestration.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.util.UUID;
import java.util.List;

@Entity
@Table(name = "learning_plans")
@Data
public class LearningPlan {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private UUID userId;
    private String goalStatement;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(columnDefinition = "jsonb")
    private PlanData planData;

    @Data
    public static class PlanData {
        private List<Milestone> milestones;
    }

    @Data
    public static class Milestone {
        private String id;
        private String title;
        private int orderIndex;
        private List<Task> tasks;
    }

    @Data
    public static class Task {
        private String id;
        private String title;
        private int estimatedMinutes;
        private int actualTimeSpentMinutes;
        private java.time.LocalDate deadlineDate;
        private String resourceUrl;
        private boolean isCompleted;
    }
}
