package com.oreo.engine.orchestration;

import com.oreo.auth.User;
import com.oreo.auth.UserRepository;
import com.oreo.engine.orchestration.model.OrchestrationRequest;
import com.oreo.engine.orchestration.model.OrchestrationResponse;
import com.oreo.engine.orchestration.models.LearningTrack;
import com.oreo.engine.orchestration.models.LearningTrackRepository;
import com.oreo.engine.orchestration.schemas.DagOutputSchema;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class OrchestrationService {

    private final com.oreo.engine.orchestration.pipelines.DynamicProfilerPipeline dynamicProfilerPipeline;
    private final com.oreo.engine.orchestration.pipelines.DagGeneratorPipeline dagGeneratorPipeline;
    private final LearningTrackRepository trackRepository;
    private final UserRepository userRepository;

    public OrchestrationService(
            com.oreo.engine.orchestration.pipelines.DynamicProfilerPipeline dynamicProfilerPipeline,
            com.oreo.engine.orchestration.pipelines.DagGeneratorPipeline dagGeneratorPipeline,
            LearningTrackRepository trackRepository,
            UserRepository userRepository) {
        this.dynamicProfilerPipeline = dynamicProfilerPipeline;
        this.dagGeneratorPipeline = dagGeneratorPipeline;
        this.trackRepository = trackRepository;
        this.userRepository = userRepository;
    }

    @Transactional
    public OrchestrationResponse process(OrchestrationRequest request) {
        return switch (request.getMode()) {
            case INTERVIEW -> handleInterview(request);
            case DAG_GENERATE -> handleDagGenerate(request);
            default -> throw new UnsupportedOperationException("Mode not supported yet: " + request.getMode());
        };
    }

    private OrchestrationResponse handleInterview(OrchestrationRequest request) {
        return dynamicProfilerPipeline.run(request);
    }

    private OrchestrationResponse handleDagGenerate(OrchestrationRequest request) {
        OrchestrationResponse response = dagGeneratorPipeline.run(request);
        
        // C: Database Binding - Save the generated DAG
        if (response.getPayload() instanceof DagOutputSchema schema) {
            User user = userRepository.findById(request.getUserId())
                .orElse(null); // In real scenario, handle properly

            if (user != null) {
                LearningTrack track = new LearningTrack();
                track.setUser(user);
                track.setGoal(schema.getGoal() != null ? schema.getGoal() : request.getUserInput());
                track.setNodes(schema.getNodes());
                trackRepository.save(track);
            }
        }
        
        return response;
    }
}
