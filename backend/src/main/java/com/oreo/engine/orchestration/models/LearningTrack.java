package com.oreo.engine.orchestration.models;

import com.oreo.auth.User;
import com.oreo.engine.orchestration.schemas.DagOutputSchema.DagNode;
import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Data
@Entity
@Table(name = "learning_tracks")
public class LearningTrack {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false)
    private String goal;

    @Column(nullable = false, length = 20)
    private String status = "PROPOSED"; // PROPOSED, ACCEPTED, ARCHIVED

    @Column(name = "course_title")
    private String courseTitle;

    @Column(name = "difficulty")
    private String difficulty;

    @Column(name = "estimated_hours")
    private Integer estimatedHours;

    @Column(name = "graph_type")
    private String graphType = "DAG";

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(columnDefinition = "jsonb", nullable = false)
    private List<com.oreo.engine.orchestration.schemas.KnowledgeGraphSchema.KnowledgeNode> nodes;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(columnDefinition = "jsonb")
    private List<com.oreo.engine.orchestration.schemas.GraphEdge> edges;

    @Version
    private Integer version;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
