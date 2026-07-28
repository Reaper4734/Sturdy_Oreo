package com.oreo.engine.orchestration.controller;

import com.oreo.engine.orchestration.pipelines.MindMapPipeline;
import com.oreo.engine.orchestration.pipelines.PersonaPipeline;
import com.oreo.engine.orchestration.schemas.MindMapSchema;
import com.oreo.engine.orchestration.schemas.PersonaProfileSchema;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.util.HtmlUtils;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/mindmap")
public class MindMapController {

    private final MindMapPipeline mindMapPipeline;
    private final PersonaPipeline personaPipeline;

    public MindMapController(MindMapPipeline mindMapPipeline, PersonaPipeline personaPipeline) {
        this.mindMapPipeline = mindMapPipeline;
        this.personaPipeline = personaPipeline;
    }

    @PostMapping("/generate")
    public ResponseEntity<Map<String, Object>> generateMindMap(@RequestBody Map<String, String> payload) {
        String rawSubject = payload.getOrDefault("subjectTitle", "General Knowledge");
        String subject = HtmlUtils.htmlEscape(rawSubject);
        String personaContext = payload.getOrDefault("persona", "A general learner.");
        
        MindMapSchema schema = mindMapPipeline.generateMindMap(subject);
        PersonaProfileSchema persona = personaPipeline.generatePersona(personaContext);
        
        Map<String, Object> response = new HashMap<>();
        response.put("subjectId", schema.getSubjectId());
        response.put("subjectTitle", schema.getSubjectTitle());
        response.put("rootNode", schema.getRootNode());
        response.put("persona", persona);
        
        return ResponseEntity.ok(response);
    }
}
