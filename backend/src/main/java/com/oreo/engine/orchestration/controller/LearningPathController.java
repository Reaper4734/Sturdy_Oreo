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

    private final SyllabusAnalyzerPipeline analyzerPipeline;
    private final SkillNodeRepository skillNodeRepository;

    public LearningPathController(SyllabusAnalyzerPipeline analyzerPipeline, SkillNodeRepository skillNodeRepository) {
        this.analyzerPipeline = analyzerPipeline;
        this.skillNodeRepository = skillNodeRepository;
    }

    public record SyllabusUploadRequest(String text, UUID userId) {}

    @PostMapping("/generate")
    public ResponseEntity<List<SkillNode>> generatePath(@RequestBody SyllabusUploadRequest request) {
        // Run LangChain4j structured extraction
        List<SyllabusAnalyzerPipeline.ExtractedSkill> extractedSkills = analyzerPipeline.generateTreeFromText(request.text());
        
        List<SkillNode> savedNodes = new ArrayList<>();
        
        for (int i = 0; i < extractedSkills.size(); i++) {
            SyllabusAnalyzerPipeline.ExtractedSkill ex = extractedSkills.get(i);
            SkillNode node = new SkillNode();
            node.setUserId(request.userId());
            node.setTitle(ex.title);
            node.setDescription(ex.description);
            // First node is ACTIVE, others are LOCKED initially
            node.setStatus(i == 0 ? SkillNode.NodeStatus.ACTIVE : SkillNode.NodeStatus.LOCKED);
            node.setPrerequisiteIds(String.join(",", ex.prerequisiteTitles));
            
            savedNodes.add(skillNodeRepository.save(node));
        }

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
