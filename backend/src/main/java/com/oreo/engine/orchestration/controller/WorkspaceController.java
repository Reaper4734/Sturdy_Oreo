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

    @GetMapping
    public ResponseEntity<List<Map<String, Object>>> getAllWorkspaces(@AuthenticationPrincipal String userId) {
        List<Workspace> workspaces = workspaceRepository.findByUserId(UUID.fromString(userId));
        List<Map<String, Object>> response = workspaces.stream().map(Workspace::getData).collect(Collectors.toList());
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{id}")
    public ResponseEntity<Map<String, Object>> getWorkspace(@AuthenticationPrincipal String userId, @PathVariable String id) {
        return workspaceRepository.findById(id)
                .filter(w -> w.getUserId().equals(UUID.fromString(userId)))
                .map(w -> ResponseEntity.ok(w.getData()))
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<Map<String, Object>> createWorkspace(@AuthenticationPrincipal String userId, @RequestBody Map<String, Object> payload) {
        String id = (String) payload.getOrDefault("id", "ws_" + System.currentTimeMillis());
        String title = (String) payload.getOrDefault("title", "New Workspace");

        Workspace ws = new Workspace();
        ws.setId(id);
        ws.setUserId(UUID.fromString(userId));
        ws.setTitle(title);
        ws.setData(payload);

        workspaceRepository.save(ws);
        return ResponseEntity.ok(ws.getData());
    }

    @PutMapping("/{id}")
    public ResponseEntity<Map<String, Object>> updateWorkspace(@AuthenticationPrincipal String userId, @PathVariable String id, @RequestBody Map<String, Object> payload) {
        return workspaceRepository.findById(id)
                .filter(w -> w.getUserId().equals(UUID.fromString(userId)))
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
                .filter(w -> w.getUserId().equals(UUID.fromString(userId)))
                .map(ws -> {
                    workspaceRepository.delete(ws);
                    return ResponseEntity.ok().<Void>build();
                })
                .orElse(ResponseEntity.notFound().build());
    }
}
