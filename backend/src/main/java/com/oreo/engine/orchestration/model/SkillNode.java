package com.oreo.engine.orchestration.model;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "skill_nodes")
@Data
@NoArgsConstructor
public class SkillNode {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private UUID userId;

    private String title;

    @Column(length = 1000)
    private String description;

    @Enumerated(EnumType.STRING)
    private NodeStatus status; // LOCKED, ACTIVE, MASTERED

    // Stores prerequisite node IDs as a comma-separated string for simplicity in this MVP
    private String prerequisiteIds; 

    public enum NodeStatus {
        LOCKED, ACTIVE, MASTERED
    }
}
