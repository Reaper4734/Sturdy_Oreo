package com.oreo.engine.orchestration.model;

import jakarta.persistence.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "workspace_note_pages")
public class WorkspaceNotePage {

    @Id
    @Column(length = 255)
    private String id;

    @Column(name = "workspace_id", nullable = false, length = 255)
    private String workspaceId;

    @Column(nullable = false, length = 255)
    private String title = "Untitled";

    @Column(name = "parent_page_id", length = 255)
    private String parentPageId;

    @Column(length = 50)
    private String icon;

    @Column(name = "sort_order")
    private int sortOrder = 0;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    public WorkspaceNotePage() {}

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getWorkspaceId() { return workspaceId; }
    public void setWorkspaceId(String workspaceId) { this.workspaceId = workspaceId; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getParentPageId() { return parentPageId; }
    public void setParentPageId(String parentPageId) { this.parentPageId = parentPageId; }

    public String getIcon() { return icon; }
    public void setIcon(String icon) { this.icon = icon; }

    public int getSortOrder() { return sortOrder; }
    public void setSortOrder(int sortOrder) { this.sortOrder = sortOrder; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}
