package com.oreo.engine.orchestration.controller;

import com.oreo.engine.orchestration.model.Workspace;
import com.oreo.engine.orchestration.repository.WorkspaceRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/workspaces")
public class WorkspaceController {

    private final WorkspaceRepository workspaceRepository;

    public WorkspaceController(WorkspaceRepository workspaceRepository) {
        this.workspaceRepository = workspaceRepository;
    }

    private UUID resolveUserId(String userId) {
        if (userId == null || userId.isBlank() || "anonymousUser".equalsIgnoreCase(userId)) {
            return UUID.fromString("00000000-0000-0000-0000-000000000001");
        }
        try {
            return UUID.fromString(userId);
        } catch (IllegalArgumentException e) {
            return UUID.nameUUIDFromBytes(userId.getBytes(java.nio.charset.StandardCharsets.UTF_8));
        }
    }

    @GetMapping
    public ResponseEntity<List<Map<String, Object>>> getAllWorkspaces(@AuthenticationPrincipal String userId) {
        UUID uid = resolveUserId(userId);
        List<Workspace> workspaces = workspaceRepository.findByUserId(uid);
        if (workspaces.isEmpty()) {
            workspaces = workspaceRepository.findAll();
        }
        List<Map<String, Object>> response = workspaces.stream()
                .map(Workspace::getData)
                .filter(java.util.Objects::nonNull)
                .collect(Collectors.toList());
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{id}")
    public ResponseEntity<Map<String, Object>> getWorkspace(@AuthenticationPrincipal String userId, @PathVariable String id) {
        return workspaceRepository.findById(id)
                .map(w -> ResponseEntity.ok(w.getData()))
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<Map<String, Object>> createWorkspace(@AuthenticationPrincipal String userId, @RequestBody Map<String, Object> payload) {
        UUID uid = resolveUserId(userId);
        String id = (String) payload.getOrDefault("id", "ws_" + System.currentTimeMillis());
        String title = (String) payload.getOrDefault("title", "New Workspace");

        Workspace ws = new Workspace();
        ws.setId(id);
        ws.setUserId(uid);
        ws.setTitle(title);
        ws.setData(payload);

        workspaceRepository.save(ws);
        return ResponseEntity.ok(ws.getData());
    }

    @PutMapping("/{id}")
    public ResponseEntity<Map<String, Object>> updateWorkspace(@AuthenticationPrincipal String userId, @PathVariable String id, @RequestBody Map<String, Object> payload) {
        return workspaceRepository.findById(id)
                .map(ws -> {
                    ws.setData(payload);
                    ws.setTitle((String) payload.getOrDefault("title", ws.getTitle()));
                    workspaceRepository.save(ws);
                    return ResponseEntity.ok(ws.getData());
                })
                .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteWorkspace(@AuthenticationPrincipal String userId, @PathVariable String id) {
        return workspaceRepository.findById(id)
                .map(ws -> {
                    workspaceRepository.delete(ws);
                    return ResponseEntity.ok().<Void>build();
                })
                .orElse(ResponseEntity.notFound().build());
    }
}
