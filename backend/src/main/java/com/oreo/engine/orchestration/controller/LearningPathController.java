package com.oreo.engine.orchestration.controller;

import com.oreo.engine.orchestration.model.SkillNode;
import com.oreo.engine.orchestration.pipelines.SyllabusAnalyzerPipeline;
import com.oreo.engine.orchestration.repository.SkillNodeRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/learning-path")
public class LearningPathController {

    private final com.oreo.engine.orchestration.pipelines.LearningPathService learningPathService;
    private final SkillNodeRepository skillNodeRepository;

    public LearningPathController(com.oreo.engine.orchestration.pipelines.LearningPathService learningPathService, SkillNodeRepository skillNodeRepository) {
        this.learningPathService = learningPathService;
        this.skillNodeRepository = skillNodeRepository;
    }

    public record SyllabusUploadRequest(String text, UUID userId) {}

    @PostMapping("/generate")
    public ResponseEntity<List<SkillNode>> generatePath(@RequestBody SyllabusUploadRequest request) {
        List<SkillNode> savedNodes = learningPathService.generateAndSavePath(request.text(), request.userId());

        return ResponseEntity.ok(savedNodes);
    }

    @GetMapping("/{userId}")
    public ResponseEntity<List<SkillNode>> getTree(@PathVariable UUID userId) {
        return ResponseEntity.ok(skillNodeRepository.findByUserId(userId));
    }
    
    @PostMapping("/node/{nodeId}/complete")
    public ResponseEntity<String> completeNode(@PathVariable UUID nodeId) {
        SkillNode node = skillNodeRepository.findById(nodeId).orElseThrow();
        node.setStatus(SkillNode.NodeStatus.MASTERED);
        skillNodeRepository.save(node);
        
        // In a full implementation, this is where we'd unlock dependent nodes by scanning prerequisites.
        return ResponseEntity.ok("Node Mastered");
    }
}
