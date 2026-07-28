package com.oreo.engine.orchestration.model;

import jakarta.persistence.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.util.UUID;

@Entity
@Table(name = "curriculum_cache")
public class CurriculumCache {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(nullable = false, unique = true)
    private String subject;

    @Column(name = "mermaid_data", columnDefinition = "TEXT")
    private String mermaidData;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "resource_map_data", columnDefinition = "jsonb")
    private Object resourceMapData;

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public String getSubject() {
        return subject;
    }

    public void setSubject(String subject) {
        this.subject = subject;
    }

    public String getMermaidData() {
        return mermaidData;
    }

    public void setMermaidData(String mermaidData) {
        this.mermaidData = mermaidData;
    }

    public Object getResourceMapData() {
        return resourceMapData;
    }

    public void setResourceMapData(Object resourceMapData) {
        this.resourceMapData = resourceMapData;
    }
}
