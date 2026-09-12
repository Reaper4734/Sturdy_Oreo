package com.oreo.engine.orchestration.model;

import jakarta.persistence.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.type.SqlTypes;

import java.time.LocalDateTime;
import java.util.Map;

@Entity
@Table(name = "workspace_note_blocks")
public class WorkspaceNoteBlock {

    @Id
    @Column(length = 255)
    private String id;

    @Column(name = "page_id", nullable = false, length = 255)
    private String pageId;

    @Column(nullable = false, length = 50)
    private String type;

    @Column(columnDefinition = "TEXT")
    private String content = "";

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(columnDefinition = "jsonb")
    private Map<String, Object> metadata;

    @Column(name = "sort_order")
    private int sortOrder = 0;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    public WorkspaceNoteBlock() {}

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getPageId() { return pageId; }
    public void setPageId(String pageId) { this.pageId = pageId; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }

    public Map<String, Object> getMetadata() { return metadata; }
    public void setMetadata(Map<String, Object> metadata) { this.metadata = metadata; }

    public int getSortOrder() { return sortOrder; }
    public void setSortOrder(int sortOrder) { this.sortOrder = sortOrder; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}
