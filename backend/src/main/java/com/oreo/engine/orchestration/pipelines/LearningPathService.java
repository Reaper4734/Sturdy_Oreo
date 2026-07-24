package com.oreo.engine.orchestration.pipelines;

import com.oreo.engine.orchestration.model.SkillNode;
import com.oreo.engine.orchestration.repository.SkillNodeRepository;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
public class LearningPathService {

    private final SyllabusAnalyzerPipeline analyzerPipeline;
    private final SkillNodeRepository skillNodeRepository;

    public LearningPathService(SyllabusAnalyzerPipeline analyzerPipeline, SkillNodeRepository skillNodeRepository) {
        this.analyzerPipeline = analyzerPipeline;
        this.skillNodeRepository = skillNodeRepository;
    }

    public List<SkillNode> generateAndSavePath(String text, UUID userId) {
        List<SyllabusAnalyzerPipeline.ExtractedSkill> extractedSkills = analyzerPipeline.generateTreeFromText(text);
        List<SkillNode> savedNodes = new ArrayList<>();
        
        for (int i = 0; i < extractedSkills.size(); i++) {
            SyllabusAnalyzerPipeline.ExtractedSkill ex = extractedSkills.get(i);
            SkillNode node = new SkillNode();
            node.setUserId(userId);
            node.setTitle(ex.title);
            node.setDescription(ex.description);
            node.setStatus(i == 0 ? SkillNode.NodeStatus.ACTIVE : SkillNode.NodeStatus.LOCKED);
            if (ex.prerequisiteTitles != null) {
                node.setPrerequisiteIds(String.join(",", ex.prerequisiteTitles));
            }
            savedNodes.add(skillNodeRepository.save(node));
        }
        return savedNodes;
    }
}
